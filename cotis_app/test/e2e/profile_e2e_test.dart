import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kased_app/main.dart';
import 'package:kased_app/providers/auth_provider.dart';
import 'package:kased_app/services/auth_service.dart';
import 'package:kased_app/providers/app_data_provider.dart';
import 'package:kased_app/core/services/stats_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ── Mocks ──────────────────────────────────────────────────────────────────────
class MockAuthService extends Mock implements AuthService {}
class MockSecureStorage extends Mock implements FlutterSecureStorage {}

class FakeAppData extends AppData {
  @override
  Future<AppState> build() async => AppState();

  @override
  Future<void> loadDashboard() async {}

  @override
  Future<void> syncData() async {}

  @override
  DashboardStats getDashboardStats() => DashboardStats(
        totalMembres: 10,
        totalCultes: 5,
        totalCollecte: 50000,
        membresEnRetard: 2,
        totalDu: 15000,
      );
}

// ── E2E Tests ──────────────────────────────────────────────────────────────────
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('E2E - Profile & Settings Flows', () {
    late MockAuthService mockAuth;
    late MockSecureStorage mockStorage;

    setUp(() {
      mockAuth = MockAuthService();
      mockStorage = MockSecureStorage();

      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);
      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});
      when(() => mockStorage.deleteAll()).thenAnswer((_) async {});
      when(() => mockAuth.signOut()).thenAnswer((_) async {});
    });

    ProviderScope buildApp() => ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuth),
            secureStorageProvider.overrideWithValue(mockStorage),
            appDataProvider.overrideWith(() => FakeAppData()),
          ],
          child: const KasedApp(),
        );

    testWidgets('Flow 1: Profile from drawer', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mon profil'));
      await tester.pumpAndSettle();

      expect(find.text('Mon profil'), findsOneWidget);
    });

    testWidgets('Flow 2: Theme options available', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mon profil'));
      await tester.pumpAndSettle();

      expect(find.text('Clair'), findsOneWidget);
      expect(find.text('Sombre'), findsOneWidget);
      expect(find.text('Auto'), findsOneWidget);
    });

    testWidgets('Flow 3: Notification panel', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Tout marquer lu'), findsOneWidget);
    });

    testWidgets('Flow 4: Logout flow', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mon profil'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Se déconnecter'));
      await tester.pumpAndSettle();

      expect(find.text('Déconnexion'), findsOneWidget);
    });
  });
}
