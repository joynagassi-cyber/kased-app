# Checklist de Déploiement — Mise à jour Kased App

> **À cocher étape par étape**

## Avant le Build

- [ ] Version modifiée dans `pubspec.yaml` (ex: `1.2.0+1`)
- [ ] `flutter pub get` exécuté
- [ ] `flutter analyze` passe sans erreur
- [ ] Changements de cette version listés dans `docs/manifest.json`

## Build

- [ ] `flutter build apk --release --target-platform android-arm64 --split-per-abi`
- [ ] APK généré dans `build/app/outputs/apk/release/`
- [ ] SHA-256 calculé (optionnel mais recommandé)

## Manifeste

- [ ] `version_name` mis à jour (ex: "1.2.0")
- [ ] `version_code` calculé et augmenté
- [ ] `download_url` pointant vers le bon fichier APK
- [ ] `changelog` rempli
- [ ] `sha256` rempli si calculé
- [ ] `published_at` à la date actuelle

## Upload InsForge

- [ ] Bucket `app-updates` vérifié (`npx @insforge/cli storage buckets`)
- [ ] APK uploadé : `npx @insforge/cli storage upload docs/X.Y.Z.apk --bucket app-updates`
- [ ] Manifest uploadé : `npx @insforge/cli storage upload docs/manifest.json --bucket app-updates`
- [ ] Liste des objets vérifiée : `npx @insforge/cli storage list-objects app-updates`
- [ ] Manifest testé via curl

## Test

- [ ] APK installé sur appareil test : `adb install build/app/outputs/apk/release/app-arm64-v8a-release.apk`
- [ ] Badge "NEW" visible dans Profil
- [ ] Dialogue de mise à jour apparaît
- [ ] Téléchargement fonctionne
- [ ] Installation fonctionne

## Après Déploiement

- [ ] Sauvegarder l'ancien APK (archive)
- [ ] Notifier l'équipe de la nouvelle version
- [ ] Mettre à jour la documentation si modifications du système

---

**Version** : 1.0.0  
**Dernière mise à jour** : 2026-08-26  
**Auteur** : Claude Code (agent)
