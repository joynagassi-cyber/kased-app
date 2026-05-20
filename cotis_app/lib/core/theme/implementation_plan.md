# Refonte UI/UX "Modern Soft UI" - KASED-APP

L'objectif est d'appliquer un design moderne, épuré, basé sur des cartes, des ombres douces (Soft UI) et une palette dynamique centrée sur le **Bleu Électrique** combiné à une couleur de transition pour créer de superbes dégradés.

## User Review Required
> [!IMPORTANT]
> Veuillez valider la combinaison de couleurs pour le dégradé. Le bleu électrique sera la base, et je propose de le combiner avec un **Violet Profond (Royal Purple)** ou un **Cyan Vif** pour le dégradé des cartes principales. Le vert sera totalement évité.

## Open Questions
> [!NOTE]
> 1. Pour les avatars des membres dans les listes, avons-nous des photos dans la base de données, ou voulons-nous utiliser des cercles colorés avec les initiales (ex: "JD" pour John Doe) ?
> 2. Souhaitez-vous que le Dark Mode soit également mis à jour avec ces nouvelles palettes, ou nous concentrons-nous sur le Light Mode d'abord ?

## Proposed Changes

---
### Theme & Core (Charte Graphique)

#### [MODIFY] [app_theme.dart](file:///c:/Users/joyda/Documents/Project/Terrain-app/cotis_app/lib/core/theme/app_theme.dart)
- Mise à jour de `AppColors` pour introduire :
  - `primary`: Bleu Électrique (`#2962FF`).
  - `gradientEnd`: Violet (`#7C4DFF`) ou Cyan, pour les effets dégradés.
  - Ajustement du background (`#F8F9FE`) pour faire ressortir les cartes blanches.
- Mise à jour des `CardTheme` et `InputDecorationTheme` pour utiliser des `borderRadius` plus importants (ex: 20px ou 24px) et des ombres ultra-douces.

---
### Composants Réutilisables (Design System)

Nous allons créer une série de widgets de base qui seront réutilisés dans toute l'application.

#### [NEW] [kased_card.dart](file:///c:/Users/joyda/Documents/Project/Terrain-app/cotis_app/lib/widgets/kased_card.dart)
- Conteneur de base blanc, bords très arrondis (24px).
- Ombre diffuse (couleur gris bleuté très claire avec un grand `blurRadius`).

#### [NEW] [kased_gradient_card.dart](file:///c:/Users/joyda/Documents/Project/Terrain-app/cotis_app/lib/widgets/kased_gradient_card.dart)
- Basée sur `KasedCard` mais avec le background en dégradé (Bleu Électrique vers Violet/Cyan).
- Texte blanc contrasté, parfait pour afficher le total des cotisations.

#### [NEW] [kased_status_badge.dart](file:///c:/Users/joyda/Documents/Project/Terrain-app/cotis_app/lib/widgets/kased_status_badge.dart)
- Widget "pilule" pour indiquer les statuts (ex: Payé/Non Payé) avec un fond pastel et texte foncé.

#### [NEW] [kased_smooth_chart.dart](file:///c:/Users/joyda/Documents/Project/Terrain-app/cotis_app/lib/widgets/kased_smooth_chart.dart)
- Wrapper autour de `fl_chart` pour afficher des courbes fluides (isCurved: true) avec un remplissage dégradé sous la ligne.

---
### Écrans (Screens)

#### [MODIFY] [dashboard_screen.dart](file:///c:/Users/joyda/Documents/Project/Terrain-app/cotis_app/lib/screens/dashboard/dashboard_screen.dart)
- Remplacement du widget affichant le total des collectes par la `KasedGradientCard`.
- Restructuration des statistiques rapides (cultes, taux de participation) en une grille (2x2) de petites cartes carrées.
- Intégration du graphique d'évolution en version courbe lissée.

#### [MODIFY] [stats_screen.dart](file:///c:/Users/joyda/Documents/Project/Terrain-app/cotis_app/lib/screens/stats/stats_screen.dart)
- Remplacement des graphiques basiques par des `fl_chart` (BarChart pour les mois, PieChart/Donut pour les répartitions).

#### [MODIFY] [cultes_screen.dart](file:///c:/Users/joyda/Documents/Project/Terrain-app/cotis_app/lib/screens/cultes/cultes_screen.dart) et `culte_detail_screen.dart`
- Mise à jour des `ListView` : chaque ligne (Culte ou Membre) deviendra une carte élégante avec avatars/icônes rondes et badges de statuts.

## Verification Plan

### Automated Tests
- Lancer le pipeline de tests unitaires pour s'assurer qu'aucun changement UI n'a cassé la logique d'état Riverpod.

### Manual Verification
- Naviguer sur le Dashboard pour valider le rendu du dégradé et des ombres.
- Vérifier la fluidité des graphiques (fl_chart) lors de l'affichage des données.
- S'assurer que le contraste des textes sur le dégradé bleu électrique permet une lecture claire (Accessibilité).
