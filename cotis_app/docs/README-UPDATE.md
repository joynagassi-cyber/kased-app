# 🚀 Quick Start — Système de Mise à Jour

> **Pour l'agent Claude Code** — Ce fichier donne un accès rapide aux infos essentielles.

---

## 🎯 En 30 Secondes

### Déployer une nouvelle version

```bash
# 1. Builder
cd cotis_app
flutter build apk --release --target-platform android-arm64 --split-per-abi

# 2. Upload APK + manifest
npx @insforge/cli storage upload docs/1.2.0.apk --bucket app-updates
npx @insforge/cli storage upload docs/manifest.json --bucket app-updates

# 3. Vérifier
npx @insforge/cli storage list-objects app-updates
```

---

## 📚 Documentation Complète

| Besoin | Lire |
|--------|------|
| **Guide complet** | `docs/SYSTEM_REFERENCE.md` |
| **Workflow étape par étape** | `docs/UPDATE_GUIDE.md` |
| **Checklist avant déploiement** | `docs/DEPLOYMENT_CHECKLIST.md` |
| **Architecture technique** | `docs/adr/ADR-001-update-system.md` |
| **Liste des changements** | `docs/CHANGES.md` |

---

## 🔑 Infos Clés

### InsForge
- **Bucket** : `app-updates`
- **URL** : `https://pu74z8pe.us-east.insforge.app`
- **Manifeste** : `docs/manifest.json`

### Commandes Utiles
```bash
# Analyser
flutter analyze lib/core/updates/ lib/providers/update_provider.dart

# Tester
flutter test

# Générer code
dart run build_runner build --delete-conflicting-outputs
```

### Version Code
```
version_code = MAJOR * 1000000 + MINOR * 1000 + PATCH * 1 + BUILD
```

---

## ✅ Checklist Rapide

- [ ] Version modifiée dans `pubspec.yaml`
- [ ] `version_code` augmenté dans `docs/manifest.json`
- [ ] `flutter analyze` passe
- [ ] APK uploadé sur InsForge
- [ ] Manifest uploadé sur InsForge
- [ ] Test sur appareil effectué

---

**Mis à jour** : 2026-08-26
