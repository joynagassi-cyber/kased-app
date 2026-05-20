#!/bin/bash

# ============================================================
# Axiom-Scaffold – Exécuteur de Micro-Tâche Zero-Trust
# Exécute UNE micro-tâche avec validation complète
# Usage : ./scripts/execute-task.sh features/<feature>/tasks/task-001.yaml
# ============================================================

set -euo pipefail

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# --- Arguments ---
if [ $# -lt 1 ]; then
  echo -e "${RED}❌ Erreur: Fichier task.yaml manquant${NC}" >&2
  echo "Usage: $0 features/<feature>/tasks/task-XXX.yaml" >&2
  exit 1
fi

TASK_FILE="$1"

# --- Vérification ---
if [ ! -f "$TASK_FILE" ]; then
  echo -e "${RED}❌ Erreur: $TASK_FILE introuvable${NC}" >&2
  exit 1
fi

# --- Extraction des informations ---
if command -v yq &> /dev/null; then
  TASK_ID=$(yq eval '.task_id' "$TASK_FILE")
  FEATURE=$(yq eval '.feature' "$TASK_FILE")
  SYMBOL=$(yq eval '.target_symbol' "$TASK_FILE")
  RETRY_COUNT=$(yq eval '.retry_count' "$TASK_FILE")
else
  TASK_ID=$(grep "^task_id:" "$TASK_FILE" | sed 's/^task_id: *//')
  FEATURE=$(grep "^feature:" "$TASK_FILE" | sed 's/^feature: *//')
  SYMBOL=$(grep "^target_symbol:" "$TASK_FILE" | sed 's/^target_symbol: *//')
  RETRY_COUNT=$(grep "^retry_count:" "$TASK_FILE" | sed 's/^retry_count: *//')
fi

MAX_RETRIES=3
WORKSPACE="agent-workspaces/$TASK_ID"
LOG_DIR="logs/execution/$TASK_ID"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")

echo ""
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
echo -e "${MAGENTA}  AXIOM-SCAFFOLD — EXÉCUTION ZERO-TRUST${NC}"
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}ℹ${NC}  Tâche: $TASK_ID"
echo -e "${BLUE}ℹ${NC}  Feature: $FEATURE"
echo -e "${BLUE}ℹ${NC}  Symbole: $SYMBOL"
echo -e "${BLUE}ℹ${NC}  Tentatives précédentes: $RETRY_COUNT"
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
echo ""

# --- Création des répertoires ---
mkdir -p "$LOG_DIR"
mkdir -p "agent-workspaces"

# --- Mise à jour du statut ---
if command -v yq &> /dev/null; then
  yq -i '.status = "in_progress"' "$TASK_FILE"
  yq -i ".updated_at = \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"" "$TASK_FILE"
fi

# --- 1. PRÉPARATION DU WORKSPACE ---
echo -e "${BLUE}📦 Étape 1/7: Préparation du workspace${NC}"

if [ -d "$WORKSPACE" ]; then
  echo -e "${YELLOW}⚠${NC}  Workspace existant, nettoyage..."
  rm -rf "$WORKSPACE"
fi

mkdir -p "$WORKSPACE"

# Clone ou worktree
if git worktree list &> /dev/null; then
  echo -e "${BLUE}ℹ${NC}  Création d'un git worktree..."
  git worktree add "$WORKSPACE" HEAD 2>&1 | tee "$LOG_DIR/worktree.log"
else
  echo -e "${BLUE}ℹ${NC}  Clone du dépôt..."
  git clone . "$WORKSPACE" --shared 2>&1 | tee "$LOG_DIR/clone.log"
fi

cd "$WORKSPACE"

echo -e "${GREEN}✓${NC}  Workspace prêt: $WORKSPACE"
echo ""

# --- 2. GÉNÉRATION DU PROMPT ---
echo -e "${BLUE}📝 Étape 2/7: Génération du prompt minimal${NC}"

# Copie du fichier task dans le workspace
cp "../$TASK_FILE" "task.yaml"

# Appel au minimiseur (Couche 3)
echo -e "${BLUE}ℹ${NC}  Appel au minimiseur de contexte..."

if [ -f "../scripts/minimize.sh" ]; then
  PROMPT=$(../scripts/minimize.sh "$SYMBOL" "task.yaml" 2>&1 | tee "$LOG_DIR/minimizer.log")
  echo "$PROMPT" > "prompt-$TIMESTAMP.md"
  echo -e "${GREEN}✓${NC}  Prompt généré: prompt-$TIMESTAMP.md"
else
  echo -e "${YELLOW}⚠${NC}  Minimiseur non trouvé, prompt par défaut"
  PROMPT="// TÂCHE : Implémente $SYMBOL"
  echo "$PROMPT" > "prompt-$TIMESTAMP.md"
