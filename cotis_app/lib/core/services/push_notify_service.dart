import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../insforge/insforge_config.dart';

/// Envoie les notifications push multi-utilisateurs via la fonction serveur
/// InsForge `push-notify` (qui relaie vers l'API REST OneSignal).
///
/// RÈGLE : appel **fire-and-forget** — un échec d'envoi ne doit JAMAIS
/// bloquer ni casser une action de l'utilisateur. La fonction serveur
/// s'occupe d'exclure l'acteur et de cibler les autres utilisateurs
/// (external ID OneSignal = email).
///
/// Événements reconnus côté serveur :
///   membre_ajoute, membre_modifie, membre_supprime,
///   cotisation_payee, cotisation_modifiee, cotisation_absente,
///   cotisations_bulk, culte_cree, culte_modifie
class PushNotifyService {
  PushNotifyService._();

  static const String _endpoint = '/push-notify';

  /// Envoie la notification. Ne lance jamais d'exception.
  ///
  /// [event] : type d'événement (voir liste ci-dessus).
  /// [entityLabel] : libellé affiché (ex. « Jean Dupont »).
  /// [actorEmail] / [actorName] : identité de l'utilisateur qui a agi.
  /// [token] : token de session InsForge (permet au serveur de lister les
  ///           autres utilisateurs de la table profiles).
  static Future<void> notifier({
    required String event,
    required String entityLabel,
    String? actorEmail,
    String? actorName,
    String? token,
    String? extra,
  }) async {
    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: InsForgeConfig.functionsBaseUrl,
          connectTimeout: const Duration(seconds: 8),
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );

      await dio.post(
        _endpoint,
        data: {
          'event': event,
          if (actorEmail != null && actorEmail.isNotEmpty)
            'actorEmail': actorEmail,
          if (actorName != null && actorName.isNotEmpty) 'actorName': actorName,
          'entityLabel': entityLabel,
          if (extra != null && extra.isNotEmpty) 'extra': extra,
        },
        options: Options(
          headers: {
            'apikey': InsForgeConfig.effectiveAnonKey,
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
    } catch (e) {
      // Non bloquant : on loggue et on continue.
      debugPrint('[PushNotify] Envoi push ignoré (non bloquant): $e');
    }
  }
}
