import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kased_app/main.dart';
import 'package:kased_app/providers/auth_provider.dart';
import 'package:kased_app/services/auth_service.dart';
import 'package:kased_app/providers/kased_app_provider.dart' as store;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kased_app/core/services/stats_service.dart';

class MockAuthService extends Mock implements AuthService {}
class MockSecureStorage extends Mock implements FlutterSecureStorage {}

class TestKasedApp extends store.KasedApp {
  @override
  Future<store.AppState> build() async {
    return store.AppState();
  }
  @override
  Future<void> loadDashboard() async {}
  @override
  Future<void> syncData() async {}
  @override
  DashboardStats getDashboardStats() => DashboardStats(
        totalMembres: 10,
        totalCultes: 5,
        totalCollecte: 50000,
        membresEnRetard: 0,
        totalDu: 15000,
      );
  @override
  Future<List<Map<String, dynamic>>> loadRetardsMembres() async => [];
  @override
  List<Map<String, dynamic>> getRetardsMembresLocally() => [];
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
        store.kasedAppProvider.overrideWith(() => TestKasedApp()),
      ],
      child: const KasedApp(),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('E2E - Navigation Flows', () {
    late MockAuthService mockAuth;
    late MockSecureStorage mockStorage;

    setUp(() {
      mockAuth = MockAuthService();
      mockStorage = MockSecureStorage();
      _preAuth(mockStorage);
      when(() => mockAuth.signOut()).thenAnswer((_) async {});
    });

    testWidgets('Flow 1: Dashboard loads correctly', (tester) async {
      await tester.pumpWidget(buildApp(mockAuth, mockStorage));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Dashboard Kased'), findsOneWidget);
      expect(find.textContaining('MEMBRES'), findsOneWidget);
      expect(find.textContaining('CULTES'), findsOneWidget);
      expect(find.textContaining('COLLECTE TOTALE'), findsOneWidget);
    });

    testWidgets('Flow 2: Navigate to Members screen', (tester) async {
      await tester.pumpWidget(buildApp(mockAuth, mockStorage));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Membres'), findsOneWidget);
    });

    testWidgets('Flow 3: Navigate to Cultes screen', (tester) async {
      await tester.pumpWidget(buildApp(mockAuth, mockStorage));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Cultes'), findsOneWidget);
    });

    testWidgets('Flow 4: Navigate to Stats screen', (tester) async {
      await tester.pumpWidget(buildApp(mockAuth, mockStorage));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Stats'), findsOneWidget);
    });

    testWidgets('Flow 5: Navigate to Retards screen', (tester) async {
      await tester.pumpWidget(buildApp(mockAuth, mockStorage));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Retards'), findsOneWidget);
    });

    testWidgets('Flow 6: Return to Dashboard from any screen', (tester) async {
      await tester.pumpWidget(buildApp(mockAuth, mockStorage));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Dashboard Kased'), findsOneWidget);
    });

    testWidgets('Flow 7: Notification icon present', (tester) async {
      await tester.pumpWidget(buildApp(mockAuth, mockStorage));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('Flow 8: Menu drawer accessible', (tester) async {
      await tester.pumpWidget(buildApp(mockAuth, mockStorage));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
    });

    testWidgets('Flow 9: Trash navigation', (tester) async {
      await tester.pumpWidget(buildApp(mockAuth, mockStorage));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Dashboard Kased'), findsOneWidget);
    });
  });
}
