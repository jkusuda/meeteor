import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final _client = Supabase.instance.client;

  Future<Map<String, dynamic>?> getProfile() async {
    final session = _client.auth.currentSession;
    if (session == null) return null;

    try {
      // 1. Try to fetch the existing profile
      var data = await _client
          .from('users')
          .select('username, display_name, bio, avatar_url')
          .eq('id', session.user.id)
          .maybeSingle();

      // 2. If it doesn't exist, create it (Auto-Initialization)
      if (data == null) {
        debugPrint('DEBUG: UserService creating default profile for ${session.user.id}');
        final emailPrefix = session.user.email?.split('@').first ?? 'user';
        final newRow = {
          'id': session.user.id,
          'username': emailPrefix,
          'display_name': emailPrefix,
        };
        
        await _client.from('users').upsert(newRow);
        
        // Fetch again to get the fresh record
        data = await _client
            .from('users')
            .select('username, display_name, bio, avatar_url')
            .eq('id', session.user.id)
            .single();
      }
      
      return data;
    } catch (e) {
      debugPrint('DEBUG: UserService error: $e');
      return null;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    final session = _client.auth.currentSession;
    if (session == null) return;
    
    await _client
        .from('users')
        .update(updates)
        .eq('id', session.user.id);
  }
}
