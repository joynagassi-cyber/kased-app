#!/bin/bash

# ============================================================
# Axiom-Scaffold – Minimiseur de Contexte (shell)
# Usage : ./scripts/minimize.sh <targetSymbol> <taskFile.yaml>
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
  echo -e "${RED}❌ Erreur: Arguments manquants${NC}" >&2
  echo "Usage: $0 <targetSymbol> [taskFile.yaml]" >&2
  exit 1
fi

TARGET_SYMBOL="$1"
TASK_FILE="${2:-.agent/task.yaml}"

# --- Vérification des fichiers ---
CONFIG=".agent/minimizer-config.yaml"

if [ ! -f "$CONFIG" ]; then
  echo -e "${RED}❌ Erreur: $CONFIG introuvable${NC}" >&2
  exit 1
fi

if [ ! -f "$TASK_FILE" ]; then
  echo -e "${RED}❌ Erreur: $TASK_FILE introuvable${NC}" >&2
  exit 1
fi

# --- Fonction pour lire YAML (fallback si yq absent) ---
read_yaml() {
  local file="$1"
  local key="$2"
  
  # Essayer avec yq si disponible
  if command -v yq &> /dev/null; then
    yq eval "$key" "$file" 2>/dev/null || echo ""
  else
    # Fallback simple avec grep/sed (limité mais fonctionnel)
    grep "^${key##*.}:" "$file" | sed 's/^[^:]*: *//' | head -1
  fi
}

# --- Chargement de la configuration ---
echo -e "${BLUE}ℹ${NC} Chargement de la configuration..." >&2

if command -v yq &> /dev/null; then
  MAX_TOKENS=$(yq eval '.limits.max_tokens' "$CONFIG")
  MAX_DEPTH=$(yq eval '.limits.max_depth' "$CONFIG")
  MAX_CONSTRAINTS=$(yq eval '.limits.max_constraint_lines' "$CONFIG")
else
  echo -e "${YELLOW}⚠${NC}  yq non trouvé, utilisation des valeurs par défaut" >&2
  MAX_TOKENS=500
  MAX_DEPTH=2
  MAX_CONSTRAINTS=5
fi

# --- Extraction des données de la tâche ---
echo -e "${BLUE}ℹ${NC} Extraction de la tâche: $TARGET_SYMBOL" >&2

if command -v yq &> /dev/null; then
  TASK_SIGNATURE=$(yq eval '.signature' "$TASK_FILE" 2>/dev/null || echo "")
  TASK_TYPES=$(yq eval '.types // ""' "$TASK_FILE" 2>/dev/null || echo "")
  TASK_FAILED_TESTS=$(yq eval '.failed_tests // ""' "$TASK_FILE" 2>/dev/null || echo "")
  TASK_KEYWORDS=$(yq eval '.keywords[]' "$TASK_FILE" 2>/dev/null | tr '\n' ' ' || echo "")
else
  # Fallback simple
  TASK_SIGNATURE=$(grep "^signature:" "$TASK_FILE" | sed 's/^signature: *//' || echo "")
  TASK_TYPES=$(grep -A10 "^types:" "$TASK_FILE" | tail -n +2 | sed '/^[a-z]/q' | sed '$d' || echo "")
  TASK_FAILED_TESTS=$(grep -A10 "^failed_tests:" "$TASK_FILE" | tail -n +2 | sed '/^[a-z]/q' | sed '$d' || echo "")
  TASK_KEYWORDS=$(grep "^keywords:" "$TASK_FILE" | sed 's/^keywords: *//' | tr ',' ' ' || echo "")
fi

# --- Extraction du sous‑graphe mémoire (via jq) ---
echo -e "${BLUE}ℹ${NC} Extraction des dépendances depuis la mémoire..." >&2

