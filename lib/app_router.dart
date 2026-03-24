import 'package:go_router/go_router.dart';
import 'package:astrophotography_blog/screens/home.dart';
import 'package:astrophotography_blog/screens/login.dart';
import 'package:astrophotography_blog/screens/explore.dart';
import 'package:astrophotography_blog/screens/profile.dart';
import 'package:astrophotography_blog/screens/create_post.dart';
import 'package:astrophotography_blog/screens/challenges.dart';

// GoRouter configuration
final _router = GoRouter(
  routes: [
    ShellRoute(
        GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
        path: '/explore',
        builder: (context, state) => const ExploreScreen(),
        ),
        GoRoute(
        path: '/challenges',
        builder: (context, state) => const ChallengesScreen(),
        ),
        GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
        ),
    ),
  ],
);
