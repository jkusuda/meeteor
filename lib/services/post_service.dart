import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> createPost({
    required dynamic
    imageFile, // XFile on web, File on mobile, but byte array or path usually works. Let's rely on bytes for both.
    required Uint8List imageBytes,
    required String extension,
    required String caption,
    String? iso,
    String? aperture,
    String? exposure,
    String? camera,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to post.');
    }

    final uniqueFileName =
        '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$extension';

    // 1. Upload to Supabase Storage
    await _client.storage
        .from('posts')
        .uploadBinary(
          uniqueFileName,
          imageBytes,
          fileOptions: FileOptions(contentType: 'image/$extension'),
        );

    // 2. Get Public URL
    final imageUrl = _client.storage.from('posts').getPublicUrl(uniqueFileName);

    // 3. Insert into Database
    await _client.from('posts').insert({
      'user_id': user.id,
      'image_url': imageUrl,
      'caption': caption,
      if (iso?.isNotEmpty == true) 'iso': iso,
      if (aperture?.isNotEmpty == true) 'aperture': aperture,
      if (exposure?.isNotEmpty == true) 'exposure': exposure,
      if (camera?.isNotEmpty == true) 'camera': camera,
    });
  }

  Future<void> toggleLike(String postId, bool isLiked) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('You must be logged in to like posts.');

    if (isLiked) {
      // Unlike
      await _client.from('post_likes').delete().match(
        {'post_id': postId, 'user_id': user.id},
      );
    } else {
      // Like
      await _client.from('post_likes').insert({
        'post_id': postId,
        'user_id': user.id,
      });
    }
  }

  Future<void> addComment(String postId, String content) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('You must be logged in to comment.');
    if (content.trim().isEmpty) return;

    await _client.from('comments').insert({
      'post_id': postId,
      'user_id': user.id,
      'content': content.trim(),
    });
  }

  Future<List<Map<String, dynamic>>> fetchComments(String postId) async {
    final response = await _client
        .from('comments')
        .select('*, users(username, avatar_id)')
        .eq('post_id', postId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> getPostById(String postId) async {
    final response = await _client
        .from('posts')
        .select('*, users(username, avatar_id), post_likes(user_id)')
        .eq('id', postId)
        .single();
    
    return response;
  }
}
