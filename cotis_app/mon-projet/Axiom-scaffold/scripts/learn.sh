#!/bin/bash
# Pipeline d'apprentissage post-cycle
# Analyse les événements de développement et génère automatiquement des skills
# Usage : ./learn.sh [repertoire_evenements]

set -euo pipefail

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
EVENTS_DIR="${1:-learning/events}"
PATTERNS_DIR="learning/patterns"
REPORTS_DIR="learning/reports"
SKILLS_DIR="skills/generated"
MIN_OCCURRENCES=3
CONSTITUTION_FILE="specs/rules/constitution.md"

# Fonction d'affichage
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_learning() {
    echo -e "${MAGENTA}🧠${NC} $1"
}

# Vérifier que le répertoire d'événements existe
if [ ! -d "$EVENTS_DIR" ]; then
    log_error "Répertoire d'événements introuvable : $EVENTS_DIR"
    log_info "Créez-le avec : mkdir -p $EVENTS_DIR"
    exit 1
fi

# Créer les répertoires nécessaires
mkdir -p "$PATTERNS_DIR" "$REPORTS_DIR" "$SKILLS_DIR"

log_learning "🎓 Démarrage du pipeline d'apprentissage..."
log_info "Répertoire d'événements : $EVENTS_DIR"

# Compter les événements à traiter
TOTAL_EVENTS=$(find "$EVENTS_DIR" -name "*.yaml" -not -name "*-template.yaml" | wc -l)
NEW_EVENTS=$(find "$EVENTS_DIR" -name "*.yaml" -not -name "*-template.yaml" -not -name "*.done" | wc -l)

log_info "Événements totaux : $TOTAL_EVENTS"
log_info "Événements non traités : $NEW_EVENTS"

if [ "$NEW_EVENTS" -eq 0 ]; then
    log_success "Aucun nouvel événement à traiter"
    exit 0
fi

# Initialiser les compteurs
PATTERNS_DETECTED=0
SKILLS_GENERATED=0
RULES_ADDED=0

# Fonction pour extraire les keywords d'un événement
extract_keywords() {
    local event_file="$1"
    
    if command -v yq &> /dev/null; then
        yq '.pattern_keywords[]' "$event_file" 2>/dev/null | tr '\n' ' ' || echo ""
    else
        # Fallback avec grep
        grep -A 10 "pattern_keywords:" "$event_file" | grep "^  -" | sed 's/^  - //' | tr '\n' ' ' || echo ""
    fi
}

# Fonction pour extraire le statut
extract_status() {
    local event_file="$1"
    
    if command -v yq &> /dev/null; then
        yq '.status' "$event_file" 2>/dev/null || echo "unknown"
    else
        grep "^status:" "$event_file" | cut -d':' -f2 | tr -d ' "' || echo "unknown"
    fi
}

# Fonction pour extraire le nombre de tentatives
extract_attempts() {
    local event_file="$1"
    
    if command -v yq &> /dev/null; then
        yq '.attempts' "$event_file" 2>/dev/null || echo "1"
    else
        grep "^attempts:" "$event_file" | cut -d':' -f2 | tr -d ' ' || echo "1"
    fi
}

