#!/bin/bash
# Scan de sécurité complet pour Axiom-Scaffold
# Ce script enchaîne SAST, SCA, détection de secrets, et optionnellement DAST

set -euo pipefail

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Répertoires
SECURITY_DIR="security"
REPORTS_DIR="$SECURITY_DIR/reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Créer le répertoire de rapports
mkdir -p "$REPORTS_DIR"

echo -e "${BLUE}🛡️  Lancement du scan de sécurité Axiom-Scaffold${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Compteurs
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Fonction pour afficher le résultat d'un check
check_result() {
  local name=$1
  local status=$2
  
  TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
  
  if [ "$status" -eq 0 ]; then
    echo -e "${GREEN}✅ $name${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
  else
    echo -e "${RED}❌ $name${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
  fi
}

# ============================================================================
# 1. ANALYSE STATIQUE (SAST) avec Semgrep
# ============================================================================
echo -e "${BLUE}→ 1. Analyse statique (Semgrep)${NC}"

if command -v semgrep &> /dev/null; then
  semgrep --config=auto \
    --config=p/owasp-top-ten \
    --config=p/security-audit \
    --json \
    --output="$REPORTS_DIR/semgrep-$TIMESTAMP.json" \
    --error \
    . || check_result "SAST (Semgrep)" $?
  
  # Afficher un résumé
  if [ -f "$REPORTS_DIR/semgrep-$TIMESTAMP.json" ]; then
    SEMGREP_ERRORS=$(jq '.results | length' "$REPORTS_DIR/semgrep-$TIMESTAMP.json")
    if [ "$SEMGREP_ERRORS" -gt 0 ]; then
      echo -e "${YELLOW}   ⚠️  $SEMGREP_ERRORS vulnérabilités détectées${NC}"
      check_result "SAST (Semgrep)" 1
    else
      check_result "SAST (Semgrep)" 0
    fi
  fi
else
  echo -e "${YELLOW}   ⚠️  Semgrep non installé, installation...${NC}"
  pip install semgrep
  check_result "SAST (Semgrep)" 1
fi

echo ""

# ============================================================================
# 2. SCAN DES DÉPENDANCES (SCA)
# ============================================================================
echo -e "${BLUE}→ 2. Scan des dépendances${NC}"

# npm audit (si package.json existe)
if [ -f "package.json" ]; then
  echo -e "${BLUE}   → npm audit${NC}"
  npm audit --audit-level=high --json > "$REPORTS_DIR/npm-audit-$TIMESTAMP.json" || true
  
  VULNERABILITIES=$(jq '.metadata.vulnerabilities | .high + .critical' "$REPORTS_DIR/npm-audit-$TIMESTAMP.json" 2>/dev/null || echo "0")
  
  if [ "$VULNERABILITIES" -gt 0 ]; then
    echo -e "${RED}   ❌ $VULNERABILITIES vulnérabilités haute/critique détectées${NC}"
    check_result "npm audit" 1
  else
    check_result "npm audit" 0
  fi
fi

# pip-audit (si requirements.txt existe)
if [ -f "requirements.txt" ]; then
  echo -e "${BLUE}   → pip-audit${NC}"
  
  if command -v pip-audit &> /dev/null; then
    pip-audit --format=json --output="$REPORTS_DIR/pip-audit-$TIMESTAMP.json" || check_result "pip-audit" $?
  else
    echo -e "${YELLOW}   ⚠️  pip-audit non installé${NC}"
    check_result "pip-audit" 1
  fi
fi

echo ""

# ============================================================================
# 3. DÉTECTION DE SECRETS
# ============================================================================
echo -e "${BLUE}→ 3. Détection de secrets${NC}"

if command -v detect-secrets &> /dev/null; then
  # Créer une baseline si elle n'existe pas
  if [ ! -f ".secrets.baseline" ]; then
    echo -e "${YELLOW}   ⚠️  Création de la baseline...${NC}"
    detect-secrets scan > .secrets.baseline
  fi
  
  # Scanner les fichiers
  detect-secrets scan --baseline .secrets.baseline || check_result "Détection de secrets" $?
  
  # Vérifier s'il y a de nouveaux secrets
  NEW_SECRETS=$(detect-secrets scan | jq '.results | length' 2>/dev/null || echo "0")
  
  if [ "$NEW_SECRETS" -gt 0 ]; then
    echo -e "${RED}   ❌ $NEW_SECRETS secrets potentiels détectés${NC}"
    check_result "Détection de secrets" 1
  else
    check_result "Détection de secrets" 0
  fi
