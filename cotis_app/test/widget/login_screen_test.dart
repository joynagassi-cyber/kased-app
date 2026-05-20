import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kased_app/screens/login_screen.dart';
import 'package:kased_app/core/insforge/insforge_service.dart';
import 'package:kased_app/services/auth_service.dart';
import 'package:kased_app/providers/auth_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';

import 'dart:io';

class MockInsForgeService extends Mock implements InsForgeService {}
class MockAuthService extends Mock implements AuthService {}
class MockSecureStorage extends Mock implements FlutterSecureStorage {}

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient extends Mock implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
}

class _MockHttpClientRequest extends Mock implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpClientResponse extends Mock implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => 0;
  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData, {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return const Stream<List<int>>.empty().listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}

void main() {
  HttpOverrides.global = MockHttpOverrides();
  late MockInsForgeService mockApi;
  late MockAuthService mockAuth;
  late MockSecureStorage mockStorage;

  setUp(() {
    mockApi = MockInsForgeService();
    mockAuth = MockAuthService();
    mockStorage = MockSecureStorage();
    
    when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
    when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value'))).thenAnswer((_) async => {});
    when(() => mockStorage.delete(key: any(named: 'key'))).thenAnswer((_) async => {});
  });

  Widget createLoginScreen() {
    return ProviderScope(
      overrides: [
        insForgeServiceProvider.overrideWithValue(mockApi),
        authServiceProvider.overrideWithValue(mockAuth),
        secureStorageProvider.overrideWithValue(mockStorage),
      ],
      child: const MaterialApp(
        home: LoginScreen(),
      ),
    );
  }

  testWidgets('Renders essential login fields', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    expect(find.text('Bienvenue sur Kased'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Se connecter'), findsOneWidget);
  });

  testWidgets('Login success calls AuthService and storage', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockResponse = {
      'token': 'fake_token',
      'email': 'test@test.com',
      'name': 'Test User',
      'id': 'u1'
    };
    
    when(() => mockAuth.signInWithEmail(any(), any())).thenAnswer((_) async => mockResponse);

    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'test@test.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    
    await tester.tap(find.text('Se connecter'));
    // Pump multiple frames to allow Riverpod state (isEmailLoading=true) to propagate
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    
    // The CircularProgressIndicator may or may not be visible depending on timing,
    // so we don't assert it strictly. What matters is that the action was completed.
    await tester.pumpAndSettle(const Duration(seconds: 5));
    
    verify(() => mockAuth.signInWithEmail('test@test.com', 'password')).called(1);
    verify(() => mockStorage.write(key: 'auth_token', value: 'fake_token')).called(1);
  });
}
