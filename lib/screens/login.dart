import 'package:flutter/material.dart';
import 'package:meeteor/services/auth_service.dart';
import 'package:meeteor/widgets/auth_widgets.dart';
import 'package:meeteor/screens/signup.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:meeteor/core/app_router.dart';

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

  Future<void> _showForgotPasswordDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ForgotPasswordDialog(initialEmail: _emailController.text),
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
                onPressed: _showForgotPasswordDialog,
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

class _ForgotPasswordDialog extends StatefulWidget {
  final String initialEmail;

  const _ForgotPasswordDialog({required this.initialEmail});

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  final _authService = AuthService();

  int _step = 1;
  late final TextEditingController _emailController;
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    isPasswordRecoveryFlow = false;
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
  }

  void _showSuccess(String message) {
    setState(() => _errorMessage = null);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      _showError('Please enter a valid email.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _authService.resetPassword(email: email);
      if (!mounted) return;
      _showSuccess('OTP code sent! Check your email.');
      setState(() => _step = 2);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final token = _otpController.text.trim();
    if (token.isEmpty) {
      _showError('Please enter the 6-digit OTP code.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      isPasswordRecoveryFlow = true;
      await _authService.verifyRecoveryOTP(
        email: _emailController.text.trim(),
        token: token,
      );
      if (!mounted) return;
      setState(() => _step = 3);
    } catch (e) {
      isPasswordRecoveryFlow = false;
      if (!mounted) return;
      _showError('Invalid or expired OTP code.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePassword() async {
    final newPassword = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    if (newPassword.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }
    if (newPassword != confirmPassword) {
      _showError('Passwords do not match.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _authService.updatePassword(newPassword);
      isPasswordRecoveryFlow = false;
      if (!mounted) return;
      _showSuccess('Password updated successfully!');
      Navigator.pop(context); // Close dialog
      GoRouter.of(context).go('/');
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Reset Password';
    String description = '';
    Widget inputField = const SizedBox.shrink();
    String actionLabel = '';
    VoidCallback? onAction;

    if (_step == 1) {
      description = 'Enter your email address and we will send you a 6-digit OTP code.';
      inputField = TextField(
        controller: _emailController,
        cursorColor: AuthColors.accent,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'your@email.com',
          hintStyle: TextStyle(color: Colors.white30),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AuthColors.fieldBorder)),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AuthColors.accent)),
        ),
      );
      actionLabel = 'Send OTP';
      onAction = _sendOtp;
    } else if (_step == 2) {
      title = 'Enter OTP';
      description = 'Check your email for the 6-digit recovery code.';
      inputField = TextField(
        controller: _otpController,
        cursorColor: AuthColors.accent,
        style: const TextStyle(color: Colors.white),
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          hintText: '123456',
          hintStyle: TextStyle(color: Colors.white30),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AuthColors.fieldBorder)),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AuthColors.accent)),
        ),
      );
      actionLabel = 'Verify';
      onAction = _verifyOtp;
    } else if (_step == 3) {
      title = 'New Password';
      description = 'Enter your new password to secure your account.';
      inputField = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _passwordController,
            cursorColor: AuthColors.accent,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'New Password',
              hintStyle: TextStyle(color: Colors.white30),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AuthColors.fieldBorder)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AuthColors.accent)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmPasswordController,
            cursorColor: AuthColors.accent,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Confirm Password',
              hintStyle: TextStyle(color: Colors.white30),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AuthColors.fieldBorder)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AuthColors.accent)),
            ),
          ),
        ],
      );
      actionLabel = 'Update';
      onAction = _updatePassword;
    }

    return AlertDialog(
      backgroundColor: const Color(0xFF231E3D),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(description, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          inputField,
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Color(0xFFEF5350), fontSize: 13, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: AuthColors.accent, strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      actions: [
        if (!_isLoading)
          TextButton(
            onPressed: () {
              isPasswordRecoveryFlow = false;
              Navigator.pop(context);
              if (Supabase.instance.client.auth.currentSession != null) {
                GoRouter.of(context).go('/');
              }
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
        if (!_isLoading)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel, style: const TextStyle(color: AuthColors.accent)),
          ),
      ],
    );
  }
}
