#!/bin/bash
# Génère un SKILL.md à partir d'un pattern JSON et d'un événement exemple
# Usage : ./generate-skill.sh <pattern.json> <event_example.yaml>

set -euo pipefail

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $1"; }

# Paramètres
PATTERN_FILE="$1"
EVENT_EXAMPLE="$2"

if [ ! -f "$PATTERN_FILE" ]; then
    log_error "Fichier pattern introuvable : $PATTERN_FILE"
    exit 1
fi

if [ ! -f "$EVENT_EXAMPLE" ]; then
    log_error "Fichier événement introuvable : $EVENT_EXAMPLE"
    exit 1
fi

# Extraire les informations du pattern
if command -v jq &> /dev/null; then
    PATTERN_NAME=$(jq -r '.pattern_name' "$PATTERN_FILE")
    KEYWORDS=$(jq -r '.keywords' "$PATTERN_FILE")
    OCCURRENCES=$(jq -r '.occurrences' "$PATTERN_FILE")
else
    log_error "jq n'est pas installé. Impossible de parser le JSON."
    exit 1
fi

# Extraire les informations de l'événement exemple
if command -v yq &> /dev/null; then
    TARGET_SYMBOL=$(yq '.target_symbol' "$EVENT_EXAMPLE" 2>/dev/null || echo "unknown")
    FINAL_CODE=$(yq '.final_code_snippet' "$EVENT_EXAMPLE" 2>/dev/null || echo "// Code non disponible")
    ERROR_LOG=$(yq '.error_log' "$EVENT_EXAMPLE" 2>/dev/null || echo "null")
    CORRECTION=$(yq '.correction_applied' "$EVENT_EXAMPLE" 2>/dev/null || echo "null")
    STATUS=$(yq '.status' "$EVENT_EXAMPLE" 2>/dev/null || echo "unknown")
else
    log_warning "yq n'est pas installé. Utilisation de valeurs par défaut."
    TARGET_SYMBOL="unknown"
    FINAL_CODE="// Code non disponible"
    ERROR_LOG="null"
    CORRECTION="null"
    STATUS="unknown"
fi

# Créer le fichier skill
SKILL_FILE="skills/generated/${PATTERN_NAME}.md"

log_info "Génération du skill : $SKILL_FILE"
log_info "  Pattern : $PATTERN_NAME"
log_info "  Occurrences : $OCCURRENCES"
log_info "  Keywords : $KEYWORDS"

# Convertir les keywords en array YAML
KEYWORDS_ARRAY=$(echo "$KEYWORDS" | tr ' ' '\n' | sed 's/^/  - /' | tr '\n' '|' | sed 's/|$//')
KEYWORDS_YAML=$(echo "$KEYWORDS_ARRAY" | tr '|' '\n')

# Déterminer le domaine à partir des keywords
DOMAIN="general"
if echo "$KEYWORDS" | grep -qi "validation\|validate\|input"; then
    DOMAIN="validation"
elif echo "$KEYWORDS" | grep -qi "auth\|login\|security"; then
    DOMAIN="security"
elif echo "$KEYWORDS" | grep -qi "api\|http\|request"; then
    DOMAIN="api"
elif echo "$KEYWORDS" | grep -qi "database\|sql\|query"; then
    DOMAIN="database"
elif echo "$KEYWORDS" | grep -qi "ui\|component\|design"; then
    DOMAIN="design"
fi

# Déterminer la complexité
COMPLEXITY="intermediate"
if [ "$OCCURRENCES" -ge 10 ]; then
    COMPLEXITY="beginner"  # Si très fréquent, c'est probablement basique
elif [ "$OCCURRENCES" -le 3 ]; then
    COMPLEXITY="advanced"  # Si rare, c'est probablement complexe
fi

# Générer le contenu du skill
cat > "$SKILL_FILE" << EOF
---
id: $PATTERN_NAME
domain: $DOMAIN
complexity: $COMPLEXITY
triggers:
$KEYWORDS_YAML
source: auto-generated
generated_from: $OCCURRENCES occurrences
generated_at: $(date -Iseconds)
example_event: $(basename "$EVENT_EXAMPLE")
---

# Skill : $PATTERN_NAME

## 📋 Objectif

Ce skill a été généré automatiquement à partir de **$OCCURRENCES occurrences** d'un pattern récurrent.

