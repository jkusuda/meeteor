import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  // Sign in with email and password
  Future<AuthResponse> signIn({required String email, required String password}) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  // Sign up with email and password
  Future<AuthResponse> signUp({required String email, required String password}) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  // Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Get current session synchronously
  Session? get currentSession => _client.auth.currentSession;

  // Listen to auth state changes (login, logout, token refresh)
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;
}
