import 'package:flutter_test/flutter_test.dart';
import 'package:kased_app/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// Tests de la logique de redirection du routeur.
// On teste la fonction de redirect directement en simulant les états Auth.
// ---------------------------------------------------------------------------
void main() {
  group('Router redirect logic — non authentifié', () {
    test('isLoading=true → reste sur /loading', () {
      const auth = AuthState(isLoading: true, isAuthenticated: false);
      final redirect = _evaluateRedirect(auth: auth, location: '/loading');
      // Pendant le chargement, on ne redirige pas si on est déjà sur /loading
      expect(redirect, isNull);
    });

    test('isLoading=true + location /dashboard → redirige vers /loading', () {
      const auth = AuthState(isLoading: true, isAuthenticated: false);
      final redirect = _evaluateRedirect(auth: auth, location: '/dashboard');
      expect(redirect, equals('/loading'));
    });

    test('non-authentifié + location /loading → redirige vers /onboarding', () {
      const auth = AuthState(isLoading: false, isAuthenticated: false);
      final redirect = _evaluateRedirect(auth: auth, location: '/loading');
      expect(redirect, equals('/onboarding'));
    });

    test('non-authentifié + location /dashboard → redirige vers /onboarding', () {
      const auth = AuthState(isLoading: false, isAuthenticated: false);
      final redirect = _evaluateRedirect(auth: auth, location: '/dashboard');
      expect(redirect, equals('/onboarding'));
    });

    test('non-authentifié + location /membres → redirige vers /onboarding', () {
      const auth = AuthState(isLoading: false, isAuthenticated: false);
      final redirect = _evaluateRedirect(auth: auth, location: '/membres');
      expect(redirect, equals('/onboarding'));
    });
  });

  group('Router redirect logic — authentifié', () {
    test('authentifié + /loading → redirige vers /dashboard', () {
      const auth = AuthState(
        isLoading: false,
        isAuthenticated: true,
      );
      final redirect = _evaluateRedirect(auth: auth, location: '/loading');
      expect(redirect, equals('/dashboard'));
    });

    test('authentifié + /login → redirige vers /dashboard', () {
      const auth = AuthState(
        isLoading: false,
        isAuthenticated: true,
      );
      final redirect = _evaluateRedirect(auth: auth, location: '/login');
      expect(redirect, equals('/dashboard'));
    });

    test('authentifié + /onboarding → redirige vers /dashboard', () {
      const auth = AuthState(
        isLoading: false,
        isAuthenticated: true,
      );
      final redirect = _evaluateRedirect(auth: auth, location: '/onboarding');
      expect(redirect, equals('/dashboard'));
    });

    test('authentifié + /signup → redirige vers /dashboard', () {
      const auth = AuthState(
        isLoading: false,
        isAuthenticated: true,
      );
      final redirect = _evaluateRedirect(auth: auth, location: '/signup');
      expect(redirect, equals('/dashboard'));
    });

    test('authentifié + /dashboard → pas de redirection', () {
      const auth = AuthState(
        isLoading: false,
        isAuthenticated: true,
      );
      final redirect = _evaluateRedirect(auth: auth, location: '/dashboard');
      expect(redirect, isNull);
    });

    test('authentifié + /membres → pas de redirection', () {
      const auth = AuthState(
        isLoading: false,
        isAuthenticated: true,
      );
      final redirect = _evaluateRedirect(auth: auth, location: '/membres');
      expect(redirect, isNull);
    });
  });
}

/// Reproduit la logique de redirect du GoRouter sans instancier le routeur complet.
/// Cela permet de tester la logique de redirection de manière pure (sans widgets).
String? _evaluateRedirect({
  required AuthState auth,
  required String location,
}) {
  // Copie exacte de la logique dans app_router.dart
  if (auth.isLoading) {
    return location == '/loading' ? null : '/loading';
  }

  if (location == '/loading') {
    if (!auth.isAuthenticated) return '/onboarding';
    return '/dashboard';
  }

  final isPublic = location == '/login' || location == '/signup' || location == '/onboarding';
  if (!auth.isAuthenticated && !isPublic) return '/onboarding';
  if (auth.isAuthenticated && isPublic) {
    return '/dashboard';
  }

  return null;
}
