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

class MockAuthService extends Mock implements AuthService {}
class MockSecureStorage extends Mock implements FlutterSecureStorage {}

class FakeAppData extends AppData {
  @override
  Future<AppState> build() async {
    this.statsService = StatsService();
    return AppState();
  }

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
  @override
  Future<List<Map<String, dynamic>>> loadRetardsMembres() async => [];
}

const _validAccessToken =
    'eyJhbGciOiAiSFMyNTYiLCAidHlwIjogIkpXVCJ9.eyJzdWIiOiAidGVzdCIsICJleHAiOiA0MTAyNDQ0ODAwLCAiaWF0IjogMTc4NzA5NDUxMiwgImVtYWlsIjogInRlc3RAdGVzdC5jb20iLCAibmFtZSI6ICJUZXN0IFVzZXIifQ.fakesignature';
const _validRefreshToken =
    'eyJhbGciOiAiSFMyNTYiLCAidHlwIjogIkpXVCJ9.eyJzdWIiOiAicmVmcmVzaCIsICJleHAiOiA0MTAyNDQ0ODAwfQ.fakesignature';

void _preAuth(MockSecureStorage storage) {
  when(() => storage.read(key: 'auth_token')).thenAnswer((_) async => _validAccessToken);
  when(() => storage.read(key: 'refresh_token')).thenAnswer((_) async => _validRefreshToken);
  when(() => storage.read(key: 'user_email')).thenAnswer((_) async => 'test@test.com');
  when(() => storage.read(key: 'user_name')).thenAnswer((_) async => 'Test User');
  when(() => storage.read(key: any(named: 'key'))).thenAnswer((_) async => _validAccessToken);
  when(() => storage.write(key: any(named: 'key'), value: any(named: 'value'))).thenAnswer((_) async {});
  when(() => storage.deleteAll()).thenAnswer((_) async {});
}

ProviderScope buildApp(MockAuthService mockAuth, MockSecureStorage mockStorage) => ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(mockAuth),
        secureStorageProvider.overrideWithValue(mockStorage),
        appDataProvider.overrideWith(() => FakeAppData()),
      ],
      child: const KasedApp(),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('E2E - Cult Management Flows', () {
    late MockAuthService mockAuth;
    late MockSecureStorage mockStorage;

    setUp(() {
      mockAuth = MockAuthService();
      mockStorage = MockSecureStorage();
      _preAuth(mockStorage);
      when(() => mockAuth.signOut()).thenAnswer((_) async {});
    });

    testWidgets('Flow 1: Cult list displays', (tester) async {
      await tester.pumpWidget(buildApp(mockAuth, mockStorage));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Cultes'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Gestion des Cultes'), findsOneWidget);
    });

    testWidgets('Flow 2: Create cult dialog opens', (tester) async {
      await tester.pumpWidget(buildApp(mockAuth, mockStorage));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Cultes'));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.byIcon(Icons.add_task));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Nouveau culte'), findsOneWidget);
    });

    testWidgets('Flow 3: Cult detail actions', (tester) async {
      await tester.pumpWidget(buildApp(mockAuth, mockStorage));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Cultes'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byIcon(Icons.edit_outlined), findsWidgets);
      expect(find.byIcon(Icons.delete_outline), findsWidgets);
    });

    testWidgets('Flow 4: Sync button available', (tester) async {
      await tester.pumpWidget(buildApp(mockAuth, mockStorage));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Cultes'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byIcon(Icons.sync), findsOneWidget);
    });
  });
}
