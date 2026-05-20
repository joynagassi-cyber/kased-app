#!/bin/bash
set -euo pipefail

echo "🔍 Recherche Automatique de Stack Technique"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Chemins
TECH_STACK_FILE="Axiom-scaffold/tools/tech-stack.md"
MCP_REGISTRY_FILE="Axiom-scaffold/tools/mcp-registry.yaml"
PROJECT_MAP="Axiom-scaffold/workspace/logs/project-map.md"

# Créer les dossiers
mkdir -p "$(dirname "$TECH_STACK_FILE")"

# 1. Analyser le projet
echo "📊 Analyse du projet..."

LANGUAGES=""
FRAMEWORKS=""

if [ -f "package.json" ]; then
    LANGUAGES="$LANGUAGES JavaScript/TypeScript"
    
    if grep -q "\"react\"" package.json 2>/dev/null; then
        FRAMEWORKS="$FRAMEWORKS React"
    fi
    if grep -q "\"next\"" package.json 2>/dev/null; then
        FRAMEWORKS="$FRAMEWORKS Next.js"
    fi
    if grep -q "\"vue\"" package.json 2>/dev/null; then
        FRAMEWORKS="$FRAMEWORKS Vue.js"
    fi
    if grep -q "\"express\"" package.json 2>/dev/null; then
        FRAMEWORKS="$FRAMEWORKS Express"
    fi
fi

if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
    LANGUAGES="$LANGUAGES Python"
fi

if [ -f "Cargo.toml" ]; then
    LANGUAGES="$LANGUAGES Rust"
fi

if [ -f "go.mod" ]; then
    LANGUAGES="$LANGUAGES Go"
fi

echo "   Langages détectés : $LANGUAGES"
echo "   Frameworks détectés : $FRAMEWORKS"

# 2. Générer le fichier tech-stack.md
echo ""
echo "📝 Génération de tech-stack.md..."

cat > "$TECH_STACK_FILE" << EOF
# Stack Technique Recommandée

Généré le : $(date -Iseconds)

## Langages Détectés

$LANGUAGES

## Frameworks Détectés

$FRAMEWORKS

## Bibliothèques Recommandées

### Pour le Développement

- **Linting** : ESLint, Prettier
- **Tests** : Jest, Playwright
- **Build** : TypeScript, Webpack/Vite

### Pour la Production

- **Logging** : Winston, Pino
- **Monitoring** : Sentry
- **Base de données** : PostgreSQL, Redis

## Serveurs MCP Recommandés

### Essentiels

- **filesystem** : Accès aux fichiers
- **git** : Opérations Git
- **github** : Intégration GitHub

### Selon le Projet

- **postgres** : Si base de données PostgreSQL
- **linear** : Si gestion de projet Linear
- **stripe** : Si paiements en ligne

## Justification

Cette stack est recommandée car :
1. Compatible avec les langages détectés
2. Écosystème mature et bien documenté
3. Bonne intégration avec les outils existants

## Prochaines Étapes

1. Valider cette stack
2. Installer les dépendances
3. Configurer les MCPs dans \`mcp-registry.yaml\`

EOF

echo "   ✅ $TECH_STACK_FILE créé"

# 3. Générer le fichier mcp-registry.yaml
echo ""
echo "📝 Génération de mcp-registry.yaml..."

cat > "$MCP_REGISTRY_FILE" << 'EOF'
# Registre des Serveurs MCP pour Axiom-Scaffold
# Copier les serveurs nécessaires dans votre fichier de configuration MCP

version: "1.0.0"
updated: "2026-05-09"

# Serveurs Essentiels
essential:
  filesystem:
    command: "npx"
    args: ["-y", "@modelcontextprotocol/server-filesystem", "."]
    description: "Accès aux fichiers du projet"
    
  git:
    command: "npx"
    args: ["-y", "@modelcontextprotocol/server-git"]
    description: "Opérations Git"
    
  github:
    command: "npx"
    args: ["-y", "@modelcontextprotocol/server-github"]
    env:
      GITHUB_TOKEN: "${GITHUB_TOKEN}"
    description: "Intégration GitHub"

# Serveurs Optionnels
optional:
  postgres:
    command: "npx"
    args: ["-y", "@modelcontextprotocol/server-postgres"]
    env:
      DATABASE_URL: "${DATABASE_URL}"
    description: "Base de données PostgreSQL"
    
  linear:
    command: "npx"
    args: ["-y", "@linear/mcp-server"]
    env:
      LINEAR_API_KEY: "${LINEAR_API_KEY}"
    description: "Gestion de projet Linear"
    
  stripe:
    command: "npx"
    args: ["-y", "@stripe/mcp-server"]
    env:
      STRIPE_API_KEY: "${STRIPE_API_KEY}"
    description: "Paiements Stripe"

# Instructions
instructions: |
  1. Copier les serveurs nécessaires dans votre fichier MCP :
     - VS Code/Cursor : .vscode/mcp.json
     - Claude Desktop : ~/Library/Application Support/Claude/claude_desktop_config.json
  
  2. Définir les variables d'environnement dans .env :
     - GITHUB_TOKEN=...
     - LINEAR_API_KEY=...
     - etc.
  
  3. Redémarrer l'IDE pour charger les serveurs

EOF

echo "   ✅ $MCP_REGISTRY_FILE créé"

# 4. Résumé
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Recherche de stack terminée !"
echo ""
echo "📁 Fichiers générés :"
echo "   - $TECH_STACK_FILE"
echo "   - $MCP_REGISTRY_FILE"
echo ""
echo "📚 Prochaines étapes :"
echo "   1. Consulter $TECH_STACK_FILE"
echo "   2. Valider la stack recommandée"
echo "   3. Configurer les MCPs depuis $MCP_REGISTRY_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
