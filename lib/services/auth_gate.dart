import 'package:astrophotography_blog/screens/home.dart';
import 'package:astrophotography_blog/screens/login.dart';
import 'package:astrophotography_blog/services/auth_service.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Listen to changes in auth state and rebuild the UI
    _authService.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {}); 
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // If the user has a session, show the HomePage, else show the LoginScreen
    if (_authService.currentSession != null) {
      return const HomePage();
    } else {
      return const LoginScreen();
    }
  }
}
