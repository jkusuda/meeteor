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
}
