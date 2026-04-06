import 'package:flutter/material.dart';
import 'package:meeteor/services/auth_service.dart';
import 'package:meeteor/widgets/auth_widgets.dart';
import 'package:meeteor/screens/signup.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSigningIn = false;
  final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  Future<void> _handleSignIn() async {
    if (_isSigningIn) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password.')),
      );
      return;
    }

    if (!_emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Incorrect email format.')));
      return;
    }

    setState(() {
      _isSigningIn = true;
    });

    try {
      final response = await _authService.signIn(
        email: email,
        password: password,
      );

      if (!mounted) {
        return;
      }

      if (response.session == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Login did not create a session. Check your email confirmation status.',
            ),
          ),
        );
      }
      // On successful login with a valid session, AuthGate reacts to auth state
      // changes and automatically routes to the main app.
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      await _authService.signInWithGoogle();
      // AuthGate listens to auth state and will automatically navigate
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _showNotImplementedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google sign in is not configured yet.')),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AuthBranding(),
            const SizedBox(height: 58),
            const AuthFieldLabel('Email'),
            AuthTextField(
              controller: _emailController,
              hint: 'your@email.com',
              icon: Icons.email_outlined,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 18),
            const AuthFieldLabel('Password'),
            AuthTextField(
              controller: _passwordController,
              hint: '••••••••',
              icon: Icons.lock_outline,
              obscureText: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (_emailController.text.trim().isNotEmpty &&
                    _passwordController.text.trim().isNotEmpty) {
                  _handleSignIn();
                }
              },
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showNotImplementedMessage,
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(color: AuthColors.accent),
                ),
              ),
            ),
            const SizedBox(height: 14),
            AuthPrimaryButton(
              label: _isSigningIn ? 'Logging In...' : 'Log In',
              onPressed: _handleSignIn,
            ),
            const SizedBox(height: 26),
            const AuthOrDivider(),
            const SizedBox(height: 22),
            AuthGoogleButton(
              onPressed: _handleGoogleSignIn,
            ),
            const SizedBox(height: 24),
            AuthBottomLink(
              leadingText: 'Don\'t have an account? ',
              actionText: 'Sign up',
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const SignUpScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }
}
