# Micro-Tâche — Spring Animations on Buttons & Bottom Navigation Bar Icons

**Date** : 2026-05-20  
**Statut** : 🟢 Terminé

---

## Objectif
Ajouter des spring animations moelleuses et élastiques sur les boutons principaux et sur les icônes de la BottomNavigationBar avec retour haptique précis, et rendre la BottomNavigationBar flottante et visuellement très profonde en 3D glassmorphism.

## Fichiers impactés
- [x] `cotis_app/pubspec.yaml`
- [x] `cotis_app/lib/core/animation_constants.dart` [NEW]
- [x] `cotis_app/lib/widgets/spring_button.dart` [NEW]
- [x] `cotis_app/lib/widgets/spring_nav_icon.dart` [NEW]
- [x] `cotis_app/lib/widgets/app_shell.dart`
- [x] `cotis_app/lib/widgets/member_pay_tile.dart`
- [x] `cotis_app/lib/screens/membres/membres_screen.dart`
- [x] `cotis_app/lib/screens/cultes/culte_detail_screen.dart`
- [x] `cotis_app/lib/screens/login_screen.dart`
- [x] `cotis_app/lib/screens/signup_screen.dart`
- [x] `cotis_app/lib/screens/onboarding_screen.dart`

---

## Plan de Travail

### Phase 1 : Dépendances et Constantes
- [x] **Tâche 1.1** : Ajouter les dépendances `flutter_animate` et `haptic_feedback` dans `pubspec.yaml` et lancer `flutter pub get`.
- [x] **Tâche 1.2** : Créer le fichier `lib/core/animation_constants.dart` contenant les descriptions physiques de ressorts.

### Phase 2 : Widgets Physiques Génériques
- [x] **Tâche 2.1** : Créer le widget `SpringButton` dans `lib/widgets/spring_button.dart`.
- [x] **Tâche 2.2** : Créer le widget `SpringNavIcon` dans `lib/widgets/spring_nav_icon.dart`.

### Phase 3 : Intégration Visuelle et Tactile
- [x] **Tâche 3.1** : Intégrer `SpringNavIcon` et refondre la Floating Navigation Bar (avec BackdropFilter de flou 3D, double ombre profonde et micro-bordure lumineuse) dans `lib/widgets/app_shell.dart`.
- [x] **Tâche 3.2** : Wrap les boutons d'action principaux dans `SpringButton` (login, signup, onboarding, cultes, add membre, etc.).

### Phase 4 : Animations Déclaratives Complémentaires
- [x] **Tâche 4.1** : Animer le changement de statut de paiement élastique dans `MemberPayTile`.
- [x] **Tâche 4.2** : Ajouter la cascade d'entrée progressive sur les listes de membres dans `membres_screen.dart` et `culte_detail_screen.dart`.
- [x] **Tâche 4.3** : Ajouter la pulsation continue d'échelle sur le badge de retards s'il y a des retards actifs.

### Phase 5 : Diagnostics et Build
- [x] **Tâche 5.1** : Lancer `flutter analyze` et corriger toute anomalie.
- [x] **Tâche 5.2** : Lancer `build_runner` s'il y a lieu pour synchroniser le code généré.
- [x] **Tâche 5.3** : Lancer la compilation de l'APK en mode debug (`flutter build apk --debug`) pour vérifier l'absence de jank ou d'erreur.

---

## Critères de Validation
- [x] Toutes les animations physiques de ressort (boutons, icônes) sont fluides et ont un feel moelleux/élastique.
- [x] La BottomNavigationBar est visuellement flottante, profonde, floutée en arrière-plan et possède une lueur néon/ombre ultra-soignée.
- [x] Les retours haptiques vibrent précisément au press/selection.
- [x] `flutter analyze` s'achève avec 0 erreur.
- [x] Le build de l'APK debug compile sans aucune erreur.