MEMORY_DEPS=""
if [ -f "graph/super-graph.json" ] && command -v jq &> /dev/null; then
  MEMORY_DEPS=$(jq -r --arg target "$TARGET_SYMBOL" --argjson depth "$MAX_DEPTH" '
    [.nodes[]? | select(.name == $target or (.dependencies[]?.name == $target))] 
    | .[:$depth] 
    | .[] 
    | "  \(.name): \(.signature // "signature inconnue")"
  ' graph/super-graph.json 2>/dev/null || echo "")
fi

if [ -z "$MEMORY_DEPS" ]; then
  MEMORY_DEPS="  // Aucune dépendance trouvée dans le graphe"
fi

# --- Extraction des contraintes (grep dans les specs) ---
echo -e "${BLUE}ℹ${NC} Extraction des contraintes..." >&2

CONSTRAINTS=""
if [ -f "specs/rules/constitution.md" ]; then
  CONSTRAINTS=$(grep -h '^[-*]' specs/rules/constitution.md 2>/dev/null | head -"$MAX_CONSTRAINTS" || echo "")
fi

if [ -f "specs/rules/coding-standards.md" ] && [ -z "$CONSTRAINTS" ]; then
  CONSTRAINTS=$(grep -h '^[-*]' specs/rules/coding-standards.md 2>/dev/null | head -"$MAX_CONSTRAINTS" || echo "")
fi

if [ -z "$CONSTRAINTS" ]; then
  CONSTRAINTS="  - Respecter la constitution du projet"
fi

# Indenter les contraintes
CONSTRAINTS=$(echo "$CONSTRAINTS" | sed 's/^/  /')

# --- Extraction des skills pertinents ---
echo -e "${BLUE}ℹ${NC} Recherche des skills pertinents..." >&2

SKILLS_SUMMARY=""
if [ -f "skills/registry.json" ] && command -v jq &> /dev/null && [ -n "$TASK_KEYWORDS" ]; then
  # Pour chaque mot-clé de la tâche, on cherche un skill
  for kw in $TASK_KEYWORDS; do
    SKILL_NAME=$(jq -r --arg kw "$kw" '
      .skills[]? | select(.triggers[]? | contains($kw)) | .id
    ' skills/registry.json 2>/dev/null | head -1)
    
    if [ -n "$SKILL_NAME" ]; then
      SKILL_PATH=$(jq -r --arg id "$SKILL_NAME" '
        .skills[]? | select(.id == $id) | .path
      ' skills/registry.json 2>/dev/null)
      
      if [ -f "$SKILL_PATH" ]; then
        SKILL_OBJECTIF=$(grep -A1 "## Objectif" "$SKILL_PATH" 2>/dev/null | tail -1 | cut -c 1-80 || echo "")
        SKILL_PIEGES=$(grep -A1 "## Anti-patterns" "$SKILL_PATH" 2>/dev/null | tail -1 | cut -c 1-80 || echo "")
        
        if [ -n "$SKILL_OBJECTIF" ]; then
          SKILLS_SUMMARY="${SKILLS_SUMMARY}  // SKILL $SKILL_NAME : $SKILL_OBJECTIF"
          [ -n "$SKILL_PIEGES" ] && SKILLS_SUMMARY="${SKILLS_SUMMARY} | PIÈGES : $SKILL_PIEGES"
          SKILLS_SUMMARY="${SKILLS_SUMMARY}\n"
        fi
      fi
    fi
  done
fi

# --- Assemblage du prompt ---
echo -e "${BLUE}ℹ${NC} Assemblage du prompt..." >&2

PROMPT="// TÂCHE : Implémente $TARGET_SYMBOL

// SIGNATURE :
$TASK_SIGNATURE"

# Ajouter les types si présents
if [ -n "$TASK_TYPES" ]; then
  PROMPT="$PROMPT

// TYPES ASSOCIÉS :
$TASK_TYPES"
fi

# Ajouter les tests échouants si présents
if [ -n "$TASK_FAILED_TESTS" ]; then
  PROMPT="$PROMPT

// TESTS ÉCHOUANTS :
$TASK_FAILED_TESTS"
fi

# Ajouter les dépendances
PROMPT="$PROMPT

// DÉPENDANCES (signatures uniquement) :
$MEMORY_DEPS"

# Ajouter les contraintes (toujours présentes)
PROMPT="$PROMPT

// RÈGLES :
$CONSTRAINTS"

# Ajouter les skills si présents
if [ -n "$SKILLS_SUMMARY" ]; then
  PROMPT="$PROMPT

// SKILLS ACTIVÉS :
$(echo -e "$SKILLS_SUMMARY")"
fi

# --- Vérification des tokens (estimation : 1 token ≈ 4 caractères) ---
TOKEN_COUNT=$(( ${#PROMPT} / 4 ))

echo -e "${BLUE}ℹ${NC} Tokens estimés : $TOKEN_COUNT / $MAX_TOKENS" >&2

if [ "$TOKEN_COUNT" -gt "$MAX_TOKENS" ]; then
  echo -e "${YELLOW}⚠${NC}  Prompt trop long, troncature nécessaire..." >&2
  
  # Troncature intelligente : supprimer dans l'ordre de priorité
  # 1. Skills
  if [ -n "$SKILLS_SUMMARY" ]; then
    SKILLS_SUMMARY=""
    PROMPT="// TÂCHE : Implémente $TARGET_SYMBOL

// SIGNATURE :
$TASK_SIGNATURE"
    [ -n "$TASK_TYPES" ] && PROMPT="$PROMPT

// TYPES ASSOCIÉS :
$TASK_TYPES"
    [ -n "$TASK_FAILED_TESTS" ] && PROMPT="$PROMPT

// TESTS ÉCHOUANTS :
$TASK_FAILED_TESTS"
    PROMPT="$PROMPT

// DÉPENDANCES (signatures uniquement) :
$MEMORY_DEPS

// RÈGLES :
$CONSTRAINTS"
    TOKEN_COUNT=$(( ${#PROMPT} / 4 ))
    echo -e "${YELLOW}⚠${NC}  Skills supprimés. Tokens : $TOKEN_COUNT" >&2
  fi
  
  # 2. Dépendances
  if [ "$TOKEN_COUNT" -gt "$MAX_TOKENS" ]; then
    MEMORY_DEPS="  // Dépendances omises (prompt trop long)"
    PROMPT="// TÂCHE : Implémente $TARGET_SYMBOL

// SIGNATURE :
$TASK_SIGNATURE"
    [ -n "$TASK_TYPES" ] && PROMPT="$PROMPT

// TYPES ASSOCIÉS :
$TASK_TYPES"
    [ -n "$TASK_FAILED_TESTS" ] && PROMPT="$PROMPT

// TESTS ÉCHOUANTS :
$TASK_FAILED_TESTS"
    PROMPT="$PROMPT

// DÉPENDANCES (signatures uniquement) :
$MEMORY_DEPS

// RÈGLES :
$CONSTRAINTS"
    TOKEN_COUNT=$(( ${#PROMPT} / 4 ))
    echo -e "${YELLOW}⚠${NC}  Dépendances supprimées. Tokens : $TOKEN_COUNT" >&2
  fi
  
  # 3. Tests échouants (garder au moins la première ligne)
  if [ "$TOKEN_COUNT" -gt "$MAX_TOKENS" ] && [ -n "$TASK_FAILED_TESTS" ]; then
    TASK_FAILED_TESTS=$(echo "$TASK_FAILED_TESTS" | head -3)
    PROMPT="// TÂCHE : Implémente $TARGET_SYMBOL

// SIGNATURE :
$TASK_SIGNATURE"
    [ -n "$TASK_TYPES" ] && PROMPT="$PROMPT

// TYPES ASSOCIÉS :
$TASK_TYPES"
    PROMPT="$PROMPT

// TESTS ÉCHOUANTS (tronqués) :
$TASK_FAILED_TESTS

// DÉPENDANCES (signatures uniquement) :
$MEMORY_DEPS

// RÈGLES :
$CONSTRAINTS"
    TOKEN_COUNT=$(( ${#PROMPT} / 4 ))
    echo -e "${YELLOW}⚠${NC}  Tests tronqués. Tokens : $TOKEN_COUNT" >&2
  fi
  
  # 4. Types
  if [ "$TOKEN_COUNT" -gt "$MAX_TOKENS" ] && [ -n "$TASK_TYPES" ]; then
    TASK_TYPES=""
    PROMPT="// TÂCHE : Implémente $TARGET_SYMBOL

// SIGNATURE :
$TASK_SIGNATURE

// TESTS ÉCHOUANTS (tronqués) :
$TASK_FAILED_TESTS

// DÉPENDANCES (signatures uniquement) :
$MEMORY_DEPS

// RÈGLES :
$CONSTRAINTS"
    TOKEN_COUNT=$(( ${#PROMPT} / 4 ))
    echo -e "${YELLOW}⚠${NC}  Types supprimés. Tokens : $TOKEN_COUNT" >&2
  fi
  
  # 5. Troncature brutale si toujours trop long
  if [ "$TOKEN_COUNT" -gt "$MAX_TOKENS" ]; then
    MAX_CHARS=$((MAX_TOKENS * 4))
    PROMPT="${PROMPT:0:$MAX_CHARS}"
    TOKEN_COUNT=$MAX_TOKENS
    echo -e "${YELLOW}⚠${NC}  Troncature brutale à $MAX_TOKENS tokens" >&2
  fi
fi

# --- Affichage du résultat ---
echo "$PROMPT"

echo -e "${GREEN}✓${NC} Prompt généré : $TOKEN_COUNT tokens" >&2

exit 0
