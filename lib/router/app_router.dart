import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../ui/screens/dashboard_screen.dart';
import '../ui/screens/calendar_screen.dart';
import '../ui/screens/history_screen.dart';
import '../ui/screens/settings_screen.dart';
import '../ui/screens/login_screen.dart';
import '../logic/viewmodels/auth_viewmodel.dart';
import '../utils/app_localizations.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter createRouter(AuthViewModel authViewModel) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      refreshListenable: authViewModel,
      redirect: (context, state) {
        final loggingIn = state.uri.path == '/login';

        if (!authViewModel.isAuthenticated) {
          return '/login';
        }

        if (loggingIn) {
          return '/';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) {
            return ScaffoldWithNavBar(child: child);
          },
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const DashboardScreen(),
              ),
            ),
            GoRoute(
              path: '/calendar',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const CalendarScreen(),
              ),
            ),
            GoRoute(
              path: '/history',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const HistoryScreen(),
              ),
            ),
            GoRoute(
              path: '/settings',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const SettingsScreen(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNavBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    int currentIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/calendar');
              break;
            case 2:
              context.go('/history');
              break;
            case 3:
              context.go('/settings');
              break;
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: context.tr('dashboard'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: context.tr('calendar'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.badge_outlined),
            selectedIcon: const Icon(Icons.badge),
            label: 'Card',
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: context.tr('settings'),
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    try {
      final String location = GoRouterState.of(context).uri.path;
      if (location.startsWith('/settings')) return 3;
      if (location.startsWith('/history')) return 2;
      if (location.startsWith('/calendar')) return 1;
    } catch (e) {
      debugPrint("Router state error: $e");
    }
    return 0;
  }
}