else
  echo -e "${YELLOW}   ⚠️  detect-secrets non installé${NC}"
  pip install detect-secrets
  check_result "Détection de secrets" 1
fi

echo ""

# ============================================================================
# 4. ANALYSE DES PERMISSIONS (si Android)
# ============================================================================
if [ -f "AndroidManifest.xml" ]; then
  echo -e "${BLUE}→ 4. Analyse des permissions Android${NC}"
  
  # Vérifier les permissions dangereuses
  DANGEROUS_PERMS=$(grep -c "android.permission" AndroidManifest.xml || echo "0")
  
  if [ "$DANGEROUS_PERMS" -gt 10 ]; then
    echo -e "${YELLOW}   ⚠️  $DANGEROUS_PERMS permissions demandées (vérifier si nécessaires)${NC}"
    check_result "Permissions Android" 1
  else
    check_result "Permissions Android" 0
  fi
  
  echo ""
fi

# ============================================================================
# 5. DAST (si environnement de test disponible)
# ============================================================================
if [ "${AXIOM_DAST_ENABLED:-false}" = "true" ]; then
  echo -e "${BLUE}→ 5. Tests dynamiques (DAST)${NC}"
  
  if [ -z "${AXIOM_TARGET_URL:-}" ]; then
    echo -e "${YELLOW}   ⚠️  AXIOM_TARGET_URL non défini, DAST ignoré${NC}"
    check_result "DAST" 1
  else
    echo -e "${BLUE}   → Scan de $AXIOM_TARGET_URL${NC}"
    
    # Utiliser Strix si disponible
    if command -v strix &> /dev/null; then
      strix scan \
        --target "$AXIOM_TARGET_URL" \
        --output "$REPORTS_DIR/dast-$TIMESTAMP.json" || check_result "DAST (Strix)" $?
    else
      echo -e "${YELLOW}   ⚠️  Strix non installé, DAST ignoré${NC}"
      check_result "DAST" 1
    fi
  fi
  
  echo ""
fi

# ============================================================================
# 6. VÉRIFICATION DES CONFIGURATIONS DE SÉCURITÉ
# ============================================================================
echo -e "${BLUE}→ 6. Vérification des configurations${NC}"

# Vérifier que les secrets ne sont pas dans le code
if grep -r "sk-[a-zA-Z0-9]\{48\}" --exclude-dir=node_modules --exclude-dir=.git . > /dev/null 2>&1; then
  echo -e "${RED}   ❌ Clés API détectées dans le code${NC}"
  check_result "Secrets hardcodés" 1
else
  check_result "Secrets hardcodés" 0
fi

# Vérifier que .env n'est pas commité
if git ls-files | grep -q "^\.env$"; then
  echo -e "${RED}   ❌ .env est commité dans Git${NC}"
  check_result ".env dans Git" 1
else
  check_result ".env dans Git" 0
fi

# Vérifier que les dépendances sont épinglées
if [ -f "package.json" ]; then
  if grep -q '"\^' package.json || grep -q '"~' package.json; then
    echo -e "${YELLOW}   ⚠️  Dépendances non épinglées détectées (^ ou ~)${NC}"
    check_result "Dépendances épinglées" 1
  else
    check_result "Dépendances épinglées" 0
  fi
fi

echo ""

# ============================================================================
# RÉSUMÉ
# ============================================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 Résumé du scan de sécurité${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "Total de vérifications : $TOTAL_CHECKS"
echo -e "${GREEN}✅ Réussies : $PASSED_CHECKS${NC}"
echo -e "${RED}❌ Échouées : $FAILED_CHECKS${NC}"
echo ""

# Générer un rapport JSON
cat > "$REPORTS_DIR/summary-$TIMESTAMP.json" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "total_checks": $TOTAL_CHECKS,
  "passed": $PASSED_CHECKS,
  "failed": $FAILED_CHECKS,
  "reports": {
    "semgrep": "$REPORTS_DIR/semgrep-$TIMESTAMP.json",
    "npm_audit": "$REPORTS_DIR/npm-audit-$TIMESTAMP.json",
    "pip_audit": "$REPORTS_DIR/pip-audit-$TIMESTAMP.json"
  }
}
EOF

echo -e "${BLUE}📄 Rapports générés dans $REPORTS_DIR/${NC}"
echo ""

# Retourner un code d'erreur si des checks ont échoué
if [ "$FAILED_CHECKS" -gt 0 ]; then
  echo -e "${RED}❌ Scan de sécurité échoué : $FAILED_CHECKS vérifications ont échoué${NC}"
  exit 1
else
  echo -e "${GREEN}✅ Scan de sécurité terminé avec succès${NC}"
  exit 0
fi
