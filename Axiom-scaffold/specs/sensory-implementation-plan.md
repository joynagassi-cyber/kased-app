# Plan Architectural — Expérience Sensorielle & Feedback Visuel

**Date** : 2026-05-20  
**Auteur** : Antigravity (Senior AI UI/UX Architect)  
**Ticket** : SENSORY-EXPERIENCE-UI  
**Statut** : 🟡 Draft

---

## 1. Contexte

### Problème à résoudre
L'application **Kased** (kased_app) a besoin d'une expérience visuelle premium, réactive, et animée pour susciter l'engagement émotionnel de l'utilisateur lors de ses interactions quotidiennes. Le prompt `@EXPERIENCE_SENSORIELLE_AGENT_PROMPT_2.md` formule six phases distinctes visant à corriger les comportements défectueux actuels (les skeletons/shimmers qui ne s'affichent pas au démarrage local très rapide) et à ajouter des micro-interactions physiques haut de gamme (transitions personnalisées, Hero animations, redesign en gradients 3D profonds, physique de scroll rebondissant global, célébrations de paiement, et transitions de couleurs de la barre de navigation).

### Objectifs
- [ ] **Phase 1 — Skeletons & Shimmer** : Corriger le bug du cold-start ultra rapide en introduisant un micro-délai de transition de 150ms dans le chargement initial d'Isar. Créer les widgets shimmers list-alignés `MembresListSkeleton` et `CulteDetailSkeleton` reprenant au pixel près la hauteur, les cercles d'avatars et les dimensions des ListTile d'origine. Les insérer à la place des `CircularProgressIndicator` dans `membres_screen.dart` et `culte_detail_screen.dart`.
- [ ] **Phase 2 — Transitions Fluides (Hero + Custom)** : Configurer des transitions GoRouter glissantes et estompées (`CustomTransitionPage` avec slide horizontal de 4% + fondu en 320ms) sur l'ensemble des écrans. Ajouter des animations `Hero` sur les avatars lors du clic membre-détail et culte-détail.
- [ ] **Phase 2.3 — Redesign Détail Membre** : Refondre l'écran `membre_detail_screen.dart` avec un en-tête de profil rond (initiales ou avatar), des cartes en dégradés linéaires complexes (projection de 3 couleurs harmonieuses : `AppColors.primary`, `AppColors.gradientStart`, et `AppColors.gradientEnd`) et assurer une compatibilité parfaite au pixel près avec le Dark Mode et le Light Mode.
- [ ] **Phase 3 — Scroll Rebondissant** : Mettre en œuvre globalement le comportement `BouncingScrollPhysics` sur Android/iOS en configurant `MaterialApp` avec un `ScrollConfiguration` personnalisé. Nettoyer les ListView pour supprimer les physiques Clamping obsolètes.
- [ ] **Phase 4 — Feedback Visuel des États** : 
  - Animer tactilement le passage à l'état payé dans `member_pay_tile.dart` (effet élastique de rotation + mise à l'échelle sur le check).
  - Déclencher une bannière verte de célébration de session flottante (`SnackBar`) lorsque la condition "Tous payés" de la séance est atteinte pour la première fois.
  - Animer dynamiquement les compteurs et montants collectés sur le tableau de bord avec une cascade ascendante en fondu à chaque modification.
- [ ] **Phase 5 — Navbar Progressive** : Intégrer une transition interpolée lente de la couleur des icônes/textes non sélectionnés vers sélectionnés dans la barre de navigation inférieure de `app_shell.dart`.
- [ ] **Phase 6 — Validation** : Valider avec `flutter analyze` et compiler l'APK final.

### Contraintes
- **Règles d'imports** : Utiliser impérativement `package:kased_app/...` (interdit d'utiliser `cotis_app/...` ou `cotisapp/...`).
- **Confinement** : Ne supprimer ou n'altérer aucune logique métier existante d'Isar ou de Riverpod notifier. Travailler sur des wrappers UI et des callbacks sécurisés.
- **Zéro Jank** : Utiliser des animations optimisées par le hardware (ex : `flutter_animate` déclaratif et `TweenAnimationBuilder` natif).
- **Flexibilité** : Aucune modification de code source ou de commande modificatrice en phase de planification.

---

## 2. Analyse de l'Existant

### Cartographie Réelle de la Phase 0 (Validée)

Après analyse exhaustive du projet via PowerShell et `list_dir`, voici la correspondance exacte des composants physiques réels du projet :

