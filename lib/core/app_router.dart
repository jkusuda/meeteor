import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:meeteor/screens/home.dart';
import 'package:meeteor/screens/login.dart';
import 'package:meeteor/screens/explore.dart';
import 'package:meeteor/screens/profile.dart';
import 'package:meeteor/screens/new_post.dart';
import 'package:meeteor/screens/challenges.dart';
import 'package:meeteor/widgets/app_shell.dart';

// Provides a listenable version of Supabase Auth state for go_router
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }
  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// Global navigator key and nested shell keys
final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _homeTabNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'homeTab');
final _exploreTabNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'exploreTab');
final _postTabNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'postTab');
final _challengesTabNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'challengesTab');
final _profileTabNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'profileTab');

// Global trigger for refreshing lists (like posts after an upload)
final ValueNotifier<int> listRefreshNotifier = ValueNotifier<int>(0);

// GoRouter configuration
final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  refreshListenable: GoRouterRefreshStream(Supabase.instance.client.auth.onAuthStateChange),
  redirect: (BuildContext context, GoRouterState state) {
    final session = Supabase.instance.client.auth.currentSession;
    final loggedIn = session != null;
    final loggingIn = state.matchedLocation == '/login';

    if (!loggedIn && !loggingIn) {
      return '/login';
    }
    if (loggedIn && loggingIn) {
      return '/';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: _homeTabNavigatorKey,
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _exploreTabNavigatorKey,
          routes: [
            GoRoute(
              path: '/explore',
              builder: (context, state) => const ExplorePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _postTabNavigatorKey,
          routes: [
            GoRoute(
              path: '/post',
              builder: (context, state) => const NewPostPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _challengesTabNavigatorKey,
          routes: [
            GoRoute(
              path: '/challenges',
              builder: (context, state) => const ChallengesPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _profileTabNavigatorKey,
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
