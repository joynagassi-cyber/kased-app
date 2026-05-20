import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../services/auth_service.dart';

part 'auth_provider.g.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final bool isEmailLoading;
  final bool isGoogleLoading;
  final String? userEmail;
  final String? userName;
  final String? token;
  final String? refreshToken;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = true,
    this.isEmailLoading = false,
    this.isGoogleLoading = false,
    this.userEmail,
    this.userName,
    this.token,
    this.refreshToken,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    bool? isEmailLoading,
    bool? isGoogleLoading,
    String? userEmail,
    String? userName,
    String? token,
    String? refreshToken,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      isEmailLoading: isEmailLoading ?? this.isEmailLoading,
      isGoogleLoading: isGoogleLoading ?? this.isGoogleLoading,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }
}

@Riverpod(keepAlive: true)
FlutterSecureStorage secureStorage(SecureStorageRef ref) {
  return const FlutterSecureStorage();
}

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  late FlutterSecureStorage _storage;
  late AuthService _authService;

  @override
  AuthState build() {
    _storage = ref.watch(secureStorageProvider);
    _authService = ref.watch(authServiceProvider);
    _checkPersistedAuth();
    return const AuthState(isLoading: true);
  }

  /// Décode un JWT et retourne true si le token est expiré.
  /// Ne fait aucun appel réseau.
  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      // Padding base64url → base64
      String payload = parts[1];
      final remainder = payload.length % 4;
      if (remainder != 0) payload += '=' * (4 - remainder);

      final decoded = utf8.decode(base64Url.decode(payload));
      final claims = jsonDecode(decoded) as Map<String, dynamic>;
      final exp = claims['exp'] as int?;
      if (exp == null) return false; // Pas d'expiry = token permanent

      final expiryDate =
          DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
      return DateTime.now().toUtc().isAfter(expiryDate);
    } catch (e) {
      debugPrint('[AUTH] Erreur décodage JWT : $e');
      return false; // En cas d'erreur, ne pas déconnecter
    }
  }

  /// Vérifie si l'appareil est en ligne.
  Future<bool> _isOnline() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return !results.contains(ConnectivityResult.none);
    } catch (_) {
      return true; // On suppose qu'on est en ligne si on ne peut pas vérifier
    }
  }

  Future<void> _checkPersistedAuth() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final refreshTokenValue = await _storage.read(key: 'refresh_token');
      final email = await _storage.read(key: 'user_email');
      final name = await _storage.read(key: 'user_name');

      if (token != null && token.isNotEmpty) {
        final expired = _isTokenExpired(token);

        if (!expired) {
          // Token valide localement → authentifié immédiatement (même offline)
          state = AuthState(
            isAuthenticated: true,
            isLoading: false,
            token: token,
            refreshToken: refreshTokenValue,
            userEmail: email,
            userName: name,
          );
          // Tenter un refresh en arrière-plan seulement si en ligne
          if (refreshTokenValue != null && refreshTokenValue.isNotEmpty) {
            final online = await _isOnline();
            if (online) {
              _silentRefresh(refreshTokenValue, email, name);
            }
          }
          return;
        }

        // Token expiré → tenter refresh si en ligne
        if (refreshTokenValue != null && refreshTokenValue.isNotEmpty) {
          final online = await _isOnline();
          if (online) {
            final success = await refreshSession(refreshTokenValue);
            if (success) return;
          } else {
            // Offline + token expiré : garder connecté avec l'ancien token
            // L'utilisateur pourra utiliser les données cachées
            debugPrint('[AUTH] Offline : token expiré mais on garde la session locale');
            state = AuthState(
              isAuthenticated: true,
              isLoading: false,
              token: token,
              refreshToken: refreshTokenValue,
              userEmail: email,
              userName: name,
            );
            return;
          }
        }
      } else if (refreshTokenValue != null && refreshTokenValue.isNotEmpty) {
        // Pas de token mais refresh token disponible → tenter refresh si en ligne
        final online = await _isOnline();
        if (online) {
          await refreshSession(refreshTokenValue);
          return;
        }
      }

      // Aucun token valide
      state = const AuthState(
        isAuthenticated: false,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('[AUTH] Erreur lecture secure storage : $e');
      state = const AuthState(
        isAuthenticated: false,
        isLoading: false,
      );
    }
  }

  /// Refresh silencieux en arrière-plan (ne déconnecte pas si ça échoue).
  Future<void> _silentRefresh(
      String rToken, String? email, String? name) async {
    try {
      final result = await _authService.refreshToken(rToken);
      if (result != null) {
        await setAuthenticated(
          token: result['token'] ?? '',
          refreshToken: result['refreshToken'],
          email: email ?? state.userEmail ?? '',
          name: name ?? state.userName ?? 'Utilisateur',
        );
      }
    } catch (e) {
      debugPrint('[AUTH] Refresh silencieux échoué (ignoré) : $e');
    }
  }

  Future<void> setAuthenticated({
    required String token,
    String? refreshToken,
    required String email,
    required String name,
  }) async {
    await _storage.write(key: 'auth_token', value: token);
    if (refreshToken != null) {
      await _storage.write(key: 'refresh_token', value: refreshToken);
    }
    await _storage.write(key: 'user_email', value: email);
    await _storage.write(key: 'user_name', value: name);

    state = AuthState(
      isAuthenticated: true,
      isLoading: false,
      isEmailLoading: false,
      isGoogleLoading: false,
      token: token,
      refreshToken: refreshToken ?? state.refreshToken,
      userEmail: email,
      userName: name,
    );
  }

  Future<bool> refreshSession(String rToken) async {
    try {
      final result = await _authService.refreshToken(rToken);
      if (result != null) {
        await setAuthenticated(
          token: result['token'] ?? '',
          refreshToken: result['refreshToken'],
          email: state.userEmail ?? '',
          name: state.userName ?? 'Utilisateur',
        );
        return true;
      }
      await logout();
      return false;
    } catch (e) {
      debugPrint('[AUTH] Erreur refresh session : $e');
      final errorStr = e.toString();
      if (errorStr.contains('DioExceptionType.connectionTimeout') || 
          errorStr.contains('DioExceptionType.receiveTimeout') || 
          errorStr.contains('DioExceptionType.sendTimeout') || 
          errorStr.contains('DioExceptionType.connectionError') ||
          errorStr.contains('SocketException') ||
          errorStr.contains('Failed host lookup')) {
        debugPrint('[AUTH] Erreur réseau lors du refresh, maintien de la session locale.');
        return false;
      }
      await logout();
      return false;
    }
  }

  Future<void> login(String email, String password) async {
    try {
      state = state.copyWith(isEmailLoading: true);
      final result = await _authService.signInWithEmail(email, password);

      if (result != null) {
        final token = result['token']?.toString() ?? '';
        if (token.isEmpty) {
          throw Exception(
              'Veuillez vérifier votre email pour valider votre compte.');
        }
        await setAuthenticated(
          token: token,
          refreshToken: result['refreshToken'],
          email: result['email'] ?? '',
          name: result['name'] ?? 'Utilisateur',
        );
      } else {
        throw Exception('Email ou mot de passe incorrect.');
      }
    } catch (e) {
      debugPrint('[AUTH] Erreur login Email : $e');
      state = state.copyWith(isEmailLoading: false);
      rethrow;
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      state = state.copyWith(isEmailLoading: true);
      final result = await _authService.signUp(
        email: email,
        password: password,
        name: name,
      );

      if (result != null) {
        final token = result['token']?.toString() ?? '';
        if (token.isEmpty) {
          throw Exception(
              'Inscription réussie ! Veuillez vérifier votre email pour valider votre compte.');
        }
        await setAuthenticated(
          token: token,
          refreshToken: result['refreshToken'],
          email: result['email'] ?? '',
          name: result['name'] ?? name,
        );
      } else {
        throw Exception(
            'Erreur inattendue lors de l\'inscription. Veuillez réessayer.');
      }
    } catch (e) {
      debugPrint('[AUTH] Erreur register Email : $e');
      state = state.copyWith(isEmailLoading: false);
      rethrow;
    }
  }

  Future<void> updateProfile(String name) async {
    try {
      if (state.token == null) throw Exception('Non authentifié');
      // Tenter la mise à jour réseau mais ignorer les erreurs (endpoint peut être absent)
      try {
        await _authService.updateProfile(token: state.token!, name: name);
      } catch (e) {
        debugPrint('[AUTH] updateProfile réseau échoué, sauvegarde locale uniquement: $e');
        // On continue quand même pour sauvegarder localement
      }
      // Toujours sauvegarder le nom localement dans le secure storage
      await setAuthenticated(
        token: state.token!,
        refreshToken: state.refreshToken,
        email: state.userEmail ?? '',
        name: name,
      );
    } catch (e) {
      debugPrint('[AUTH] Erreur updateProfile : $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      state = state.copyWith(isGoogleLoading: true);
      final result = await _authService.signInWithGoogle();

      if (result != null) {
        final token = result['token']?.toString() ?? '';
        if (token.isEmpty) {
          throw Exception('Erreur de token via Google Sign-In.');
        }
        await setAuthenticated(
          token: token,
          refreshToken: result['refreshToken'],
          email: result['email'] ?? '',
          name: result['name'] ?? 'Utilisateur',
        );
      }

      state = state.copyWith(isGoogleLoading: false);
      return result;
    } catch (e) {
      debugPrint('[AUTH PROVIDER] Erreur Google Sign-In : $e');
      state = state.copyWith(isGoogleLoading: false);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    await _authService.signOut();
    state = const AuthState(
      isAuthenticated: false,
      isLoading: false,
    );
  }
}
