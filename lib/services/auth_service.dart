import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

  // Sign in with Google (web: OAuth redirect, mobile: native SDK)
  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      // On web, use Supabase's OAuth redirect flow
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'http://localhost:8080',
      );
      return;
    }

    // Native mobile flow (iOS / Android)
    const webClientId =
        '360591984993-043n7rqkrml5delngap244h1co8eb16p.apps.googleusercontent.com';
    const iosClientId =
        '360591984993-8pgvn1g93hosvmj5n0srjcpqcpid11oq.apps.googleusercontent.com';

    await GoogleSignIn.instance.initialize(
      clientId: iosClientId,
      serverClientId: webClientId,
    );

    final googleUser = await GoogleSignIn.instance.authenticate();
    // authenticate() throws GoogleSignInException on cancel/failure.

    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw Exception('Google sign in failed: no ID token received.');
    }

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );
  }

  // Get current session synchronously
  Session? get currentSession => _client.auth.currentSession;

  // Get current user synchronously
  User? get currentUser => _client.auth.currentUser;

  bool get isAdmin {
    final user = currentUser;
    if (user == null) {
      return false;
    }

    final metadata = <String, dynamic>{
      ...user.appMetadata,
      ...?user.userMetadata,
    };

    final role = metadata['role']?.toString().toLowerCase();
    final isAdminFlag = metadata['is_admin'];

    if (role == 'admin' ||
        isAdminFlag == true ||
        isAdminFlag?.toString().toLowerCase() == 'true') {
      return true;
    }

    final adminEmails = dotenv.env['ADMIN_EMAILS'];
    final email = user.email?.toLowerCase();

    if (adminEmails == null || adminEmails.trim().isEmpty || email == null) {
      return false;
    }

    final allowedEmails = adminEmails
        .split(',')
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet();

    return allowedEmails.contains(email);
  }

  Future<bool> isAdminFromUsersTable() async {
    final user = currentUser;
    if (user == null) {
      return false;
    }

    try {
      final row = await _client
          .from('users')
          .select('admin')
          .eq('id', user.id)
          .maybeSingle();

      if (row == null) {
        return false;
      }

      final adminValue = row['admin'];
      return adminValue == true || adminValue?.toString().toLowerCase() == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasAdminAccess() async {
    if (isAdmin) {
      return true;
    }
    return isAdminFromUsersTable();
  }

  // Listen to auth state changes (login, logout, token refresh)
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;
}