fi

echo ""

# --- BOUCLE DE TENTATIVES ---
for ((i=RETRY_COUNT+1; i<=MAX_RETRIES; i++)); do
  echo -e "${MAGENTA}───────────────────────────────────────────────────────────${NC}"
  echo -e "${BLUE}🎯 Tentative $i/$MAX_RETRIES${NC}"
  echo -e "${MAGENTA}───────────────────────────────────────────────────────────${NC}"
  echo ""
  
  # --- 3. APPEL AU LLM ---
  echo -e "${BLUE}🤖 Étape 3/7: Génération du code (LLM)${NC}"
  echo -e "${YELLOW}⚠${NC}  Placeholder: Appel au LLM à implémenter"
  echo -e "${BLUE}ℹ${NC}  Prompt sauvegardé dans: prompt-$TIMESTAMP.md"
  echo ""
  echo -e "${YELLOW}⚠${NC}  Pour l'instant, le code doit être écrit manuellement"
  echo -e "${YELLOW}⚠${NC}  ou généré par un LLM externe et placé dans le workspace"
  echo ""
  
  # TODO: Intégrer l'appel au LLM
  # Exemples:
  # - claude --print "$(cat prompt-$TIMESTAMP.md)" > generated_code.txt
  # - curl -X POST https://api.anthropic.com/v1/messages ...
  # - python scripts/call_llm.py --prompt prompt-$TIMESTAMP.md
  
  echo -e "${BLUE}ℹ${NC}  Appuyez sur Entrée une fois le code généré..."
  read -r
  
  # --- 4. VALIDATION ---
  echo -e "${BLUE}🔍 Étape 4/7: Validation Zero-Trust${NC}"
  
  if ../scripts/validate-code.sh "task.yaml" 2>&1 | tee "$LOG_DIR/validation-attempt-$i.log"; then
    echo ""
    echo -e "${GREEN}✅ Validation réussie !${NC}"
    echo ""
    
    # --- 5. FUSION ---
    echo -e "${BLUE}🔀 Étape 5/7: Fusion du code${NC}"
    
    # Commit
    git add .
    COMMIT_MSG="feat($FEATURE): implémente $SYMBOL ($TASK_ID)"
    git commit -m "$COMMIT_MSG" 2>&1 | tee "$LOG_DIR/commit.log"
    echo -e "${GREEN}✓${NC}  Commit créé: $COMMIT_MSG"
    
    # Push vers branche temporaire
    BRANCH_NAME="auto-$TASK_ID-$TIMESTAMP"
    git push origin HEAD:refs/heads/$BRANCH_NAME 2>&1 | tee "$LOG_DIR/push.log"
    echo -e "${GREEN}✓${NC}  Branche poussée: $BRANCH_NAME"
    
    # Création PR (si gh CLI disponible)
    if command -v gh &> /dev/null; then
      echo -e "${BLUE}ℹ${NC}  Création de la Pull Request..."
      gh pr create \
        --title "Auto: $SYMBOL ($TASK_ID)" \
        --body "Micro-tâche validée par Axiom Zero-Trust.

**Feature**: $FEATURE
**Symbole**: $SYMBOL
**Tâche**: $TASK_ID
**Tentatives**: $i

Toutes les validations ont réussi :
- ✅ Compilation
- ✅ Linting
- ✅ Tests unitaires (100%)
- ✅ Tests de mutation (100%)
- ✅ Sécurité
- ✅ Régression visuelle (si applicable)