# Fonction pour trouver des événements similaires
find_similar_events() {
    local keywords="$1"
    local current_file="$2"
    local similar_files=""
    
    # Convertir les keywords en array
    IFS=' ' read -ra KEYWORD_ARRAY <<< "$keywords"
    
    # Chercher dans tous les événements (y compris les traités)
    for event_file in "$EVENTS_DIR"/*.yaml; do
        # Ignorer le template et le fichier actuel
        [[ "$event_file" == *"template"* ]] && continue
        [[ "$event_file" == "$current_file" ]] && continue
        
        # Extraire les keywords de cet événement
        local event_keywords=$(extract_keywords "$event_file")
        
        # Compter les keywords en commun
        local common_count=0
        for keyword in "${KEYWORD_ARRAY[@]}"; do
            if echo "$event_keywords" | grep -qi "$keyword"; then
                ((common_count++))
            fi
        done
        
        # Si au moins 50% des keywords correspondent
        local threshold=$((${#KEYWORD_ARRAY[@]} / 2))
        if [ "$common_count" -ge "$threshold" ] && [ "$common_count" -gt 0 ]; then
            similar_files="$similar_files $event_file"
        fi
    done
    
    echo "$similar_files"
}

# Fonction pour créer un nom de pattern à partir des keywords
create_pattern_name() {
    local keywords="$1"
    echo "$keywords" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g' | cut -c1-50
}

# Traiter chaque événement non traité
for event_file in "$EVENTS_DIR"/*.yaml; do
    # Ignorer le template
    [[ "$event_file" == *"template"* ]] && continue
    
    # Vérifier si déjà traité
    if [ -f "${event_file}.done" ]; then
        continue
    fi
    
    log_info "📄 Analyse de $(basename "$event_file")..."
    
    # Extraire les informations
    KEYWORDS=$(extract_keywords "$event_file")
    STATUS=$(extract_status "$event_file")
    ATTEMPTS=$(extract_attempts "$event_file")
    
    if [ -z "$KEYWORDS" ]; then
        log_warning "  Aucun keyword trouvé, événement ignoré"
        touch "${event_file}.done"
        continue
    fi
    
    log_info "  Keywords : $KEYWORDS"
    log_info "  Statut : $STATUS"
    log_info "  Tentatives : $ATTEMPTS"
    
    # Chercher des événements similaires
    SIMILAR_FILES=$(find_similar_events "$KEYWORDS" "$event_file")
    SIMILAR_COUNT=$(echo "$SIMILAR_FILES" | wc -w)
    
    log_info "  Événements similaires trouvés : $SIMILAR_COUNT"
    
    # Si pattern récurrent détecté
    if [ "$SIMILAR_COUNT" -ge "$MIN_OCCURRENCES" ]; then
        log_learning "  🎯 Pattern récurrent détecté ! ($SIMILAR_COUNT occurrences, seuil $MIN_OCCURRENCES)"
        ((PATTERNS_DETECTED++))
        
        # Créer le nom du pattern
        PATTERN_NAME=$(create_pattern_name "$KEYWORDS")
        PATTERN_FILE="$PATTERNS_DIR/${PATTERN_NAME}.json"
        
        # Vérifier si le pattern existe déjà
        if [ -f "$PATTERN_FILE" ]; then
            log_info "  Pattern déjà existant : $PATTERN_NAME"
            # Mettre à jour le compteur d'occurrences
            if command -v jq &> /dev/null; then
                CURRENT_COUNT=$(jq '.occurrences' "$PATTERN_FILE" 2>/dev/null || echo "0")
                NEW_COUNT=$((CURRENT_COUNT + 1))
                jq --arg count "$NEW_COUNT" '.occurrences = ($count | tonumber)' "$PATTERN_FILE" > tmp && mv tmp "$PATTERN_FILE"
            fi
        else
            log_learning "  📝 Création du pattern : $PATTERN_NAME"
            
            # Créer le fichier pattern (JSON simple)
            cat > "$PATTERN_FILE" << EOF
{
  "pattern_name": "$PATTERN_NAME",
  "keywords": "$KEYWORDS",
  "occurrences": $((SIMILAR_COUNT + 1)),
  "first_seen": "$(date -Iseconds)",
  "last_seen": "$(date -Iseconds)",
  "avg_attempts": $ATTEMPTS,
  "status_distribution": {
    "success": 0,
    "corrected": 0,
    "failure": 0
  },
  "example_event": "$(basename "$event_file")"
}
EOF
            
            # Générer le skill
            log_learning "  🎓 Génération du skill..."
            if bash scripts/generate-skill.sh "$PATTERN_FILE" "$event_file"; then
                log_success "  Skill généré avec succès"
                ((SKILLS_GENERATED++))
                
                # Si beaucoup d'occurrences, ajouter une règle à la constitution
                if [ "$SIMILAR_COUNT" -ge 5 ]; then
                    log_learning "  📜 Ajout d'une règle à la constitution (≥5 occurrences)"
                    
                    if [ -f "$CONSTITUTION_FILE" ]; then
                        # Vérifier si la section auto-générée existe
                        if ! grep -q "## Règles auto-générées" "$CONSTITUTION_FILE"; then
                            echo "" >> "$CONSTITUTION_FILE"
                            echo "## Règles auto-générées" >> "$CONSTITUTION_FILE"
                            echo "" >> "$CONSTITUTION_FILE"
                            echo "Ces règles ont été générées automatiquement par la Couche 7 (Apprentissage) à partir de patterns récurrents." >> "$CONSTITUTION_FILE"
                            echo "" >> "$CONSTITUTION_FILE"
                        fi
                        
                        # Ajouter la règle
                        RULE_TEXT="- [$(date +%Y-%m-%d)] Pattern récurrent détecté : $PATTERN_NAME ($SIMILAR_COUNT occurrences). Utiliser le skill généré."
                        if ! grep -q "$PATTERN_NAME" "$CONSTITUTION_FILE"; then
                            echo "$RULE_TEXT" >> "$CONSTITUTION_FILE"
                            log_success "  Règle ajoutée à la constitution"
                            ((RULES_ADDED++))
                        fi
                    fi
                fi
            else
                log_error "  Échec de la génération du skill"
            fi
        fi
    else
        log_info "  Pas de pattern récurrent (seuil non atteint)"
    fi
    
    # Marquer l'événement comme traité
    touch "${event_file}.done"
    log_success "  Événement traité"
done

# Générer un rapport d'apprentissage
REPORT_FILE="$REPORTS_DIR/$(date +%Y-%m-%d-%H%M%S)-report.md"

log_learning "📊 Génération du rapport d'apprentissage..."

cat > "$REPORT_FILE" << EOF
# Rapport d'Apprentissage — $(date +%Y-%m-%d\ %H:%M:%S)

## Résumé

- **Événements analysés** : $NEW_EVENTS
- **Patterns détectés** : $PATTERNS_DETECTED
- **Skills générés** : $SKILLS_GENERATED
- **Règles ajoutées** : $RULES_ADDED

## Détails

### Patterns Détectés

EOF

# Lister les patterns
if [ "$PATTERNS_DETECTED" -gt 0 ]; then
    for pattern_file in "$PATTERNS_DIR"/*.json; do
        [ -f "$pattern_file" ] || continue
        
        if command -v jq &> /dev/null; then
            PATTERN_NAME=$(jq -r '.pattern_name' "$pattern_file")
            OCCURRENCES=$(jq -r '.occurrences' "$pattern_file")
            KEYWORDS=$(jq -r '.keywords' "$pattern_file")
            
            cat >> "$REPORT_FILE" << EOF
#### $PATTERN_NAME

- **Occurrences** : $OCCURRENCES
- **Keywords** : $KEYWORDS
- **Skill généré** : \`skills/generated/${PATTERN_NAME}.md\`

EOF
        fi
    done
else
    echo "Aucun pattern détecté." >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" << EOF

### Skills Générés

EOF

if [ "$SKILLS_GENERATED" -gt 0 ]; then
    for skill_file in "$SKILLS_DIR"/*.md; do
        [ -f "$skill_file" ] || continue
        SKILL_NAME=$(basename "$skill_file" .md)
        echo "- \`$skill_file\`" >> "$REPORT_FILE"
    done
else
    echo "Aucun skill généré." >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" << EOF

### Règles Ajoutées à la Constitution

EOF

if [ "$RULES_ADDED" -gt 0 ]; then
    echo "$RULES_ADDED règle(s) ajoutée(s) à \`$CONSTITUTION_FILE\`" >> "$REPORT_FILE"
else
    echo "Aucune règle ajoutée." >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" << EOF

## Recommandations

EOF

if [ "$PATTERNS_DETECTED" -gt 0 ]; then
    cat >> "$REPORT_FILE" << EOF
- Vérifiez les skills générés dans \`$SKILLS_DIR/\`
- Testez les skills avec le minimiseur de contexte (Couche 3)
- Validez les règles ajoutées à la constitution
EOF
else
    cat >> "$REPORT_FILE" << EOF
- Continuez à développer pour accumuler plus d'événements
- Les patterns émergeront après plusieurs cycles similaires
EOF
fi

cat >> "$REPORT_FILE" << EOF

---

**Généré automatiquement par la Couche 7 (Apprentissage)**
EOF

log_success "Rapport généré : $REPORT_FILE"

# Résumé final
echo ""
log_learning "🎓 Pipeline d'apprentissage terminé !"
echo ""
echo "  📊 Statistiques :"
echo "     - Événements analysés : $NEW_EVENTS"
echo "     - Patterns détectés : $PATTERNS_DETECTED"
echo "     - Skills générés : $SKILLS_GENERATED"
echo "     - Règles ajoutées : $RULES_ADDED"
echo ""

if [ "$SKILLS_GENERATED" -gt 0 ]; then
    log_success "✨ $SKILLS_GENERATED nouveau(x) skill(s) disponible(s) dans $SKILLS_DIR/"
    log_info "Les skills seront automatiquement chargés par le minimiseur (Couche 3)"
fi

if [ "$RULES_ADDED" -gt 0 ]; then
    log_success "📜 $RULES_ADDED règle(s) ajoutée(s) à la constitution"
    log_info "Les agents respecteront ces règles lors des prochains cycles"
fi

exit 0
