import 'dart:async';
import 'package:meeteor/screens/login.dart';
import 'package:meeteor/screens/nav_wrapper.dart';
import 'package:meeteor/services/auth_service.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();
  StreamSubscription? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    // Listen to changes in auth state and rebuild the UI
    _authStateSubscription = _authService.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If the user has a session, show the main app shell, else show login.
    if (_authService.currentSession != null) {
      return const NavWrapper();
    } else {
      return const LoginScreen();
    }
  }
}
