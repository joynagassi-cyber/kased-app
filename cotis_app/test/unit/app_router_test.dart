import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kased_app/core/router/app_router.dart';
import 'package:kased_app/providers/auth_provider.dart';

class FakeAuthNotifier extends Auth {
  final AuthState fixedState;
  FakeAuthNotifier(this.fixedState);

  @override
  AuthState build() => fixedState;
}

void main() {
  late ProviderContainer container;

  Widget createTestApp(AuthState authState) {
    container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(() => FakeAuthNotifier(authState)),
      ],
    );
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final router = container.read(routerProvider);
    final currentPath = router.routerDelegate.currentConfiguration.uri.path;
    expect(['/onboarding', '/loading', '/login'].contains(currentPath), isTrue,
        reason: 'Expected onboarding/loading/login, got: $currentPath');
  });

  testWidgets('Redirects to /dashboard if authenticated', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const authState = AuthState(isAuthenticated: true, isLoading: false);

    await tester.pumpWidget(createTestApp(authState));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final router = container.read(routerProvider);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/dashboard');
  });
}
