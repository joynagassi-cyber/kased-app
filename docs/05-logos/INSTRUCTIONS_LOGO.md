# 📋 Instructions pour Intégrer le Logo Kased-app

## Étape 1 : Copier le Logo dans le Projet

### Option A : Copie Manuelle (Recommandé)

1. **Localisez le logo** dans votre dossier Téléchargements
   - Nom probable : `kased-logo.png` ou similaire

2. **Copiez le fichier** vers le projet Flutter :
   ```
   Source : C:/Users/joyda/Downloads/[nom-du-logo].png
   Destination : cotis_app/assets/images/kased_logo.png
   ```

3. **Créez le dossier si nécessaire** :
   - Ouvrez l'Explorateur Windows
   - Naviguez vers : `cotis_app/assets/images/`
   - Si le dossier n'existe pas, créez-le

### Option B : Commande PowerShell

Ouvrez PowerShell dans le dossier du projet et exécutez :

```powershell
# Créer le dossier assets/images s'il n'existe pas
New-Item -ItemType Directory -Force -Path "cotis_app/assets/images"

# Copier le logo (remplacez [nom-du-logo] par le vrai nom)
Copy-Item "C:/Users/joyda/Downloads/[nom-du-logo].png" "cotis_app/assets/images/kased_logo.png"
```

---

## Étape 2 : Générer les Icônes pour Android et iOS

Une fois le logo copié, nous utiliserons le package `flutter_launcher_icons` pour générer automatiquement toutes les tailles d'icônes.

### Installation du Package

```bash
cd cotis_app
flutter pub add --dev flutter_launcher_icons
```

### Configuration

Créer/modifier le fichier `flutter_launcher_icons.yaml` :

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/kased_logo.png"
  
  # Android
  adaptive_icon_background: "#1246C8"  # Couleur primary de Kased-app
  adaptive_icon_foreground: "assets/images/kased_logo.png"
  
  # iOS
  remove_alpha_ios: true
  
  # Tailles générées automatiquement :
  # Android: mipmap-mdpi, mipmap-hdpi, mipmap-xhdpi, mipmap-xxhdpi, mipmap-xxxhdpi
  # iOS: AppIcon.appiconset (toutes les tailles requises)
```

### Génération des Icônes

```bash
flutter pub run flutter_launcher_icons
```

Cette commande va générer automatiquement :

**Android :**
- `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` (48x48)
- `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` (72x72)
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` (96x96)
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` (144x144)
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` (192x192)

**iOS :**
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/` (toutes les tailles)

---

## Étape 3 : Remplacer l'Icône dans les Écrans

### Écrans à Modifier

1. **Signup Screen** (`cotis_app/lib/screens/signup_screen.dart`)
2. **Login Screen** (`cotis_app/lib/screens/login_screen.dart`)

### Code Actuel (Icône Église)

```dart
Container(
  width: 80,
  height: 80,
  decoration: BoxDecoration(
    color: AppColors.primary,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withOpacity(0.15),
        blurRadius: 40,
        offset: const Offset(0, 10),
      ),
    ],
  ),
  child: const Icon(
    Icons.church,  // ← À remplacer
    size: 48,
    color: AppColors.textInverse,
  ),
)
```

### Nouveau Code (Logo Kased)

```dart
Container(
  width: 80,
  height: 80,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withOpacity(0.15),
        blurRadius: 40,
        offset: const Offset(0, 10),
      ),
    ],
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: Image.asset(
      'assets/images/kased_logo.png',
      width: 80,
      height: 80,
      fit: BoxFit.cover,
    ),
  ),
)
```

---

## Étape 4 : Déclarer l'Asset dans pubspec.yaml

Ouvrez `cotis_app/pubspec.yaml` et ajoutez :

```yaml
flutter:
  assets:
    - assets/images/kased_logo.png
```

---

## Étape 5 : Tester

```bash
cd cotis_app

# Nettoyer le build
flutter clean

# Récupérer les dépendances
flutter pub get

# Lancer l'application
flutter run
```

---

## Résumé des Commandes

```bash
# 1. Installer flutter_launcher_icons
cd cotis_app
flutter pub add --dev flutter_launcher_icons

# 2. Générer les icônes
flutter pub run flutter_launcher_icons

# 3. Nettoyer et relancer
flutter clean
flutter pub get
flutter run
```

---

## Checklist

- [ ] Logo copié dans `cotis_app/assets/images/kased_logo.png`
- [ ] Package `flutter_launcher_icons` installé
- [ ] Fichier `flutter_launcher_icons.yaml` créé
- [ ] Icônes générées avec `flutter pub run flutter_launcher_icons`
- [ ] Asset déclaré dans `pubspec.yaml`
- [ ] Écrans Signup et Login modifiés
- [ ] Application testée

---

## Besoin d'Aide ?

Si vous avez des questions ou des problèmes, faites-moi savoir et je vous guiderai étape par étape !
