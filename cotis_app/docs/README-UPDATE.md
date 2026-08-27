# 🚀 Quick Start — Système de Mise à Jour

> **Pour l'agent Claude Code** — Ce fichier donne un accès rapide aux infos essentielles.

---

## 🎯 En 30 Secondes

### Déployer une nouvelle version

```bash
# 1. Modifier la version
sed -i 's/^version: .*/version: 1.2.0+1/' pubspec.yaml

# 2. Builder l'APK
cd cotis_app
flutter build apk --release --target-platform android-arm64 --split-per-abi

# 3. Créer la release GitHub
gh release create v1.2.0+1 \
  --title "Kased v1.2.0+1" \
  --notes "## Quoi de neuf\n\n- Feature 1\n- Bug fix" \
  build/app/outputs/apk/release/app-arm64-v8a-release.apk \
  --name "kased-v1.2.0+1.apk"

# 4. Vérifier
gh release view v1.2.0+1
```

---

## 📚 Documentation Complète

| Besoin | Lire |
|--------|------|
| **Guide complet** | `docs/UPDATE_GUIDE.md` |
| **Architecture technique** | `docs/UPDATE_SYSTEM.md` |
| **Liste des changements** | `docs/CHANGES.md` |

---

## 🔑 Infos Clés

### GitHub Repository
- **Owner** : `joynagassi-cyber`
- **Repo** : `kased-app`
- **API** : `https://api.github.com/repos/joynagassi-cyber/kased-app/releases/latest`

### Format des Versions
```
Tag GitHub : vMAJOR.MINOR.PATCH+BUILDCODE
Exemple    : v1.1.9+3
```

### Commandes Utiles
```bash
# Analyser
flutter analyze lib/core/updates/ lib/providers/update_provider.dart

# Tester
flutter test

# Générer code
dart run build_runner build --delete-conflicting-outputs

# Lister les releases
gh release list --limit 5
```

---

## ✅ Checklist Rapide

- [ ] Version modifiée dans `pubspec.yaml` (format: `X.Y.Z+W`)
- [ ] `flutter analyze` passe
- [ ] `flutter build apk` réussi
- [ ] Release GitHub créée avec tag `vX.Y.Z+W`
- [ ] Asset APK présent dans la release
- [ ] Test sur appareil effectué

---

## 📝 Exemple de Release

```bash
gh release create v1.2.0+1 \
  --title "Kased v1.2.0+1" \
  --notes "## Quoi de neuf dans v1.2.0+1

### Nouvelles fonctionnalités
- Barre de filtrage avancée pour les membres
- Tri par nom et date d'adhésion
- Filtrage par statut actif/inactif

### Corrections
- Navigation corrigée après création d'un membre
" \
  build/app/outputs/apk/release/app-arm64-v8a-release.apk \
  --name "kased-v1.2.0+1.apk"
```

---

**Mis à jour** : 2026-08-27
**Système** : GitHub Releases (direct)
