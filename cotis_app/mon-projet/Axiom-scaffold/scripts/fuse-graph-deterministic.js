#!/usr/bin/env node
/**
 * Script de fusion déterministe pour Axiom-Scaffold
 * Fusionne GitNexus + Graphify + GraphRAG selon le contrat source-of-truth.yaml
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const yaml = require('js-yaml');

// Chemins
const SOURCE_OF_TRUTH = '.axiom/source-of-truth.yaml';
const SCHEMA_PATH = '.axiom/schema/entity-graph.schema.json';

console.log('🔀 Fusion Déterministe du Super-Graphe\n');

// 1. Charger le contrat source-of-truth
function loadSourceOfTruth() {
    console.log('📋 Chargement du contrat source-of-truth...');
    try {
        const content = fs.readFileSync(SOURCE_OF_TRUTH, 'utf8');
        const config = yaml.load(content);
        console.log(`   ✅ Version ${config.version}`);
        return config;
    } catch (error) {
        console.error(`   ❌ Erreur: ${error.message}`);
        process.exit(1);
    }
}

// 2. Charger les graphes sources
function loadSourceGraphs(config) {
    console.log('\n📊 Chargement des graphes sources...');
    const graphs = {};

    for (const [key, source] of Object.entries(config.sources)) {
        try {
            if (fs.existsSync(source.file)) {
                const data = fs.readFileSync(source.file, 'utf8');
                graphs[key] = JSON.parse(data);
                const nodeCount = graphs[key].nodes?.length || graphs[key].entities?.length || 0;
                console.log(`   ✅ ${source.tool}: ${nodeCount} nœuds (priorité ${source.priority})`);
            } else {
                console.log(`   ⚠️  ${source.tool}: fichier absent (${source.file})`);
                graphs[key] = { nodes: [], edges: [] };
            }
        } catch (error) {
            console.error(`   ❌ ${source.tool}: ${error.message}`);
            graphs[key] = { nodes: [], edges: [] };
        }
    }

    return graphs;
}

// 3. Normaliser les nœuds (format unifié)
function normalizeNode(node, source, confidence) {
    return {
        id: node.id || node.uid || node.name || node.filePath,
        name: node.name || node.uid || node.id,
        type: node.type || node.kind || 'unknown',
        filePath: node.filePath || node.file,
        signature: node.signature,
        startLine: node.startLine,
        endLine: node.endLine,
        kind: node.kind,
        cluster: node.cluster,
        clusterSummary: node.clusterSummary,
        centralityScore: node.centralityScore,
        documentEntities: node.documentEntities || [],
        dependencies: node.dependencies || node.outgoing_calls || [],
        callers: node.callers || node.incoming_calls || [],
        surprisingConnections: node.surprisingConnections || [],
        tags: node.tags || [],
        annotations: node.annotations || {},
        provenance: source,
        confidence: confidence
    };
}

// 4. Fusionner les nœuds selon la priorité
function mergeNodes(graphs, config) {
    console.log('\n🔀 Fusion des nœuds...');

    const nodeMap = new Map();
    const priorityOrder = config.fusion.priority_order;
    let mergedCount = 0;
    let conflictCount = 0;

    // Traiter les sources par ordre de priorité (inverse pour que la priorité 1 écrase)
    for (const sourceName of priorityOrder.reverse()) {
        const source = config.sources[sourceName];
        const graph = graphs[sourceName];
        const nodes = graph.nodes || graph.entities || [];

        nodes.forEach(node => {
            const normalized = normalizeNode(node, source.tool, source.confidence);
            const key = normalized.id;

            if (nodeMap.has(key)) {
                // Conflit : fusionner selon les règles
                const existing = nodeMap.get(key);
                const merged = mergeNodeProperties(existing, normalized, config.fusion.merge_rules);
                nodeMap.set(key, merged);
                mergedCount++;

                if (hasConflict(existing, normalized)) {
                    conflictCount++;
                }
            } else {
                nodeMap.set(key, normalized);
            }
        });
    }

    console.log(`   ✅ ${nodeMap.size} nœuds uniques`);
    console.log(`   ✅ ${mergedCount} nœuds fusionnés`);
    console.log(`   ⚠️  ${conflictCount} conflits résolus`);

    return Array.from(nodeMap.values());
}

// 5. Fusionner les propriétés selon les règles
function mergeNodeProperties(existing, incoming, rules) {
    const merged = { ...existing };

    // Propriétés structurelles : garder existing (priorité plus haute)
    // Propriétés sémantiques : prendre incoming si absent
    for (const [key, value] of Object.entries(incoming)) {
        if (value !== undefined && value !== null) {
            if (rules.structural.includes(key)) {
                // Garder existing (priorité structurelle)
                continue;
            } else if (rules.semantic.includes(key)) {
                // Prendre incoming si existing n'a pas cette propriété
                if (!merged[key]) {
                    merged[key] = value;
                }
            } else if (rules.documentary.includes(key)) {
                // Prendre incoming si existing n'a pas cette propriété
                if (!merged[key] || merged[key].length === 0) {
                    merged[key] = value;
                }
            } else if (rules.merged.includes(key)) {
                // Union des valeurs
                if (Array.isArray(value)) {
                    merged[key] = [...new Set([...(merged[key] || []), ...value])];
                } else if (typeof value === 'object') {
                    merged[key] = { ...(merged[key] || {}), ...value };
                }
            }
        }
    }

    // Marquer comme fusionné
    merged.provenance = 'merged';

    return merged;
}

// 6. Détecter les conflits
function hasConflict(node1, node2) {
    const conflictFields = ['signature', 'filePath', 'type'];
    return conflictFields.some(field => {
        return node1[field] && node2[field] && node1[field] !== node2[field];
    });
}

// 7. Fusionner les arêtes
function mergeEdges(graphs, config) {
    console.log('\n🔗 Fusion des arêtes...');

    const edgeMap = new Map();
    const priorityOrder = config.fusion.priority_order;

    for (const sourceName of priorityOrder.reverse()) {
        const source = config.sources[sourceName];
        const graph = graphs[sourceName];
        const edges = graph.edges || graph.relations || [];

        edges.forEach(edge => {
            const key = `${edge.source}-${edge.target}-${edge.relation || edge.type}`;

            if (!edgeMap.has(key)) {
                edgeMap.set(key, {
                    source: edge.source,
                    target: edge.target,
                    relation: edge.relation || edge.type || 'RELATED_TO',
                    description: edge.description,
                    weight: edge.weight || 1.0,
                    provenance: source.tool,
                    confidence: edge.confidence || source.confidence
                });
            }
        });
    }

    console.log(`   ✅ ${edgeMap.size} arêtes uniques`);

    return Array.from(edgeMap.values());
}

// 8. Extraire les clusters et communautés
function extractClustersAndCommunities(graphs) {
    console.log('\n🎨 Extraction des clusters et communautés...');

    const clusters = graphs.semantics?.clusters || [];
    const communities = graphs.documentation?.communities || [];

    console.log(`   ✅ ${clusters.length} clusters`);
    console.log(`   ✅ ${communities.length} communautés`);

    return { clusters, communities };
}

// 9. Calculer le hash SHA256
function calculateHash(graph) {
    // Normaliser le graphe (trier les clés, exclure les métadonnées temporelles)
    const normalized = {
        nodes: graph.nodes.map(n => {
            const { ...node } = n;
            return node;
        }).sort((a, b) => a.id.localeCompare(b.id)),
        edges: graph.edges.sort((a, b) => {
            const keyA = `${a.source}-${a.target}`;
            const keyB = `${b.source}-${b.target}`;
            return keyA.localeCompare(keyB);
        })
    };

    const content = JSON.stringify(normalized, Object.keys(normalized).sort());
    return crypto.createHash('sha256').update(content).digest('hex');
}

// 10. Valider contre le schéma (basique)
function validateGraph(graph) {
    console.log('\n✅ Validation du graphe...');

    const errors = [];

    // Vérifications basiques
    if (!graph.nodes || !Array.isArray(graph.nodes)) {
        errors.push('nodes doit être un tableau');
    }

    if (!graph.edges || !Array.isArray(graph.edges)) {
        errors.push('edges doit être un tableau');
    }

    // Vérifier que chaque nœud a les champs requis
    graph.nodes.forEach((node, i) => {
        if (!node.id) errors.push(`Node ${i}: id manquant`);
        if (!node.name) errors.push(`Node ${i}: name manquant`);
        if (!node.provenance) errors.push(`Node ${i}: provenance manquant`);
        if (node.confidence === undefined) errors.push(`Node ${i}: confidence manquant`);
    });

    // Vérifier que chaque arête a les champs requis
    graph.edges.forEach((edge, i) => {
        if (!edge.source) errors.push(`Edge ${i}: source manquant`);
        if (!edge.target) errors.push(`Edge ${i}: target manquant`);
        if (!edge.relation) errors.push(`Edge ${i}: relation manquant`);
    });

    // Vérifier qu'il n'y a pas de nœuds orphelins référencés
    const nodeIds = new Set(graph.nodes.map(n => n.id));
    graph.edges.forEach((edge, i) => {
        if (!nodeIds.has(edge.source)) {
            errors.push(`Edge ${i}: source ${edge.source} n'existe pas`);
        }
        if (!nodeIds.has(edge.target)) {
            errors.push(`Edge ${i}: target ${edge.target} n'existe pas`);
        }
    });

    if (errors.length > 0) {
        console.log(`   ⚠️  ${errors.length} erreurs de validation:`);
        errors.slice(0, 5).forEach(err => console.log(`      - ${err}`));
        if (errors.length > 5) {
            console.log(`      ... et ${errors.length - 5} autres`);
        }
    } else {
        console.log('   ✅ Graphe valide');
    }

    return errors.length === 0;
}

// 11. Sauvegarder le graphe et le hash
function saveGraph(graph, hash, config) {
    console.log('\n💾 Sauvegarde du graphe...');

    const outputPath = config.fusion.output.entity_graph;
    const hashPath = config.fusion.output.hash_file;

    // Créer les répertoires si nécessaire
    fs.mkdirSync(path.dirname(outputPath), { recursive: true });
    fs.mkdirSync(path.dirname(hashPath), { recursive: true });

    // Sauvegarder le graphe
    fs.writeFileSync(outputPath, JSON.stringify(graph, null, 2));
    console.log(`   ✅ Graphe sauvegardé: ${outputPath}`);

    // Sauvegarder le hash
    fs.writeFileSync(hashPath, hash);
    console.log(`   ✅ Hash sauvegardé: ${hashPath}`);
    console.log(`   📊 SHA256: ${hash}`);
}

// Main
function main() {
    try {
        // 1. Charger la configuration
        const config = loadSourceOfTruth();

        // 2. Charger les graphes sources
        const graphs = loadSourceGraphs(config);

        // 3. Fusionner les nœuds
        const nodes = mergeNodes(graphs, config);

        // 4. Fusionner les arêtes
        const edges = mergeEdges(graphs, config);

        // 5. Extraire clusters et communautés
        const { clusters, communities } = extractClustersAndCommunities(graphs);

        // 6. Construire le graphe final
        const graph = {
            nodes,
            edges,
            clusters,
            communities,
            metadata: {
                version: config.version,
                exportedAt: new Date().toISOString(),
                sources: {
                    gitnexus: {
                        nodes: graphs.structure?.nodes?.length || 0,
                        edges: graphs.structure?.edges?.length || 0,
                        confidence: config.sources.structure.confidence
                    },
                    graphify: {
                        nodes: graphs.semantics?.nodes?.length || 0,
                        edges: graphs.semantics?.edges?.length || 0,
                        confidence: config.sources.semantics.confidence
                    },
                    graphrag: {
                        nodes: graphs.documentation?.entities?.length || 0,
                        edges: graphs.documentation?.relations?.length || 0,
                        confidence: config.sources.documentation.confidence
                    }
                },
                fusion: {
                    totalNodes: nodes.length,
                    totalEdges: edges.length,
                    mergedNodes: nodes.filter(n => n.provenance === 'merged').length,
                    conflicts: 0, // Calculé pendant la fusion
                    entityCodeLinks: nodes.reduce((sum, n) => sum + (n.documentEntities?.length || 0), 0)
                }
            }
        };

        // 7. Calculer le hash
        const hash = calculateHash(graph);
        graph.metadata.hash = hash;

        // 8. Valider
        const isValid = validateGraph(graph);

        // 9. Sauvegarder
        saveGraph(graph, hash, config);

        // 10. Résumé
        console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        console.log('✅ Fusion déterministe terminée avec succès !');
        console.log('');
        console.log('📊 Statistiques:');
        console.log(`   • Nœuds: ${nodes.length}`);
        console.log(`   • Arêtes: ${edges.length}`);
        console.log(`   • Clusters: ${clusters.length}`);
        console.log(`   • Communautés: ${communities.length}`);
        console.log(`   • Hash: ${hash.substring(0, 16)}...`);
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        process.exit(isValid ? 0 : 1);

    } catch (error) {
        console.error('\n❌ Erreur fatale:', error.message);
        console.error(error.stack);
        process.exit(1);
    }
}

// Vérifier que js-yaml est installé
try {
    require.resolve('js-yaml');
} catch (e) {
    console.error('❌ Module js-yaml manquant');
    console.error('   Installation: npm install js-yaml');
    process.exit(1);
}

main();
