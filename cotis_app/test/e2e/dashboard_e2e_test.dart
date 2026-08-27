import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kased_app/main.dart';
import 'package:kased_app/providers/auth_provider.dart';
import 'package:kased_app/services/auth_service.dart';
import 'package:kased_app/providers/kased_app_provider.dart' as store;
import 'package:kased_app/core/services/stats_service.dart';
import 'package:kased_app/widgets/kased_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  group('E2E - Dashboard & Stats Flows', () {
    late MockAuthService mockAuth;
    late MockSecureStorage mockStorage;

    setUp(() {
      mockAuth = MockAuthService();
      mockStorage = MockSecureStorage();
      _preAuth(mockStorage);
      when(() => mockAuth.signOut()).thenAnswer((_) async {});
    });

    testWidgets('Flow 1: Dashboard main stats card', (tester) async {
      await tester.pumpWidget(buildApp(mockAuth, mockStorage));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Dashboard Kased'), findsOneWidget);
      expect(find.textContaining('MEMBRES'), findsOneWidget);
      expect(find.textContaining('CULTES'), findsOneWidget);
      expect(find.textContaining('COLLECTE TOTALE'), findsOneWidget);
    });

    testWidgets('Flow 2: Quick action buttons', (tester) async {
      await tester.pumpWidget(buildApp(mockAuth, mockStorage));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(KasedCard), findsWidgets);
    });

    testWidgets('Flow 3: Pull to refresh', (tester) async {
      await tester.pumpWidget(buildApp(mockAuth, mockStorage));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('Flow 4: Visual improvements', (tester) async {
      await tester.pumpWidget(buildApp(mockAuth, mockStorage));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(BackdropFilter), findsWidgets);
      expect(find.byType(ShaderMask), findsWidgets);
    });

    testWidgets('Flow 5: Stats screen loads', (tester) async {
      await tester.pumpWidget(buildApp(mockAuth, mockStorage));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Stats'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      expect(find.text('Statistiques'), findsOneWidget);
    });

    testWidgets('Flow 6: Retards screen loads', (tester) async {
      await tester.pumpWidget(buildApp(mockAuth, mockStorage));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Retards'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      expect(find.text('Retards'), findsOneWidget);
    });
  });
}
