# Audit d'Accessibilité WCAG 2.2 — Kased App

## Résumé

| Critère WCAG 2.2 | Score | Problèmes |
|---|---|---|
| **Perceptible** (1.x) | ⚠️ | 81faible contraste, 20 texte illisible |
| **Operable** (2.x) | ❌ | 0Semantics, nav sans labels |
| **Understandable** (3.x) | ⚠️ | États chargement non annoncés |
| **Robust** (4.x) | ✅ | Aucun problème critique |

**Score global: C** — Des correctifs ciblés amélioreront significativement l'accessibilité.

## Problèmes Prioritaires

### P1 — Critique (A)

| # | Critère | Fichier | Problème |
|---|---------|---------|----------|
| 1 | SC 1.4.3 | `lib/widgets/kased_status_badge.dart` | Badges color-only: vert/rouge sans texte descriptif |
| 2 | SC 2.4.6 | `lib/widgets/spring_nav_icon.dart` | Navigation par icône sans label sémantique |
| 3 | SC 2.4.11 | `lib/widgets/app_shell.dart` | 3 IconButton sans tooltip descriptif |
| 4 | SC 4.1.2 | Global | 0utilisation de Semantics/MergeSemantics |

### P2 — Important (AA)

| # | Critère | Fichier | Problème |
|---|---------|---------|----------|
| 5 | SC 1.4.4 | Multiple | 20occurrences de texte fontSize ≤ 11 (illéisible) |
| 6 | SC 1.4.11 | Global | 81occurrences de contraste faible (alpha < 0.6) |
| 7 | SC 2.2.2 | Global | CircularProgressIndicator sans label |
| 8 | SC 3.2.6 | Global | Pas de focus management dans les dialogues |

## Corrections Appliquées

### 1. StatCard — Ajout de semanticLabel
### 2. StatusBadge — Amélioration du contraste et accessibilité
### 3. SpringNavIcon — Utilisation du paramètre label
### 4. AppShell — Tooltips manquants
### 5. Global — Minimum fontSize 12 pour le texte fonctionnel