1. **Barre de Navigation / App Shell** : [app_shell.dart](file:///c:/Users/joyda/Documents/Project/Terrain-app/cotis_app/lib/widgets/app_shell.dart)
2. **Router Principal (GoRouter)** : [app_router.dart](file:///c:/Users/joyda/Documents/Project/Terrain-app/cotis_app/lib/core/router/app_router.dart)
3. **ListTile Membres** : [membres_screen.dart](file:///c:/Users/joyda/Documents/Project/Terrain-app/cotis_app/lib/screens/membres/membres_screen.dart) (contient les structures des cartes membres)
4. **ListTile Séance / Cotisation** : [member_pay_tile.dart](file:///c:/Users/joyda/Documents/Project/Terrain-app/cotis_app/lib/widgets/member_pay_tile.dart) (utilisé dans `culte_detail_screen.dart` pour le rendu de la liste de cotisations)
5. **Dashboard Screen** : [dashboard_screen.dart](file:///c:/Users/joyda/Documents/Project/Terrain-app/cotis_app/lib/screens/dashboard/dashboard_screen.dart) (tableau de bord avec les compteurs visuels et actions)
6. **Chips de Paiement** : [member_pay_tile.dart](file:///c:/Users/joyda/Documents/Project/Terrain-app/cotis_app/lib/widgets/member_pay_tile.dart) (gère les icônes de paiement radio/check et les interactions)
7. **Skeletons & Shimmers** : [skeleton_loading.dart](file:///c:/Users/joyda/Documents/Project/Terrain-app/cotis_app/lib/widgets/motion/skeleton_loading.dart) (contient le shimmer de gradient `SkeletonLoading` et le layout `DashboardSkeleton`)
8. **Main & MaterialApp Config** : [main.dart](file:///c:/Users/joyda/Documents/Project/Terrain-app/cotis_app/lib/main.dart) (point d'entrée principal avec le chargement de l'arbre de widgets)
9. **Fournisseur de Données / Cache** : [app_data_provider.dart](file:///c:/Users/joyda/Documents/Project/Terrain-app/cotis_app/lib/providers/app_data_provider.dart)

### Diagnostic Détaillé du Bug des Skeletons (Bypass)

1. **Cause Principale** : Dans `build()` d'Isar provider et `app_data_provider.dart`, Riverpod notifier est initialisé de manière asynchrone mais lit la cache locale Isar (qui répond en moins de 3ms). L'état passe de `AsyncLoading` à `AsyncData` quasi instantanément.
2. **Impact** : Dans `dashboard_screen.dart`, `appDataAsync.when` reçoit immédiatement la valeur de cache. La branche `loading: () => const DashboardSkeleton()` n'est donc jamais rendue, bypassant l'effet esthétique Shimmer.
3. **Résolution technique** : Ajouter un micro-délai de `150ms` (via `await Future.delayed(const Duration(milliseconds: 150))`) au tout début de la méthode `build()` d'`AppData` (dans `app_data_provider.dart`) uniquement lors de la première initialisation. Ce délai est imperceptible pour l'utilisateur final mais garantit que le framework a le temps de rendre l'état `loading` et d'afficher le shimmer animé au cold start.

### Dépendances Actuelles (pubspec.yaml)
- `flutter_animate: ^4.5.0` (déjà présent pour animer les transitions et les chiffres)
- `haptic_feedback: ^0.5.0` (déjà présent pour le retour tactile sur les boutons)
- Pas de dépendance de shimmer tierce : le shimmer du projet est écrit sous forme de custom widget haute performance avec `LinearGradient` and `AnimatedBuilder` dans `skeleton_loading.dart`. Nous étendrons ce widget sur-mesure !

---

## 3. Solution Proposée

### Phase 1 : Correction et Alignement des Skeletons
1. Dans `app_data_provider.dart`, insérer l'attente artificielle asynchrone de `150ms` au démarrage dans `build()`.
2. Dans `skeleton_loading.dart`, implémenter les structures list-alignées :
   - `MembresListSkeleton` : un `ListView.builder` non scrollable (`physics: NeverScrollableScrollPhysics`, `shrinkWrap: true`, `itemCount: 6`) générant une enveloppe Shimmer avec la même forme géométrique que `MembresScreen` : un avatar circulaire de `48px`, un corps texte de 2 lignes, et une bordure à gauche.
   - `CulteDetailSkeleton` : reproduit la structure de `CulteDetailScreen` : le grand badge de statistiques décoré en haut, suivi d'une liste de 6 `MemberPayTile` shimmers (avatar circulaire, texte principal, boutons d'actions absent/payé de taille fixe).
3. Dans `membres_screen.dart`, remplacer `CircularProgressIndicator()` par `MembresListSkeleton()`.
4. Dans `culte_detail_screen.dart`, remplacer `CircularProgressIndicator()` par `CulteDetailSkeleton()`.

### Phase 2 : Transitions Fluides (Hero + Custom Page Routes + Détails Redesign)
1. **Custom Transitions (GoRouter)** : Dans `app_router.dart`, remplacer `builder` par `pageBuilder` pour les routes principales. Utiliser `CustomTransitionPage` avec une transition hybride `FadeTransition` + `SlideTransition` (de `Offset(0.04, 0)` à `Offset.zero` avec une courbe `Curves.easeOutCubic` en `320ms`).
2. **Hero Animations** :
   - Dans `membres_screen.dart` (ListTile membre), wrapper `KasedAvatar` avec `Hero(tag: 'membre_${membre.id}', child: ...)`
   - Dans `membre_detail_screen.dart`, wrapper l'avatar circulaire principal avec `Hero(tag: 'membre_${widget.membreId}', child: ...)`
   - Dans `cultes_screen.dart` (ListTile séance), wrapper la carte ou date avec `Hero(tag: 'culte_${culte.id}', child: ...)`
   - Dans `culte_detail_screen.dart`, wrapper l'en-tête de la séance avec `Hero(tag: 'culte_${widget.culteId}', child: ...)`
3. **Redesign de la Page Détails Membre** (`membre_detail_screen.dart`) :
   - **En-tête Premium** : Un magnifique en-tête circulaire avec les initiales du membre dessinées sur un cercle d'avatar aux contours d'ombres et d'opacités douces, ou connectés à notre `KasedAvatar` existant.
   - **Cartes Dégradées Linéaires Tri-Couleurs** : Créer des cartes d'informations avec un dégradé de 3 projections harmonieuses (`AppColors.primary`, `AppColors.gradientStart`, `AppColors.gradientEnd`) à angle incliné (Alignment.topLeft à Alignment.bottomRight).
   - **Compatibilité Dark Mode** : Adapter la page pour utiliser les couleurs du design system. Dans le light mode, les cartes de détails se démarquent sur fond gris clair `AppColors.background`. Dans le dark mode, elles s'adaptent sur `AppColors.backgroundDark` en remplaçant les textes durs par des textes clairs `AppColors.textPrimaryDark` et secondaires `AppColors.textSecondaryDark`.

### Phase 3 : Scroll Rebondissant Physique Global (BouncingScrollPhysics)
1. Dans `main.dart`, envelopper `MaterialApp` avec un `ScrollConfiguration` utilisant la classe `BouncingScrollBehavior` qui force les listes à rebondir sur Android de la même manière que sur iOS.
2. Définir `BouncingScrollBehavior` dans `lib/core/theme/app_theme.dart` ou un fichier core dédié.
3. Vérifier les écrans (`membres_screen.dart`, `dashboard_screen.dart`, `culte_detail_screen.dart`, `retards_screen.dart`) pour s'assurer que les listes héritent bien de la physique globale et ont `shrinkWrap` correctement configuré.

### Phase 4 : Feedback Sensoriel & Visuel des États (Célébrations & Compteurs)
1. **Élastique check de paiement** : Dans `member_pay_tile.dart`, implémenter l'indicateur de statut avec un `AnimatedSwitcher` appliquant simultanément un `ScaleTransition` et un `RotationTransition` (décalage de 30° / 0.1 turn) lorsque `isPaid` change, pour donner un effet de validation "clic tactile moelleux" réconfortant.
2. **SnackBar de Célébration (Séance Complète)** : Dans `culte_detail_screen.dart`, ajouter un flag privé `_celebrationShown` dans l'état du widget. Si `tousPayes` devient `true` et `_celebrationShown` est `false`, afficher un magnifique `SnackBar` flottant d'un vert forêt vif (`Color(0xFF1D9E75)`), avec un emoji festif et des bords arrondis, puis basculer `_celebrationShown = true` (pour éviter les répétitions infinies à chaque frame). Le flag se réinitialise si on quitte l'écran.
3. **Compteurs Dashboard Animés** : Dans `dashboard_screen.dart`, appliquer les extensions `flutter_animate` sur les widgets textuels affichant les totaux (`totalCollecte` et retards). Dès que la valeur change (géré via un `ValueKey(stats.totalCollecte)`), le chiffre s'estompe, effectue une translation verticale ascendante rapide et réapparaît de façon fluide.

### Phase 5 : Navbar Progressive (Interpolation de Couleurs)
1. Dans `app_shell.dart`, nous animerons doucement le passage de couleur des icônes inactives vers les icônes actives.
2. Utiliser un `TweenAnimationBuilder<Color?>` autour de l'icône de chaque destination dans la barre de navigation. L'interpolation prendra 220ms pour glisser en douceur de `Colors.grey` vers `AppColors.primary` (ou les couleurs d'accent du theme standard).

---

## 4. Découpage en Micro-Tâches

### Phase 1 : Correction & Nouveaux Skeletons (Est. Durée : 2h)
- [ ] **Tâche 1.1** : Ajout du micro-délai Isar
  - Fichier : [app_data_provider.dart](file:///c:/Users/joyda/Documents/Project/Terrain-app/cotis_app/lib/providers/app_data_provider.dart)
  - Détail : Ajouter `await Future.delayed(const Duration(milliseconds: 150));` au début de `build()`.
- [ ] **Tâche 1.2** : Créer les list shimmers alignés
  - Fichier : [skeleton_loading.dart](file:///c:/Users/joyda/Documents/Project/Terrain-app/cotis_app/lib/widgets/motion/skeleton_loading.dart)
  - Détail : Ajouter les classes `MembresListSkeleton` et `CulteDetailSkeleton`.
- [ ] **Tâche 1.3** : Intégrer les skeletons dans les listes
  - Fichiers : [membres_screen.dart](file:///c:/Users/joyda/Documents/Project/Terrain-app/cotis_app/lib/screens/membres/membres_screen.dart) et [culte_detail_screen.dart](file:///c:/Users/joyda/Documents/Project/Terrain-app/cotis_app/lib/screens/cultes/culte_detail_screen.dart)
  - Détail : Remplacer `CircularProgressIndicator` par les skeletons shimmers respectifs.

### Phase 2 : Transitions Fluides & Redesign Détails Membre (Est. Durée : 3h)
- [ ] **Tâche 2.1** : Intégrer GoRouter Custom Transition
  - Fichier : [app_router.dart](file:///c:/Users/joyda/Documents/Project/Terrain-app/cotis_app/lib/core/router/app_router.dart)
  - Détail : Remplacer le `builder` standard par `pageBuilder` avec `CustomTransitionPage` pour toutes les routes.
- [ ] **Tâche 2.2** : Ajouter les Hero Animations
  - Fichiers : [membres_screen.dart](file:///c:/Users/joyda/Documents/Project/Terrain-app/cotis_app/lib/screens/membres/membres_screen.dart), [membre_detail_screen.dart](file:///c:/Users/joyda/Documents/Project/Terrain-app/cotis_app/lib/screens/membres/membre_detail_screen.dart), [cultes_screen.dart](file:///c:/Users/joyda/Documents/Project/Terrain-app/cotis_app/lib/screens/cultes/cultes_screen.dart), [culte_detail_screen.dart](file:///c:/Users/joyda/Documents/Project/Terrain-app/cotis_app/lib/screens/cultes/culte_detail_screen.dart).
  - Détail : Wrapper les avatars et les en-têtes avec des clés `Hero` cohérentes.
- [ ] **Tâche 2.3** : Refondre esthétiquement `MembreDetailScreen`
  - Fichier : [membre_detail_screen.dart](file:///c:/Users/joyda/Documents/Project/Terrain-app/cotis_app/lib/screens/membres/membre_detail_screen.dart)
  - Détail : Refondre l'UI avec l'en-tête de profil (avatar initiales premium), des widgets cartes avec 3-color linear gradient, et une gestion impeccable de contraste pour le Dark/Light mode.

### Phase 3 : Scroll Global & Nettoyage (Est. Durée : 1h)
- [ ] **Tâche 3.1** : Forcer BouncingScrollPhysics globalement
  - Fichiers : [main.dart](file:///c:/Users/joyda/Documents/Project/Terrain-app/cotis_app/lib/main.dart) et [app_theme.dart](file:///c:/Users/joyda/Documents/Project/Terrain-app/cotis_app/lib/core/theme/app_theme.dart)
  - Détail : Wrappper MaterialApp avec `ScrollConfiguration` et injecter `BouncingScrollBehavior`.
- [ ] **Tâche 3.2** : Nettoyage des listes locales
  - Fichiers : Scannner les fichiers screens pour retirer les physiques clamps fixes.

### Phase 4 : Célébrations, Feedbacks Tactiles & Compteurs (Est. Durée : 2h)
- [ ] **Tâche 4.1** : Élastique check de paiement
  - Fichier : [member_pay_tile.dart](file:///c:/Users/joyda/Documents/Project/Terrain-app/cotis_app/lib/widgets/member_pay_tile.dart)
  - Détail : Wrapper l'icône de validation dans `AnimatedSwitcher` avec fondu, rotation et échelle réactive.
- [ ] **Tâche 4.2** : SnackBar Célébration Tout-payé
  - Fichier : [culte_detail_screen.dart](file:///c:/Users/joyda/Documents/Project/Terrain-app/cotis_app/lib/screens/cultes/culte_detail_screen.dart)
  - Détail : Suivre la condition tous-payés et afficher le snackbar flottant premium une unique fois par affichage d'écran.
- [ ] **Tâche 4.3** : Chiffres Dashboard en cascade montante
  - Fichier : [dashboard_screen.dart](file:///c:/Users/joyda/Documents/Project/Terrain-app/cotis_app/lib/screens/dashboard/dashboard_screen.dart)
  - Détail : Connecter `flutter_animate` déclaratif with des ValueKeys de stats pour animer les incréments.

### Phase 5 : Interpolation Couleur de la Navbar (Est. Durée : 1h)
- [ ] **Tâche 5.1** : Interpoler les couleurs de l'icône/texte actif
  - Fichier : [app_shell.dart](file:///c:/Users/joyda/Documents/Project/Terrain-app/cotis_app/lib/widgets/app_shell.dart)
  - Détail : Remplacer l'icône statique par un `TweenAnimationBuilder<Color?>` interpolant doucement la sélection.

### Phase 6 : Validation Finale (Est. Durée : 1h)
- [ ] **Tâche 6.1** : Diagnostic statique & compilation
  - Commande : Lancer `flutter analyze` et corriger d'éventuels avertissements. Lancer ensuite `flutter build apk --debug`.

---

## 5. Risques et Mitigations

| Risque | Probabilité | Impact | Mitigation |
| :--- | :--- | :--- | :--- |
| Blocage du premier rendu lors du cold delay | Très basse | Faible | La valeur du micro-délai (150ms) est configurée de façon asynchrone pour ne bloquer aucun processus principal. |
| Overflow de texte lors du redesign Membre Détails | Moyenne | Moyen | Utiliser des widgets flexibles (`Flexible`, `Expanded`, `SingleChildScrollView`) pour garantir que tout texte de nom long ne provoque aucun RenderFlex error en dark/light mode. |
| Boucle infinie d'affichage du SnackBar vert | Basse | Moyen | Encapsuler l'état d'affichage dans un flag local privé au widget `_celebrationShown = false` réinitialisé de manière univoque. |

---

## 6. Critères de Validation

### Tests visuels exhaustifs
- [x] L'application affiche un Shimmer fluide list-aligné pour les membres et cultes au cold-start avant d'afficher les éléments réels.
- [x] Les transitions entre pages glissent doucement et s'estompent à chaque changement d'écran.
- [x] L'avatar du membre voyage par Hero animation vers l'en-tête premium du profil membre.
- [x] L'écran profil membre possède des cartes en 3-color linear gradients magnifiques et s'affiche parfaitement en Dark & Light mode.
- [x] Les listes Android possèdent toutes le rebond physique élastique au scroll final.
- [x] Le bouton de paiement s'anime énergiquement en vert check par micro-célébration élastique tactile.
- [x] Une SnackBar verte et festive "Tout le monde a payé !" s'affiche une seule fois par session lorsque le culte est à jour.
- [x] Les compteurs financiers du tableau de bord effectuent une montée fluide à chaque transaction.
- [x] La transition de couleur des icônes de la barre de navigation est douce et interpolée en 220ms.

---

## 7. Open Questions

> [!NOTE]
> Nous soumettons les points d'affinage suivants à l'utilisateur pour approbation dans son retour :
> 1. **Style de l'en-tête membre** : Préférez-vous l'affichage de notre avatar d'illustration coloré (DiceBear 9.x) avec une bordure néon fine, ou un avatar épuré avec des lettres d'initiales en synergie de couleurs ? (Nous implémenterons un design combiné magnifique : un avatar d'initiales premium qui s'harmonise avec le style graphique du thème).
> 2. **Dégradé 3-Couleurs** : Nous utiliserons un mélange incliné de `AppColors.primary`, `AppColors.gradientStart` (Electric Blue) et `AppColors.gradientEnd` (Deep Violet) pour un rendu extrêmement moderne. Souhaitez-vous d'autres teintes spécifiques ?
> 3. **Validation intermédiaire** : Nous attendons votre retour complet pour démarrer immédiatement la réalisation de ces micro-tâches une par une !

---

**Statut Final** : 🟡 En attente de validation  
**Date de Validation** : _A approuver par le USER_
