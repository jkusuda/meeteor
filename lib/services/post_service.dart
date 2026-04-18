
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:meeteor/services/auth_service.dart';

class PostService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Fetches all available tags from the tags table, ordered by name.
  Future<List<Map<String, dynamic>>> fetchTags() async {
    final rows = await _client
        .from('tags')
        .select('id, name, category')
        .order('name');
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Finds or creates a tag by name, returning its id.
  Future<String> findOrCreateTag(String name, {String category = 'challenge'}) async {
    // Check if it already exists
    final existing = await _client
        .from('tags')
        .select('id')
        .eq('name', name)
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as String;
    }

    // Insert new tag
    final inserted = await _client
        .from('tags')
        .insert({'name': name, 'category': category})
        .select('id')
        .single();
    return inserted['id'] as String;
  }

  Future<void> createPost({
    required dynamic imageFile,
    required Uint8List imageBytes,
    required String extension,
    required String caption,
    String? challengeId,
    String? iso,
    String? aperture,
    String? exposure,
    String? camera,
    List<String> tagIds = const [],
    String? challengeTagName,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }

    final filePath =
        '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$extension';

    await _client.storage
        .from('posts')
        .uploadBinary(
          filePath,
          imageBytes,
          fileOptions: const FileOptions(upsert: true),
        );

    final imageUrl = _client.storage.from('posts').getPublicUrl(filePath);

    final postRow = await _client.from('posts').insert({
      'user_id': user.id,
      'caption': caption,
      'image_url': imageUrl,
      'iso': iso,
      'aperture': aperture,
      'exposure': exposure,
      'camera': camera,
    }).select('id').single();

    final postId = postRow['id'] as String;

    // Collect all tag IDs to associate with this post
    final allTagIds = <String>{...tagIds};

    // If this is a challenge submission, find-or-create the challenge tag
    if (challengeTagName != null && challengeTagName.isNotEmpty) {
      try {
        final challengeTagId = await findOrCreateTag(challengeTagName, category: 'challenge');
        allTagIds.add(challengeTagId);
      } catch (e) {
        debugPrint('Warning: could not create challenge tag: $e');
      }
    }

    // Batch insert post_tags rows
    if (allTagIds.isNotEmpty) {
      final postTagRows = allTagIds.map((tagId) => {
        'post_id': postId,
        'tag_id': tagId,
      }).toList();

      try {
        await _client.from('post_tags').insert(postTagRows);
      } catch (e) {
        debugPrint('Warning: could not insert post tags: $e');
      }
    }

    if (challengeId != null && challengeId.isNotEmpty) {
      // Link challenge submissions using the existing join-table schema.
      await _client.from('user_challenges').insert({
        'user_id': user.id,
        'challenge_id': challengeId,
        'completed_at': DateTime.now().toIso8601String(),
        'imageUrl': imageUrl,
      });
    }
  }

  Future<Map<String, dynamic>?> getPostById(String postId) async {
    return _client
        .from('posts')
        .select('*, users(username, avatar_id), post_likes(user_id), post_tags(tags(name, category))')
        .eq('id', postId)
        .maybeSingle();
  }

  Future<List<Map<String, dynamic>>> fetchComments(String postId) async {
    final rows = await _client
        .from('comments')
        .select('id, content, created_at, users(username, avatar_id)')
        .eq('post_id', postId)
        .order('created_at');

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> addComment(String postId, String content) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }

    await _client.from('comments').insert({
      'post_id': postId,
      'user_id': user.id,
      'content': content.trim(),
    });
  }

  Future<void> toggleLike(String postId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }

    try {
      // Check if already liked
      final existing = await _client
          .from('post_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (existing != null) {
        // Unlike: delete the like
        await _client
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', user.id);
      } else {
        // Like: insert new like
        await _client.from('post_likes').insert({
          'post_id': postId,
          'user_id': user.id,
        });
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
      rethrow;
    }
  }

  Future<void> deletePost(String postId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }

    try {
      // Get the post to extract the image URL for deletion from storage
      final post = await _client.from('posts').select('image_url').eq('id', postId).maybeSingle();
      
      final isAdmin = await AuthService().hasAdminAccess();
      
      // Delete from database and return the deleted rows to verify success
      var query = _client.from('posts').delete().eq('id', postId);
      if (!isAdmin) {
        query = query.eq('user_id', user.id);
      }
      
      final deletedData = await query.select();
      
      if (deletedData.isEmpty) {
        throw Exception('Post could not be deleted. Check if you have permission (RLS) to delete this post.');
      }

      // Attempt to delete the image from storage if it exists
      if (post != null && post['image_url'] != null) {
        final imageUrl = post['image_url'] as String;
        // The URL contains something like /storage/v1/object/public/posts/user_id/filename.ext
        final splitUrl = imageUrl.split('posts/');
        if (splitUrl.length > 1) {
          final filePath = splitUrl.last;
          await _client.storage.from('posts').remove([filePath]);
        }
      }
    } catch (e) {
      debugPrint('Error deleting post: $e');
      rethrow;
    }
  }
}
