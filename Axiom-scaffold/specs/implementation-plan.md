# Plan Architectural — Spring Animations on Buttons & Bottom Navigation Bar Icons

**Date** : 2026-05-20  
**Auteur** : Antigravity (AI UI/UX Architect)  
**Ticket** : SPRING-ANIMATIONS-UI  
**Statut** : 🟡 Draft

---

## 1. Contexte

### Problème à résoudre
L'application **Kased** (kased_app) a besoin d'un polissage visuel et sensoriel pour ses éléments interactifs principaux. Pour améliorer la sensation d'interaction physique, moelleuse et élastique, nous devons introduire des **Spring Animations** (animations avec physique de ressort) sur tous les boutons principaux et sur les icônes de la barre de navigation inférieure (`BottomNavigationBar`). 

De plus, pour accentuer la sensation de modernité et de légèreté, l'utilisateur a spécifié que la **barre de navigation inférieure doit être visuellement profonde et donner un sentiment clair de flottaison**. Nous allons donc retravailler ses ombres, ses bordures, et y ajouter un effet de flou d'arrière-plan (glassmorphism) haut de gamme.

### Objectifs
- [ ] Ajouter les dépendances `flutter_animate` et `haptic_feedback` dans `pubspec.yaml` et s'assurer que `flutter pub get` s'exécute avec succès.
- [ ] Créer les constantes physiques et de durées d'animation dans `lib/core/animation_constants.dart`.
- [ ] Implémenter le widget custom `SpringButton` dans `lib/widgets/spring_button.dart` qui gère les effets physiques au press/release et les vibrations haptiques légères.
- [ ] Remplacer les boutons interactifs principaux (`ElevatedButton`, `FilledButton`, etc.) par des `SpringButton`.
- [ ] Implémenter le widget custom `SpringNavIcon` dans `lib/widgets/spring_nav_icon.dart` pour animer les transitions d'onglets de navigation avec un retour tactile précis.
- [ ] **Mise à jour (Floating Navbar)** : Refondre l'esthétique de la barre de navigation dans `lib/widgets/app_shell.dart` pour la rendre flottante et ultra-profonde (combinaison de `BackdropFilter` pour le floutage de fond, ombres multi-couches intenses, micro-bordure néon subtile et translation réactive d'échelle sur l'onglet actif).
- [ ] Ajouter une animation d'entrée en cascade sur la liste des membres dans `lib/screens/membres/membres_screen.dart` et sur les paiements dans `lib/screens/cultes/culte_detail_screen.dart`.
- [ ] Ajouter un effet d'échelle élastique sur les états de paiement dans `MemberPayTile`.
- [ ] Ajouter une animation pulsante sur le badge de retards s'il y a des retards non traités.
- [ ] S'assurer que le code compile, s'analyse proprement sans erreur, et générer les fichiers nécessaires avec `build_runner`.

### Contraintes
- **Respect du style de codage** : Utiliser le package correct `kased_app` pour les imports de fichiers internes (et non `cotisapp` ou `cotis_app`).
- **Confinement** : Conserver toutes les structures actuelles saines et opérationnelles. Ne pas supprimer les actions (`onTap`/`onPressed`) existantes, les déléguer proprement aux wrappers physiques.
- **Micro-tâches indépendantes** : Traiter et valider une micro-tâche à la fois en demandant confirmation.
- **Zéro jank** : Pas d'animations lourdes ou complexes qui reconstruisent inutilement l'interface à chaque frame sans `AnimationController`.

---

## 2. Analyse de l'Existant

### Composants Impactés
- `cotis_app/pubspec.yaml` : Ajout de `flutter_animate` et `haptic_feedback`.
- `cotis_app/lib/core/animation_constants.dart` [NEW] : Constantes de physique de ressort (button, navIcon, soft) et de durée.
- `cotis_app/lib/widgets/spring_button.dart` [NEW] : Wrapper de bouton avec retour haptique léger et compression élastique.
- `cotis_app/lib/widgets/spring_nav_icon.dart` [NEW] : Icône de barre de navigation animée avec rotation légère, mise à l'échelle overshoot, et retour haptic selection.
- `cotis_app/lib/widgets/app_shell.dart` : Intégration de `SpringNavIcon` et refonte esthétique de la barre de navigation en conteneur flottant 3D profond.
- `cotis_app/lib/widgets/member_pay_tile.dart` : Ajout de l'animation d'échelle sur les boutons/icônes de paiement.
- `cotis_app/lib/screens/membres/membres_screen.dart` : Cascade d'entrée des cartes de membres.
- `cotis_app/lib/screens/cultes/culte_detail_screen.dart` : Cascade d'entrée des tuiles de paiement.
- `cotis_app/lib/screens/login_screen.dart`, `cotis_app/lib/screens/signup_screen.dart`, `cotis_app/lib/screens/onboarding_screen.dart` : Wrap des boutons de soumission principaux dans `SpringButton`.

