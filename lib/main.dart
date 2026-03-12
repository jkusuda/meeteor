import 'package:astrophotography_blog/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color prussianBlue = Color(0xFF141C34);
  static const Color spaceIndigo = Color(0xFF302C5C);
  static const Color vintageLavender = Color(0xFF73628A);
  static const Color thistle = Color(0xFFCBC3D5);
  static const Color honeyBronze = Color(0xFFFCB454);
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.dmSansTextTheme(),
      ),
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: AppColors.spaceIndigo,
          secondary: AppColors.honeyBronze,
          tertiary: AppColors.vintageLavender,
          surface: AppColors.thistle,
          onPrimary: Colors.white,
          onSecondary: AppColors.prussianBlue,
          onTertiary: Colors.white,
          onSurface: AppColors.prussianBlue,
        ),
        scaffoldBackgroundColor: AppColors.thistle,
      ),
      home: const const HomePage(),,
    );
  }
}

