# Guide de Test - Nouveau Design d'Authentification

## 🚀 Démarrage Rapide

### 1. Lancer l'Application

```bash
cd cotis_app
flutter run
```

### 2. Naviguer vers les Pages d'Authentification

L'application démarre sur la page de **Login** (route initiale : `/login`)

## ✅ Checklist de Test

### Page Login (`/login`)

#### Éléments Visuels
- [ ] **Animation d'entrée** : La page apparaît avec un fade-in + slide-up fluide (600ms)
- [ ] **Icône de l'église** : 
  - [ ] Taille : 80x80px
  - [ ] Couleur de fond : Bleu (#1246C8)
  - [ ] Ombre portée visible et élégante
  - [ ] Border radius : 20px
- [ ] **Badge "Bon retour !"** :
  - [ ] Visible au-dessus du titre
  - [ ] Fond bleu clair (#E8EEFB)
  - [ ] Icône check_circle à gauche
  - [ ] Forme pill (border-radius: 100px)
- [ ] **Titre** : "Se connecter" (32px, Syne, bold)
- [ ] **Sous-titre** : "Accédez à votre espace de gestion des cotisations"
- [ ] **Bouton Google** :
  - [ ] Texte : "Continuer avec Google"
  - [ ] Hauteur : 56px
  - [ ] Fond blanc avec bordure
  - [ ] Logo Google visible (ou icône de fallback)
  - [ ] Border radius : 16px
- [ ] **Divider** : Lignes horizontales avec "OU" au centre
- [ ] **Lien** : "Première visite ? **Créer un compte**"
- [ ] **Note de sécurité** : 
  - [ ] Icône de bouclier
  - [ ] Texte : "Vos données sont sécurisées et stockées localement"

#### Interactions
- [ ] **Tap sur le bouton Google** :
  - [ ] Affiche un spinner de chargement
  - [ ] Texte change en "Connexion..."
  - [ ] Bouton désactivé pendant le chargement
- [ ] **Tap sur "Créer un compte"** :
  - [ ] Navigation vers la page Signup (`/signup`)
  - [ ] Transition fluide

#### Responsive
- [ ] **Mobile** : Conteneur prend toute la largeur (avec padding 24px)
- [ ] **Desktop** : Conteneur limité à 440px de largeur
- [ ] **Textes** : Lisibles sur toutes les tailles d'écran

---

### Page Signup (`/signup`)

#### Éléments Visuels
- [ ] **Animation d'entrée** : La page apparaît avec un fade-in + slide-up fluide (600ms)
- [ ] **Icône de l'église** : 
  - [ ] Taille : 80x80px
  - [ ] Couleur de fond : Bleu (#1246C8)
  - [ ] Ombre portée visible et élégante
  - [ ] Border radius : 20px
- [ ] **Titre** : "Créer un compte" (32px, Syne, bold)
- [ ] **Sous-titre** : "Gérez les cotisations de votre église facilement"
- [ ] **Bouton Google** :
  - [ ] Texte : "S'inscrire avec Google"
  - [ ] Hauteur : 56px
  - [ ] Fond blanc avec bordure
  - [ ] Logo Google visible (ou icône de fallback)
  - [ ] Border radius : 16px
- [ ] **Divider** : Lignes horizontales avec "OU" au centre
- [ ] **Lien** : "Vous avez déjà un compte ? **Se connecter**"
- [ ] **Note de sécurité** : 
  - [ ] Icône de bouclier
  - [ ] Texte : "Vos données sont sécurisées et stockées localement"

#### Interactions
- [ ] **Tap sur le bouton Google** :
  - [ ] Affiche un spinner de chargement
  - [ ] Texte change en "Connexion..."
  - [ ] Bouton désactivé pendant le chargement
- [ ] **Tap sur "Se connecter"** :
  - [ ] Navigation vers la page Login (`/login`)
  - [ ] Transition fluide

#### Responsive
- [ ] **Mobile** : Conteneur prend toute la largeur (avec padding 24px)
- [ ] **Desktop** : Conteneur limité à 440px de largeur
- [ ] **Textes** : Lisibles sur toutes les tailles d'écran

---

## 🎨 Comparaison avec le Design HTML

### Ouvrir les Designs HTML

1. **Page Signup** : Ouvrir `kased-signup-design.html` dans un navigateur
2. **Page Login** : Ouvrir `kased-login-design.html` dans un navigateur

### Vérifier la Cohérence

- [ ] **Couleurs** : Identiques entre HTML et Flutter
- [ ] **Espacements** : Similaires (padding, margins)
- [ ] **Typographie** : Tailles et poids de police cohérents
- [ ] **Animations** : Durée et effet similaires
- [ ] **Responsive** : Comportement similaire sur mobile/desktop

---

## 🐛 Tests de Bugs Potentiels

### Scénarios à Tester

1. **Navigation rapide** :
   - [ ] Naviguer rapidement entre Login et Signup plusieurs fois
   - [ ] Vérifier qu'il n'y a pas de crash ou de lag

2. **Rotation d'écran** (mobile) :
   - [ ] Tourner l'écran en mode paysage
   - [ ] Vérifier que le layout s'adapte correctement

3. **Connexion Google** :
   - [ ] Tester la vraie connexion Google
   - [ ] Vérifier la redirection vers le dashboard après connexion
   - [ ] Vérifier le message de succès (SnackBar)

4. **Erreur de connexion** :
   - [ ] Simuler une erreur (désactiver internet)
   - [ ] Vérifier que le message d'erreur s'affiche
   - [ ] Vérifier que le bouton redevient actif

5. **État de chargement** :
   - [ ] Vérifier que le spinner s'affiche pendant la connexion
   - [ ] Vérifier que le bouton est désactivé pendant le chargement
   - [ ] Vérifier que le texte change en "Connexion..."

---

## 📱 Tests sur Différents Appareils

### Émulateurs/Simulateurs

- [ ] **Android** : Pixel 5 (API 33)
- [ ] **iOS** : iPhone 14 Pro (iOS 16)

### Appareils Physiques (si disponibles)

- [ ] **Android** : Téléphone réel
- [ ] **iOS** : iPhone réel

### Tailles d'Écran

- [ ] **Petit** : 320x568 (iPhone SE)
- [ ] **Moyen** : 375x812 (iPhone 12)
- [ ] **Grand** : 414x896 (iPhone 12 Pro Max)
- [ ] **Tablette** : 768x1024 (iPad)

---

## 🎯 Critères de Validation

### Design
- [ ] Le design correspond au HTML validé
- [ ] Les couleurs sont cohérentes avec le thème
- [ ] Les animations sont fluides (60 FPS)
- [ ] Le responsive fonctionne correctement

### Fonctionnalité
- [ ] La navigation fonctionne (Login ↔ Signup)
- [ ] Le bouton Google déclenche l'authentification
- [ ] Les états de chargement s'affichent correctement
- [ ] Les messages d'erreur/succès s'affichent

### Performance
- [ ] Pas de lag au chargement
- [ ] Animations fluides
- [ ] Pas de crash

### Accessibilité
- [ ] Textes lisibles (contraste suffisant)
- [ ] Boutons suffisamment grands (touch target ≥ 48dp)
- [ ] Navigation au clavier possible (desktop)

---

## 📝 Rapport de Test

### Template

```markdown
## Test du [DATE]

### Environnement
- **Appareil** : [Nom de l'appareil]
- **OS** : [Android/iOS + version]
- **Taille d'écran** : [Résolution]

### Résultats
- **Page Login** : ✅ / ❌
- **Page Signup** : ✅ / ❌
- **Navigation** : ✅ / ❌
- **Animations** : ✅ / ❌
- **Responsive** : ✅ / ❌

### Bugs Trouvés
1. [Description du bug]
2. [Description du bug]

### Commentaires
[Vos observations]
```

---

## 🚨 Problèmes Connus

### Logo Google Manquant

**Symptôme** : Icône générique au lieu du logo Google

**Solution** :
1. Télécharger le logo Google officiel (PNG, 24x24px)
2. Placer dans `cotis_app/assets/images/google_logo.png`
3. Vérifier `pubspec.yaml` :
   ```yaml
   flutter:
     assets:
       - assets/images/
   ```
4. Relancer l'app : `flutter run`

**Note** : Le fallback avec `Icons.login` fonctionne déjà.

---

## 📞 Support

Si vous rencontrez des problèmes :

1. Vérifier les logs : `flutter logs`
2. Nettoyer le build : `flutter clean && flutter pub get`
3. Vérifier la documentation : `FLUTTER_AUTH_DESIGN_UPDATE.md`

---

**Date de création** : 3 mai 2026  
**Version** : 2.0.2  
**Statut** : Prêt pour les tests
