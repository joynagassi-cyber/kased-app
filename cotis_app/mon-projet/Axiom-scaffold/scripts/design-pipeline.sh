#!/usr/bin/env bash

###############################################################################
# design-pipeline.sh
#
# Pipeline de design automatisé pour Axiom-Scaffold.
# Orchestre la sélection de bibliothèque, la génération de maquettes,
# et la revue Huashu-Design.
#
# Usage:
#   ./scripts/design-pipeline.sh --framework react --style modern --screen login
#   ./scripts/design-pipeline.sh --framework solid --style minimal --screen dashboard
#
# Étapes:
#   1. Sélection de la bibliothèque UI
#   2. Génération des instructions de maquette
#   3. Validation des couleurs
#   4. Revue Huashu-Design (5D)
#   5. Itération jusqu'à score > 0.85
###############################################################################

set -euo pipefail

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
FRAMEWORK=""
STYLE=""
SCREEN=""
ACCESSIBILITY="excellent"
OUTPUT_DIR="design/screens"
REPORT_DIR="design/review/huashu-reports"

###############################################################################
# Fonctions utilitaires
###############################################################################

log_info() {
  echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
  echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
  echo -e "${RED}✗${NC} $1"
}

usage() {
  cat << EOF
Usage: $0 --framework <framework> --style <style> --screen <screen>

Options:
  --framework <framework>    Framework UI (react, solid, etc.)
  --style <style>           Style de design (modern, minimal, playful, etc.)
  --screen <screen>         Nom de l'écran à designer (login, dashboard, etc.)
  --accessibility <level>   Niveau d'accessibilité (excellent, good) [défaut: excellent]
  -h, --help               Afficher cette aide

Exemples:
  $0 --framework react --style modern --screen login
  $0 --framework solid --style minimal --screen dashboard --accessibility good

EOF
  exit 1
}

###############################################################################
# Parse des arguments
###############################################################################

while [[ $# -gt 0 ]]; do
  case $1 in
    --framework)
      FRAMEWORK="$2"
      shift 2
      ;;
    --style)
      STYLE="$2"
      shift 2
      ;;
    --screen)
      SCREEN="$2"
      shift 2
      ;;
    --accessibility)
      ACCESSIBILITY="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      log_error "Option inconnue: $1"
      usage
      ;;
  esac
done

# Validation des arguments
if [[ -z "$FRAMEWORK" ]] || [[ -z "$STYLE" ]] || [[ -z "$SCREEN" ]]; then
  log_error "Arguments manquants"
  usage
fi

###############################################################################
# Étape 1: Sélection de la bibliothèque UI
###############################################################################

log_info "Étape 1/5: Sélection de la bibliothèque UI..."

LIBRARY_RESULT=$(node scripts/select-library.js \
  --framework "$FRAMEWORK" \
  --style "$STYLE" \
  --accessibility "$ACCESSIBILITY")

if [[ $? -ne 0 ]]; then
  log_error "Échec de la sélection de bibliothèque"
  echo "$LIBRARY_RESULT"
  exit 1
fi

LIBRARY_NAME=$(echo "$LIBRARY_RESULT" | jq -r '.selected.name')
LIBRARY_ID=$(echo "$LIBRARY_RESULT" | jq -r '.selected.id')
LIBRARY_URL=$(echo "$LIBRARY_RESULT" | jq -r '.selected.url')

log_success "Bibliothèque sélectionnée: $LIBRARY_NAME ($LIBRARY_ID)"
log_info "Documentation: $LIBRARY_URL"

###############################################################################
# Étape 2: Génération des instructions de maquette
###############################################################################

log_info "Étape 2/5: Génération des instructions de maquette..."

MOCKUP_FILE="$OUTPUT_DIR/${SCREEN}.html"
INSTRUCTIONS_FILE="$OUTPUT_DIR/${SCREEN}.instructions.md"

cat > "$INSTRUCTIONS_FILE" << EOF
# Instructions de Maquette — ${SCREEN}

## Bibliothèque Sélectionnée
- **Nom**: $LIBRARY_NAME
- **ID**: $LIBRARY_ID
- **URL**: $LIBRARY_URL
- **Framework**: $FRAMEWORK
- **Style**: $STYLE

## Contraintes de Design

### Couleurs
- Utiliser UNIQUEMENT les couleurs du design system (design/design-system.json)
- Saturation maximale: 70% en HSL (sauf annotation explicite)
- Contraste minimum: 4.5:1 pour le texte normal

