import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kased_app/providers/auth_provider.dart';
import 'package:kased_app/services/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('AuthState', () {
    test('valeur initiale correcte', () {
      const state = AuthState();
      expect(state.isAuthenticated, isFalse);
      expect(state.isLoading, isTrue);
      expect(state.userEmail, isNull);
      expect(state.token, isNull);
    });

    test('copyWith met à jour uniquement les champs spécifiés', () {
      const original = AuthState(
        isAuthenticated: false,
        isLoading: true,
        userEmail: 'test@test.com',
      );

      final updated = original.copyWith(
        isAuthenticated: true,
        isLoading: false,
        token: 'tok_123',
      );

      expect(updated.isAuthenticated, isTrue);
      expect(updated.isLoading, isFalse);
      expect(updated.userEmail, equals('test@test.com')); // inchangé
      expect(updated.token, equals('tok_123'));
    });

    test('copyWith sans arguments retourne état identique', () {
      const state = AuthState(
        isAuthenticated: true,
        isLoading: false,
        userEmail: 'a@b.com',
        userName: 'Alice',
        token: 'tok',
      );

      final copy = state.copyWith();

      expect(copy.isAuthenticated, equals(state.isAuthenticated));
      expect(copy.isLoading, equals(state.isLoading));
      expect(copy.userEmail, equals(state.userEmail));
      expect(copy.userName, equals(state.userName));
      expect(copy.token, equals(state.token));
    });
  });

  group('AuthState — construction', () {
    test('AuthState complet construit correctement', () {
      const state = AuthState(
        isAuthenticated: true,
        isLoading: false,
        userEmail: 'jean@eglise.cm',
        userName: 'Jean Dupont',
        token: 'eyJhbGc...',
        refreshToken: 'ref_tok',
      );

      expect(state.isAuthenticated, isTrue);
      expect(state.userEmail, equals('jean@eglise.cm'));
      expect(state.userName, equals('Jean Dupont'));
      expect(state.token, equals('eyJhbGc...'));
      expect(state.refreshToken, equals('ref_tok'));
    });
  });

  group('Auth Provider (Riverpod)', () {
    late MockAuthService mockAuthService;
    const validJwt = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjIwMDAwMDAwMDB9.signature';

    setUp(() {
      mockAuthService = MockAuthService();
      // Default stubs
      when(() => mockAuthService.refreshToken(any())).thenAnswer((_) async => {
        'token': validJwt,
        'refreshToken': 'fake_refresh',
      });
      when(() => mockAuthService.signOut()).thenAnswer((_) async => {});
    });

    test('Émet unauthenticated par défaut (après mock storage)', () async {
      FlutterSecureStorage.setMockInitialValues({});
      
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(authProvider, (_, __) {});

      expect(container.read(authProvider).isLoading, isTrue);

      int retries = 0;
      while (container.read(authProvider).isLoading && retries < 20) {
        await Future.delayed(const Duration(milliseconds: 50));
        retries++;
      }

      final state = container.read(authProvider);
      expect(state.isLoading, isFalse);
      expect(state.isAuthenticated, isFalse);
      
      sub.close();
    });

    test('Émet authenticated si tokens dans le storage', () async {
      FlutterSecureStorage.setMockInitialValues({
        'auth_token': validJwt,
        'refresh_token': 'fake_refresh',
        'user_email': 'test@test.com',
        'user_name': 'Test User',
      });
      
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
        ],
      );
      addTearDown(container.dispose);

      int retries = 0;
      while (container.read(authProvider).isLoading && retries < 20) {
        await Future.delayed(const Duration(milliseconds: 50));
        retries++;
      }

      final state = container.read(authProvider);
      expect(state.isLoading, isFalse);
      expect(state.isAuthenticated, isTrue);
      expect(state.token, equals(validJwt));
    });

    test('updateProfile met à jour le nom dans le state et storage', () async {
      FlutterSecureStorage.setMockInitialValues({
        'auth_token': validJwt,
        'refresh_token': 'fake_refresh',
        'user_email': 'test@test.com',
        'user_name': 'Test User',
      });

      when(() => mockAuthService.updateProfile(
            token: any(named: 'token'),
            name: any(named: 'name'),
          )).thenAnswer((_) async => {});
      
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
        ],
      );
      addTearDown(container.dispose);

      int retries = 0;
      while (container.read(authProvider).isLoading && retries < 20) {
        await Future.delayed(const Duration(milliseconds: 50));
        retries++;
      }

      expect(container.read(authProvider).userName, equals('Test User'));

      await container.read(authProvider.notifier).updateProfile('Nouveau Nom');

      expect(container.read(authProvider).userName, equals('Nouveau Nom'));
    });
  });
}