Logs: logs/execution/$TASK_ID/" \
        --base main \
        --head $BRANCH_NAME 2>&1 | tee "$LOG_DIR/pr-create.log"
      
      echo -e "${GREEN}✓${NC}  Pull Request créée"
      
      # Auto-merge (si configuré)
      echo -e "${BLUE}ℹ${NC}  Fusion automatique..."
      gh pr merge $BRANCH_NAME --auto --squash 2>&1 | tee "$LOG_DIR/pr-merge.log" || true
      echo -e "${GREEN}✓${NC}  Fusion programmée"
    else
      echo -e "${YELLOW}⚠${NC}  gh CLI non disponible, PR à créer manuellement"
    fi
    
    echo ""
    
    # --- 6. RÉ-INDEXATION ---
    echo -e "${BLUE}🔄 Étape 6/7: Ré-indexation de la mémoire${NC}"
    
    if command -v npx &> /dev/null && [ -f "../scripts/index-memory.sh" ]; then
      echo -e "${BLUE}ℹ${NC}  Mise à jour du graphe de connaissances..."
      cd ..
      ./scripts/index-memory.sh 2>&1 | tee "$LOG_DIR/reindex.log" || true
      cd "$WORKSPACE"
      echo -e "${GREEN}✓${NC}  Mémoire mise à jour"
    else
      echo -e "${YELLOW}⚠${NC}  Ré-indexation skippée (outils non disponibles)"
    fi
    
    echo ""
    
    # --- 7. NETTOYAGE ---
    echo -e "${BLUE}🧹 Étape 7/7: Nettoyage${NC}"
    
    cd ..
    
    # Mise à jour du statut
    if command -v yq &> /dev/null; then
      yq -i '.status = "completed"' "$TASK_FILE"
      yq -i ".updated_at = \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"" "$TASK_FILE"
    fi
    
    # Suppression du workspace
    if git worktree list | grep -q "$WORKSPACE"; then
      git worktree remove "$WORKSPACE" --force
    else
      rm -rf "$WORKSPACE"
    fi
    
    echo -e "${GREEN}✓${NC}  Workspace nettoyé"
    echo ""
    
    # --- SUCCÈS ---
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✅ SUCCÈS : $TASK_ID fusionné avec succès${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}ℹ${NC}  Feature: $FEATURE"
    echo -e "${BLUE}ℹ${NC}  Symbole: $SYMBOL"
    echo -e "${BLUE}ℹ${NC}  Tentatives: $i"
    echo -e "${BLUE}ℹ${NC}  Logs: $LOG_DIR"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    exit 0
  else
    # --- ÉCHEC DE LA VALIDATION ---
    echo ""
    echo -e "${RED}❌ Échec de la tentative $i${NC}"
    echo ""
    
    # Capture de l'erreur
    if [ -f "error.log" ]; then
      ERROR_LOG=$(cat error.log | head -20)
    else
      ERROR_LOG="Erreur inconnue"
    fi
    
    echo -e "${BLUE}ℹ${NC}  Erreur capturée:"
    echo "$ERROR_LOG" | sed 's/^/    /'
    echo ""
    
    # Sauvegarde de l'erreur
    echo "$ERROR_LOG" > "$LOG_DIR/error-attempt-$i.txt"
    
    # Mise à jour du fichier task
    cd ..
    if command -v yq &> /dev/null; then
      yq -i ".previous_errors += [\"Tentative $i: $ERROR_LOG\"]" "$TASK_FILE"
      yq -i ".retry_count = $i" "$TASK_FILE"
      yq -i ".updated_at = \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"" "$TASK_FILE"
    fi
    
    # Si pas la dernière tentative, préparer la correction
    if [ $i -lt $MAX_RETRIES ]; then
      echo -e "${YELLOW}⚠${NC}  Préparation de la correction..."
      
      # Nouveau prompt de correction
      if [ -f "scripts/minimize.sh" ]; then
        PROMPT=$(./scripts/minimize.sh --correction "$SYMBOL" "$TASK_FILE" 2>&1 | tee "$LOG_DIR/minimizer-correction-$i.log" || echo "// CORRECTION : $ERROR_LOG")
        echo "$PROMPT" > "$WORKSPACE/prompt-correction-$i-$TIMESTAMP.md"
        echo -e "${GREEN}✓${NC}  Prompt de correction généré"
      fi
      
      echo ""
      echo -e "${BLUE}ℹ${NC}  Nouvelle tentative dans 3 secondes..."
      sleep 3
    fi
    
    cd "$WORKSPACE"
  fi
done

# --- ÉCHEC DÉFINITIF ---
cd ..

echo ""
echo -e "${RED}═══════════════════════════════════════════════════════════${NC}"
echo -e "${RED}  🚨 ÉCHEC : Escalade humaine requise${NC}"
echo -e "${RED}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}ℹ${NC}  Tâche: $TASK_ID"
echo -e "${BLUE}ℹ${NC}  Feature: $FEATURE"
echo -e "${BLUE}ℹ${NC}  Symbole: $SYMBOL"
echo -e "${BLUE}ℹ${NC}  Tentatives: $MAX_RETRIES"
echo -e "${BLUE}ℹ${NC}  Logs: $LOG_DIR"
echo -e "${RED}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Mise à jour du statut
if command -v yq &> /dev/null; then
  yq -i '.status = "escalated"' "$TASK_FILE"
  yq -i ".updated_at = \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"" "$TASK_FILE"
fi

# Nettoyage du workspace
if git worktree list | grep -q "$WORKSPACE"; then
  git worktree remove "$WORKSPACE" --force
else
  rm -rf "$WORKSPACE"
fi

# TODO: Notification (Linear, GitHub Issues, Slack, etc.)
echo -e "${YELLOW}⚠${NC}  TODO: Créer un ticket d'escalade"
echo ""

exit 1
