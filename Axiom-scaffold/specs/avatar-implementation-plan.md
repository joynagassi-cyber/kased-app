# Plan Architectural — Automatic Avatar Illustrations (API v9.x)

**Date** : 2026-05-20  
**Auteur** : Antigravity (AI UI/UX Architect)  
**Ticket** : AVATAR-ILLUSTRATION-API  
**Statut** : 🟢 Approuvé (En cours d'exécution)

---

## 1. Contexte

### Problème à résoudre
L'application **Kased** (kased_app) nécessite une solution esthétique et automatique pour afficher l'avatar/l'illustration de profil de chaque utilisateur authentifié (par exemple, le secrétaire ou l'administrateur). L'illustration doit être générée de manière déterministe à partir de l'adresse email de l'utilisateur en utilisant l'API **DiceBear** (style *adventurer*). Cela ne doit nécessiter aucun stockage dans le cloud ni configuration complexe, et doit fonctionner de manière fluide hors ligne grâce au cache local.

### Objectifs
- [ ] Ajouter la dépendance `cached_network_image` au fichier `pubspec.yaml` et exécuter `flutter pub get`.
- [ ] Créer `AvatarService` dans `lib/core/avatar_service.dart` pour la génération déterministe d'URL DiceBear **v9.x** et la gestion des fallbacks (initiales et couleur de fond stable).
- [ ] Inclure un registre complet des styles disponibles dans le code pour permettre un changement de design instantané.
- [ ] Créer le widget réutilisable `UserAvatar` dans `lib/widgets/user_avatar.dart`.
- [ ] Remplacer l'avatar générique `Icon(Icons.person)` par `UserAvatar` dans le `AppDrawer` (`lib/widgets/app_drawer.dart`).
- [ ] Remplacer l'avatar générique `Icon(Icons.person)` par `UserAvatar` dans l'écran de profil (`lib/screens/profile/profile_screen.dart`).
- [ ] S'assurer que le système est déterministe, résilient hors ligne, et que `flutter analyze` et `build_runner` tournent sans erreur.

### Contraintes
- **Respect du style de codage** : Utiliser impérativement `package:kased_app/...` pour tous les imports internes.
- **Déterminisme** : Même email = même illustration/couleur/initiales à chaque fois.
- **Résilience hors ligne** : Utilisation automatique du cache local et fallback propre (initiales + couleur stable) si le cache est vide et qu'il n'y a pas de réseau.

---

## 2. Analyse de l'Existant

### Composants Impactés
- `cotis_app/pubspec.yaml` : Ajout de la dépendance `cached_network_image: ^3.3.1`.
- `cotis_app/lib/core/avatar_service.dart` [NEW] : Service de calcul d'URL (API v9.x) et de fallbacks de couleur/initiales.
- `cotis_app/lib/widgets/user_avatar.dart` [NEW] : Widget d'avatar réutilisable avec mise en cache réseau.
- `cotis_app/lib/widgets/app_drawer.dart` : Remplacement du placeholder `Icon(Icons.person)` par `UserAvatar`.
- `cotis_app/lib/screens/profile/profile_screen.dart` : Remplacement du placeholder `Icon(Icons.person)` par `UserAvatar`.

### Dépendances
```
 [AppDrawer] / [ProfileScreen]
             │
             ▼
        [UserAvatar]
             │
             ▼
      [AvatarService]
             │
             ▼
   [cached_network_image]
```

### Patterns Existants
- **Riverpod State Management** : `ref.watch(authProvider).userEmail` contient l'email de l'utilisateur authentifié sous forme de `String?`.

---

## 3. Solution Proposée

### Vue d'Ensemble
Nous utiliserons l'API publique et gratuite DiceBear **v9.x** avec le style `adventurer` pour obtenir des illustrations d'avatars de haute qualité de façon déterministe en passant l'email de l'utilisateur encodé en URL comme graine (`seed`). 

Les images générées au format SVG/PNG seront chargées et mises en cache localement par `cached_network_image`. En cas d'erreur de chargement (ex: premier démarrage sans connexion réseau), le widget affichera un fallback de haute qualité avec les initiales de l'utilisateur sur un fond de couleur stable et harmonieuse généré à partir du hachage de l'email.

