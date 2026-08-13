import 'package:onesignal_flutter/onesignal_flutter.dart';

/// Wrapper centralisé du SDK OneSignal (onesignal_flutter 5.5.2).
///
/// RÈGLE : aucun appel direct au SDK OneSignal ne doit être fait ailleurs
/// dans l'application — tout passe par ce singleton :
/// - Initialisation (App ID public du projet OneSignal)
/// - Identité utilisateur (login/logout → ciblage multi-utilisateurs)
/// - Permission de notification push
/// - Observateur d'abonnement push (vérification d'enregistrement du device)
/// - Email / tags / clics sur notifications
class OneSignalService {
  OneSignalService._internal();

  /// Instance unique du service.
  static final OneSignalService instance = OneSignalService._internal();

  /// App ID public du projet OneSignal « Kased ».
  ///
  /// Ce n'est PAS un secret : c'est un identifiant public de l'application
  /// (comme un Project ID Firebase), destiné à être embarqué dans l'app.
  /// Les secrets OneSignal (ex. REST API Key) ne doivent jamais être
  /// embarqués dans l'application.
  static const String appId = 'cd2949d4-8ab7-4ad0-8c32-e5599e1a9bd3';

  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Initialise le SDK OneSignal. Idempotent.
  /// À appeler une seule fois, dans main(), avant runApp().
  Future<void> initialize() async {
    if (_initialized) return;

    // Logs verbeux uniquement en debug (supprimés en release).
    if (!const bool.fromEnvironment('dart.vm.product')) {
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    }

    await OneSignal.initialize(appId);
    _initialized = true;
  }

  /// Relie cet appareil à l'utilisateur connecté (email = external ID).
  ///
  /// C'est ce qui permet d'envoyer des notifications ciblées à un utilisateur
  /// précis (multi-utilisateurs) depuis le dashboard OneSignal ou l'API REST.
  /// Le tag `user_email` sert de ciblage de repli côté serveur quand la liste
  /// des profils est indisponible (fonction push-notify).
  Future<void> login(String externalId) async {
    if (!_initialized) return;
    await OneSignal.login(externalId);
    if (externalId.contains('@')) {
      await OneSignal.User.addTagWithKey(
        'user_email',
        externalId.trim().toLowerCase(),
      );
    }
  }

  /// Dissocie l'appareil de l'utilisateur (déconnexion).
  Future<void> logout() async {
    if (!_initialized) return;
    await OneSignal.logout();
  }

  /// Demande la permission d'afficher des notifications push.
  ///
  /// Ne doit être appelée QUE depuis le bouton du dialogue de vérification
  /// (jamais au lancement de l'app).
  Future<bool> requestPermission() async {
    if (!_initialized) return false;
    return OneSignal.Notifications.requestPermission(true);
  }

  /// ID d'abonnement push actuel.
  ///
  /// Tant que le device n'est pas enregistré auprès des serveurs OneSignal,
  /// la valeur est null ou préfixée par 'local-' (placeholder local).
  String? get pushSubscriptionId {
    if (!_initialized) return null;
    return OneSignal.User.pushSubscription.id;
  }

  /// Attache un observateur aux changements d'abonnement push.
  ///
  /// L'appelant doit conserver une référence forte à l'observateur pour la
  /// durée de vie du widget qui s'en sert (champ State).
  void addPushSubscriptionObserver(OnPushSubscriptionChangeObserver observer) {
    if (!_initialized) return;
    OneSignal.User.pushSubscription.addObserver(observer);
  }

  /// Associe l'email de l'utilisateur en tant que canal de notification.
  Future<void> addEmail(String email) async {
    if (!_initialized) return;
    await OneSignal.User.addEmail(email);
  }

  /// Ajoute une étiquette (tag) pour segmenter / cibler les utilisateurs.
  Future<void> addTag(String key, String value) async {
    if (!_initialized) return;
    await OneSignal.User.addTagWithKey(key, value);
  }

  /// Définit le niveau de log du SDK.
  void setLogLevel(OSLogLevel level) {
    if (!_initialized) return;
    OneSignal.Debug.setLogLevel(level);
  }

  /// Écoute les clics sur les notifications (l'utilisateur a ouvert la notif).
  void addNotificationClickListener(OnNotificationClickListener listener) {
    if (!_initialized) return;
    OneSignal.Notifications.addClickListener(listener);
  }
}
