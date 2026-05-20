# 🚀 Guide de Build Release - Kased App

## ✅ Configuration Terminée

Votre projet est maintenant configuré pour compiler des APK signés pour le Play Store !

---

## 📋 Informations du Keystore

| Propriété            | Valeur                                        |
| -------------------- | --------------------------------------------- |
| **Fichier keystore** | `cotis_app/android/app/kased-release-key.jks` |
| **Alias**            | `kased-key`                                   |
| **Mot de passe**     | `Kased2026Secure!`                            |
| **Validité**         | 10 000 jours (~27 ans)                        |
| **Organisation**     | Kased                                         |
| **Ville**            | Kinshasa, CD                                  |

⚠️ **IMPORTANT** : Sauvegardez le fichier `.jks` et le mot de passe dans un endroit sûr !

---

## 🎯 Commandes de Build

### 1. APK Release Signé (Tous les CPU)

```bash
cd cotis_app
flutter build apk --release
```

**Taille** : ~50-60 MB  
**Emplacement** : `build/app/outputs/flutter-apk/app-release.apk`

### 2. APK Release Signé (ARM64 uniquement - Recommandé)

```bash
cd cotis_app
flutter build apk --release --target-platform android-arm64 --split-per-abi
```

**Taille** : ~20-25 MB  
**Emplacement** : `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

### 3. App Bundle (Format Google Play Store - Recommandé)

```bash
cd cotis_app
flutter build appbundle --release
```

**Taille** : ~15-20 MB  
**Emplacement** : `build/app/outputs/bundle/release/app-release.aab`

---

## 📦 Quel Format Choisir ?

| Format                | Utilisation          | Avantages                                             |
| --------------------- | -------------------- | ----------------------------------------------------- |
| **App Bundle (.aab)** | Google Play Store    | ✅ Plus petit<br>✅ Optimisé par Google<br>✅ Recommandé |
| **APK ARM64**         | Distribution directe | ✅ Compatible 95% des appareils<br>✅ Taille réduite    |
| **APK Universal**     | Distribution directe | ✅ Compatible 100% des appareils<br>❌ Plus gros        |

---

## 🔍 Vérifier la Signature

```bash
# Vérifier que l'APK est signé
keytool -printcert -jarfile cotis_app/build/app/outputs/flutter-apk/app-release.apk

# Vérifier les informations du keystore
keytool -list -v -keystore cotis_app/android/app/kased-release-key.jks -alias kased-key -storepass Kased2026Secure!
```

---

## 📱 Tester l'APK Release

```bash
# Installer l'APK sur un appareil connecté
flutter install --release

# Ou installer manuellement
adb install cotis_app/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

---

## 🎨 Informations de l'Application

| Propriété        | Valeur                      |
| ---------------- | --------------------------- |
| **Package Name** | `com.kasedapp`              |
| **App Name**     | Kased App                   |
| **Version**      | Définie dans `pubspec.yaml` |
| **Min SDK**      | Android 5.0 (API 21)        |
| **Target SDK**   | Dernière version            |

---

## 📊 Checklist Avant Publication

### Avant de compiler :
- [ ] Version mise à jour dans `pubspec.yaml`
- [ ] Changelog mis à jour
- [ ] Tests passés (`flutter test`)
- [ ] Analyse de code propre (`flutter analyze`)
- [ ] Logo et icônes corrects

### Après compilation :
- [ ] APK/AAB signé correctement
- [ ] Taille de l'APK acceptable (<30 MB pour ARM64)
- [ ] Testé sur un appareil réel
- [ ] Fonctionnalités principales testées
- [ ] Authentification Google fonctionne

---

## 🚀 Publication sur Google Play Store

### 1. Préparer les Assets

- **Icône de l'application** : 512x512 px (PNG)
- **Feature Graphic** : 1024x500 px
- **Screenshots** : Minimum 2 (téléphone et tablette)
- **Description courte** : Maximum 80 caractères
- **Description complète** : Maximum 4000 caractères

### 2. Uploader l'App Bundle

1. Aller sur [Google Play Console](https://play.google.com/console)
2. Créer une nouvelle application
3. Remplir les informations de l'application
4. Uploader le fichier `.aab`
5. Remplir le questionnaire de contenu
6. Soumettre pour révision

---

## 🔒 Sécurité

### ✅ Fichiers à Sauvegarder :
- `kased-release-key.jks` (keystore)
- `key.properties` (configuration)
- Mot de passe du keystore

### ❌ Ne JAMAIS Commiter :
- `*.jks` (keystore)
- `key.properties` (mots de passe)
- `local.properties`

---

## 🆘 Problèmes Courants

### Erreur : "Keystore file not found"

Le fichier `key.properties` pointe vers un mauvais chemin. Vérifiez :
```properties
storeFile=kased-release-key.jks
```

### Erreur : "Wrong password"

Le mot de passe dans `key.properties` est incorrect. Vérifiez :
```properties
storePassword=Kased2026Secure!
keyPassword=Kased2026Secure!
```

### APK trop gros

Utilisez le build ARM64 uniquement :
```bash
flutter build apk --release --target-platform android-arm64 --split-per-abi
```

---

## 📚 Documentation Complète

- [Configuration Keystore](./KEYSTORE_SETUP.md)
- [Fix Gradle Timeout](./FIX_GRADLE_TIMEOUT.md)
- [Fix Gradle Build](./FIX_GRADLE_BUILD.md)

---

*Document créé le 4 mai 2026*
*Pour le projet Kased-App*
