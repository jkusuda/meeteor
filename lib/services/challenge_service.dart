import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:meeteor/core/challenge_models.dart';

class ChallengeService {
  final SupabaseClient _client = Supabase.instance.client;

  bool _supportsActivationDate = true;

  Future<List<DailyChallenge>> fetchChallenges() async {
    try {
      final rows = await (_supportsActivationDate
          ? _client
                .from('challenges')
                .select()
                .order('activation_date', ascending: false)
          : _client
                .from('challenges')
                .select()
                .order('created_at', ascending: false));

      final mapped = List<Map<String, dynamic>>.from(
        rows,
      ).map((row) => DailyChallenge.fromMap(row)).toList();

      return Future.wait(mapped.map(_attachSubmissions));
    } catch (e) {
      final errorText = e.toString();
      if (errorText.contains('activation_date') && _supportsActivationDate) {
        _supportsActivationDate = false;
        return fetchChallenges();
      }
      debugPrint('Error fetching challenges: $e');
      rethrow;
    }
  }

  Future<DailyChallenge> _attachSubmissions(DailyChallenge challenge) async {
    try {
      final rows = await _client
          .from('user_challenges')
          .select(
            'id, user_id, challenge_id, completed_at, imageUrl, users(username)',
          )
          .eq('challenge_id', challenge.id)
          .order('completed_at', ascending: false);

      final imageUrls = List<Map<String, dynamic>>.from(rows)
          .map((row) => (row['imageUrl'] ?? '').toString())
          .where((url) => url.isNotEmpty)
          .toSet()
          .toList();

      final postCaptionByImageUrl = <String, String>{};
      if (imageUrls.isNotEmpty) {
        final postRows = await _client
            .from('posts')
            .select('image_url, caption')
            .inFilter('image_url', imageUrls);

        for (final postRow in List<Map<String, dynamic>>.from(postRows)) {
          final imageUrl = (postRow['image_url'] ?? '').toString();
          final caption = (postRow['caption'] ?? '').toString();
          if (imageUrl.isNotEmpty) {
            postCaptionByImageUrl[imageUrl] = caption;
          }
        }
      }

      final submissions = List<Map<String, dynamic>>.from(rows).map((row) {
        final user = row['users'] as Map<String, dynamic>?;
        final completedAt = _parseDate(row['completed_at']);
        final imageUrl = (row['imageUrl'] ?? '').toString();
        return ChallengeSubmission(
          username: (user?['username'] as String? ?? 'Anonymous').toString(),
          imageUrl: imageUrl,
          note: postCaptionByImageUrl[imageUrl]?.trim().isNotEmpty == true
              ? postCaptionByImageUrl[imageUrl]!.trim()
              : 'Challenge submission',
          gear: 'Posted from Meeteor',
          timeAgo: submissionTimeLabel(completedAt),
          accentColor: highlightForIndex(row['id'].hashCode.abs()),
          completedAt: completedAt,
        );
      }).toList();

      return challenge.copyWith(submissions: submissions);
    } catch (e) {
      debugPrint('Error loading submissions for ${challenge.id}: $e');
      return challenge;
    }
  }

  Future<(bool, String)> saveChallenge({
    required DailyChallenge? existing,
    required String title,
    required String description,
    required String activationDateRaw,
    required String selectedIcon,
    required List<String> tips,
    XFile? imageFile,
    Uint8List? imageBytes,
  }) async {
    if (title.isEmpty || description.isEmpty) {
      return (false, 'Title and description are required.');
    }

    final activationDate = DateTime.tryParse(activationDateRaw);
    if (activationDate == null) {
      return (false, 'Activation Date is required.');
    }

    // New challenges must have an image; edits can keep the old one.
    final bool isNew = existing == null;
    if (isNew && (imageFile == null || imageBytes == null)) {
      return (false, 'An image is required for new challenges.');
    }

    if (_supportsActivationDate) {
      final conflict = await hasChallengeOnDate(
        activationDate: activationDate,
        excludingId: existing?.id,
      );
      if (conflict) {
        return (false, 'A challenge already exists for that activation date.');
      }
    }

    // Resolve image URL
    String imageUrl = existing?.imageUrl ?? '';
    if (imageFile != null && imageBytes != null) {
      imageUrl = await _uploadImage(imageFile, imageBytes);
    }

    final cleanTips = tips.where((t) => t.isNotEmpty).toList();
    final data = {
      'title': title,
      'description': description,
      'imageURL': imageUrl,
      'icon': selectedIcon,
      'tips': cleanTips.isEmpty
          ? const [
              'Add a few practical shooting tips so people know where to start.',
            ]
          : cleanTips,
      'activation_date': dateKey(activationDate),
    };

    try {
      if (isNew) {
        await _client.from('challenges').insert(data);
      } else {
        await _client.from('challenges').update(data).eq('id', existing.id);
      }
      final msg = isNew
          ? 'Daily challenge created.'
          : 'Daily challenge updated.';
      return (true, msg);
    } catch (e) {
      final errorText = e.toString();

      // Fallback when activation_date column doesn't exist.
      if (errorText.contains('activation_date') && _supportsActivationDate) {
        _supportsActivationDate = false;
        final label = relativeDateLabel(activationDate);
        final retryData = {
          'title': title,
          'description': description,
          'imageURL': imageUrl,
          'icon': selectedIcon,
          'tips': data['tips'],
          'badge_label': label == 'Today' ? 'Today' : '',
          'date_label': label,
        };
        try {
          if (isNew) {
            await _client.from('challenges').insert(retryData);
          } else {
            await _client
                .from('challenges')
                .update(retryData)
                .eq('id', existing.id);
          }
          final msg = isNew
              ? 'Daily challenge created.'
              : 'Daily challenge updated.';
          return (true, msg);
        } catch (retryError) {
          debugPrint('Challenge save retry error: $retryError');
          return (false, 'Error saving challenge: $retryError');
        }
      }

      // RLS permission error
      if (errorText.contains('row-level security policy') ||
          errorText.contains('code: 42501')) {
        return (
          false,
          'You do not have permission to create challenges. Update Supabase RLS policies for the challenges table.',
        );
      }

      debugPrint('Challenge save error: $e');
      return (false, 'Error: $e');
    }
  }

  Future<String> _uploadImage(XFile imageFile, Uint8List imageBytes) async {
    const fallbackUrl =
        'https://images.unsplash.com/photo-1464802686167-b939a6910659?auto=format&fit=crop&w=1200&q=80';
    try {
      final extension = imageFile.name
          .split('.')
          .last
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '');
      final cleanExt = extension.isNotEmpty ? extension : 'jpg';
      final fileName =
          'challenges/${DateTime.now().millisecondsSinceEpoch}.$cleanExt';

      await _client.storage
          .from('challenges')
          .uploadBinary(fileName, imageBytes);

      return _client.storage.from('challenges').getPublicUrl(fileName);
    } catch (uploadError) {
      debugPrint('Error uploading challenge image: $uploadError');
      return fallbackUrl;
    }
  }

  Future<bool> hasChallengeOnDate({
    required DateTime activationDate,
    String? excludingId,
  }) async {
    if (!_supportsActivationDate) return false;

    final dateValue = dateKey(activationDate);
    final rows = await _client
        .from('challenges')
        .select('id')
        .eq('activation_date', dateValue);

    final existing = List<Map<String, dynamic>>.from(rows);
    if (excludingId == null) return existing.isNotEmpty;
    return existing.any((row) => row['id']?.toString() != excludingId);
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }
}