### Dépendances de Code
```
         [AppShell / Screens]
                  │
                  ▼
          [SpringWidgets]
                  │
                  ▼
      [animation_constants.dart]
         (SpringDescription)
```

### Patterns Existants
- **Riverpod State Management** : Pour écouter les données et l'état global.
- **GoRouter Navigation** : Pour obtenir l'index d'onglet actif de manière saine via les URI de navigation (`GoRouterState.of(context).uri.toString()`).

---

## 3. Solution Proposée

### Vue d'Ensemble
Nous allons structurer les ressorts physiques en utilisant `SpringSimulation` natif de Flutter pour les animations initiées par des interactions tactiles utilisateur (comme les boutons et les icônes de la barre de navigation). Pour les animations d'entrée déclaratives et les états d'animation en boucle (comme les cascades de listes ou les pulsations du badge), nous utiliserons le package `flutter_animate` qui offre une syntaxe déclarative moderne et concise.

### Architecture des Composants Physiques et Visuels
1. **AppSprings** : Stocke les descriptions de ressorts avec des propriétés ajustées de rigidité (`stiffness`) et d'amortissement (`damping`) :
   - `button` : Stiffness 500, Damping 28 (moelleux, rebond léger).
   - `navIcon` : Stiffness 700, Damping 22 (vif, rebond marqué).
   - `soft` : Stiffness 380, Damping 32 (très amorti, quasi sans rebond, pour FAB/chips).
2. **SpringButton** : Capture les événements tactiles avec `GestureDetector` pour animer un `ScaleTransition` via un `AnimationController`. Lors du relâchement tactile, applique une simulation `SpringSimulation` avec vélocité initiale négative pour simuler le rebond élastique de retour à 1.0.
3. **SpringNavIcon** : Observe le changement d'état `isSelected`. Dès que `isSelected` passe de `false` à `true`, déclenche une vibration haptique sélective et exécute une animation d'échelle avec `ScaleTransition` et de rotation légère avec `RotationTransition`, stabilisées par un `SpringSimulation`.
4. **Visuel de la Floating Navbar** :
   - Remplacement du conteneur classique par un conteneur utilisant un floutage d'arrière-plan (`BackdropFilter` avec sigmaX: 12, sigmaY: 12).
   - Utilisation d'ombres multicouches profondes (double `BoxShadow` : une ombre principale sombre et diffuse pour la flottaison, et une ombre secondaire très douce et colorée basée sur la couleur primaire pour donner un effet de lueur sous la barre).
   - Micro-bordure néon subtile avec un dégradé lumineux pour donner une démarcation de profondeur par rapport au reste de l'écran.

---

## 4. Découpage en Micro-Tâches

### Phase 1 : Dépendances et Constantes
- [ ] **Tâche 1.1** : Configurer les dépendances
  - Fichier : `cotis_app/pubspec.yaml`
  - Changement : Ajouter `flutter_animate: ^4.5.0` et `haptic_feedback: ^0.5.0`. Lancer `flutter pub get`.
- [ ] **Tâche 1.2** : Créer les constantes d'animation
  - Fichier : `cotis_app/lib/core/animation_constants.dart`
  - Changement : Définir les classes `AppSprings` et `AppAnimDurations`.

### Phase 2 : Widgets Physiques Génériques
- [ ] **Tâche 2.1** : Créer le widget `SpringButton`
  - Fichier : `cotis_app/lib/widgets/spring_button.dart`
  - Changement : Implémenter le widget gérant la compression à 0.93 et le retour élastique au relâchement avec retour haptique précis.
- [ ] **Tâche 2.2** : Créer le widget `SpringNavIcon`
  - Fichier : `cotis_app/lib/widgets/spring_nav_icon.dart`
  - Changement : Implémenter l'icône de navigation animée avec rotation et échelle de rebond avec physique de ressort.

