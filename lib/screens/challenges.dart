import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:meeteor/main.dart';
import 'package:meeteor/screens/all_past_challenges.dart';
import 'package:meeteor/screens/all_upcoming_challenges.dart';
import 'package:meeteor/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChallengeSubmission {
  final String username;
  final String imageUrl;
  final String note;
  final String gear;
  final String timeAgo;
  final Color accentColor;
  final DateTime? completedAt;

  const ChallengeSubmission({
    required this.username,
    required this.imageUrl,
    required this.note,
    required this.gear,
    required this.timeAgo,
    required this.accentColor,
    this.completedAt,
  });
}

class DailyChallenge {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final DateTime activationDate;
  final String iconName;
  final List<String> tips;
  final List<ChallengeSubmission> submissions;
  final bool isCompleted;

  const DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.activationDate,
    required this.iconName,
    required this.tips,
    required this.submissions,
    this.isCompleted = false,
  });

  DailyChallenge copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    DateTime? activationDate,
    String? iconName,
    List<String>? tips,
    List<ChallengeSubmission>? submissions,
    bool? isCompleted,
  }) {
    return DailyChallenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      activationDate: activationDate ?? this.activationDate,
      iconName: iconName ?? this.iconName,
      tips: tips ?? this.tips,
      submissions: submissions ?? this.submissions,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class ChallengesPage extends StatefulWidget {
  final bool adminViewEnabled;

  const ChallengesPage({super.key, this.adminViewEnabled = true});

  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> {
  final AuthService _authService = AuthService();
  late List<DailyChallenge> _challenges;
  late bool _canUseAdminView;
  late bool _adminViewEnabled;
  bool _isLoadingChallenges = true;
  bool _supportsActivationDate = true;

  @override
  void initState() {
    super.initState();
    _canUseAdminView = _authService.isAdmin;
    _adminViewEnabled = widget.adminViewEnabled && _canUseAdminView;
    _challenges = [];
    _loadAdminState();
    _fetchChallenges();
  }

  Future<void> _loadAdminState() async {
    final hasAccess = await _authService.hasAdminAccess();
    if (!mounted) return;
    setState(() {
      _canUseAdminView = hasAccess;
      _adminViewEnabled = widget.adminViewEnabled && hasAccess;
    });
  }

  Future<void> _fetchChallenges() async {
    setState(() => _isLoadingChallenges = true);
    try {
      final rows = await (_supportsActivationDate
          ? Supabase.instance.client
                .from('challenges')
                .select()
                .order('activation_date', ascending: false)
          : Supabase.instance.client
                .from('challenges')
                .select()
                .order('created_at', ascending: false));

      final mapped = List<Map<String, dynamic>>.from(
        rows,
      ).map(_challengeFromRow).toList();

      final enriched = await Future.wait(
        mapped.map(_attachChallengeSubmissions),
      );

      if (!mounted) return;
      setState(() {
        _challenges = enriched;
      });
    } catch (e) {
      final errorText = e.toString();
      final missingActivationColumn = errorText.contains('activation_date');
      if (missingActivationColumn && _supportsActivationDate) {
        _supportsActivationDate = false;
        await _fetchChallenges();
        return;
      }

      debugPrint('Error fetching challenges: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load challenges.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingChallenges = false);
      }
    }
  }

  DailyChallenge _challengeFromRow(Map<String, dynamic> row) {
    final tipsRaw = row['tips'];
    final tips = tipsRaw is List
        ? tipsRaw.map((tip) => tip.toString()).toList()
        : const <String>[];

    return DailyChallenge(
      id: (row['id'] ?? '').toString(),
      title: (row['title'] ?? 'Challenge').toString(),
      description: (row['description'] ?? '').toString(),
      imageUrl: (row['imageURL'] ?? row['image_url'] ?? '').toString(),
      activationDate:
          _parseActivationDate(row['activation_date']) ??
          _parseActivationDate(row['created_at']) ??
          DateTime.now(),
      iconName: (row['icon'] ?? row['icon_name'] ?? 'star').toString(),
      tips: tips,
      submissions: const [],
      isCompleted: false,
    );
  }

  Future<DailyChallenge> _attachChallengeSubmissions(
    DailyChallenge challenge,
  ) async {
    try {
      final rows = await Supabase.instance.client
          .from('user_challenges')
          .select(
            'id, user_id, challenge_id, completed_at, imageUrl, users(username)',
          )
          .eq('challenge_id', challenge.id)
          .order('completed_at', ascending: false);

      final imageUrls = List<Map<String, dynamic>>.from(rows)
          .map((row) => (row['imageUrl'] ?? '').toString())
          .where((imageUrl) => imageUrl.isNotEmpty)
          .toSet()
          .toList();

      final postCaptionByImageUrl = <String, String>{};
      if (imageUrls.isNotEmpty) {
        final postRows = await Supabase.instance.client
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
        final completedAt = _parseActivationDate(row['completed_at']);
        final imageUrl = (row['imageUrl'] ?? '').toString();
        return ChallengeSubmission(
          username: (user?['username'] as String? ?? 'Anonymous').toString(),
          imageUrl: imageUrl,
          note: postCaptionByImageUrl[imageUrl]?.trim().isNotEmpty == true
              ? postCaptionByImageUrl[imageUrl]!.trim()
              : 'Challenge submission',
          gear: 'Posted from Meeteor',
          timeAgo: _submissionTimeLabel(completedAt),
          accentColor: _highlightForIndex(row['id'].hashCode.abs()),
          completedAt: completedAt,
        );
      }).toList();

      return challenge.copyWith(submissions: submissions);
    } catch (e) {
      debugPrint('Error loading submissions for ${challenge.id}: $e');
      return challenge;
    }
  }

  DateTime? _parseActivationDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  String _dateKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

  String _relativeDateLabel(DateTime activationDate) {
    final today = DateTime.now();
    final a = DateTime(
      activationDate.year,
      activationDate.month,
      activationDate.day,
    );
    final t = DateTime(today.year, today.month, today.day);
    final days = t.difference(a).inDays;

    if (days == 0) return 'Today';
    if (days == 1) return 'Yesterday';
    if (days > 1) return '$days days ago';
    if (days == -1) return 'Tomorrow';
    return 'In ${-days} days';
  }

  String _submissionTimeLabel(DateTime? completedAt) {
    if (completedAt == null) {
      return 'Now';
    }

    final diff = DateTime.now().difference(completedAt);
    if (diff.isNegative || diff.inMinutes < 60) {
      return 'Now';
    }

    if (diff.inHours < 24) {
      final hours = diff.inHours;
      return hours == 1 ? '1 hour ago' : '$hours hours ago';
    }

    final days = diff.inDays;
    return days == 1 ? '1 day ago' : '$days days ago';
  }

  Future<bool> _hasChallengeOnDate({
    required DateTime activationDate,
    String? excludingId,
  }) async {
    if (!_supportsActivationDate) return false;

    final dateValue = _dateKey(activationDate);
    final rows = await Supabase.instance.client
        .from('challenges')
        .select('id')
        .eq('activation_date', dateValue);

    final existing = List<Map<String, dynamic>>.from(rows);
    if (excludingId == null) {
      return existing.isNotEmpty;
    }

    return existing.any((row) => row['id']?.toString() != excludingId);
  }

  int get _completedChallenges =>
      _challenges.where((challenge) => challenge.isCompleted).length;

  static const int _trophySlots = 7;

  int get _trophiesEarned =>
      _completedChallenges > _trophySlots ? _trophySlots : _completedChallenges;

  DateTime get _todayDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DailyChallenge? get _todayChallenge {
    final today = _todayDate;
    for (final challenge in _challenges) {
      if (_normalizeDate(challenge.activationDate) == today) {
        return challenge;
      }
    }
    return null;
  }

  List<DailyChallenge> get _pastChallenges {
    final sevenDaysAgo = _todayDate.subtract(const Duration(days: 7));
    return _challenges.where((challenge) {
      final normalized = _normalizeDate(challenge.activationDate);
      return normalized.isBefore(_todayDate) &&
          (normalized.isAfter(sevenDaysAgo) ||
              normalized.isAtSameMomentAs(sevenDaysAgo));
    }).toList();
  }

  List<DailyChallenge> get _allPastChallenges => _challenges
      .where(
        (challenge) =>
            _normalizeDate(challenge.activationDate).isBefore(_todayDate),
      )
      .toList();

  bool get _hasMorePastChallenges =>
      _allPastChallenges.length > _pastChallenges.length;

  List<DailyChallenge> get _futureChallenges {
    final sevenDaysFromNow = _todayDate.add(const Duration(days: 7));
    final future = _challenges.where((challenge) {
      final normalized = _normalizeDate(challenge.activationDate);
      return normalized.isAfter(_todayDate) &&
          (normalized.isBefore(sevenDaysFromNow) ||
              normalized.isAtSameMomentAs(sevenDaysFromNow));
    }).toList();
    future.sort((a, b) => a.activationDate.compareTo(b.activationDate));
    return future;
  }

  List<DailyChallenge> get _allFutureChallenges {
    final future = _challenges
        .where(
          (challenge) =>
              _normalizeDate(challenge.activationDate).isAfter(_todayDate),
        )
        .toList();
    future.sort((a, b) => a.activationDate.compareTo(b.activationDate));
    return future;
  }

  bool get _hasMoreFutureChallenges =>
      _allFutureChallenges.length > _futureChallenges.length;

  IconData _iconForName(String iconName) {
    switch (iconName) {
      case 'camera':
        return Icons.camera_alt_rounded;
      case 'moon':
        return Icons.nightlight_round_rounded;
      case 'star':
      default:
        return Icons.star_rounded;
    }
  }

  Color _highlightForIndex(int index) {
    const palette = [
      Color(0xFFFCB454),
      Color(0xFF7E6AD8),
      Color(0xFF4FD1C5),
      Color(0xFFF37F8D),
      Color(0xFF9A8CFF),
    ];

    return palette[index % palette.length];
  }

  Widget _buildChallengeImage({
    required String imagePath,
    required BoxFit fit,
    required Widget Function() fallbackBuilder,
  }) {
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => fallbackBuilder(),
      );
    }

    return Image.network(
      imagePath,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => fallbackBuilder(),
    );
  }

  Future<void> _openChallengeDetails(DailyChallenge challenge) async {
    var shouldOpenSubmissionPage = false;

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: AppColors.prussianBlue,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 1.3,
                        child: _buildChallengeImage(
                          imagePath: challenge.imageUrl,
                          fit: BoxFit.cover,
                          fallbackBuilder: () => Container(
                            color: AppColors.spaceIndigo,
                            alignment: Alignment.center,
                            child: Icon(
                              _iconForName(challenge.iconName),
                              size: 72,
                              color: AppColors.honeyBronze,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        top: 16,
                        child: _Badge(
                          label: _relativeDateLabel(challenge.activationDate),
                        ),
                      ),
                      Positioned(
                        right: 16,
                        top: 16,
                        child: CircleAvatar(
                          backgroundColor: AppColors.prussianBlue.withValues(
                            alpha: 0.75,
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close_rounded),
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          challenge.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          challenge.description,
                          style: TextStyle(
                            color: AppColors.thistle,
                            fontSize: 15,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _InfoPill(
                              icon: Icons.schedule_rounded,
                              label: _relativeDateLabel(
                                challenge.activationDate,
                              ),
                            ),
                            const SizedBox(width: 10),
                            _InfoPill(
                              icon: Icons.visibility_rounded,
                              label:
                                  '${challenge.submissions.length} ${challenge.submissions.length == 1 ? 'submission' : 'submissions'}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.spaceIndigo.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.vintageLavender.withValues(
                                alpha: 0.45,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tips',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...challenge.tips.map(
                                (tip) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.auto_awesome_rounded,
                                        size: 18,
                                        color: AppColors.honeyBronze,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          tip,
                                          style: TextStyle(
                                            color: AppColors.thistle,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Community Submissions',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (challenge.submissions.length > 5)
                              TextButton(
                                onPressed: () {
                                  _showAllSubmissionsSheet(challenge);
                                },
                                child: Text(
                                  'View All',
                                  style: TextStyle(
                                    color: AppColors.honeyBronze,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (challenge.submissions.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.spaceIndigo.withValues(
                                alpha: 0.65,
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              'No submissions yet. Be the first to post your take on this challenge.',
                              style: TextStyle(color: AppColors.thistle),
                            ),
                          )
                        else
                          ...challenge.submissions
                              .take(5)
                              .map(
                                (submission) => Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.spaceIndigo.withValues(
                                      alpha: 0.72,
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: submission.accentColor.withValues(
                                        alpha: 0.22,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: SizedBox(
                                          width: 72,
                                          height: 72,
                                          child: _buildChallengeImage(
                                            imagePath: submission.imageUrl,
                                            fit: BoxFit.cover,
                                            fallbackBuilder: () => Container(
                                              color: AppColors.prussianBlue,
                                              alignment: Alignment.center,
                                              child: Icon(
                                                Icons.image_rounded,
                                                color: submission.accentColor,
                                                size: 28,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  submission.username,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                Text(
                                                  submission.timeAgo,
                                                  style: TextStyle(
                                                    color: AppColors.thistle
                                                        .withValues(alpha: 0.7),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              submission.note,
                                              style: TextStyle(
                                                color: AppColors.thistle,
                                                height: 1.3,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 6),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: challenge.isCompleted
                                    ? null
                                    : () {
                                        shouldOpenSubmissionPage = true;
                                        Navigator.of(sheetContext).pop(true);
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.honeyBronze,
                                  foregroundColor: AppColors.prussianBlue,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: Icon(
                                  challenge.isCompleted
                                      ? Icons.verified_rounded
                                      : Icons.camera_alt_rounded,
                                ),
                                label: Text(
                                  challenge.isCompleted
                                      ? 'Completed'
                                      : 'Complete Now',
                                ),
                              ),
                            ),
                            if (_adminViewEnabled) ...[
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(sheetContext);
                                  _openChallengeEditor(challenge: challenge);
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.thistle,
                                  side: BorderSide(
                                    color: AppColors.vintageLavender.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: const Icon(Icons.edit_rounded),
                                label: const Text('Edit'),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(
                          height:
                              MediaQuery.of(sheetContext).padding.bottom + 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (shouldOpenSubmissionPage && mounted) {
      context.push(
        Uri(
          path: '/post',
          queryParameters: {
            'challengeId': challenge.id,
            'challengeTitle': challenge.title,
            'challengeDescription': challenge.description,
          },
        ).toString(),
      );
    }
  }

  Future<void> _showAllSubmissionsSheet(DailyChallenge challenge) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: AppColors.prussianBlue,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'All Community Submissions',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        CircleAvatar(
                          backgroundColor: AppColors.prussianBlue.withValues(
                            alpha: 0.75,
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: challenge.submissions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final submission = challenge.submissions[index];
                        return _buildSubmissionTile(submission);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubmissionTile(ChallengeSubmission submission) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.spaceIndigo.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: submission.accentColor.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 72,
              height: 72,
              child: _buildChallengeImage(
                imagePath: submission.imageUrl,
                fit: BoxFit.cover,
                fallbackBuilder: () => Container(
                  color: AppColors.prussianBlue,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.image_rounded,
                    color: submission.accentColor,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      submission.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      submission.timeAgo,
                      style: TextStyle(
                        color: AppColors.thistle.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  submission.note,
                  style: TextStyle(color: AppColors.thistle, height: 1.3),
                ),
                const SizedBox(height: 6),
                Text(
                  submission.gear,
                  style: TextStyle(
                    color: submission.accentColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openChallengeEditor({DailyChallenge? challenge}) async {
    final parentContext = context;
    final titleController = TextEditingController(text: challenge?.title ?? '');
    final descriptionController = TextEditingController(
      text: challenge?.description ?? '',
    );
    final activationDateController = TextEditingController(
      text: _dateKey(challenge?.activationDate ?? DateTime.now()),
    );
    final tipControllers = List.generate(
      3,
      (index) => TextEditingController(
        text: challenge?.tips.elementAtOrNull(index) ?? '',
      ),
    );
    String selectedIcon = challenge?.iconName ?? 'star';
    final scaffoldMessenger = ScaffoldMessenger.of(parentContext);

    // Image picker state
    XFile? selectedImage;
    Uint8List? selectedImageBytes;
    final picker = ImagePicker();

    final message = await showDialog<String?>(
      context: parentContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (innerContext, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.spaceIndigo,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                challenge == null
                    ? 'Create Daily Challenge'
                    : 'Edit Daily Challenge',
                style: const TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: selectedIcon,
                        dropdownColor: AppColors.spaceIndigo,
                        decoration: _editorFieldDecoration('Icon'),
                        items: const [
                          DropdownMenuItem(
                            value: 'star',
                            child: Text(
                              'Star',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'camera',
                            child: Text(
                              'Camera',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'moon',
                            child: Text(
                              'Moon',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => selectedIcon = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: titleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _editorInputDecoration('Title'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        decoration: _editorInputDecoration('Description'),
                      ),
                      const SizedBox(height: 12),
                      // Image picker UI
                      GestureDetector(
                        onTap: () async {
                          final pickedFile = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (pickedFile != null) {
                            final bytes = await pickedFile.readAsBytes();
                            setDialogState(() {
                              selectedImage = pickedFile;
                              selectedImageBytes = bytes;
                            });
                          }
                        },
                        child: SizedBox(
                          width: double.infinity,
                          child: Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: AppColors.prussianBlue,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedImage == null
                                    ? AppColors.honeyBronze.withValues(
                                        alpha: 0.5,
                                      )
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: selectedImageBytes != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(
                                      selectedImageBytes!,
                                      fit: BoxFit.contain,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_a_photo,
                                        size: 48,
                                        color: AppColors.honeyBronze,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tap to select an image',
                                        style: TextStyle(
                                          color: AppColors.thistle,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: activationDateController,
                        readOnly: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: _editorInputDecoration('Activation Date')
                            .copyWith(
                              suffixIcon: Icon(
                                Icons.calendar_today_rounded,
                                color: AppColors.thistle,
                                size: 18,
                              ),
                            ),
                        onTap: () async {
                          final initial =
                              DateTime.tryParse(
                                activationDateController.text,
                              ) ??
                              DateTime.now();
                          final picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: initial,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (!dialogContext.mounted) return;
                          if (picked != null) {
                            activationDateController.text = _dateKey(picked);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(
                        tipControllers.length,
                        (index) => Padding(
                          padding: EdgeInsets.only(
                            bottom: index == tipControllers.length - 1 ? 0 : 12,
                          ),
                          child: TextField(
                            controller: tipControllers[index],
                            style: const TextStyle(color: Colors.white),
                            decoration: _editorInputDecoration(
                              'Tip ${index + 1}',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.thistle),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final result = await _saveChallenge(
                      challenge: challenge,
                      title: title,
                      description: descriptionController.text.trim(),
                      imageFile: selectedImage,
                      imageBytes: selectedImageBytes,
                      activationDateRaw: activationDateController.text.trim(),
                      selectedIcon: selectedIcon,
                      tipControllers: tipControllers,
                    );
                    if (!dialogContext.mounted) return;
                    if (result.$1) {
                      Navigator.of(dialogContext).pop(result.$2);
                    } else {
                      await showDialog<void>(
                        context: dialogContext,
                        builder: (errorDialogContext) => AlertDialog(
                          backgroundColor: AppColors.spaceIndigo,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: const Text(
                            'Cannot Create Challenge',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: Text(
                            result.$2,
                            style: TextStyle(color: AppColors.thistle),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(errorDialogContext).pop(),
                              child: Text(
                                'OK',
                                style: TextStyle(color: AppColors.honeyBronze),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.honeyBronze,
                    foregroundColor: AppColors.prussianBlue,
                  ),
                  child: Text(challenge == null ? 'Create' : 'Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );

    if (message != null && mounted) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<(bool, String)> _saveChallenge({
    required DailyChallenge? challenge,
    required String title,
    required String description,
    required XFile? imageFile,
    required Uint8List? imageBytes,
    required String activationDateRaw,
    required String selectedIcon,
    required List<TextEditingController> tipControllers,
  }) async {
    final tips = tipControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final activationDate = DateTime.tryParse(activationDateRaw);

    if (title.isEmpty || description.isEmpty) {
      return (false, 'Title and description are required.');
    }
    if (activationDate == null) {
      return (false, 'Activation Date is required.');
    }
    if (imageFile == null || imageBytes == null) {
      return (false, 'An image is required.');
    }

    if (_supportsActivationDate) {
      final duplicateDateExists = await _hasChallengeOnDate(
        activationDate: activationDate,
        excludingId: challenge?.id,
      );
      if (duplicateDateExists) {
        return (false, 'A challenge already exists for that activation date.');
      }
    }

    // Upload image to Supabase storage
    String imageUrl =
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

      await Supabase.instance.client.storage
          .from('challenges')
          .uploadBinary(fileName, imageBytes);

      imageUrl = Supabase.instance.client.storage
          .from('challenges')
          .getPublicUrl(fileName);
    } catch (uploadError) {
      debugPrint('Error uploading challenge image: $uploadError');
      // Continue with default image URL if upload fails
    }

    final chall = DailyChallenge(
      id: challenge?.id ?? '',
      title: title,
      description: description,
      imageUrl: imageUrl,
      activationDate: activationDate,
      iconName: selectedIcon,
      tips: tips.isEmpty
          ? const [
              'Add a few practical shooting tips so people know where to start.',
            ]
          : tips,
      submissions: challenge?.submissions ?? const [],
      isCompleted: challenge?.isCompleted ?? false,
    );

    try {
      final data = {
        'title': chall.title,
        'description': chall.description,
        'imageURL': chall.imageUrl,
        'icon': chall.iconName,
        'tips': chall.tips,
        'activation_date': _dateKey(chall.activationDate),
      };
      if (challenge == null) {
        await Supabase.instance.client.from('challenges').insert(data);
      } else {
        await Supabase.instance.client
            .from('challenges')
            .update(data)
            .eq('id', challenge.id);
      }
      await _fetchChallenges();
      final msg = challenge == null
          ? 'Daily challenge created.'
          : 'Daily challenge updated.';
      return (true, msg);
    } catch (e) {
      final errorText = e.toString();
      final missingActivationColumn = errorText.contains('activation_date');

      // Keep backward compatibility when activation_date is unavailable.
      if (missingActivationColumn && _supportsActivationDate) {
        _supportsActivationDate = false;
        final relativeLabel = _relativeDateLabel(chall.activationDate);
        final retryData = {
          'title': chall.title,
          'description': chall.description,
          'imageURL': chall.imageUrl,
          'icon': chall.iconName,
          'tips': chall.tips,
          'badge_label': relativeLabel == 'Today' ? 'Today' : '',
          'date_label': relativeLabel,
        };
        try {
          if (challenge == null) {
            await Supabase.instance.client.from('challenges').insert(retryData);
          } else {
            await Supabase.instance.client
                .from('challenges')
                .update(retryData)
                .eq('id', challenge.id);
          }
          await _fetchChallenges();
          final msg = challenge == null
              ? 'Daily challenge created.'
              : 'Daily challenge updated.';
          return (true, msg);
        } catch (retryError) {
          debugPrint(
            'Challenge save retry error (activation_date): $retryError',
          );
          return (false, 'Error saving challenge: $retryError');
        }
      }

      final isRlsError =
          errorText.contains('row-level security policy') ||
          errorText.contains('code: 42501');
      if (isRlsError) {
        return (
          false,
          'You do not have permission to create challenges. Update Supabase RLS policies for the challenges table.',
        );
      }

      debugPrint('Challenge save error: $e');
      return (false, 'Error: $e');
    }
  }

  InputDecoration _editorInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppColors.thistle),
      filled: true,
      fillColor: AppColors.prussianBlue,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.vintageLavender.withValues(alpha: 0.45),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.honeyBronze.withValues(alpha: 0.9),
        ),
      ),
    );
  }

  InputDecoration _editorFieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppColors.thistle),
      filled: true,
      fillColor: AppColors.prussianBlue,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.vintageLavender.withValues(alpha: 0.45),
        ),
      ),
    );
  }

  void _editChallenge(DailyChallenge challenge) {
    _openChallengeEditor(challenge: challenge);
  }

  @override
  Widget build(BuildContext context) {
    final trophiesEarned = _trophiesEarned;

    return Scaffold(
      backgroundColor: AppColors.prussianBlue,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 1.0,
              child: Image.asset(
                'assets/starry_sky_bg_1.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: -120,
            right: -80,
            child: _GlowBlob(
              color: AppColors.honeyBronze.withValues(alpha: 0.18),
              size: 220,
            ),
          ),
          Positioned(
            bottom: 120,
            left: -120,
            child: _GlowBlob(
              color: AppColors.vintageLavender.withValues(alpha: 0.16),
              size: 260,
            ),
          ),
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 72),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Daily Challenges',
                          style: TextStyle(
                            color: AppColors.thistle,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Complete challenges to earn trophies and gain experience capturing the cosmos.',
                          style: TextStyle(
                            color: AppColors.vintageLavender,
                            fontSize: 15,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.spaceIndigo.withValues(
                              alpha: 0.78,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: AppColors.vintageLavender.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Trophy Collection',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.emoji_events_rounded,
                                    color: AppColors.honeyBronze,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$trophiesEarned',
                                    style: TextStyle(
                                      color: AppColors.honeyBronze,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final availableWidth = constraints.maxWidth;
                                  final trophySize =
                                      ((availableWidth -
                                                  ((_trophySlots - 1) * 8)) /
                                              _trophySlots)
                                          .clamp(32.0, 50.0);
                                  final iconSize = trophySize * 0.6;

                                  return Row(
                                    children: List.generate(_trophySlots, (
                                      index,
                                    ) {
                                      final earned = index < trophiesEarned;
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          right: index < _trophySlots - 1
                                              ? 8
                                              : 0,
                                        ),
                                        child: Container(
                                          width: trophySize,
                                          height: trophySize,
                                          decoration: BoxDecoration(
                                            color: earned
                                                ? AppColors.honeyBronze
                                                      .withValues(alpha: 0.95)
                                                : AppColors.spaceIndigo
                                                      .withValues(alpha: 0.5),
                                            borderRadius: BorderRadius.circular(
                                              trophySize * 0.36,
                                            ),
                                            border: Border.all(
                                              color: earned
                                                  ? AppColors.honeyBronze
                                                  : AppColors.vintageLavender
                                                        .withValues(
                                                          alpha: 0.28,
                                                        ),
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.emoji_events_rounded,
                                            size: iconSize,
                                            color: earned
                                                ? AppColors.prussianBlue
                                                : AppColors.vintageLavender,
                                          ),
                                        ),
                                      );
                                    }),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Keep up with the daily challenges this week! $trophiesEarned/$_trophySlots trophies collected.',
                                style: TextStyle(
                                  color: AppColors.thistle,
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_adminViewEnabled) ...[
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.honeyBronze.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.honeyBronze.withValues(
                                  alpha: 0.25,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.admin_panel_settings_rounded,
                                      color: AppColors.honeyBronze,
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Admin Challenge Tools',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Create a new challenge or edit the current prompt for today.',
                                  style: TextStyle(
                                    color: AppColors.thistle,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _openChallengeEditor(),
                                    icon: const Icon(
                                      Icons.add_circle_outline_rounded,
                                    ),
                                    label: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text('Create Challenge'),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.honeyBronze,
                                      foregroundColor: AppColors.prussianBlue,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        Text(
                          "Today's Challenge",
                          style: TextStyle(
                            color: AppColors.thistle,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_isLoadingChallenges)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_challenges.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.spaceIndigo.withValues(
                                alpha: 0.75,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.vintageLavender.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Text(
                              'No daily challenges yet.',
                              style: TextStyle(color: AppColors.thistle),
                            ),
                          )
                        else if (_todayChallenge == null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.spaceIndigo.withValues(
                                alpha: 0.75,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.vintageLavender.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Text(
                              'No challenge is scheduled for today.',
                              style: TextStyle(color: AppColors.thistle),
                            ),
                          )
                        else
                          _TodayChallengeCard(
                            challenge: _todayChallenge!,
                            badgeLabel: _relativeDateLabel(
                              _todayChallenge!.activationDate,
                            ),
                            icon: _iconForName(_todayChallenge!.iconName),
                            onTap: () =>
                                _openChallengeDetails(_todayChallenge!),
                            onEdit: _adminViewEnabled
                                ? () => _editChallenge(_todayChallenge!)
                                : null,
                          ),
                        const SizedBox(height: 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Past Challenges',
                              style: TextStyle(
                                color: AppColors.thistle,
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (_hasMorePastChallenges)
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AllPastChallengesPage(
                                            challenges: _allPastChallenges,
                                            onChallengeSelected:
                                                _openChallengeDetails,
                                            relativeDateLabel:
                                                _relativeDateLabel,
                                            iconForName: _iconForName,
                                          ),
                                    ),
                                  );
                                },
                                child: Text(
                                  'View All',
                                  style: TextStyle(
                                    color: AppColors.honeyBronze,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_pastChallenges.isEmpty)
                          Text(
                            'No past challenges to view.',
                            style: TextStyle(color: AppColors.thistle),
                          )
                        else
                          ..._pastChallenges.asMap().entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _PastChallengeCard(
                                challenge: entry.value,
                                dateLabel: _relativeDateLabel(
                                  entry.value.activationDate,
                                ),
                                icon: _iconForName(entry.value.iconName),
                                accent: _highlightForIndex(entry.key),
                                onTap: () => _openChallengeDetails(entry.value),
                                onEdit: _adminViewEnabled
                                    ? () => _editChallenge(entry.value)
                                    : null,
                              ),
                            ),
                          ),
                        if (_adminViewEnabled) ...[
                          const SizedBox(height: 22),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Future Challenges',
                                style: TextStyle(
                                  color: AppColors.thistle,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (_hasMoreFutureChallenges)
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AllUpcomingChallengesPage(
                                              challenges: _allFutureChallenges,
                                              onChallengeSelected:
                                                  _openChallengeDetails,
                                              relativeDateLabel:
                                                  _relativeDateLabel,
                                              iconForName: _iconForName,
                                            ),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'View All',
                                    style: TextStyle(
                                      color: AppColors.honeyBronze,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_futureChallenges.isEmpty)
                            Text(
                              'No upcoming challenges in the next 7 days.',
                              style: TextStyle(color: AppColors.thistle),
                            )
                          else
                            ..._futureChallenges.asMap().entries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _PastChallengeCard(
                                  challenge: entry.value,
                                  dateLabel: _relativeDateLabel(
                                    entry.value.activationDate,
                                  ),
                                  icon: _iconForName(entry.value.iconName),
                                  accent: _highlightForIndex(entry.key),
                                  onTap: () =>
                                      _openChallengeDetails(entry.value),
                                  onEdit: () => _editChallenge(entry.value),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;

  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.honeyBronze,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.prussianBlue,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.vintageLavender.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.thistle),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: AppColors.thistle,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayChallengeCard extends StatelessWidget {
  final DailyChallenge challenge;
  final String badgeLabel;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  const _TodayChallengeCard({
    required this.challenge,
    required this.badgeLabel,
    required this.icon,
    required this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.spaceIndigo.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.vintageLavender.withValues(alpha: 0.28),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                    child: AspectRatio(
                      aspectRatio: 1.45,
                      child: challenge.imageUrl.startsWith('assets/')
                          ? Image.asset(
                              challenge.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: AppColors.vintageLavender.withValues(
                                      alpha: 0.2,
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      icon,
                                      size: 72,
                                      color: AppColors.honeyBronze,
                                    ),
                                  ),
                            )
                          : Image.network(
                              challenge.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: AppColors.vintageLavender.withValues(
                                      alpha: 0.2,
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      icon,
                                      size: 72,
                                      color: AppColors.honeyBronze,
                                    ),
                                  ),
                            ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 16,
                    child: _Badge(label: badgeLabel),
                  ),
                  if (onEdit != null)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.prussianBlue.withValues(
                          alpha: 0.75,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          color: Colors.white,
                          onPressed: onEdit,
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.vintageLavender.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        icon,
                        color: AppColors.prussianBlue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  challenge.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Color(0xFFB6A7D9),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            challenge.description,
                            style: TextStyle(
                              color: AppColors.thistle,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PastChallengeCard extends StatelessWidget {
  final DailyChallenge challenge;
  final String dateLabel;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  const _PastChallengeCard({
    required this.challenge,
    required this.dateLabel,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.spaceIndigo.withValues(alpha: 0.84),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.22)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.prussianBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateLabel,
                      style: TextStyle(
                        color: accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (challenge.isCompleted)
                Icon(Icons.check_circle_rounded, size: 18, color: accent),
              if (challenge.isCompleted) const SizedBox(width: 8),
              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded),
                  color: AppColors.thistle,
                )
              else
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.vintageLavender,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
