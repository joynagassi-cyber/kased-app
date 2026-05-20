# Micro-Tâche — Automatic User Avatars (DiceBear API v9.x)

**Date** : 2026-05-20  
**Statut** : 🟢 Terminé (En attente de la tâche suivante de l'utilisateur)

---

## Objectif
Implémenter la génération automatique et déterministe d'illustrations d'avatars via l'API DiceBear v9.x (style adventurer) à partir de l'email de l'utilisateur. Mettre en cache localement et gérer les fallbacks hors ligne.

## Fichiers impactés
- [ ] `cotis_app/pubspec.yaml`
- [ ] `cotis_app/lib/core/avatar_service.dart` [NEW]
- [ ] `cotis_app/lib/widgets/user_avatar.dart` [NEW]
- [ ] `cotis_app/lib/widgets/app_drawer.dart`
- [ ] `cotis_app/lib/screens/profile/profile_screen.dart`

---

## Plan de Travail

### Phase 1 : Dépendances et Service d'Avatar
- [x] **Tâche 1.1** : Ajouter la dépendance `cached_network_image: ^3.3.1` sous `dependencies` dans `pubspec.yaml` et exécuter `flutter pub get`.
- [x] **Tâche 1.2** : Créer `lib/core/avatar_service.dart` avec la configuration de base de l'URL d'API `9.x` et le dictionnaire complet de tous les styles disponibles, incluant le style actif `adventurer`.
- [x] **Tâche 1.3** : Créer le widget réutilisable `UserAvatar` dans `lib/widgets/user_avatar.dart` exploitant `CachedNetworkImage` pour afficher l'avatar et charger les initiales avec couleur de fond stable en cas d'erreur de chargement (hors ligne).

### Phase 2 : Intégration dans l'Application
- [x] **Tâche 2.1** : Intégrer `UserAvatar` dans le `AppDrawer` (`lib/widgets/app_drawer.dart`) à la place de l'icône statique de profil de l'utilisateur connecté.
- [x] **Tâche 2.2** : Intégrer `UserAvatar` dans l'écran de profil (`lib/screens/profile/profile_screen.dart`) à la place du placeholder statique d'icône.

### Phase 3 : Diagnostics et Validation
- [x] **Tâche 3.1** : Lancer `flutter analyze` pour vérifier la correction de la syntaxe et de l'analyse statique.
- [x] **Tâche 3.2** : Regénérer avec `build_runner` s'il y a lieu pour assurer la conformité globale.
- [ ] **Tâche 3.3** : compiler et valider l'APK de débogage.

---

## Critères de Validation
- [ ] L'email de l'utilisateur connecté produit de manière déterministe une illustration DiceBear (style adventurer) unique et stable.
- [ ] En mode hors ligne, le widget affiche un fallback élégant avec les initiales de l'utilisateur sur une couleur de fond déterministe.
- [ ] Les imports utilisent strictement le package correct `kased_app`.
- [ ] `flutter analyze` s'achève avec 0 erreur.
