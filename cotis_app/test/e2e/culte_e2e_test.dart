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

  group('E2E - Cult Management Flows', () {
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
            appDataProvider.overrideWith((ref) => FakeAppData()),
          ],
          child: const KasedApp(),
        );

    testWidgets('Flow 1: Cult list displays', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.church));
      await tester.pumpAndSettle();

      expect(find.text('Gestion des Cultes'), findsOneWidget);
      expect(find.textContaining('FCFA'), findsOneWidget);
      print('✅ Flow 1: Cult list displays');
    });

    testWidgets('Flow 2: Create cult dialog opens', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.church));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_task));
      await tester.pumpAndSettle();

      expect(find.text('Nouveau culte'), findsOneWidget);
      print('✅ Flow 2: Create cult dialog opens');
    });

    testWidgets('Flow 3: Cult detail actions', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.church));
      await tester.pumpAndSettle();

      // Verify action icons exist
      expect(find.byIcon(Icons.edit), findsWidgets);
      expect(find.byIcon(Icons.delete_outline), findsWidgets);
      print('✅ Flow 3: Cult detail actions available');
    });

    testWidgets('Flow 4: Sync button available', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.church));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.sync), findsOneWidget);
      print('✅ Flow 4: Sync button available');
    });
  });
}
