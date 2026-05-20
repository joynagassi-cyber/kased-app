# Plan d'Implémentation : Audit & Correction UX Lumina

## Objectif
Mettre l'application en conformité avec les contraintes strictes de `UX-Lumina.md`.
1. Remplacer tous les `CircularProgressIndicator` par des Skeletons Shimmer.
2. Éliminer les couleurs hardcodées au profit du thème Lumina.
3. Préparer l'internationalisation (l10n).

## Technos
- Flutter / Dart
- Shimmer package
- Riverpod (State management)

## Fichiers modifiés
- `lib/features/bible/plans/widgets/pdf_reward_reader.dart`
- `lib/core/widgets/loading_dots.dart`
- Audit global de `lib/`

## Micro-tâches
- [ ] Task 1 : Audit exhaustif des spinners (grep)
- [ ] Task 2 : Création/Vérification du composant Skeleton standard
- [ ] Task 3 : Remplacement dans `PdfRewardReader`
- [ ] Task 4 : Audit des couleurs hardcodées `Colors.xxx`
- [ ] Task 5 : Rapport final dans `LUMINA_FIXES.md`

## Tests
- Vérification visuelle sur simulateur
- Tests unitaires des widgets modifiés