### Phase 3 : Intégration Visuelle et Tactile
- [ ] **Tâche 3.1** : Refonte de la Floating Navigation Bar (Ultra-profonde & 3D flottante)
  - Fichier : `cotis_app/lib/widgets/app_shell.dart`
  - Changement : Remplacer l'icône de chaque `NavigationDestination` par un `SpringNavIcon` connecté à l'index d'onglet actif du GoRouter. Retravailler le conteneur décoratif avec du glassmorphism (`BackdropFilter`), des ombres multicouches intenses et une bordure lumineuse pour une sensation de flottaison absolue au-dessus des pages.
- [ ] **Tâche 3.2** : Appliquer `SpringButton` aux boutons principaux
  - Fichiers :
    - `cotis_app/lib/screens/login_screen.dart`
    - `cotis_app/lib/screens/signup_screen.dart`
    - `cotis_app/lib/screens/onboarding_screen.dart`
    - `cotis_app/lib/screens/cultes/cultes_screen.dart`
    - `cotis_app/lib/screens/cultes/culte_detail_screen.dart`
    - `cotis_app/lib/screens/membres/add_membre_screen.dart`
  - Changement : Envelopper les boutons d'action cruciaux dans `SpringButton` pour donner une sensation d'appui charnu.

### Phase 4 : Animations Déclaratives Complémentaires
- [ ] **Tâche 4.1** : Animer le changement de statut de paiement
  - Fichier : `cotis_app/lib/widgets/member_pay_tile.dart`
  - Changement : Animer l'icône/bouton de statut de paiement avec une mise à l'échelle élastique via `flutter_animate` lorsque le statut change.
- [ ] **Tâche 4.2** : Entrée en cascade des listes
  - Fichiers :
    - `cotis_app/lib/screens/membres/membres_screen.dart`
    - `cotis_app/lib/screens/cultes/culte_detail_screen.dart`
  - Changement : Appliquer des effets `.animate().fadeIn().slideX()` avec délai incrémental indexé sur les éléments de liste pour une apparition fluide.
- [ ] **Tâche 4.3** : Badge pulsant de retards
  - Fichier : `cotis_app/lib/widgets/app_shell.dart` (ou sous-jacent)
  - Changement : Si le compteur de retards est supérieur à 0, appliquer une animation pulsante d'échelle continue sur le badge.

### Phase 5 : Diagnostics et Build
- [ ] **Tâche 5.1** : Analyse statique
  - Commande : `flutter analyze` pour vérifier l'absence d'erreurs d'analyse Dart.
- [ ] **Tâche 5.2** : Synchronisation du code généré
  - Commande : `flutter pub run build_runner build --delete-conflicting-outputs` pour regénérer les fichiers `.g.dart` s'il y a lieu.
- [ ] **Tâche 5.3** : Build APK de débogage/vérification
  - Commande : `flutter build apk --debug` pour confirmer qu'aucun jank ni erreur de compilation n'a été introduit.

---

## 5. Risques et Mitigations

| Risque | Probabilité | Impact | Mitigation |
| :--- | :--- | :--- | :--- |
| Conflit de version de dépendances | Faible | Moyen | Utiliser des contraintes de version flexibles ou utiliser les simulations natives en cas de conflit avec `flutter_animate`. |
| Comportement inattendu lors des clics multiples | Moyenne | Moyen | Gérer l'état du contrôleur d'animation pour qu'il réinitialise correctement et proprement toute animation en cours si l'utilisateur tapote à répétition. |
| Altération involontaire de styles de boutons désactivés | Basse | Moyen | Conserver les onPressed/onTap d'origine au format vide `() {}` plutôt que `null` s'ils modifient le style graphique désactivé. |

---

## 6. Critères de Validation

### Tests visuels
- [ ] Boutons principaux : compression tactile immédiate, retour moelleux avec overshoot léger au relâchement, vibration haptique subtile perçue.
- [ ] Onglets Navigation : l'icône sélectionnée effectue un saut élastique avec une rotation subtile, vibration haptique selection perçue au toucher.
- [ ] Cascades d'entrée : apparition ordonnée et progressive des listes sans à-coup.
- [ ] Badge retards : pulsation douce d'échelle 1.0 à 1.08 en boucle continue.
- [ ] Pas d'animations actives sur les éléments inactifs (disabled).

### Compilation & Analyse
- [ ] `flutter analyze` retourne 0 avertissement ni erreur.
- [ ] La compilation de l'APK s'achève avec succès.

---

## 7. Approbation
- [ ] Utilisateur (En attente d'approbation)
