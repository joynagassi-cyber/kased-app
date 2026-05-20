class InsForgeConfig {
  // ─── PRODUCTION : passer via --dart-define au build
  // flutter build apk --release
  //   --dart-define=INSFORGE_URL=https://pu74z8pe.us-east.insforge.app
  //   --dart-define=INSFORGE_KEY=<votre_cle>
  //
  // ─── DÉVELOPPEMENT LOCAL : créer un .env ou utiliser --dart-define
  //     Aucune valeur de fallback n'est fournie pour INSFORGE_KEY
  //     afin d'éviter toute exposition accidentelle en debug.

  static const String baseUrl = String.fromEnvironment(
    'INSFORGE_URL',
    defaultValue: 'https://pu74z8pe.us-east.insforge.app',
  );

  /// La clé anon DOIT être passée via --dart-define=INSFORGE_KEY
  /// Aucun fallback par défaut — le build échouera si omise.
  static String get anonKey {
    const key = String.fromEnvironment('INSFORGE_KEY');
    assert(key.isNotEmpty, 'INFORGE_KEY manquante. '
        'Utilisez --dart-define=INSFORGE_KEY=... au build');
    return key;
  }

  static const String membersPhotosBucket = 'membres-photos';

  /// Génère les headers avec le token fourni (ou l'anonKey par défaut)
  static Map<String, String> buildHeaders(String? token) {
    final activeKey = token ?? anonKey;
    return {
      'Authorization': 'Bearer $activeKey',
      'apikey': activeKey,
      'Content-Type': 'application/json',
      'Prefer': 'return=representation',
    };
  }
}
