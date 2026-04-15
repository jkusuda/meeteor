import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:meeteor/core/app_router.dart';

class AppColors {
  static const Color prussianBlue = Color(0xFF141C34);
  static const Color spaceIndigo = Color(0xFF302C5C);
  static const Color vintageLavender = Color(0xFF73628A);
  static const Color thistle = Color(0xFFCBC3D5);
  static const Color honeyBronze = Color(0xFFFCB454);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null ||
      supabaseUrl.isEmpty ||
      supabaseAnonKey == null ||
      supabaseAnonKey.isEmpty) {
    throw StateError('Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env file.');
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  await initializeAppState();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.dmSansTextTheme(),
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
      routerConfig: appRouter,
    );
  }
}
