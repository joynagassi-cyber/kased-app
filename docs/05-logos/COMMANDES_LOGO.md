# 🚀 Commandes pour Tester le Logo Kased-app

## Commandes Essentielles

### 1. Nettoyer et Relancer l'Application

```bash
cd cotis_app
flutter clean
flutter pub get
flutter run
```

### 2. Analyser le Code

```bash
cd cotis_app
flutter analyze
```

**Résultat attendu :** `No issues found!`

### 3. Build APK Release

```bash
cd cotis_app
flutter build apk --release
```

**APK généré dans :**
```
cotis_app/build/app/outputs/flutter-apk/app-release.apk
```

---

## Commandes Avancées

### Vérifier les Assets

```bash
cd cotis_app
flutter pub get
flutter build apk --debug
```

### Vérifier les Icônes Générées

**Windows PowerShell :**
```powershell
cd cotis_app
Get-ChildItem -Recurse -Filter "ic_launcher.png" | Select-Object FullName
```

**Bash :**
```bash
cd cotis_app
find android/app/src/main/res -name "ic_launcher.png"
```

### Logs en Temps Réel

```bash
cd cotis_app
flutter run --verbose
```

---

## Commandes de Débogage

### Vérifier l'Environnement Flutter

```bash
flutter doctor -v
```

### Vérifier les Dépendances

```bash
cd cotis_app
flutter pub outdated
```

### Nettoyer Complètement

```bash
cd cotis_app
flutter clean
rm -rf build/
rm -rf .dart_tool/
flutter pub get
```

---

## Commandes de Test

### Lancer les Tests Unitaires

```bash
cd cotis_app
flutter test
```

### Lancer les Tests d'Intégration

```bash
cd cotis_app
flutter test integration_test/
```

---

## Commandes de Build

### Build APK Debug

```bash
cd cotis_app
flutter build apk --debug
```

### Build APK Release

```bash
cd cotis_app
flutter build apk --release
```

### Build App Bundle (Pour Google Play)

```bash
cd cotis_app
flutter build appbundle --release
```

---

## Commandes de Profiling

### Lancer en Mode Profile

```bash
cd cotis_app
flutter run --profile
```

### Analyser la Performance

```bash
cd cotis_app
flutter run --profile --trace-startup
```

---

## Commandes Utiles

### Prendre une Capture d'Écran

```bash
cd cotis_app
flutter run
# Dans un autre terminal :
flutter screenshot --out=screenshot.png
```

### Vérifier la Taille de l'APK

**Windows PowerShell :**
```powershell
cd cotis_app
Get-Item build/app/outputs/flutter-apk/app-release.apk | Select-Object Name, Length
```

**Bash :**
```bash
cd cotis_app
ls -lh build/app/outputs/flutter-apk/app-release.apk
```

### Installer l'APK sur un Appareil

```bash
cd cotis_app
flutter install
```

---

## Résumé : Commandes Essentielles

```bash
# 1. Nettoyer
cd cotis_app
flutter clean

# 2. Récupérer les dépendances
flutter pub get

# 3. Analyser le code
flutter analyze

# 4. Lancer l'application
flutter run

# 5. Build APK release
flutter build apk --release
```

---

## Checklist de Vérification

Après avoir exécuté les commandes, vérifiez :

- [ ] `flutter analyze` : Aucune erreur
- [ ] `flutter run` : L'application démarre
- [ ] Logo Kased visible sur la page Signup
- [ ] Logo Kased visible sur la page Login
- [ ] Icône Kased visible sur l'écran d'accueil de l'appareil

---

## Problèmes Courants

### Problème : "Unable to load asset"

**Solution :**
```bash
cd cotis_app
flutter clean
flutter pub get
flutter run
```

### Problème : "Build failed"

**Solution :**
```bash
cd cotis_app
flutter clean
rm -rf build/
flutter pub get
flutter run
```

### Problème : "Icône ne change pas"

**Solution :**
1. Désinstaller l'application de l'appareil
2. Réinstaller avec `flutter run`

---

## Commandes de Génération d'Icônes

### Régénérer les Icônes

```bash
cd cotis_app
dart run flutter_launcher_icons
```

### Vérifier la Configuration

```bash
cd cotis_app
cat flutter_launcher_icons.yaml
```

---

*Document créé le 3 mai 2026*
