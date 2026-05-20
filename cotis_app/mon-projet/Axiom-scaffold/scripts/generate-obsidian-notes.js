#!/usr/bin/env node
/**
 * Génération des notes Obsidian
 * 
 * Ce script lit le super-graphe et génère un vault Obsidian
 * avec une note par cluster fonctionnel.
 */

const fs = require('fs');
const path = require('path');

// Configuration
const SUPER_GRAPH_PATH = 'graph/super-graph.json';
const VAULT_DIR = 'vault/02-codebase';
const DECISIONS_DIR = 'vault/03-decisions';
const INDEX_FILE = 'vault/02-codebase/_index.md';

/**
 * Slugifie un texte pour créer un nom de fichier
 */
function slugify(text) {
    return text
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '-')
        .replace(/^-+|-+$/g, '');
}

/**
 * Génère le frontmatter YAML pour une note
 */
function generateFrontmatter(cluster, nodes) {
    const date = new Date().toISOString().split('T')[0];
    const tags = ['codebase', 'cluster', slugify(cluster)];

    return `---
title: "${cluster}"
tags: [${tags.join(', ')}]
cluster: "${cluster}"
nodeCount: ${nodes.length}
date: ${date}
---

`;
}

/**
 * Génère une note Markdown pour un cluster
 */
function generateClusterNote(cluster, nodes) {
    let content = generateFrontmatter(cluster, nodes);

    // Titre
    content += `# ${cluster}\n\n`;

    // Résumé du cluster
    const summary = nodes[0]?.clusterSummary || 'Aucun résumé disponible';
    content += `## Résumé\n\n${summary}\n\n`;

    // Statistiques
    const avgCentrality = nodes.reduce((sum, n) => sum + (n.centralityScore || 0), 0) / nodes.length;
    content += `## Statistiques\n\n`;
    content += `- **Nombre de fichiers** : ${nodes.length}\n`;
    content += `- **Centralité moyenne** : ${avgCentrality.toFixed(2)}\n\n`;

    // Liste des fichiers
    content += `## Fichiers\n\n`;
    nodes
        .sort((a, b) => (b.centralityScore || 0) - (a.centralityScore || 0))
        .forEach(node => {
            const name = node.name || node.filePath || node.uid;
            const score = node.centralityScore ? ` (${node.centralityScore.toFixed(2)})` : '';
            const kind = node.kind ? ` \`${node.kind}\`` : '';
            content += `- [[${name}]]${kind}${score}\n`;
        });

    content += `\n`;

    // Dépendances
    const dependencies = nodes.flatMap(n => n.dependencies || []);
    if (dependencies.length > 0) {
        content += `## Dépendances principales\n\n`;
        const uniqueDeps = [...new Set(dependencies)].slice(0, 10);
        uniqueDeps.forEach(dep => {
            content += `- \`${dep}\`\n`;
        });
        content += `\n`;
    }

    // Connexions surprenantes
    const surprising = nodes.flatMap(n => n.surprisingConnections || []);
    if (surprising.length > 0) {
        content += `## Connexions surprenantes\n\n`;
        const uniqueSurprising = [...new Set(surprising)].slice(0, 5);
        uniqueSurprising.forEach(conn => {
            content += `- ⚠️ [[${conn}]]\n`;
        });
        content += `\n`;
    }

    return content;
}

/**
 * Génère l'index des clusters
 */
function generateIndex(clusterMap) {
    let content = `---
title: "Index des Clusters"
tags: [index, codebase]
date: ${new Date().toISOString().split('T')[0]}
---

# Index des Clusters

Ce fichier liste tous les clusters fonctionnels du projet.

## Vue d'ensemble

- **Nombre de clusters** : ${clusterMap.size}
- **Dernière mise à jour** : ${new Date().toISOString()}

## Clusters

`;

    // Trier les clusters par centralité moyenne
    const clusters = Array.from(clusterMap.entries())
        .map(([name, nodes]) => ({
            name,
            nodes,
            avgCentrality: nodes.reduce((sum, n) => sum + (n.centralityScore || 0), 0) / nodes.length
        }))
        .sort((a, b) => b.avgCentrality - a.avgCentrality);

    clusters.forEach(({ name, nodes, avgCentrality }) => {
        const slug = slugify(name);
        content += `### [[${slug}|${name}]]\n\n`;
        content += `- **Fichiers** : ${nodes.length}\n`;
        content += `- **Centralité** : ${avgCentrality.toFixed(2)}\n`;
        content += `- **Résumé** : ${nodes[0]?.clusterSummary || 'N/A'}\n\n`;
    });

    return content;
}

/**
 * Fonction principale
 */
function main() {
    console.log('📝 Génération du vault Obsidian\n');

    // Charger le super-graphe
    console.log('📊 Chargement du super-graphe...');
    if (!fs.existsSync(SUPER_GRAPH_PATH)) {
        console.error(`❌ Fichier non trouvé : ${SUPER_GRAPH_PATH}`);
        process.exit(1);
    }

    const graph = JSON.parse(fs.readFileSync(SUPER_GRAPH_PATH, 'utf8'));
    const nodes = graph.nodes || [];

    console.log(`   ✅ ${nodes.length} nœuds chargés`);

    // Créer les répertoires
    fs.mkdirSync(VAULT_DIR, { recursive: true });
    fs.mkdirSync(DECISIONS_DIR, { recursive: true });

    // Grouper les nœuds par cluster
    console.log('\n🗂️  Groupement par cluster...');
    const clusterMap = new Map();

    nodes.forEach(node => {
        const cluster = node.cluster || 'Uncategorized';
        if (!clusterMap.has(cluster)) {
            clusterMap.set(cluster, []);
        }
        clusterMap.get(cluster).push(node);
    });

    console.log(`   ✅ ${clusterMap.size} clusters trouvés`);

    // Générer une note par cluster
    console.log('\n📝 Génération des notes...');
    let noteCount = 0;

    clusterMap.forEach((nodes, cluster) => {
        const slug = slugify(cluster);
        const filename = path.join(VAULT_DIR, `${slug}.md`);
        const content = generateClusterNote(cluster, nodes);

        fs.writeFileSync(filename, content);
        noteCount++;
        console.log(`   ✅ ${slug}.md (${nodes.length} nœuds)`);
    });

    // Générer l'index
    console.log('\n📋 Génération de l\'index...');
    const indexContent = generateIndex(clusterMap);
    fs.writeFileSync(INDEX_FILE, indexContent);
    console.log(`   ✅ _index.md`);

    // Créer un fichier README pour le vault
    const readmeContent = `# Vault Obsidian — Axiom-Scaffold

Ce vault contient la documentation générée automatiquement du projet.

## Structure

- **02-codebase/** : Notes par cluster fonctionnel
- **03-decisions/** : Architecture Decision Records (ADR)

## Navigation

Commencez par [[_index|l'index des clusters]].

## Mise à jour

Ce vault est généré automatiquement par \`scripts/generate-obsidian-notes.js\`.
Pour le régénérer : \`npm run index-memory\`

---

Dernière mise à jour : ${new Date().toISOString()}
`;

    fs.writeFileSync('vault/README.md', readmeContent);

    console.log(`\n✅ Vault Obsidian généré avec succès !`);
    console.log(`   - ${noteCount} notes de clusters`);
    console.log(`   - 1 index`);
    console.log(`   - Ouvrir vault/ dans Obsidian pour naviguer`);
}

main();
