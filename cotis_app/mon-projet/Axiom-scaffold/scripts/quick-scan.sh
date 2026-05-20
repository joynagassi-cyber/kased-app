#!/bin/bash
set -euo pipefail

echo "🔍 Scan Rapide du Projet"
echo ""

# Chemins
OUTPUT_FILE="Axiom-scaffold/workspace/logs/project-map.md"
TIMEOUT=300  # 5 minutes max

# Créer le dossier de logs
mkdir -p "$(dirname "$OUTPUT_FILE")"

# Initialiser le fichier de sortie
cat > "$OUTPUT_FILE" << 'EOF'
# Carte du Projet

Généré le : $(date -Iseconds)

## Sections Détectées

EOF

# Fonction pour analyser un dossier
analyze_directory() {
    local dir=$1
    local name=$2
    
    if [ ! -d "$dir" ]; then
        return
    fi
    
    local file_count=$(find "$dir" -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.py" -o -name "*.dart" -o -name "*.yaml" \) 2>/dev/null | wc -l)
    local line_count=$(find "$dir" -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.py" -o -name "*.dart" -o -name "*.yaml" \) -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
    
    if [ "$file_count" -gt 0 ]; then
        echo "### $name" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "- **Chemin** : \`$dir\`" >> "$OUTPUT_FILE"
        echo "- **Fichiers** : $file_count" >> "$OUTPUT_FILE"
        echo "- **Lignes** : ~$line_count" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    fi
}

# Analyser les principaux dossiers
echo "📊 Analyse des dossiers..."

# Chercher dans le dossier courant et le dossier parent (pour les projets imbriqués)
analyze_directory "src" "Source Code"
analyze_directory "lib" "Library (Flutter/Dart)"
analyze_directory "../feu_evangile_flutter/lib" "Feu Evangile Flutter (Lib)"
analyze_directory "../backend" "Backend"
analyze_directory "tests" "Tests"
analyze_directory "app" "Application"
analyze_directory "pages" "Pages"
analyze_directory "components" "Components"
analyze_directory "api" "API"

# Détecter les langages
echo "" >> "$OUTPUT_FILE"
echo "## Langages Détectés" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

if [ -f "package.json" ] || [ -f "../package.json" ]; then
    echo "- **JavaScript/TypeScript** (package.json trouvé)" >> "$OUTPUT_FILE"
fi

if [ -f "requirements.txt" ] || [ -f "setup.py" ] || [ -f "pyproject.toml" ] || [ -f "../requirements.txt" ]; then
    echo "- **Python** (requirements.txt/setup.py/pyproject.toml trouvé)" >> "$OUTPUT_FILE"
fi

if [ -f "Cargo.toml" ]; then
    echo "- **Rust** (Cargo.toml trouvé)" >> "$OUTPUT_FILE"
fi

if [ -f "go.mod" ]; then
    echo "- **Go** (go.mod trouvé)" >> "$OUTPUT_FILE"
fi

if [ -f "pubspec.yaml" ] || [ -f "../feu_evangile_flutter/pubspec.yaml" ]; then
    echo "- **Dart/Flutter** (pubspec.yaml trouvé)" >> "$OUTPUT_FILE"
fi

# Détecter les frameworks
echo "" >> "$OUTPUT_FILE"
echo "## Frameworks Détectés" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

if [ -f "package.json" ]; then
    if grep -q "\"react\"" package.json 2>/dev/null; then
        echo "- **React**" >> "$OUTPUT_FILE"
    fi
    
    if grep -q "\"next\"" package.json 2>/dev/null; then
        echo "- **Next.js**" >> "$OUTPUT_FILE"
    fi
fi

if [ -f "pubspec.yaml" ] || [ -f "../feu_evangile_flutter/pubspec.yaml" ]; then
    echo "- **Flutter**" >> "$OUTPUT_FILE"
fi

# Statistiques globales
echo "" >> "$OUTPUT_FILE"
echo "## Statistiques Globales" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

TOTAL_FILES=$(find . .. -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.py" -o -name "*.dart" \) ! -path "*/node_modules/*" ! -path "*/Axiom-scaffold/*" ! -path "*/.git/*" ! -path "*/build/*" 2>/dev/null | wc -l)
TOTAL_LINES=$(find . .. -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.py" -o -name "*.dart" \) ! -path "*/node_modules/*" ! -path "*/Axiom-scaffold/*" ! -path "*/.git/*" ! -path "*/build/*" -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")

echo "- **Total de fichiers** : $TOTAL_FILES" >> "$OUTPUT_FILE"
echo "- **Total de lignes** : ~$TOTAL_LINES" >> "$OUTPUT_FILE"

# Recommandation
echo "" >> "$OUTPUT_FILE"
echo "## Recommandation" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

if [ "$TOTAL_LINES" -lt 10000 ]; then
    echo "✅ **Petit projet** : Vous pouvez travailler sur l'ensemble du projet." >> "$OUTPUT_FILE"
elif [ "$TOTAL_LINES" -lt 100000 ]; then
    echo "⚠️  **Projet moyen** : Recommandé de travailler par section." >> "$OUTPUT_FILE"
else
    echo "🔴 **Gros projet** : Obligatoire de travailler par section pour garantir la réactivité." >> "$OUTPUT_FILE"
fi

echo ""
echo "✅ Scan rapide terminé"
echo "📄 Résultat : $OUTPUT_FILE"
echo ""
