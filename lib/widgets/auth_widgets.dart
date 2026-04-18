import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthColors {
  static const Color pageBackground = Color(0xFF141C34);
  static const Color fieldFill = Color(0x403A336F);
  static const Color fieldBorder = Color(0x806D5EA8);
  static const Color mutedText = Color(0xFFB8B1D4);
  static const Color subtleText = Color(0xFF8F88B0);
  static const Color accent = Color(0xFFF0B14F);
}

class AuthBackground extends StatelessWidget {
  const AuthBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AuthColors.pageBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 1.0,
              child: Image.asset(
                'assets/starry_sky_bg_1.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthBranding extends StatelessWidget {
  const AuthBranding({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 30),
          Text(
            'meeteor',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 54,
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'blast off into the cosmos',
            textAlign: TextAlign.center,
            style: GoogleFonts.cedarvilleCursive(
              color: AuthColors.accent,
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text.toUpperCase(),
          style: GoogleFonts.dmSans(
            color: AuthColors.subtleText,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.textInputAction,
    this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      cursorColor: AuthColors.accent,
      obscureText: obscureText,
      obscuringCharacter: '•',
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      textAlignVertical: TextAlignVertical.center,
      style: GoogleFonts.dmSans(
        color: Colors.white,
        fontSize: 18,
        fontWeight: obscureText ? FontWeight.w600 : FontWeight.w500,
        letterSpacing: obscureText ? 2.8 : 0,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(
          color: AuthColors.mutedText,
          fontSize: 16,
        ),
        prefixIcon: Icon(icon, color: AuthColors.subtleText),
        filled: true,
        fillColor: AuthColors.fieldFill,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 22,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AuthColors.fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AuthColors.fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AuthColors.accent, width: 1.2),
        ),
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AuthColors.accent,
          foregroundColor: const Color(0xFF2D233D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: GoogleFonts.dmSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: Color(0x4DA79CC8), thickness: 1, endIndent: 14),
        ),
        Text(
          'OR',
          style: GoogleFonts.dmSans(
            color: AuthColors.subtleText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Expanded(
          child: Divider(color: Color(0x4DA79CC8), thickness: 1, indent: 14),
        ),
      ],
    );
  }
}

class AuthGoogleButton extends StatelessWidget {
  const AuthGoogleButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.public, color: Colors.white70),
        label: Text(
          'Continue with Google',
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AuthColors.fieldBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: AuthColors.fieldFill,
        ),
      ),
    );
  }
}

class AuthBottomLink extends StatelessWidget {
  const AuthBottomLink({
    required this.leadingText,
    required this.actionText,
    required this.onTap,
    super.key,
  });

  final String leadingText;
  final String actionText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          leadingText,
          style: GoogleFonts.dmSans(color: AuthColors.mutedText, fontSize: 16),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            actionText,
            style: GoogleFonts.dmSans(
              color: AuthColors.accent,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
