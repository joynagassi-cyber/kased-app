#!/bin/bash

# ============================================================
# Axiom-Scaffold – Décomposition de Fonctionnalité
# Découpe une feature en micro-tâches YAML atomiques
# Usage : ./scripts/decompose-feature.sh features/<nom>/feature.yaml
# ============================================================

set -euo pipefail

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Arguments ---
if [ $# -lt 1 ]; then
  echo -e "${RED}❌ Erreur: Fichier feature.yaml manquant${NC}" >&2
  echo "Usage: $0 features/<nom>/feature.yaml" >&2
  exit 1
fi

FEATURE_FILE="$1"

# --- Vérification ---
if [ ! -f "$FEATURE_FILE" ]; then
  echo -e "${RED}❌ Erreur: $FEATURE_FILE introuvable${NC}" >&2
  exit 1
fi

# --- Extraction des informations ---
echo -e "${BLUE}ℹ${NC} Analyse du fichier feature..." >&2

if command -v yq &> /dev/null; then
  FEATURE_NAME=$(yq eval '.feature' "$FEATURE_FILE")
  DESCRIPTION=$(yq eval '.description' "$FEATURE_FILE")
  TARGET_SYMBOLS=$(yq eval '.target_symbols[]' "$FEATURE_FILE")
else
  # Fallback simple
  FEATURE_NAME=$(grep "^feature:" "$FEATURE_FILE" | sed 's/^feature: *//')
  DESCRIPTION=$(grep -A5 "^description:" "$FEATURE_FILE" | tail -n +2 | head -5)
  TARGET_SYMBOLS=$(grep -A20 "^target_symbols:" "$FEATURE_FILE" | grep "^  -" | sed 's/^  - *//')
fi

echo -e "${GREEN}✓${NC} Fonctionnalité: $FEATURE_NAME" >&2
echo -e "${BLUE}ℹ${NC} Description: $DESCRIPTION" >&2

# --- Création du répertoire tasks ---
TASKS_DIR="features/$FEATURE_NAME/tasks"
mkdir -p "$TASKS_DIR"

echo -e "${BLUE}ℹ${NC} Création des micro-tâches..." >&2

# --- Génération des micro-tâches ---
COUNT=0
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

for symbol in $TARGET_SYMBOLS; do
  COUNT=$((COUNT + 1))
  TASK_ID=$(printf "task-%03d" $COUNT)
  TASK_FILE="$TASKS_DIR/$TASK_ID.yaml"
  
  echo -e "${BLUE}ℹ${NC}   Création de $TASK_ID pour $symbol..." >&2
  
  # Génère le fichier YAML de la micro-tâche
  if command -v yq &> /dev/null; then
    yq -n \
      --arg id "$TASK_ID" \
      --arg feature "$FEATURE_NAME" \
      --arg symbol "$symbol" \
      --arg timestamp "$TIMESTAMP" \
      '{
        task_id: $id,
        feature: $feature,
        target_symbol: $symbol,
        description: "",
        signature: "",
        types: "",
        dependencies: [],
        constraints: ["specs/rules/constitution.md"],
        tests: [],
        visual_test: false,
        retry_count: 0,
        previous_errors: [],
        created_at: $timestamp,
        updated_at: $timestamp,
        status: "pending"
      }' > "$TASK_FILE"
  else
    # Fallback manuel
    cat > "$TASK_FILE" << EOF
# Micro-tâche générée automatiquement
task_id: $TASK_ID
feature: $FEATURE_NAME
target_symbol: $symbol
description: ""
signature: ""
types: ""
dependencies: []
constraints:
  - specs/rules/constitution.md
tests: []
visual_test: false
retry_count: 0
previous_errors: []
created_at: $TIMESTAMP
updated_at: $TIMESTAMP
status: pending
EOF
  fi
  
  echo -e "${GREEN}✓${NC}   Créé $TASK_FILE" >&2
done

# --- Résumé ---
echo ""
echo -e "${GREEN}✅ Décomposition terminée${NC}"
echo -e "${BLUE}ℹ${NC}  Fonctionnalité: $FEATURE_NAME"
echo -e "${BLUE}ℹ${NC}  Micro-tâches créées: $COUNT"
echo -e "${BLUE}ℹ${NC}  Répertoire: $TASKS_DIR"
echo ""
echo -e "${YELLOW}⚠${NC}  Prochaines étapes:"
echo "  1. Compléter les signatures et descriptions dans chaque task-XXX.yaml"
echo "  2. Exécuter: ./scripts/execute-task.sh $TASKS_DIR/task-001.yaml"
echo ""

exit 0
