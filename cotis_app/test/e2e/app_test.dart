import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kased_app/main.dart';
import 'package:kased_app/providers/auth_provider.dart';
import 'package:kased_app/services/auth_service.dart';
import 'package:kased_app/providers/app_data_provider.dart';
import 'package:kased_app/widgets/spring_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ── Mocks ──────────────────────────────────────────────────────────────────
class MockAuthService extends Mock implements AuthService {}
class MockSecureStorage extends Mock implements FlutterSecureStorage {}

// ── Fake AppData ─────────────────────────────────────────────────────────
// Uses a real subclass so Riverpod can call _setElement internally.
// Overrides build() to return an empty AppState immediately (no Isar, no
// network), and overrides every method that would normally do IO.
class FakeAppData extends AppData {
  @override
  Future<AppState> build() async => AppState();

  @override
  Future<void> loadDashboard() async {}

  @override
  Future<void> syncData() async {}

  @override
  Future<List<Map<String, dynamic>>> loadRetardsMembres() async => [];

  @override
  DashboardStats getDashboardStats() => DashboardStats(
        totalMembres: 10,
        totalCultes: 5,
        totalCollecte: 50000,
        membresEnRetard: 2,
        totalDu: 15000,
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('E2E - Flux Complet (Simulé)', () {
    late MockAuthService mockAuth;
    late MockSecureStorage mockStorage;

    setUp(() {
      mockAuth = MockAuthService();
      mockStorage = MockSecureStorage();

      // Secure storage : aucune session persistée → non connecté
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);
      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});
      when(() => mockStorage.deleteAll()).thenAnswer((_) async {});

      // signOut ne doit pas planter
      when(() => mockAuth.signOut()).thenAnswer((_) async {});
    });

    ProviderScope buildApp() => ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuth),
            secureStorageProvider.overrideWithValue(mockStorage),
            appDataProvider.overrideWith(FakeAppData.new),
          ],
          child: const KasedApp(),
        );

    testWidgets('Onboarding → Login → Dashboard (E2E)', (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildApp());

      // Laisser le temps à l'auth d'initialiser (pas de token → unauthenticated).
      // L'initial route est /loading → auth.isLoading=true → on pump jusqu'à
      // ce que isLoading devienne false → redirect vers /onboarding.
      // On utilise pump() au lieu de pumpAndSettle() car l'onboarding contient
      // une animation continue de 12s (OnboardingHeroAnimation) et un
      // BouncingScrollBehavior global qui empêchent pumpAndSettle de se terminer.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 1. On doit être sur l'onboarding
      expect(find.text('Bienvenue sur Kased'), findsOneWidget);

      // Aller au login
      final startBtn = find.ancestor(
        of: find.text('Se connecter'),
        matching: find.byType(SpringButton),
      );
      await tester.tap(startBtn.first);
      await tester.pump(const Duration(milliseconds: 600));

      // 2. Vérifier qu'on est sur le login
      expect(
        find.text("Gérez vos cotisations d'église en toute simplicité"),
        findsOneWidget,
      );

      // 3. Simuler login email réussi
      when(() => mockAuth.signInWithEmail(any(), any())).thenAnswer(
        (_) async => {
          'token': 'fake_token_valide_12345',
          'refreshToken': 'fake_refresh',
          'email': 'test@example.com',
          'name': 'Utilisateur Test',
          'id': 'user123',
        },
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');

      final loginBtn = find.ancestor(
        of: find.text('Se connecter'),
        matching: find.byType(SpringButton),
      );
      await tester.tap(loginBtn.first);
      await tester.pump(const Duration(milliseconds: 800));

      // 4. Vérifier qu'on est redirigé vers le Dashboard
      expect(find.text('Accueil'), findsWidgets);
    });

    testWidgets('Onboarding → Login Google → Dashboard (E2E)', (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Bienvenue sur Kased'), findsOneWidget);

      await tester.tap(find.ancestor(
        of: find.text('Se connecter'),
        matching: find.byType(SpringButton),
      ).first);
      await tester.pump(const Duration(milliseconds: 600));

      when(() => mockAuth.signInWithGoogle()).thenAnswer(
        (_) async => {
          'token': 'fake_google_token_12345',
          'refreshToken': 'fake_refresh',
          'email': 'admin@example.com',
          'name': 'Admin User',
          'id': 'admin123',
        },
      );

      await tester.tap(find.ancestor(
        of: find.text('Continuer avec Google'),
        matching: find.byType(SpringButton),
      ).first);
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('Accueil'), findsWidgets);
    });
  });
}
