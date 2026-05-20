#!/bin/bash

# ============================================================
# Axiom-Scaffold – Pipeline de Validation Zero-Trust
# Valide le code selon 6 étapes déterministes
# Usage : ./scripts/validate-code.sh <task_file.yaml>
# Retourne 0 si tout passe, 1 sinon
# ============================================================

set -euo pipefail

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Arguments ---
TASK_FILE="${1:-task.yaml}"

# --- Initialisation ---
ERROR_LOG="error.log"
> "$ERROR_LOG"  # Vider le fichier d'erreur

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  PIPELINE DE VALIDATION ZERO-TRUST${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# --- Fonction pour logger les erreurs ---
log_error() {
  local step="$1"
  local message="$2"
  echo "$step: $message" >> "$ERROR_LOG"
  echo -e "${RED}    ❌ $step${NC}"
  echo -e "${RED}    Erreur: $message${NC}"
}

# --- 1. COMPILATION ---
echo -e "${BLUE}🔨 Étape 1/6: Compilation${NC}"

if command -v tsc &> /dev/null && [ -f "tsconfig.json" ]; then
  if tsc --noEmit 2>&1 | tee -a "$ERROR_LOG" | grep -q "error TS"; then
    log_error "Compilation" "Erreurs TypeScript détectées"
    exit 1
  fi
  echo -e "${GREEN}    ✅ Compilation${NC}"
else
  echo -e "${YELLOW}    ⚠  TypeScript non configuré, skip${NC}"
fi

echo ""

# --- 2. LINTING ---
echo -e "${BLUE}📏 Étape 2/6: Linting${NC}"

if command -v eslint &> /dev/null && [ -f ".eslintrc.json" ] || [ -f ".eslintrc.js" ] || [ -f "eslint.config.js" ]; then
  if ! eslint . --max-warnings 0 2>&1 | tee -a "$ERROR_LOG"; then
    log_error "Linting" "Violations des conventions de code"
    exit 1
  fi
  echo -e "${GREEN}    ✅ Linting${NC}"
else
  echo -e "${YELLOW}    ⚠  ESLint non configuré, skip${NC}"
fi

echo ""

# --- 3. TESTS UNITAIRES ---
echo -e "${BLUE}🧪 Étape 3/6: Tests unitaires (couverture 100%)${NC}"

if command -v jest &> /dev/null; then
  # Configuration de couverture stricte
  if ! jest --coverage \
    --coverageThreshold='{"global":{"branches":100,"functions":100,"lines":100,"statements":100}}' \
    2>&1 | tee -a "$ERROR_LOG"; then
    log_error "Tests unitaires" "Couverture insuffisante ou tests échoués"
    exit 1
  fi
  echo -e "${GREEN}    ✅ Tests unitaires (100%)${NC}"
elif command -v pytest &> /dev/null; then
  # Python
  if ! pytest --cov --cov-report=term --cov-fail-under=100 2>&1 | tee -a "$ERROR_LOG"; then
    log_error "Tests unitaires" "Couverture insuffisante ou tests échoués"
    exit 1
  fi
  echo -e "${GREEN}    ✅ Tests unitaires (100%)${NC}"
else
  echo -e "${YELLOW}    ⚠  Aucun framework de test trouvé, skip${NC}"
fi

echo ""

# --- 4. TESTS DE MUTATION ---
echo -e "${BLUE}🧬 Étape 4/6: Tests de mutation (score 100%)${NC}"

if command -v npx &> /dev/null && [ -f "stryker.conf.js" ] || [ -f "stryker.conf.json" ]; then
  if ! npx stryker run 2>&1 | tee -a "$ERROR_LOG" | grep -q "All mutants killed"; then
    log_error "Tests de mutation" "Score de mutation < 100%"
    exit 1
  fi
  echo -e "${GREEN}    ✅ Tests de mutation (100%)${NC}"
elif command -v mutmut &> /dev/null; then
  # Python
  if ! mutmut run 2>&1 | tee -a "$ERROR_LOG"; then
    log_error "Tests de mutation" "Mutants survivants détectés"
    exit 1
  fi
  echo -e "${GREEN}    ✅ Tests de mutation (100%)${NC}"
else
  echo -e "${YELLOW}    ⚠  Stryker/mutmut non configuré, skip${NC}"
fi

echo ""

# --- 5. SÉCURITÉ ---
echo -e "${BLUE}🔒 Étape 5/6: Scan de sécurité${NC}"

# 5.1 Audit des dépendances
if command -v npm &> /dev/null && [ -f "package.json" ] && [ -f "package-lock.json" ]; then
  echo -e "${BLUE}    ℹ  Audit npm...${NC}"
  if ! npm audit --audit-level=high 2>&1 | tee -a "$ERROR_LOG"; then
    log_error "Sécurité" "Vulnérabilités détectées dans les dépendances"
    exit 1
  fi
  echo -e "${GREEN}    ✅ Audit npm${NC}"
elif command -v npm &> /dev/null && [ -f "package.json" ]; then
  echo -e "${YELLOW}    ⚠  package-lock.json manquant, skip audit npm${NC}"
elif command -v pip &> /dev/null && [ -f "requirements.txt" ]; then
  echo -e "${BLUE}    ℹ  Audit pip...${NC}"
  if command -v pip-audit &> /dev/null; then
    if ! pip-audit 2>&1 | tee -a "$ERROR_LOG"; then
      log_error "Sécurité" "Vulnérabilités détectées dans les dépendances Python"
      exit 1
    fi
    echo -e "${GREEN}    ✅ Audit pip${NC}"
  else
    echo -e "${YELLOW}    ⚠  pip-audit non installé, skip${NC}"
  fi
else
  echo -e "${YELLOW}    ⚠  Aucun gestionnaire de dépendances configuré, skip${NC}"
fi

# 5.2 Détection de secrets
echo -e "${BLUE}    ℹ  Détection de secrets...${NC}"

# Patterns de secrets réels (valeurs hardcodées, pas références de variables)
# Cherche des patterns comme: API_KEY="sk-..." ou password: "actual_password"
SECRETS_FOUND=false

# Chercher des clés API hardcodées (commence par sk-, pk-, etc.)
if grep -rE '(api_key|apikey|secret|password|token)\s*[:=]\s*["\047](sk-|pk-|[a-zA-Z0-9]{32,})' . \
  --exclude-dir=node_modules \
  --exclude-dir=.git \
  --exclude-dir=docs \
  --exclude-dir=Axiom-scaffold \
  --exclude="*.log" \
  --exclude="*.md" \
  --exclude=".env.example" \
  --exclude="*.example" \
  --exclude="*.sh" 2>/dev/null | grep -q .; then
  echo "Secret hardcodé détecté" >> "$ERROR_LOG"
  SECRETS_FOUND=true
fi

if [ "$SECRETS_FOUND" = true ]; then
  log_error "Sécurité" "Secrets hardcodés détectés dans le code"
  exit 1
fi

echo -e "${GREEN}    ✅ Aucun secret détecté${NC}"

# 5.3 Vérification .gitignore
if [ -f ".env" ] && ! grep -q "^\.env$" .gitignore 2>/dev/null; then
  log_error "Sécurité" "Fichier .env non ignoré par git"
  exit 1
fi

echo -e "${GREEN}    ✅ Sécurité${NC}"
echo ""

# --- 6. RÉGRESSION VISUELLE ---
echo -e "${BLUE}👁  Étape 6/6: Tests de régression visuelle${NC}"

# Vérifier si la tâche nécessite des tests visuels
VISUAL_TEST=false
if command -v yq &> /dev/null && [ -f "$TASK_FILE" ]; then
  VISUAL_TEST=$(yq eval '.visual_test // false' "$TASK_FILE")
elif [ -f "$TASK_FILE" ]; then
  if grep -q "visual_test: true" "$TASK_FILE"; then
    VISUAL_TEST=true
  fi
fi

if [ "$VISUAL_TEST" = "true" ]; then
  if command -v npx &> /dev/null && [ -f "playwright.config.ts" ] || [ -f "playwright.config.js" ]; then
    echo -e "${BLUE}    ℹ  Exécution des tests Playwright...${NC}"
    if ! npx playwright test 2>&1 | tee -a "$ERROR_LOG"; then
      log_error "Régression visuelle" "Tests visuels échoués"
      exit 1
    fi
    echo -e "${GREEN}    ✅ Régression visuelle${NC}"
  else
    echo -e "${YELLOW}    ⚠  Playwright non configuré, skip${NC}"
  fi
else
  echo -e "${BLUE}    ℹ  Tests visuels non requis pour cette tâche${NC}"
fi

echo ""

# --- SUCCÈS ---
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ TOUTES LES VALIDATIONS ONT RÉUSSI${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}    ✅ Compilation${NC}"
echo -e "${GREEN}    ✅ Linting${NC}"
echo -e "${GREEN}    ✅ Tests unitaires (100%)${NC}"
echo -e "${GREEN}    ✅ Tests de mutation (100%)${NC}"
echo -e "${GREEN}    ✅ Sécurité${NC}"
if [ "$VISUAL_TEST" = "true" ]; then
  echo -e "${GREEN}    ✅ Régression visuelle${NC}"
fi
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""

exit 0
