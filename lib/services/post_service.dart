import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostService {
  final SupabaseClient _client = Supabase.instance.client;

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

    await _client.from('posts').insert({
      'user_id': user.id,
      'caption': caption,
      'image_url': imageUrl,
      'iso': iso,
      'aperture': aperture,
      'exposure': exposure,
      'camera': camera,
    });

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
        .select('*, users(username, avatar_id), post_likes(user_id)')
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
}
