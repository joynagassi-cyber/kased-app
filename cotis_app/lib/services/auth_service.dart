import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/insforge/insforge_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_service.g.dart';

@riverpod
AuthService authService(AuthServiceRef ref) {
  return AuthService();
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: InsForgeConfig.baseUrl,
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
    headers: {
      // Clé anon injectée via --dart-define=INSFORGE_ANON_KEY=...
      'Content-Type': 'application/json',
    },
  ));

  // Configuration OAuth2 Google. serverClientId est passé via
  // --dart-define=GOOGLE_SERVER_CLIENT_ID=... — nécessaire pour récupérer un
  // idToken valide côté Android.
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    signInOption: SignInOption.standard,
    forceCodeForRefreshToken: true,
    serverClientId: InsForgeConfig.effectiveGoogleServerClientId.isEmpty
        ? null
        : InsForgeConfig.effectiveGoogleServerClientId,
  );

  // --- EMAIL / PASSWORD AUTH ---

  Future<Map<String, dynamic>?> signInWithEmail(String email, String password) async {
    try {
      // Pour mobile, on précise client_type pour obtenir un refresh_token
      final response = await _dio.post('/api/auth/sessions?client_type=mobile', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        // InsForge retourne souvent access_token (snake_case)
        return {
          'token': data['access_token'] ?? data['accessToken'],
          'refreshToken': data['refresh_token'] ?? data['refreshToken'],
          'email': data['user']['email'],
          'name': data['user']['name'] ?? 'Utilisateur',
          'id': data['user']['id'],
        };
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la connexion Email: $e');
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout || 
            e.type == DioExceptionType.receiveTimeout) {
          throw Exception('Le serveur met trop de temps à répondre. Veuillez vérifier votre connexion ou réessayer plus tard.');
        }
        final responseData = e.response?.data;
        debugPrint('Détails erreur: $responseData');
        if (responseData is Map) {
          final message = responseData['message'] ?? responseData['msg'] ?? responseData['error_description'] ?? responseData['error'];
          if (message != null) {
            throw Exception(message.toString());
          }
        }
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _dio.post('/api/auth/users?client_type=mobile', data: {
        'email': email,
        'password': password,
        'name': name,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        return {
          'token': data['access_token'] ?? data['accessToken'],
          'refreshToken': data['refresh_token'] ?? data['refreshToken'],
          'email': data['user']['email'],
          'name': data['user']['name'] ?? 'Utilisateur',
          'id': data['user']['id'],
        };
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de l\'inscription: $e');
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout || 
            e.type == DioExceptionType.receiveTimeout) {
          throw Exception('Le serveur met trop de temps à répondre (timeout). Votre compte a peut-être été créé avec succès en arrière-plan. Veuillez essayer de vous connecter avec cet email, ou vérifier vos emails si une confirmation est requise.');
        }
        final responseData = e.response?.data;
        debugPrint('Détails erreur: $responseData');
        if (responseData is Map) {
          final message = responseData['message'] ?? responseData['msg'] ?? responseData['error_description'] ?? responseData['error'];
          if (message != null) {
            throw Exception(message.toString());
          }
        }
      }
      rethrow;
    }
  }

  Future<void> updateProfile({
    required String token,
    required String name,
  }) async {
    try {
      final response = await _dio.put(
        '/api/auth/profile',
        data: {'name': name},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Erreur de mise à jour du profil.');
      }
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du profil: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> refreshToken(String token) async {
    try {
      final response = await _dio.post('/api/auth/refresh?client_type=mobile', data: {
        'refreshToken': token,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        return {
          'token': data['access_token'] ?? data['accessToken'],
          'refreshToken': data['refresh_token'] ?? data['refreshToken'],
        };
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors du refresh token: $e');
      return null;
    }
  }

  // --- GOOGLE AUTH ---

  Future<Map<String, dynamic>?> signInWithGoogle({
    bool forceAccountSelection = false,
  }) async {
    try {
      if (forceAccountSelection) {
        debugPrint('[AUTH] Forçage de la sélection de compte...');
        await _googleSignIn.signOut();
      }

      debugPrint('[AUTH] Étape 1 : Ouverture de la popup Google Sign-In...');
      // Timeout étendu à 120s — Android peut prendre du temps à charger la sélection de compte
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn().timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          debugPrint('[AUTH] TIMEOUT étape 1 : La popup Google n\'a pas répondu après 120s');
          throw Exception('GOOGLE_SIGNIN_TIMEOUT');
        },
      );

      if (googleUser == null) {
        debugPrint('[AUTH] ANNULÉ : L\'utilisateur a fermé la popup sans choisir de compte');
        return null;
      }

      debugPrint('[AUTH] Étape 2 : Récupération des credentials pour ${googleUser.email}...');
      // Timeout sur l'étape authentication (souvent lente sur certains appareils Android)
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('[AUTH] TIMEOUT étape 2 : Récupération des credentials après 30s');
          throw Exception('GOOGLE_AUTH_CREDENTIALS_TIMEOUT');
        },
      );
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        debugPrint('[AUTH] ERREUR : ID Token Google est null');
        await _googleSignIn.signOut();
        throw Exception('Impossible de récupérer le token Google. Réessayez.');
      }

      debugPrint('[AUTH] Étape 3 : Validation du token via le bridge InsForge...');

      final response = await _dio.post(
        'https://pu74z8pe.functions.insforge.app/google-auth-bridge',
        data: {'idToken': idToken},
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'apikey': InsForgeConfig.effectiveAnonKey,
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        debugPrint('[AUTH] SUCCÈS : Bridge validé');
        return {
          'token': data['access_token'] ?? data['accessToken'],
          'refreshToken': data['refresh_token'] ?? data['refreshToken'],
          'email': data['user']['email'],
          'name': data['user']['name'] ?? googleUser.displayName ?? 'Utilisateur',
          'id': data['user']['id'],
          'photo': googleUser.photoUrl,
        };
      }

      debugPrint('[AUTH] ERREUR BRIDGE : Status \${response.statusCode}');
      throw Exception('Erreur serveur bridge (\${response.statusCode})');
    } catch (error) {
      debugPrint('[AUTH] CRITICAL ERROR : $error');

      // Identifier et reclassifier les erreurs pour de meilleurs messages UI
      if (error is Exception) {
        final msg = error.toString();
        if (msg.contains('ACCOUNT_EXISTS_WITH_PASSWORD')) {
          await _googleSignIn.signOut();
          throw Exception('ACCOUNT_EXISTS_WITH_PASSWORD');
        }
        if (msg.contains('GOOGLE_SIGNIN_TIMEOUT') || msg.contains('GOOGLE_AUTH_CREDENTIALS_TIMEOUT')) {
          await _googleSignIn.signOut();
          throw Exception('GOOGLE_TIMEOUT');
        }
      }

      if (error is DioException) {
        debugPrint('[AUTH] DIO DATA : \${error.response?.data}');
        debugPrint('[AUTH] DIO STATUS : \${error.response?.statusCode}');

        final responseData = error.response?.data;
        if (responseData is Map && responseData['error'] == 'ACCOUNT_EXISTS_WITH_PASSWORD') {
          await _googleSignIn.signOut();
          throw Exception('ACCOUNT_EXISTS_WITH_PASSWORD');
        }

        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout) {
          await _googleSignIn.signOut();
          throw Exception('BRIDGE_TIMEOUT');
        }
      }

      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      debugPrint('Déconnexion réussie');
    } catch (error) {
      debugPrint('Erreur lors de la déconnexion: $error');
    }
  }

  Future<bool> isSignedIn() async {
    try {
      return await _googleSignIn.isSignedIn();
    } catch (error) {
      debugPrint('Erreur lors de la vérification de connexion: $error');
      return false;
    }
  }

  Future<GoogleSignInAccount?> getCurrentUser() async {
    try {
      return _googleSignIn.currentUser;
    } catch (error) {
      debugPrint('Erreur lors de la récupération de l\'utilisateur: $error');
      return null;
    }
  }

}