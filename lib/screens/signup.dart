import 'package:meeteor/screens/auth_widgets.dart';
import 'package:meeteor/services/auth_service.dart';
import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields.')),
      );
      return;
    }

    if (!_emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Incorrect email format')));
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match.')));
      return;
    }

    try {
      await _authService.signUp(email: email, password: password);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created. You can log in now.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _showNotImplementedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google sign up is not configured yet.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AuthBranding(),
            const SizedBox(height: 52),
            const AuthFieldLabel('Email'),
            AuthTextField(
              controller: _emailController,
              hint: 'your@email.com',
              icon: Icons.email_outlined,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            const AuthFieldLabel('Create password'),
            AuthTextField(
              controller: _passwordController,
              hint: '••••••••',
              icon: Icons.lock_outline,
              obscureText: true,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            const AuthFieldLabel('Confirm password'),
            AuthTextField(
              controller: _confirmController,
              hint: '••••••••',
              icon: Icons.lock_outline,
              obscureText: true,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 20),
            AuthPrimaryButton(label: 'Sign Up', onPressed: _handleSignUp),
            const SizedBox(height: 24),
            const AuthOrDivider(),
            const SizedBox(height: 22),
            AuthGoogleButton(onPressed: _showNotImplementedMessage),
            const SizedBox(height: 22),
            AuthBottomLink(
              leadingText: 'Already have an account? ',
              actionText: 'Log in',
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
