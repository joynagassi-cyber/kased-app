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
        totalMembres: 2,
        totalCultes: 2,
        totalCollecte: 10000,
        membresEnRetard: 0,
        totalDu: 0,
      );
}

// ── E2E Tests ──────────────────────────────────────────────────────────────────
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('E2E - Navigation Flows', () {
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

    testWidgets('Flow 1: Dashboard loads correctly', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Dashboard Kased'), findsOneWidget);
      expect(find.textContaining('MEMBRES'), findsOneWidget);
      expect(find.textContaining('CULTES'), findsOneWidget);
      expect(find.textContaining('COLLECTE TOTALE'), findsOneWidget);

    });

    testWidgets('Flow 2: Navigate to Members screen', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.people));
      await tester.pumpAndSettle();

      expect(find.text('Membres'), findsOneWidget);
    });

    testWidgets('Flow 3: Navigate to Cultes screen', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.church));
      await tester.pumpAndSettle();

      expect(find.text('Gestion des Cultes'), findsOneWidget);
    });

    testWidgets('Flow 4: Navigate to Stats screen', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.bar_chart));
      await tester.pumpAndSettle();

      expect(find.text('Statistiques'), findsOneWidget);
    });

    testWidgets('Flow 5: Navigate to Retards screen', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.warning_amber));
      await tester.pumpAndSettle();

      expect(find.text('Retards'), findsOneWidget);
    });

    testWidgets('Flow 6: Return to Dashboard from any screen', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Navigate to Members
      await tester.tap(find.byIcon(Icons.people));
      await tester.pumpAndSettle();
      expect(find.text('Membres'), findsOneWidget);

      // Return to Dashboard
      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();
      expect(find.text('Dashboard Kased'), findsOneWidget);

    });

    testWidgets('Flow 7: Notification icon present', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('Flow 8: Menu drawer accessible', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Mon profil'), findsOneWidget);
    });

    testWidgets('Flow 9: Trash navigation', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Corbeille'), findsOneWidget);
    });
  });
}
