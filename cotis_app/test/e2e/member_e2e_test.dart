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

  group('E2E - Member Management Flows', () {
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

    testWidgets('Flow 1: Add member form opens', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.people));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.person_add));
      await tester.pumpAndSettle();

      expect(find.text('Ajouter un membre'), findsOneWidget);
      print('✅ Flow 1: Add member form opens');
    });

    testWidgets('Flow 2: Member list displays', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.people));
      await tester.pumpAndSettle();

      expect(find.text('Membres'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      print('✅ Flow 2: Member list displays');
    });

    testWidgets('Flow 3: Search functionality', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.people));
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField).first;
      expect(searchField, findsOneWidget);
      print('✅ Flow 3: Search field present');
    });

    testWidgets('Flow 4: Sync button available', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.people));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.sync), findsOneWidget);
      print('✅ Flow 4: Sync button available');
    });
  });
}
