# 🚀 COMMANDES UTILES - AUTHENTIFICATION KASED

## 📦 Installation et configuration

### 1. Installer les dépendances
```bash
cd cotis_app
flutter pub get
```

### 2. Générer les fichiers Riverpod
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Nettoyer et régénérer (si erreurs)
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 🏃 Lancer l'application

### Mode debug
```bash
flutter run
```

### Mode release
```bash
flutter run --release
```

### Sur un appareil spécifique
```bash
# Lister les appareils
flutter devices

# Lancer sur un appareil spécifique
flutter run -d <device-id>
```

---

## 🔨 Build

### Build APK (Android)
```bash
flutter build apk --release
```

### Build APK split par ABI (plus petit)
```bash
flutter build apk --split-per-abi --release
```

### Build App Bundle (pour Google Play)
```bash
flutter build appbundle --release
```

---

## 🧪 Tests

### Tester l'authentification
```bash
# 1. Lancer l'app
flutter run

# 2. Vérifier que l'app démarre sur /login
# 3. Tester le signup
# 4. Tester le login
# 5. Tester la déconnexion
# 6. Tester la protection des routes
```

### Tester sur émulateur Android
```bash
# Démarrer l'émulateur
emulator -avd <nom-emulateur>

# Lancer l'app
flutter run
```

---

## 🔍 Debugging

### Voir les logs
```bash
flutter logs
```

### Voir les logs en temps réel
```bash
flutter run --verbose
```

### Inspecter l'app avec DevTools
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

---

## 🗄️ Base de données locale (Isar)

### Voir les données Isar
```bash
# Installer Isar Inspector
flutter pub global activate isar_inspector

# Lancer l'inspector
flutter pub global run isar_inspector
```

---

## 🔐 Vérifier la configuration Google

### Vérifier google-services.json
```bash
cat android/app/google-services.json
```

### Vérifier le Client ID
```bash
grep -r "clientId" lib/services/auth_service.dart
```

---

## 📝 Générer la documentation

### Générer la doc du code
```bash
dart doc .
```

---

## 🧹 Nettoyage

### Nettoyer le projet
```bash
flutter clean
```

### Supprimer les fichiers générés
```bash
find . -name "*.g.dart" -delete
find . -name "*.freezed.dart" -delete
```

### Nettoyer et réinstaller
```bash
flutter clean
rm -rf pubspec.lock
rm -rf .dart_tool
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 🔄 Mise à jour des dépendances

### Mettre à jour toutes les dépendances
```bash
flutter pub upgrade
```

### Mettre à jour une dépendance spécifique
```bash
flutter pub upgrade <package-name>
```

### Vérifier les dépendances obsolètes
```bash
flutter pub outdated
```

---

## 📊 Analyse du code

### Analyser le code
```bash
flutter analyze
```

### Formater le code
```bash
dart format .
```

### Vérifier les imports inutilisés
```bash
dart analyze --fatal-infos
```

---

## 🐛 Résolution de problèmes

### Erreur "Waiting for another flutter command to release the startup lock"
```bash
rm -rf ~/.flutter-devtools/.flutter-devtools-lock
```

### Erreur de build_runner
```bash
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Erreur de Google Sign-In
```bash
# Vérifier que google-services.json est présent
ls -la android/app/google-services.json

# Vérifier que le Client ID est correct
grep -A 5 "oauth_client" android/app/google-services.json
```

### Erreur de token JWT
```bash
# Supprimer les données de l'app
flutter run --clear-cache

# Ou désinstaller et réinstaller l'app
adb uninstall com.eglise.cotis_app
flutter run
```

---

## 📱 Commandes Android spécifiques

### Installer l'APK sur un appareil
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Désinstaller l'app
```bash
adb uninstall com.eglise.cotis_app
```

### Voir les logs Android
```bash
adb logcat | grep flutter
```

### Effacer les données de l'app
```bash
adb shell pm clear com.eglise.cotis_app
```

---

## 🔑 Gestion des clés et secrets

### Voir les clés stockées (flutter_secure_storage)
```bash
# Sur Android
adb shell run-as com.eglise.cotis_app ls -la /data/data/com.eglise.cotis_app/shared_prefs/
```

### Supprimer les clés stockées
```bash
# Désinstaller l'app (supprime toutes les données)
adb uninstall com.eglise.cotis_app
```

---

## 📈 Performance

### Profiler l'app
```bash
flutter run --profile
```

### Mesurer la taille de l'APK
```bash
flutter build apk --analyze-size
```

### Voir les dépendances de l'APK
```bash
flutter build apk --analyze-size --target-platform android-arm64
```

---

## 🌐 Backend local (pour tests)

### Démarrer le backend local
```bash
# Si vous avez un backend Node.js
cd backend
npm run dev
```

### Tester l'endpoint d'authentification
```bash
curl -X POST http://localhost:3000/auth/google/login \
  -H "Content-Type: application/json" \
  -d '{"idToken": "test-token"}'
```

---

## 📚 Ressources utiles

- Flutter Docs: https://docs.flutter.dev
- Riverpod Docs: https://riverpod.dev
- Google Sign-In: https://pub.dev/packages/google_sign_in
- GoRouter: https://pub.dev/packages/go_router
- Isar Database: https://isar.dev
- InsForge Docs: https://insforge.app/docs
