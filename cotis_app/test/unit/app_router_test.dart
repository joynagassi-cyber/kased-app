import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kased_app/core/router/app_router.dart';
import 'package:kased_app/providers/auth_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kased_app/providers/app_data_provider.dart';

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
        appDataProvider.overrideWith(() => mockAppData),
      ],
    );

    // Force initialization of appDataProvider
    container.read(appDataProvider);

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
    await tester.pumpAndSettle();

    final router = container.read(routerProvider);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/onboarding');
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
    await tester.pumpAndSettle();

    final router = container.read(routerProvider);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/dashboard');
  });
}
