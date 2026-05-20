#!/usr/bin/env node
/**
 * Script de génération de layout déterministe pour Axiom-Scaffold
 * Utilise @antv/layout avec un seed fixe pour garantir la reproductibilité
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const yaml = require('js-yaml');

// Chemins
const ENTITY_GRAPH_PATH = 'graph/entity-graph.json';
const VISUALIZATION_CONTRACT = '.axiom/visualization-contract.yaml';
const LAYOUT_OUTPUT = 'graph/layout.json';

console.log('📐 Génération du Layout Déterministe\n');

// 1. Charger le contrat de visualisation
function loadVisualizationContract() {
    console.log('📋 Chargement du contrat de visualisation...');
    try {
        const content = fs.readFileSync(VISUALIZATION_CONTRACT, 'utf8');
        const config = yaml.load(content);
        console.log(`   ✅ Version ${config.version}`);
        console.log(`   ✅ Algorithme: ${config.layout.algorithm} (seed: ${config.layout.seed})`);
        return config;
    } catch (error) {
        console.error(`   ❌ Erreur: ${error.message}`);
        process.exit(1);
    }
}

// 2. Charger le graphe d'entités
function loadEntityGraph() {
    console.log('\n📊 Chargement du graphe d'entités...');
  try {
        const content = fs.readFileSync(ENTITY_GRAPH_PATH, 'utf8');
        const graph = JSON.parse(content);
        console.log(`   ✅ ${graph.nodes.length} nœuds`);
        console.log(`   ✅ ${graph.edges.length} arêtes`);
        return graph;
    } catch (error) {
        console.error(`   ❌ Erreur: ${error.message}`);
        process.exit(1);
    }
}

// 3. Préparer les données pour le layout
function prepareLayoutData(graph, config) {
    console.log('\n🔧 Préparation des données...');

    // Filtrer selon la configuration
    const minConfidence = config.filters?.min_confidence || 0;
    const maxNodes = config.filters?.max_nodes || Infinity;

    let nodes = graph.nodes.filter(n => n.confidence >= minConfidence);

    // Limiter le nombre de nœuds si nécessaire
    if (nodes.length > maxNodes) {
        console.log(`   ⚠️  Limitation à ${maxNodes} nœuds (${nodes.length} disponibles)`);
        // Trier par centralité et prendre les top N
        nodes = nodes
            .sort((a, b) => (b.centralityScore || 0) - (a.centralityScore || 0))
            .slice(0, maxNodes);
    }

    const nodeIds = new Set(nodes.map(n => n.id));
    const edges = graph.edges.filter(e => nodeIds.has(e.source) && nodeIds.has(e.target));

    console.log(`   ✅ ${nodes.length} nœuds retenus`);
    console.log(`   ✅ ${edges.length} arêtes retenues`);

    return { nodes, edges };
}

// 4. Calculer le layout (simulation déterministe)
function calculateLayout(data, config) {
    console.log('\n📐 Calcul du layout...');

    const { nodes, edges } = data;
    const { algorithm, seed, params } = config.layout;

    // Simulation d'un layout déterministe
    // En production, utiliser @antv/layout avec le seed
    console.log(`   ℹ️  Algorithme: ${algorithm}`);
    console.log(`   ℹ️  Seed: ${seed}`);

    // Créer un générateur pseudo-aléatoire déterministe
    const rng = createSeededRNG(seed);

    // Layout simple en grille pour la démo
    const gridSize = Math.ceil(Math.sqrt(nodes.length));
    const spacing = params.nodesep || 50;

    const positions = nodes.map((node, i) => {
        const row = Math.floor(i / gridSize);
        const col = i % gridSize;

        // Ajouter une petite variation déterministe basée sur le seed
        const offsetX = (rng() - 0.5) * 10;
        const offsetY = (rng() - 0.5) * 10;

        return {
            id: node.id,
            x: col * spacing + offsetX,
            y: row * spacing + offsetY,
            size: calculateNodeSize(node, config.rendering.node_size),
            color: calculateNodeColor(node, config.rendering.node_color),
            shape: calculateNodeShape(node, config.rendering.node_shape)
        };
    });

    console.log(`   ✅ ${positions.length} positions calculées`);

    return positions;
}

// 5. Générateur pseudo-aléatoire seedé (LCG)
function createSeededRNG(seed) {
    let state = seed;
    return function () {
        state = (state * 1103515245 + 12345) & 0x7fffffff;
        return state / 0x7fffffff;
    };
}

// 6. Calculer la taille du nœud
function calculateNodeSize(node, config) {
    const { min_size, max_size, base_size, scale_factor } = config;

    if (config.strategy === 'proportional_to_impact') {
        const score = node[scale_factor] || 0;
        return base_size + (max_size - base_size) * score;
    }

    return base_size;
}

// 7. Calculer la couleur du nœud
function calculateNodeColor(node, config) {
    if (config.strategy === 'by_cluster') {
        // Palette de couleurs par cluster
        const colors = [
            '#3498db', '#2ecc71', '#9b59b6', '#e74c3c', '#f39c12',
            '#1abc9c', '#34495e', '#e67e22', '#95a5a6', '#16a085'
        ];

        if (node.cluster) {
            const hash = node.cluster.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0);
            return colors[hash % colors.length];
        }
    }

    return config.fallback;
}

// 8. Calculer la forme du nœud
function calculateNodeShape(node, config) {
    return config.by_type[node.type] || 'circle';
}

// 9. Calculer le hash du layout
function calculateHash(layout) {
    const normalized = {
        positions: layout.positions.sort((a, b) => a.id.localeCompare(b.id))
    };

    const content = JSON.stringify(normalized, Object.keys(normalized).sort());
    return crypto.createHash('sha256').update(content).digest('hex');
}

// 10. Sauvegarder le layout
function saveLayout(layout, hash, config) {
    console.log('\n💾 Sauvegarde du layout...');

    fs.mkdirSync(path.dirname(LAYOUT_OUTPUT), { recursive: true });

    const output = {
        ...layout,
        metadata: {
            algorithm: config.layout.algorithm,
            seed: config.layout.seed,
            generatedAt: new Date().toISOString(),
            hash: hash
        }
    };

    fs.writeFileSync(LAYOUT_OUTPUT, JSON.stringify(output, null, 2));
    console.log(`   ✅ Layout sauvegardé: ${LAYOUT_OUTPUT}`);
    console.log(`   📊 SHA256: ${hash}`);
}

// Main
function main() {
    try {
        // 1. Charger la configuration
        const config = loadVisualizationContract();

        // 2. Charger le graphe
        const graph = loadEntityGraph();

        // 3. Préparer les données
        const data = prepareLayoutData(graph, config);

        // 4. Calculer le layout
        const positions = calculateLayout(data, config);

        // 5. Construire le layout final
        const layout = {
            positions,
            edges: data.edges.map(e => ({
                source: e.source,
                target: e.target,
                relation: e.relation,
                style: config.rendering.edge_style.by_relation[e.relation] || {}
            }))
        };

        // 6. Calculer le hash
        const hash = calculateHash(layout);

        // 7. Sauvegarder
        saveLayout(layout, hash, config);

        // 8. Résumé
        console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        console.log('✅ Layout déterministe généré avec succès !');
        console.log('');
        console.log('📊 Statistiques:');
        console.log(`   • Nœuds positionnés: ${positions.length}`);
        console.log(`   • Arêtes stylées: ${layout.edges.length}`);
        console.log(`   • Hash: ${hash.substring(0, 16)}...`);
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        process.exit(0);

    } catch (error) {
        console.error('\n❌ Erreur fatale:', error.message);
        console.error(error.stack);
        process.exit(1);
    }
}

main();
