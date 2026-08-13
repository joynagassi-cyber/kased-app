/// Configuration InsForge — les secrets sont injectés via --dart-define à la compilation.
///
/// Usage:
///   flutter run --dart-define=INSFORGE_BASE_URL=... --dart-define=INSFORGE_ANON_KEY=...
///
/// En dev sans arguments, les valeurs par défaut ci-dessous sont utilisées.
/// En CI/CD, passer les vraies valeurs.
class InsForgeConfig {
  static const String baseUrl = String.fromEnvironment(
    'INSFORGE_BASE_URL',
    defaultValue: 'https://pu74z8pe.us-east.insforge.app',
  );

  static const String anonKey = String.fromEnvironment(
    'INSFORGE_ANON_KEY',
    defaultValue: '',
  );

  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  static const String googleAuthBridgeUrl = String.fromEnvironment(
    'GOOGLE_AUTH_BRIDGE_URL',
    defaultValue: 'https://pu74z8pe.function2.insforge.app/google-auth-bridge',
  );

  static const String membersPhotosBucket = 'membres-photos';

  /// Base URL des fonctions serveur InsForge (déploiement des bridges).
  static const String functionsBaseUrl =
      'https://pu74z8pe.functions.insforge.app';

  // ── Accès aux clés (retourne la valeur brute, jamais de throw) ──────────────
  // Les appels API vérifient eux-mêmes la présence de la clé et affichent un
  // message d'erreur clair à l'utilisateur si elle manque (au lieu d'un
  // StateError cryptique au runtime).
  static String get effectiveAnonKey => anonKey;

  static String get effectiveGoogleServerClientId => googleServerClientId;

  static Map<String, String> buildHeaders(String? token) {
    final activeKey = token ?? effectiveAnonKey;
    return {
      'Authorization': 'Bearer $activeKey',
      'apikey': activeKey,
      'Content-Type': 'application/json',
      'Prefer': 'return=representation',
    };
  }
}
