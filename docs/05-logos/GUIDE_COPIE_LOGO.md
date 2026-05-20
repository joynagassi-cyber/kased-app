# 📋 Guide : Copier le Logo Kased-app

## Méthode 1 : Copie Manuelle (Recommandé)

### Étape 1 : Localiser le Logo

1. Ouvrez l'**Explorateur Windows**
2. Naviguez vers : `C:\Users\joyda\Downloads`
3. Trouvez le fichier du logo (probablement nommé `kased-logo.png` ou similaire)

### Étape 2 : Créer le Dossier de Destination

1. Ouvrez une nouvelle fenêtre de l'**Explorateur Windows**
2. Naviguez vers le dossier du projet : `cotis_app`
3. Créez le dossier `assets` s'il n'existe pas
4. Dans `assets`, créez le dossier `images`
5. Vous devriez avoir : `cotis_app/assets/images/`

### Étape 3 : Copier le Logo

1. Retournez dans le dossier `Downloads`
2. **Cliquez droit** sur le fichier du logo
3. Sélectionnez **Copier**
4. Naviguez vers `cotis_app/assets/images/`
5. **Cliquez droit** dans le dossier
6. Sélectionnez **Coller**
7. **Renommez** le fichier en `kased_logo.png` (important !)

### Résultat Attendu

```
cotis_app/
├── assets/
│   └── images/
│       └── kased_logo.png  ← Le logo doit être ici
├── lib/
├── android/
├── ios/
└── pubspec.yaml
```

---

## Méthode 2 : Commande PowerShell

### Étape 1 : Ouvrir PowerShell

1. Ouvrez **PowerShell** (Windows + X → Windows PowerShell)
2. Naviguez vers le dossier du projet :
   ```powershell
   cd "chemin/vers/cotis_app"
   ```

### Étape 2 : Créer le Dossier

```powershell
New-Item -ItemType Directory -Force -Path "assets/images"
```

### Étape 3 : Copier le Logo

**Remplacez `[nom-du-logo]` par le vrai nom du fichier !**

```powershell
Copy-Item "C:/Users/joyda/Downloads/[nom-du-logo].png" "assets/images/kased_logo.png"
```

**Exemples de noms possibles :**
- `kased-logo.png`
- `logo.png`
- `kased_app_logo.png`
- `icon.png`

### Étape 4 : Vérifier

```powershell
Test-Path "assets/images/kased_logo.png"
```

**Résultat attendu :** `True`

---

## Méthode 3 : Glisser-Déposer

### Étape 1 : Ouvrir Deux Fenêtres

1. **Fenêtre 1** : Explorateur Windows → `C:\Users\joyda\Downloads`
2. **Fenêtre 2** : Explorateur Windows → `cotis_app\assets\images`

### Étape 2 : Glisser-Déposer

1. Dans la **Fenêtre 1**, sélectionnez le fichier du logo
2. **Maintenez le clic gauche** et glissez vers la **Fenêtre 2**
3. Relâchez le clic pour déposer le fichier
4. **Renommez** le fichier en `kased_logo.png`

---

## Vérification

### Vérifier que le Logo est au Bon Endroit

Ouvrez PowerShell dans le dossier `cotis_app` et exécutez :

```powershell
Get-Item "assets/images/kased_logo.png"
```

**Résultat attendu :**
```
    Directory: C:\...\cotis_app\assets\images

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----         5/3/2026   2:30 PM          12345 kased_logo.png
```

### Vérifier la Taille du Logo

Le logo doit être d'au moins **512x512 pixels** pour une qualité optimale.

Pour vérifier :
1. Cliquez droit sur le fichier
2. Sélectionnez **Propriétés**
3. Allez dans l'onglet **Détails**
4. Vérifiez les **Dimensions**

**Recommandations :**
- ✅ **Idéal** : 1024x1024 pixels ou plus
- ✅ **Acceptable** : 512x512 pixels
- ⚠️ **Minimum** : 192x192 pixels
- ❌ **Trop petit** : Moins de 192x192 pixels

---

## Après la Copie

Une fois le logo copié, exécutez le script de configuration :

### Option A : Script PowerShell Automatique

```powershell
cd cotis_app
.\setup_logo.ps1
```

### Option B : Commandes Manuelles

```bash
cd cotis_app

# 1. Installer le package
flutter pub add --dev flutter_launcher_icons

# 2. Générer les icônes
flutter pub run flutter_launcher_icons

# 3. Nettoyer et relancer
flutter clean
flutter pub get
flutter run
```

---

## Problèmes Courants

### Problème 1 : "Fichier non trouvé"

**Cause :** Le logo n'est pas au bon endroit ou mal nommé

**Solution :**
1. Vérifiez que le fichier est bien dans `cotis_app/assets/images/`
2. Vérifiez que le nom est exactement `kased_logo.png` (pas d'espace, pas de majuscule)

### Problème 2 : "Dossier assets n'existe pas"

**Cause :** Le dossier `assets/images` n'a pas été créé

**Solution :**
```powershell
New-Item -ItemType Directory -Force -Path "assets/images"
```

### Problème 3 : "Logo de mauvaise qualité"

**Cause :** Le logo est trop petit (moins de 512x512 pixels)

**Solution :**
1. Utilisez un logo de meilleure qualité (1024x1024 recommandé)
2. Ou utilisez un outil en ligne pour agrandir l'image sans perte de qualité

### Problème 4 : "Erreur lors de la génération des icônes"

**Cause :** Le package `flutter_launcher_icons` n'est pas installé

**Solution :**
```bash
flutter pub add --dev flutter_launcher_icons
flutter pub get
```

---

## Checklist Finale

Avant de passer à l'étape suivante, vérifiez :

- [ ] Le logo est copié dans `cotis_app/assets/images/kased_logo.png`
- [ ] Le nom du fichier est exactement `kased_logo.png` (pas d'espace, pas de majuscule)
- [ ] Le logo fait au moins 512x512 pixels
- [ ] Le fichier est au format PNG
- [ ] Le dossier `assets/images` existe

---

## Prochaine Étape

Une fois le logo copié et vérifié, exécutez :

```powershell
cd cotis_app
.\setup_logo.ps1
```

Ce script va automatiquement :
1. ✅ Vérifier que le logo existe
2. ✅ Installer le package `flutter_launcher_icons`
3. ✅ Générer toutes les tailles d'icônes pour Android et iOS
4. ✅ Configurer l'application

---

## Besoin d'Aide ?

Si vous rencontrez des problèmes, faites-moi savoir et je vous guiderai étape par étape !

**Questions fréquentes :**
- "Quel est le nom exact de mon fichier logo ?" → Regardez dans le dossier Downloads
- "Comment renommer le fichier ?" → Cliquez droit → Renommer
- "Le script ne fonctionne pas" → Vérifiez que vous êtes dans le dossier `cotis_app`
