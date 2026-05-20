# Guide : Ajouter le Logo Google Officiel

## 📋 Vue d'ensemble

Par défaut, les pages d'authentification utilisent une icône de fallback (`Icons.login`). Ce guide explique comment ajouter le vrai logo Google pour un rendu plus professionnel.

## 🎯 Résultat Attendu

**Avant** (fallback) :
```
[📱] S'inscrire avec Google
```

**Après** (logo officiel) :
```
[G] S'inscrire avec Google
```
(avec le logo Google multicolore officiel)

## 📥 Étape 1 : Télécharger le Logo Google

### Option A : Créer le Logo Manuellement

Le logo Google utilise 4 couleurs officielles :
- **Bleu** : #4285F4
- **Vert** : #34A853
- **Jaune** : #FBBC05
- **Rouge** : #EA4335

Vous pouvez créer un PNG 24x24px avec ces couleurs dans un éditeur graphique.

### Option B : Utiliser un Logo Existant

1. Recherchez "Google logo PNG transparent" sur Google Images
2. Téléchargez une version haute qualité (minimum 24x24px)
3. Assurez-vous que le fond est transparent

### Option C : Utiliser le SVG Officiel

Le design HTML contient déjà le SVG officiel. Vous pouvez :
1. Ouvrir `kased-signup-design.html` ou `kased-login-design.html`
2. Copier le SVG du logo Google
3. Le convertir en PNG avec un outil en ligne (ex: CloudConvert)

## 📁 Étape 2 : Placer le Logo dans le Projet

### Structure de Dossiers

Créez la structure suivante si elle n'existe pas :

```
cotis_app/
├── assets/
│   └── images/
│       └── google_logo.png
├── lib/
├── pubspec.yaml
└── ...
```

### Commandes

```bash
# Depuis la racine du projet
cd cotis_app

# Créer les dossiers
mkdir -p assets/images

# Copier votre logo (remplacez le chemin source)
cp /chemin/vers/votre/google_logo.png assets/images/
```

### Spécifications du Fichier

- **Nom** : `google_logo.png` (exactement)
- **Format** : PNG avec transparence
- **Taille recommandée** : 24x24px (ou plus grande, sera redimensionnée)
- **Poids** : < 10 KB

## ⚙️ Étape 3 : Configurer pubspec.yaml

Ouvrez `cotis_app/pubspec.yaml` et vérifiez/ajoutez :

```yaml
flutter:
  uses-material-design: true

  # Déclarer le dossier assets
  assets:
    - assets/images/
```

**Important** : Respectez l'indentation (2 espaces)

### Vérification

```bash
# Valider le fichier YAML
flutter pub get
```

Si vous voyez des erreurs, vérifiez l'indentation.

## 🔄 Étape 4 : Relancer l'Application

```bash
# Arrêter l'app en cours (Ctrl+C)

# Nettoyer le build (optionnel mais recommandé)
flutter clean

# Récupérer les dépendances
flutter pub get

# Relancer l'app
flutter run
```

## ✅ Étape 5 : Vérifier le Résultat

### Sur l'Émulateur/Appareil

1. Ouvrir la page Login ou Signup
2. Vérifier que le logo Google s'affiche sur le bouton
3. Le logo doit être :
   - Multicolore (bleu, vert, jaune, rouge)
   - 24x24px
   - Bien aligné avec le texte

### Si le Logo ne s'Affiche Pas

**Vérifications** :

1. **Chemin du fichier** :
   ```
   cotis_app/assets/images/google_logo.png
   ```
   (pas dans `cotis_app/lib/assets/...`)

2. **Nom du fichier** :
   - Exactement `google_logo.png` (minuscules)
   - Pas `Google_Logo.png` ou `google-logo.png`

3. **pubspec.yaml** :
   ```yaml
   assets:
     - assets/images/
   ```
   (avec le `/` à la fin)

4. **Rebuild** :
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

### Fallback Automatique

Si le logo ne se charge pas, l'icône `Icons.login` s'affichera automatiquement. Pas de crash !

## 🎨 Alternative : Utiliser un Package Flutter

### Option : flutter_svg

Si vous préférez utiliser le SVG directement :

1. **Ajouter la dépendance** :
   ```yaml
   dependencies:
     flutter_svg: ^2.0.0
   ```

2. **Placer le SVG** :
   ```
   cotis_app/assets/images/google_logo.svg
   ```

3. **Modifier le code** :
   ```dart
   import 'package:flutter_svg/flutter_svg.dart';

   // Dans le bouton
   SvgPicture.asset(
     'assets/images/google_logo.svg',
     width: 24,
     height: 24,
   )
   ```

**Avantage** : Qualité parfaite à toutes les résolutions

**Inconvénient** : Dépendance supplémentaire

## 📊 Comparaison des Options

| Option | Avantages | Inconvénients |
|--------|-----------|---------------|
| **PNG** | Simple, pas de dépendance | Qualité limitée au zoom |
| **SVG** | Qualité parfaite | Dépendance `flutter_svg` |
| **Fallback** | Aucune config | Moins professionnel |

## 🎯 Recommandation

Pour Kased-app, je recommande :

1. **Court terme** : Utiliser le fallback (`Icons.login`)
   - Fonctionne déjà
   - Pas de configuration
   - Suffisant pour un MVP

2. **Moyen terme** : Ajouter le PNG
   - Simple à mettre en place
   - Pas de dépendance
   - Rendu professionnel

3. **Long terme** : Passer au SVG (si besoin)
   - Qualité parfaite
   - Scalable
   - Meilleur pour le branding

## 🐛 Dépannage

### Erreur : "Unable to load asset"

**Cause** : Chemin incorrect ou fichier manquant

**Solution** :
1. Vérifier que le fichier existe : `cotis_app/assets/images/google_logo.png`
2. Vérifier `pubspec.yaml` : `assets: - assets/images/`
3. Relancer : `flutter clean && flutter pub get && flutter run`

### Erreur : "Failed to decode image"

**Cause** : Fichier PNG corrompu ou format incorrect

**Solution** :
1. Ouvrir le PNG dans un éditeur d'images
2. Exporter à nouveau en PNG avec transparence
3. Vérifier que le fichier fait < 10 KB

### Le Logo est Flou

**Cause** : Résolution trop basse

**Solution** :
1. Utiliser un PNG de meilleure qualité (48x48px ou plus)
2. Ou passer au SVG pour une qualité parfaite

### Le Logo a un Fond Blanc

**Cause** : PNG sans transparence

**Solution** :
1. Ouvrir le PNG dans un éditeur (ex: GIMP, Photoshop)
2. Supprimer le fond blanc
3. Exporter en PNG avec transparence (canal alpha)

## 📝 Checklist Finale

- [ ] Logo téléchargé (PNG 24x24px minimum)
- [ ] Fichier placé dans `cotis_app/assets/images/google_logo.png`
- [ ] `pubspec.yaml` mis à jour avec `assets: - assets/images/`
- [ ] `flutter pub get` exécuté sans erreur
- [ ] Application relancée avec `flutter run`
- [ ] Logo visible sur les pages Login et Signup
- [ ] Logo bien aligné avec le texte du bouton
- [ ] Fallback fonctionne si le logo est supprimé

## 🎉 Résultat Final

Après avoir suivi ce guide, vos pages d'authentification afficheront le logo Google officiel, donnant un aspect encore plus professionnel à votre application Kased !

---

**Date de création** : 3 mai 2026  
**Version** : 2.0.2  
**Statut** : Guide optionnel (fallback déjà en place)
