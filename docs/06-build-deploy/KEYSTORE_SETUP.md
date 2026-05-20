# 🔐 Configuration du Keystore pour Signature APK

## Qu'est-ce qu'un Keystore ?

Un **keystore** est un fichier qui contient votre clé privée pour signer les APK Android. C'est **obligatoire** pour publier sur le Google Play Store.

⚠️ **IMPORTANT** : Gardez ce fichier en sécurité ! Si vous le perdez, vous ne pourrez plus mettre à jour votre application sur le Play Store.

---

## 📋 Étapes de Création

### 1. Créer le Keystore

Exécutez cette commande dans le terminal (remplacez les valeurs) :

```bash
keytool -genkey -v -keystore C:\Users\joyda\Documents\Project\Terrain-app\cotis_app\android\app\kased-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias kased-key
```

**Informations à fournir** :
- **Mot de passe du keystore** : Choisissez un mot de passe fort (minimum 6 caractères)
- **Nom et prénom** : Votre nom ou le nom de l'organisation
- **Unité organisationnelle** : Par exemple "Développement"
- **Organisation** : Nom de votre église ou organisation
- **Ville** : Votre ville
- **État/Province** : Votre région
- **Code pays** : CD (pour RDC) ou votre pays

**Exemple de réponses** :
```
Enter keystore password: MonMotDePasseSecurise123!
Re-enter new password: MonMotDePasseSecurise123!
What is your first and last name? [Unknown]: Joyda Kasongo
What is the name of your organizational unit? [Unknown]: Développement
What is the name of your organization? [Unknown]: Kased App
What is the name of your City or Locality? [Unknown]: Kinshasa
What is the name of your State or Province? [Unknown]: Kinshasa
What is the two-letter country code for this unit? [Unknown]: CD
Is CN=Joyda Kasongo, OU=Développement, O=Kased App, L=Kinshasa, ST=Kinshasa, C=CD correct? [no]: yes

Enter key password for <kased-key>
    (RETURN if same as keystore password): [Appuyez sur Entrée]
```

---

### 2. Créer le Fichier de Configuration

Créez le fichier `cotis_app/android/key.properties` :

```properties
storePassword=VotreMotDePasseKeystore
keyPassword=VotreMotDePasseKey
keyAlias=kased-key
storeFile=kased-release-key.jks
```

⚠️ **IMPORTANT** : Ajoutez `key.properties` au `.gitignore` pour ne pas le commiter !

---

### 3. Configurer le Build Gradle

Le fichier `cotis_app/android/app/build.gradle.kts` doit être configuré pour utiliser le keystore.

Ajoutez avant le bloc `android {}` :

```kotlin
// Charger les propriétés du keystore
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

Puis dans le bloc `android {}`, ajoutez :

```kotlin
signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String
        keyPassword = keystoreProperties["keyPassword"] as String
        storeFile = file(keystoreProperties["storeFile"] as String)
        storePassword = keystoreProperties["storePassword"] as String
    }
}

buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
    }
}
```

---

### 4. Ajouter au .gitignore

Ajoutez ces lignes à `cotis_app/android/.gitignore` :

```
# Keystore files
*.jks
*.keystore
key.properties
```

---

## 🚀 Compiler l'APK Signé

Une fois le keystore configuré :

```bash
cd cotis_app

# APK release signé (tous les CPU)
flutter build apk --release

# APK release signé (ARM64 uniquement - plus petit)
flutter build apk --release --target-platform android-arm64 --split-per-abi
```

L'APK signé sera dans :
```
cotis_app/build/app/outputs/flutter-apk/app-release.apk
```

Ou pour ARM64 :
```
cotis_app/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

---

## 📦 Compiler l'App Bundle (Recommandé pour Play Store)

Le format **App Bundle** (.aab) est recommandé par Google :

```bash
flutter build appbundle --release
```

Le fichier sera dans :
```
cotis_app/build/app/outputs/bundle/release/app-release.aab
```

---

## 🔒 Sécurité du Keystore

### ✅ À FAIRE :
- Sauvegarder le fichier `.jks` dans un endroit sûr (cloud privé, disque externe)
- Noter le mot de passe dans un gestionnaire de mots de passe
- Ne JAMAIS commiter le keystore ou `key.properties` sur Git

### ❌ À NE PAS FAIRE :
- Partager le keystore publiquement
- Perdre le fichier `.jks` ou le mot de passe
- Commiter le keystore sur GitHub/GitLab

---

## 📊 Vérifier la Signature

Pour vérifier que l'APK est bien signé :

```bash
# Vérifier la signature
keytool -printcert -jarfile cotis_app/build/app/outputs/flutter-apk/app-release.apk

# Vérifier les informations du keystore
keytool -list -v -keystore cotis_app/android/app/kased-release-key.jks -alias kased-key
```

---

## 🎯 Résumé des Fichiers

| Fichier                 | Emplacement              | Description               |
| ----------------------- | ------------------------ | ------------------------- |
| `kased-release-key.jks` | `cotis_app/android/app/` | Keystore (clé privée)     |
| `key.properties`        | `cotis_app/android/`     | Configuration du keystore |
| `.gitignore`            | `cotis_app/android/`     | Ignore le keystore        |

---

## 🆘 Problèmes Courants

### Erreur : "keytool: command not found"

Le JDK n'est pas dans le PATH. Utilisez le chemin complet :

```bash
# Windows
"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey ...

# Ou trouvez le JDK de Flutter
flutter doctor -v
# Cherchez "Java binary at:"
```

### Erreur : "keystore password was incorrect"

Vous avez entré le mauvais mot de passe. Réessayez avec le bon mot de passe.

### Erreur : "Keystore file does not exist"

Le chemin vers le fichier `.jks` est incorrect dans `key.properties`. Vérifiez le chemin.

---

*Document créé le 4 mai 2026*
*Pour le projet Kased-App*
