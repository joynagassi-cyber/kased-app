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

  group('E2E - Dashboard & Stats Flows', () {
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
            appDataProvider.overrideWith(FakeAppData.new),
          ],
          child: const KasedApp(),
        );

    testWidgets('Flow 1: Dashboard main stats card', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.textContaining('COLLECTE TOTALE'), findsOneWidget);
      expect(find.textContaining('MEMBRES'), findsOneWidget);
      expect(find.textContaining('CULTES'), findsOneWidget);
      expect(find.textContaining('RETARDS'), findsOneWidget);
      print('✅ Flow 1: Dashboard main stats card displays');
    });

    testWidgets('Flow 2: Quick action buttons', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Démarrer un culte'), findsOneWidget);
      expect(find.text('Voir les retards'), findsOneWidget);
      expect(find.text('Statistiques'), findsOneWidget);
      expect(find.text('Gérer les membres'), findsOneWidget);
      print('✅ Flow 2: Quick action buttons present');
    });

    testWidgets('Flow 3: Pull to refresh', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
      print('✅ Flow 3: Pull to refresh available');
    });

    testWidgets('Flow 4: Visual improvements', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Verify glassmorphism elements
      expect(find.byType(BackdropFilter), findsWidgets);
      expect(find.byType(ShaderMask), findsWidgets);
      print('✅ Flow 4: Visual improvements rendered');
    });

    testWidgets('Flow 5: Stats screen loads', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.bar_chart));
      await tester.pumpAndSettle();

      expect(find.text('Statistiques'), findsOneWidget);
      print('✅ Flow 5: Stats screen loads');
    });

    testWidgets('Flow 6: Retards screen loads', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.warning_amber));
      await tester.pumpAndSettle();

      expect(find.text('Retards'), findsOneWidget);
      print('✅ Flow 6: Retards screen loads');
    });
  });
}