**Symbole cible** : \`$TARGET_SYMBOL\`

**Contexte** : Ce pattern a été détecté lors de l'analyse de cycles de développement où des corrections similaires ont été appliquées.

## 🔄 Processus

### Étapes recommandées

1. **Analyser le contexte** : Identifier les entrées et sorties attendues
2. **Valider les entrées** : Vérifier la nullité, le type, et les contraintes
3. **Implémenter la logique** : Suivre l'exemple de code ci-dessous
4. **Gérer les erreurs** : Retourner des résultats typés, éviter les exceptions
5. **Tester exhaustivement** : Couvrir tous les cas limites

### Points d'attention

EOF

# Ajouter les anti-patterns si des corrections ont été appliquées
if [ "$CORRECTION" != "null" ] && [ -n "$CORRECTION" ]; then
    cat >> "$SKILL_FILE" << EOF
- **Corrections fréquentes** : Les erreurs suivantes ont été corrigées dans les cycles précédents :

\`\`\`
$CORRECTION
\`\`\`

EOF
fi

if [ "$ERROR_LOG" != "null" ] && [ -n "$ERROR_LOG" ]; then
    cat >> "$SKILL_FILE" << EOF
## ⚠️ Anti-patterns

### Erreurs communes

Les erreurs suivantes ont été observées dans les cycles précédents :

\`\`\`
$ERROR_LOG
\`\`\`

### Comment les éviter

EOF

    # Extraire des conseils à partir de l'erreur
    if echo "$ERROR_LOG" | grep -qi "undefined\|null"; then
        echo "- **Toujours vérifier la nullité** avant d'accéder aux propriétés" >> "$SKILL_FILE"
    fi
    
    if echo "$ERROR_LOG" | grep -qi "type"; then
        echo "- **Utiliser des types explicites** pour éviter les erreurs de type" >> "$SKILL_FILE"
    fi
    
    if echo "$ERROR_LOG" | grep -qi "includes\|indexOf"; then
        echo "- **Préférer \`lastIndexOf\` à \`includes\`** pour les recherches de caractères uniques" >> "$SKILL_FILE"
    fi
    
    echo "" >> "$SKILL_FILE"
fi

cat >> "$SKILL_FILE" << EOF
## 💻 Exemple de code

### Implémentation validée

\`\`\`typescript
$FINAL_CODE
\`\`\`

### Tests recommandés

\`\`\`typescript
describe('$TARGET_SYMBOL', () => {
  it('devrait gérer les cas valides', () => {
    // TODO: Ajouter des tests pour les cas valides
  });
  
  it('devrait gérer les cas invalides', () => {
    // TODO: Ajouter des tests pour les cas invalides
  });
  
  it('devrait gérer les cas limites', () => {
    // TODO: Ajouter des tests pour null, undefined, chaînes vides
  });
});
\`\`\`

## 📊 Historique

- **Généré automatiquement** le $(date +%Y-%m-%d) à partir de $OCCURRENCES occurrences
- **Pattern détecté** : $PATTERN_NAME
- **Keywords** : $KEYWORDS
- **Statut des événements** : $STATUS
- **Événement exemple** : \`$(basename "$EVENT_EXAMPLE")\`

## 🔗 Références

- [Constitution du projet](../../specs/rules/constitution.md)
- [Standards de code](../../specs/rules/coding-standards.md)
- [Registre des skills](../registry.json)

## 📝 Notes

Ce skill a été généré automatiquement par la **Couche 7 (Apprentissage)** d'Axiom-Scaffold.

Si ce skill nécessite des améliorations :
1. Éditez ce fichier manuellement
2. Ajoutez des exemples supplémentaires
3. Précisez les anti-patterns
4. Mettez à jour le registre si nécessaire

---

**Dernière mise à jour** : $(date -Iseconds)  
**Source** : Auto-généré (Couche 7)
EOF

log_success "Skill créé : $SKILL_FILE"

# Mettre à jour le registre
REGISTRY_FILE="skills/registry.json"

if [ ! -f "$REGISTRY_FILE" ]; then
    log_warning "Registre introuvable, création d'un nouveau registre"
    echo '{"skills":[]}' > "$REGISTRY_FILE"
fi

log_info "Mise à jour du registre : $REGISTRY_FILE"

# Vérifier si le skill existe déjà dans le registre
if jq -e ".skills[] | select(.id == \"$PATTERN_NAME\")" "$REGISTRY_FILE" > /dev/null 2>&1; then
    log_warning "Skill déjà présent dans le registre, mise à jour..."
    
    # Mettre à jour l'entrée existante
    jq --arg id "$PATTERN_NAME" \
       --arg path "$SKILL_FILE" \
       --arg domain "$DOMAIN" \
       --arg complexity "$COMPLEXITY" \
       --arg updated "$(date -Iseconds)" \
       '(.skills[] | select(.id == $id)) |= {
           id: $id,
           path: $path,
           domain: $domain,
           complexity: $complexity,
           triggers: (.triggers // []),
           priority: 7,
           source: "auto-generated",
           updated_at: $updated
       }' "$REGISTRY_FILE" > tmp && mv tmp "$REGISTRY_FILE"
else
    log_info "Ajout du skill au registre..."
    
    # Convertir les keywords en array JSON
    KEYWORDS_JSON=$(echo "$KEYWORDS" | tr ' ' '\n' | jq -R . | jq -s .)
    
    # Ajouter une nouvelle entrée
    jq --arg id "$PATTERN_NAME" \
       --arg path "$SKILL_FILE" \
       --arg domain "$DOMAIN" \
       --arg complexity "$COMPLEXITY" \
       --argjson triggers "$KEYWORDS_JSON" \
       --arg created "$(date -Iseconds)" \
       '.skills += [{
           id: $id,
           path: $path,
           domain: $domain,
           complexity: $complexity,
           triggers: $triggers,
           priority: 7,
           source: "auto-generated",
           created_at: $created
       }]' "$REGISTRY_FILE" > tmp && mv tmp "$REGISTRY_FILE"
fi

log_success "Registre mis à jour"

# Afficher un résumé
echo ""
log_success "✨ Skill généré avec succès !"
echo ""
echo "  📄 Fichier : $SKILL_FILE"
echo "  🏷️  ID : $PATTERN_NAME"
echo "  🎯 Domaine : $DOMAIN"
echo "  📊 Complexité : $COMPLEXITY"
echo "  🔑 Keywords : $KEYWORDS"
echo "  📈 Occurrences : $OCCURRENCES"
echo ""
log_info "Le skill sera automatiquement chargé par le minimiseur (Couche 3) lors des prochaines tâches similaires"

exit 0
