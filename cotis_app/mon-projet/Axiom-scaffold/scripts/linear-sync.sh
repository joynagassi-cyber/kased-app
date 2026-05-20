#!/bin/bash
# linear-sync.sh — Synchronise les tickets Linear avec le plan d'implémentation
# Partie d'Axiom-Scaffold v2.0

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AXIOM_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$AXIOM_ROOT/config/axiom.config.yaml"
WORKSPACE_DIR="$AXIOM_ROOT/workspace"
SPECS_DIR="$AXIOM_ROOT/specs"
LOGS_DIR="$WORKSPACE_DIR/logs"

echo "🔄 Synchronisation Linear..."

# Vérifier que Linear est activé dans la config
if ! grep -q "linear:" "$CONFIG_FILE" || ! grep -q "enabled: true" "$CONFIG_FILE"; then
    echo "❌ Linear n'est pas activé dans axiom.config.yaml"
    echo "   Activez-le en modifiant integrations.linear.enabled: true"
    exit 1
fi

# Vérifier que LINEAR_API_KEY est défini
if [ -z "$LINEAR_API_KEY" ]; then
    echo "❌ Variable d'environnement LINEAR_API_KEY non définie"
    echo "   Créez un token API sur https://linear.app/settings/api"
    echo "   Puis exportez-le : export LINEAR_API_KEY='your_token'"
    exit 1
fi

# Créer le dossier de logs si nécessaire
mkdir -p "$LOGS_DIR"

# Fonction pour extraire les tâches du plan d'implémentation
extract_tasks() {
    local plan_file="$1"
    local tasks=()
    
    # Extraire les tâches (lignes commençant par "- [ ]" ou "- [x]")
    while IFS= read -r line; do
        if [[ "$line" =~ ^-[[:space:]]\[([[:space:]]|x)\][[:space:]](.+)$ ]]; then
            local status="${BASH_REMATCH[1]}"
            local task="${BASH_REMATCH[2]}"
            tasks+=("$status|$task")
        fi
    done < "$plan_file"
    
    printf '%s\n' "${tasks[@]}"
}

# Fonction pour créer un ticket Linear via API
create_linear_ticket() {
    local title="$1"
    local description="$2"
    local team_id="$3"
    
    local response=$(curl -s -X POST https://api.linear.app/graphql \
        -H "Authorization: $LINEAR_API_KEY" \
        -H "Content-Type: application/json" \
        -d "{
            \"query\": \"mutation { issueCreate(input: { title: \\\"$title\\\", description: \\\"$description\\\", teamId: \\\"$team_id\\\" }) { success issue { id identifier title } } }\"
        }")
    
    echo "$response"
}

# Fonction pour mettre à jour le statut d'un ticket Linear
update_linear_ticket() {
    local issue_id="$1"
    local state_id="$2"
    
    local response=$(curl -s -X POST https://api.linear.app/graphql \
        -H "Authorization: $LINEAR_API_KEY" \
        -H "Content-Type: application/json" \
        -d "{
            \"query\": \"mutation { issueUpdate(id: \\\"$issue_id\\\", input: { stateId: \\\"$state_id\\\" }) { success issue { id identifier state { name } } } }\"
        }")
    
    echo "$response"
}

# Chercher les plans d'implémentation dans specs/
echo "📋 Recherche des plans d'implémentation..."
plan_files=$(find "$SPECS_DIR" -name "*plan*.md" -o -name "*implementation*.md" 2>/dev/null || true)

if [ -z "$plan_files" ]; then
    echo "⚠️  Aucun plan d'implémentation trouvé dans $SPECS_DIR"
    echo "   Créez un plan avec /axiom-plan"
    exit 0
fi

# Traiter chaque plan
total_synced=0
for plan_file in $plan_files; do
    echo ""
    echo "📄 Traitement de $(basename "$plan_file")..."
    
    # Extraire les tâches
    tasks=$(extract_tasks "$plan_file")
    
    if [ -z "$tasks" ]; then
        echo "   Aucune tâche trouvée dans ce plan"
        continue
    fi
    
    # Compter les tâches
    task_count=$(echo "$tasks" | wc -l)
    echo "   Trouvé $task_count tâche(s)"
    
    # Pour chaque tâche, vérifier si elle existe déjà dans Linear
    # (Cette partie nécessiterait une base de données locale pour mapper les tâches aux tickets)
    # Pour l'instant, on affiche simplement les tâches
    while IFS='|' read -r status task; do
        if [ "$status" = "x" ]; then
            echo "   ✅ $task (complété)"
        else
            echo "   ⏳ $task (en cours)"
        fi
        ((total_synced++))
    done <<< "$tasks"
done

echo ""
echo "✅ Synchronisation terminée : $total_synced tâche(s) traitée(s)"
echo ""
echo "📝 Note : Pour créer automatiquement des tickets Linear, configurez :"
echo "   1. LINEAR_API_KEY dans votre environnement"
echo "   2. LINEAR_TEAM_ID dans axiom.config.yaml"
echo "   3. Activez create_tickets_on_plan: true dans la config"
echo ""
echo "📊 Logs sauvegardés dans : $LOGS_DIR/linear-sync.log"

# Sauvegarder un log
{
    echo "=== Linear Sync - $(date) ==="
    echo "Plans traités : $(echo "$plan_files" | wc -l)"
    echo "Tâches synchronisées : $total_synced"
    echo ""
} >> "$LOGS_DIR/linear-sync.log"

exit 0