### Registre des Styles DiceBear (API v9.x)
Le code de `AvatarService` inclura la liste complète des styles officiels supportés par DiceBear v9.x, avec `adventurer` activé par défaut (le plus adapté pour kased-app avec ses variations riches et distinctes) :
- `adventurer` (Choix par défaut - personnages mémorables)
- `adventurer-neutral`
- `avataaars`
- `avataaars-neutral`
- `big-ears`
- `big-ears-neutral`
- `big-smile`
- `bottts`
- `bottts-neutral`
- `croodles`
- `croodles-neutral`
- `dylan`
- `fun-emoji`
- `glass`
- `icons`
- `identicon`
- `initials`
- `lorelei` (Style élégant disponible)
- `lorelei-neutral`
- `micah`
- `miniavs`
- `notionists` (Style professionnel minimaliste disponible)
- `notionists-neutral`
- `open-peeps`
- `personas`
- `pixel-art`
- `pixel-art-neutral`
- `rings`
- `shapes`
- `thumbs`
- `toon-head`

### Flux de Données
1. L'application récupère l'email de l'utilisateur depuis `authProvider` (`AuthState.userEmail`).
2. Si l'email est présent, `UserAvatar` appelle `AvatarService.generateFromEmail(email)` pour obtenir l'URL DiceBear.
3. `CachedNetworkImage` tente de charger l'image depuis le cache local ou à défaut depuis le réseau, puis l'affiche sous forme de cercle.
4. En cas d'échec de chargement initial sans réseau, `UserAvatar` affiche les initiales générées par `AvatarService.initialsFromEmail(email)` avec un fond de couleur déterministe issu de `AvatarService.colorFromEmail(email)`.

---

## 4. Découpage en Micro-Tâches

### Phase 1 : Dépendances et Service d'Avatar
- [ ] **Tâche 1.1** : Configurer la dépendance `cached_network_image`
  - Fichier : `cotis_app/pubspec.yaml`
  - Changement : Ajouter `cached_network_image: ^3.3.1` sous dependencies. Exécuter `flutter pub get`.
- [ ] **Tâche 1.2** : Créer le service `AvatarService` avec registre complet des styles
  - Fichier : `cotis_app/lib/core/avatar_service.dart` [NEW]
  - Changement : Implémenter les méthodes `generateFromEmail`, `initialsFromEmail`, et `colorFromEmail` ciblant `https://api.dicebear.com/9.x/`.
- [ ] **Tâche 1.3** : Créer le widget `UserAvatar`
  - Fichier : `cotis_app/lib/widgets/user_avatar.dart` [NEW]
  - Changement : Implémenter le widget d'affichage d'avatar avec support `CachedNetworkImage` et fallback d'initiales colorées.

### Phase 2 : Intégration
- [ ] **Tâche 2.1** : Intégration dans `AppDrawer`
  - Fichier : `cotis_app/lib/widgets/app_drawer.dart`
  - Changement : Remplacer l'icône de profil statique par le widget `UserAvatar` configuré avec l'email réel issu de l'état d'authentification.
- [ ] **Tâche 2.2** : Intégration dans `ProfileScreen`
  - Fichier : `cotis_app/lib/screens/profile/profile_screen.dart`
  - Changement : Mettre à jour l'en-tête du profil pour utiliser `UserAvatar` de grande taille (radius: 38) au lieu du placeholder `Icon(Icons.person)`.

### Phase 3 : Validation
- [ ] **Tâche 3.1** : Analyse statique
  - Commande : `flutter analyze` pour s'assurer que le code est totalement exempt d'erreurs/avertissements.
- [ ] **Tâche 3.2** : Build de test
  - Commande : `dart run build_runner build -d` suivi de `flutter build apk --debug`.

---

## 5. Risques et Mitigations

| Risque | Probabilité | Impact | Mitigation |
| :--- | :--- | :--- | :--- |
| API DiceBear inaccessible temporairement | Faible | Faible | Le fallback d'initiales avec couleur stable assure que l'application reste esthétique et utilisable sans interruption. |
| Incompatibilité SVG dans `cached_network_image` | Moyenne | Faible | DiceBear supporte l'export PNG. Si le rendu SVG pose problème, nous pourrons facilement basculer l'extension d'URL vers `/png` au lieu de `/svg` dans `AvatarService`. |

---

## 6. Critères de Validation

### Tests
- [ ] Même adresse email produit systématiquement la même illustration Dicebear.
- [ ] Hors ligne, l'avatar affiche des initiales sur fond de couleur stable.
- [ ] `flutter analyze` returns 0 warnings/errors.
- [ ] La compilation s'effectue avec succès.

---

## 7. Approbation
- [x] Utilisateur (Approuvé le 2026-05-20)
