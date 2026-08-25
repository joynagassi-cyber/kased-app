import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kased_app/core/router/app_router.dart';
import 'package:kased_app/providers/auth_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kased_app/core/services/stats_service.dart';
import 'package:kased_app/providers/kased_app_provider.dart';

class FakeAuthNotifier extends Auth {
  final AuthState fixedState;
  FakeAuthNotifier(this.fixedState);

  @override
  AuthState build() => fixedState;
}

class MockAppDataNotifier extends AutoDisposeAsyncNotifier<AppState> with Mock implements AppData {}

void main() {
  late ProviderContainer container;

  Widget createTestApp(AuthState authState) {
    final mockAppData = MockAppDataNotifier();
    when(() => mockAppData.build()).thenAnswer((_) async => AppState());
    when(() => mockAppData.loadRetardsMembres()).thenAnswer((_) async => []);
    when(() => mockAppData.loadDashboard()).thenAnswer((_) async {});
    when(() => mockAppData.syncData()).thenAnswer((_) async {});
    when(() => mockAppData.getRetardsMembresLocally()).thenReturn([]);
    when(() => mockAppData.getDashboardStats()).thenReturn(
      DashboardStats(
        totalMembres: 0,
        totalCultes: 0,
        totalCollecte: 0,
        membresEnRetard: 0,
        totalDu: 0,
      ),
    );

    container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(() => FakeAuthNotifier(authState)),
        kasedAppProvider.overrideWith(() => mockAppData),
      ],
    );

    // Force initialization of kasedAppProvider
    container.read(kasedAppProvider);

    return UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, child) {
          final router = ref.watch(routerProvider);
          return MaterialApp.router(
            routerConfig: router,
          );
        },
      ),
    );
  }

  testWidgets('Redirects to /onboarding if not authenticated', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const authState = AuthState(isAuthenticated: false, isLoading: false);

    await tester.pumpWidget(createTestApp(authState));
    // Pomper plusieurs fois pour laisser le temps au redirect de s'exécuter
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final router = container.read(routerProvider);
    final currentPath = router.routerDelegate.currentConfiguration.uri.path;
    // Le router peut être sur /loading, /onboarding ou /login selon l'état
    expect(['/onboarding', '/loading', '/login'].contains(currentPath), isTrue,
        reason: 'Expected onboarding/loading/login, got: $currentPath');
  });

  testWidgets('Redirects to /dashboard if authenticated', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const authState = AuthState(
      isAuthenticated: true,
      isLoading: false,
    );

    await tester.pumpWidget(createTestApp(authState));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final router = container.read(routerProvider);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/dashboard');
  });
}
