import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../providers/auth_provider.dart';
import '../../screens/onboarding_screen.dart';
import '../../screens/login_screen.dart';
import '../../screens/signup_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/membres/membres_screen.dart';
import '../../screens/membres/add_membre_screen.dart';
import '../../screens/membres/membre_detail_screen.dart';
import '../../screens/cultes/cultes_screen.dart';
import '../../screens/cultes/culte_detail_screen.dart';
import '../../screens/stats/stats_screen.dart';
import '../../screens/retards/retards_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/corbeille/corbeille_screen.dart';
import '../../widgets/app_shell.dart';
import '../../models/membre.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter router(RouterRef ref) {
  final authNotifier = _AuthNotifier(ref);

  return GoRouter(
    initialLocation: '/loading',
    refreshListenable: authNotifier,
    debugLogDiagnostics: !const bool.fromEnvironment('dart.vm.product'),

    redirect: (BuildContext context, GoRouterState state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;

      // Pendant le chargement initial, rester sur /loading
      if (auth.isLoading) {
        return loc == '/loading' ? null : '/loading';
      }

      // Auth résolue : quitter /loading vers la bonne destination
      if (loc == '/loading') {
        if (!auth.isAuthenticated) return '/onboarding';
        return '/dashboard';
      }

      final isPublic = loc == '/login' || loc == '/signup' || loc == '/onboarding' || loc == '/';
      if (!auth.isAuthenticated && !isPublic) return '/onboarding';
      if (auth.isAuthenticated && isPublic) {
        return '/dashboard';
      }

      return null;
    },

    routes: [
      // Route de chargement initial — affichée pendant _checkPersistedAuth()
      GoRoute(
        path: '/loading',
        builder: (context, state) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => _buildFadeSlidePage(
          context: context,
          state: state,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _buildFadeSlidePage(
          context: context,
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) => _buildFadeSlidePage(
          context: context,
          state: state,
          child: const SignupScreen(),
        ),
      ),

      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => _buildFadeSlidePage(
              context: context,
              state: state,
              child: const DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/membres',
            pageBuilder: (context, state) => _buildFadeSlidePage(
              context: context,
              state: state,
              child: const MembresScreen(),
            ),
            routes: [
              GoRoute(
                path: 'add',
                pageBuilder: (context, state) => _buildFadeSlidePage(
                  context: context,
                  state: state,
                  child: const AddMembreScreen(),
                ),
              ),
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) {
                  final membre = state.extra is Membre ? state.extra as Membre : null;
                  return _buildFadeSlidePage(
                    context: context,
                    state: state,
                    child: MembreDetailScreen(
                      membreId: state.pathParameters['id']!,
                      membre: membre,
                    ),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/cultes',
            pageBuilder: (context, state) => _buildFadeSlidePage(
              context: context,
              state: state,
              child: const CultesScreen(),
            ),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) => _buildFadeSlidePage(
                  context: context,
                  state: state,
                  child: CulteDetailScreen(
                    culteId: state.pathParameters['id']!,
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/stats',
            pageBuilder: (context, state) => _buildFadeSlidePage(
              context: context,
              state: state,
              child: const StatsScreen(),
            ),
          ),
          GoRoute(
            path: '/retards',
            pageBuilder: (context, state) => _buildFadeSlidePage(
              context: context,
              state: state,
              child: const RetardsScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) => _buildFadeSlidePage(
          context: context,
          state: state,
          child: const ProfileScreen(),
        ),
      ),
      GoRoute(
        path: '/corbeille',
        pageBuilder: (context, state) => _buildFadeSlidePage(
          context: context,
          state: state,
          child: const CorbeilleScreen(),
        ),
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page introuvable : ${state.error}'),
      ),
    ),
  );
}

CustomTransitionPage<void> _buildFadeSlidePage({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.04, 0.0), // 4% horizontal translation offset
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
          ),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 320),
  );
}

class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(this._ref) {
    _ref.listen(authProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}
