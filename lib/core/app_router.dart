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
import 'package:meeteor/services/auth_service.dart';

import 'package:meeteor/screens/post_detail.dart';

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
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _homeTabNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'homeTab');
final _exploreTabNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'exploreTab');
final _postTabNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'postTab');
final _challengesTabNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'challengesTab');
final _profileTabNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'profileTab');

// Global trigger for refreshing lists (like posts after an upload)
final ValueNotifier<int> listRefreshNotifier = ValueNotifier<int>(0);

// Global like-state cache shared between feed and detail pages.
// Maps post ID -> liked boolean. Updated optimistically on toggle.
final Map<String, bool> likeStateCache = {};
// Notifies listeners whenever any like state changes.
final ValueNotifier<int> likeStateNotifier = ValueNotifier<int>(0);

// Global admin-view toggle shared between profile and challenges tabs.
final ValueNotifier<bool> adminViewEnabledNotifier = ValueNotifier<bool>(false);

StreamSubscription<AuthState>? _adminViewSyncSubscription;

Future<void> _syncAdminViewState({
  int attempts = 4,
  Duration delay = const Duration(milliseconds: 250),
}) async {
  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) {
    adminViewEnabledNotifier.value = false;
    return;
  }

  for (var attempt = 0; attempt <= attempts; attempt++) {
    final hasAdminAccess = await AuthService().hasAdminAccess();
    if (hasAdminAccess) {
      adminViewEnabledNotifier.value = true;
      return;
    }

    if (attempt < attempts) {
      await Future.delayed(delay);
    }
  }

  adminViewEnabledNotifier.value = false;
}

Future<void> initializeAppState() async {
  await _syncAdminViewState();

  _adminViewSyncSubscription ??=
      Supabase.instance.client.auth.onAuthStateChange.listen((event) {
    if (event.session == null) {
      adminViewEnabledNotifier.value = false;
      return;
    }

    if (event.event == AuthChangeEvent.signedIn ||
        event.event == AuthChangeEvent.initialSession) {
      unawaited(_syncAdminViewState());
    }
  });
}

// GoRouter configuration
final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
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
    GoRoute(
      path: '/p/:id',
      builder: (context, state) => PostDetailPage(postId: state.pathParameters['id']!),
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
              builder: (context, state) => ExplorePage(
                initialQuery: state.uri.queryParameters['q'],
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _postTabNavigatorKey,
          routes: [
            GoRoute(
              path: '/post',
              builder: (context, state) => NewPostPage(
                challengeId: state.uri.queryParameters['challengeId'],
                challengeTitle: state.uri.queryParameters['challengeTitle'],
                challengeDescription:
                    state.uri.queryParameters['challengeDescription'],
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _challengesTabNavigatorKey,
          routes: [
            GoRoute(
              path: '/challenges',
              builder: (context, state) => ValueListenableBuilder<bool>(
                valueListenable: adminViewEnabledNotifier,
                builder: (context, adminViewEnabled, _) => ChallengesPage(
                  key: ValueKey<bool>(adminViewEnabled),
                  adminViewEnabled: adminViewEnabled,
                ),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _profileTabNavigatorKey,
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => ValueListenableBuilder<bool>(
                valueListenable: adminViewEnabledNotifier,
                builder: (context, adminViewEnabled, _) => ProfilePage(
                  adminViewEnabled: adminViewEnabled,
                  onToggleAdminView: () {
                    adminViewEnabledNotifier.value = !adminViewEnabledNotifier.value;
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
