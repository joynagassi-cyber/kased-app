/// Configuration InsForge — les secrets sont injectés via --dart-define à la compilation.
///
/// Usage:
///   flutter run --dart-define=INSFORGE_BASE_URL=... --dart-define=INSFORGE_ANON_KEY=...
///
/// En dev sans arguments, les valeurs par défaut ci-dessous sont utilisées.
/// En CI/CD, passer les vraies valeurs.
class InsForgeConfig {
  static const String _defaultBaseUrl = 'https://pu74z8pe.us-east.insforge.app';

  static const String _baseUrlOverride = String.fromEnvironment(
    'INSFORGE_BASE_URL',
  );

  /// URL du backend. Un --dart-define vide (secret CI non renseigné) retombe
  /// sur l'URL de production au lieu de produire des appels vers "/api/...".
  static String get baseUrl =>
      _baseUrlOverride.isEmpty ? _defaultBaseUrl : _baseUrlOverride;

  /// Clé anonyme InsForge : publique par nature (elle est de toute façon
  /// embarquée dans l'APK). La valeur par défaut évite une app inutilisable
  /// quand le secret CI n'est pas injecté.
  static const String _defaultAnonKey =
      'anon_75c09927569e3aab8c78e8bf1a69c194bb41e0f231366e46911ffb14dca8881d';

  static const String _anonKeyOverride = String.fromEnvironment(
    'INSFORGE_ANON_KEY',
  );

  static String get anonKey =>
      _anonKeyOverride.isEmpty ? _defaultAnonKey : _anonKeyOverride;

  /// Client OAuth Web Firebase (public, présent dans google-services.json).
  /// Doit correspondre à EXPECTED_CLIENT_ID du bridge google-auth-bridge.
  static const String _defaultGoogleServerClientId =
      '535496831713-4ol3svlekn919034dp509bbi6i9j0ndo.apps.googleusercontent.com';

  static const String _googleServerClientIdOverride = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  static String get googleServerClientId =>
      _googleServerClientIdOverride.isEmpty
          ? _defaultGoogleServerClientId
          : _googleServerClientIdOverride;

  static const String _googleAuthBridgeUrlOverride = String.fromEnvironment(
    'GOOGLE_AUTH_BRIDGE_URL',
  );

  /// Endpoint du bridge Google. Par défaut l'URL canonique documentée par
  /// InsForge : `{baseUrl}/functions/{slug}`.
  static String get googleAuthBridgeUrl =>
      _googleAuthBridgeUrlOverride.isEmpty
          ? '$functionsBaseUrl/google-auth-bridge'
          : _googleAuthBridgeUrlOverride;

  static const String membersPhotosBucket = 'membres-photos';

  /// Base URL des fonctions serveur InsForge.
  /// Documentation InsForge : invocation via `/functions/{slug}` (sans /api).
  static String get functionsBaseUrl => '$baseUrl/functions';

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
