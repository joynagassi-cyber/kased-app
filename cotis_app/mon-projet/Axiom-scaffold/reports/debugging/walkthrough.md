# Walkthrough : Résolution Crash JVM OOM

[constat] Crash récurrent Gradle.
[cause] `-Xmx8G` sature RAM hôte (8G).
[action] Fix `gradle.properties` (2G).

## Sécurité
- [x] Suppression du `mock_token` dans `AuthService`.
- [!] `android/key.properties` contient des mots de passe en dur. À déplacer dans des variables d'environnement CI/CD.
- [ ] Chiffrement Isar (natif non supporté dans Isar v3 communautaire).
- [x] Liaison Google Auth -> InsForge via Interceptor Dio (JWT dynamique).
