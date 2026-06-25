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

  static const String membersPhotosBucket = 'membres-photos';

  // ── Valide à l'exécution que la clé est disponible ──────────────────────────
  static String get effectiveAnonKey {
    // En release, la clé doit être passée via --dart-define.
    if (const bool.fromEnvironment('dart.vm.product') && anonKey.isEmpty) {
      throw StateError(
        'INSFORGE_ANON_KEY doit être défini via --dart-define en mode release.',
      );
    }
    // En debug, on tolère l'absence pour le développement local.
    return anonKey;
  }

  static String get effectiveGoogleServerClientId {
    if (const bool.fromEnvironment('dart.vm.product') && googleServerClientId.isEmpty) {
      throw StateError(
        'GOOGLE_SERVER_CLIENT_ID doit être défini via --dart-define en mode release.',
      );
    }
    return googleServerClientId;
  }

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