### Typographie
- Utiliser les tokens de typographie du design system
- Hiérarchie claire (h1, h2, h3, body, caption)

### Espacement
- Utiliser les tokens d'espacement du design system
- Grille de 8px (xs=8px, sm=16px, md=24px, lg=32px, xl=48px)

### Animations
- Durée maximale: 300ms
- Easing: cubic-bezier uniquement
- Pas d'animations infinies sans raison

### Accessibilité
- Niveau requis: $ACCESSIBILITY
- ARIA labels sur tous les éléments interactifs
- Navigation au clavier complète
- Support des lecteurs d'écran

## Composants Recommandés

Consulter la documentation de $LIBRARY_NAME pour les composants disponibles:
$LIBRARY_URL

## Validation

Après génération de la maquette, exécuter:
\`\`\`bash
node scripts/validate-colors.js $MOCKUP_FILE
\`\`\`

## Revue Huashu-Design

La maquette sera évaluée selon 5 dimensions:
1. **Layout** (hiérarchie, grille, espacement)
2. **Typographie** (hiérarchie, lisibilité, cohérence)
3. **Couleur** (palette, contraste, harmonie)
4. **Mouvement** (animations, transitions, feedback)
5. **Cohérence** (design system, patterns, accessibilité)

Score minimum requis: 0.85/1.0

EOF

log_success "Instructions générées: $INSTRUCTIONS_FILE"
log_warning "Générer maintenant la maquette HTML: $MOCKUP_FILE"

###############################################################################
# Étape 3: Attente de la maquette
###############################################################################

log_info "Étape 3/5: Attente de la génération de la maquette..."
log_warning "Veuillez générer la maquette HTML et la sauvegarder dans: $MOCKUP_FILE"
log_info "Appuyez sur Entrée une fois la maquette générée..."
read -r

if [[ ! -f "$MOCKUP_FILE" ]]; then
  log_error "Maquette introuvable: $MOCKUP_FILE"
  exit 1
fi

log_success "Maquette trouvée: $MOCKUP_FILE"

###############################################################################
# Étape 4: Validation des couleurs
###############################################################################

log_info "Étape 4/5: Validation des couleurs..."

COLOR_RESULT=$(node scripts/validate-colors.js "$MOCKUP_FILE")
COLOR_SUCCESS=$(echo "$COLOR_RESULT" | jq -r '.success')

if [[ "$COLOR_SUCCESS" == "true" ]]; then
  log_success "Toutes les couleurs sont conformes au design system"
else
  log_error "Certaines couleurs ne sont pas dans le design system"
  echo "$COLOR_RESULT" | jq '.files[0].unauthorized'
  log_warning "Veuillez corriger les couleurs et relancer le pipeline"
  exit 1
fi

###############################################################################
# Étape 5: Revue Huashu-Design
###############################################################################

log_info "Étape 5/5: Revue Huashu-Design (5D)..."

REPORT_FILE="$REPORT_DIR/${SCREEN}-$(date +%Y%m%d-%H%M%S).json"

log_info "Activation du skill Huashu-Design..."
log_warning "La revue 5D doit être effectuée par l'agent IA"
log_info "Le rapport sera sauvegardé dans: $REPORT_FILE"

cat > "$REPORT_FILE" << EOF
{
  "screen": "$SCREEN",
  "library": "$LIBRARY_NAME",
  "framework": "$FRAMEWORK",
  "style": "$STYLE",
  "mockupFile": "$MOCKUP_FILE",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "pending",
  "scores": {
    "layout": null,
    "typography": null,
    "color": null,
    "motion": null,
    "coherence": null,
    "total": null
  },
  "feedback": [],
  "iteration": 1
}
EOF

log_success "Rapport initialisé: $REPORT_FILE"

###############################################################################
# Résumé
###############################################################################

echo ""
log_success "Pipeline de design terminé avec succès!"
echo ""
echo "Résumé:"
echo "  - Bibliothèque: $LIBRARY_NAME"
echo "  - Maquette: $MOCKUP_FILE"
echo "  - Instructions: $INSTRUCTIONS_FILE"
echo "  - Rapport: $REPORT_FILE"
echo ""
log_info "Prochaines étapes:"
echo "  1. Effectuer la revue Huashu-Design (5D)"
echo "  2. Itérer jusqu'à score > 0.85"
echo "  3. Exporter vers A2UI si nécessaire"
echo ""

exit 0
