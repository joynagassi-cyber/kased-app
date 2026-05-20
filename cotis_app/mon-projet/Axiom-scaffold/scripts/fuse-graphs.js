#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const GITNEXUS_GRAPH_PATH = 'graph/gitnexus-graph.json';
const GRAPHIFY_GRAPH_PATH = 'graph/graphify-graph.json';
const DOC_GRAPH_PATH = 'graph/doc-graph.json';
const OUTPUT_PATH = 'graph/super-graph.json';
const ENTITY_GRAPH_PATH = 'graph/entity-graph.json';

function loadGitNexusGraph() {
  console.log('📊 Chargement du graphe GitNexus...');
  try {
    if (fs.existsSync(GITNEXUS_GRAPH_PATH)) {
      const data = fs.readFileSync(GITNEXUS_GRAPH_PATH, 'utf8');
      const graph = JSON.parse(data);
      console.log(`   ✅ ${graph.nodes?.length || 0} nœuds GitNexus`);
      return graph;
    }
  } catch (error) {
    console.error(`   ❌ Erreur: ${error.message}`);
  }
  return { nodes: [], edges: [], metadata: {} };
}

function loadGraphifyGraph() {
  console.log('🎨 Chargement du graphe Graphify...');
  try {
    if (fs.existsSync(GRAPHIFY_GRAPH_PATH)) {
      const data = fs.readFileSync(GRAPHIFY_GRAPH_PATH, 'utf8');
      const graph = JSON.parse(data);
      console.log(`   ✅ ${graph.nodes?.length || 0} nœuds Graphify`);
      return graph;
    }
  } catch (error) {
    console.error(`   ❌ Erreur: ${error.message}`);
  }
  return { nodes: [], clusters: [], metadata: {} };
}

function loadDocGraph() {
  console.log('📄 Chargement du graphe documentaire (GraphRAG)...');
  try {
    if (fs.existsSync(DOC_GRAPH_PATH)) {
      const data = fs.readFileSync(DOC_GRAPH_PATH, 'utf8');
      const graph = JSON.parse(data);
      console.log(`   ✅ ${graph.entities?.length || 0} entités documentaires`);
      console.log(`   ✅ ${graph.relations?.length || 0} relations documentaires`);
      console.log(`   ✅ ${graph.communities?.length || 0} communautés`);
      return graph;
    }
  } catch (error) {
    console.error(`   ❌ Erreur: ${error.message}`);
  }
  return { entities: [], relations: [], communities: [], metadata: {} };
}

function fuseGraphs(gitnexus, graphify, docGraph) {
  console.log('🔀 Fusion des graphes...');

  const nodeMap = new Map();

  // Ajouter les nœuds GitNexus
  (gitnexus.nodes || []).forEach(node => {
    const key = node.filePath || node.uid;
    nodeMap.set(key, {
      ...node,
      source: 'gitnexus',
      documentEntities: [] // Préparer pour les entités documentaires
    });
  });

  // Enrichir avec Graphify
  (graphify.nodes || []).forEach(node => {
    const key = node.name || node.filePath;
    if (nodeMap.has(key)) {
      const existing = nodeMap.get(key);
      nodeMap.set(key, {
        ...existing,
        cluster: node.cluster,
        clusterSummary: node.clusterSummary,
        centralityScore: node.centralityScore,
        surprisingConnections: node.connections?.surprising || []
      });
    } else {
      nodeMap.set(key, {
        ...node,
        source: 'graphify',
        documentEntities: []
      });
    }
  });

  // Lier les entités documentaires aux nœuds de code
  console.log('🔗 Liaison des entités documentaires...');
  let linkCount = 0;

  (docGraph.entities || []).forEach(entity => {
    // Rechercher les nœuds de code correspondants
    for (const [key, node] of nodeMap.entries()) {
      const nodeName = (node.name || node.uid || key).toLowerCase();
      const entityName = entity.name.toLowerCase();
      const filePath = (node.filePath || '').toLowerCase();

      // Heuristiques de correspondance
      const nameMatch = nodeName.includes(entityName) || entityName.includes(nodeName);
      const pathMatch = filePath.includes(entityName.replace(/\s+/g, ''));
      const typeMatch = entity.type === 'module' || entity.type === 'api' || entity.type === 'service';

      if ((nameMatch || pathMatch) && typeMatch) {
        node.documentEntities.push({
          id: entity.id,
          name: entity.name,
          type: entity.type,
          description: entity.description,
          community: entity.community
        });
        linkCount++;
      }
    }
  });

  console.log(`   ✅ ${linkCount} liens entité-code créés`);

  const fusedNodes = Array.from(nodeMap.values());

  console.log(`   ✅ ${fusedNodes.length} nœuds fusionnés`);

  return {
    nodes: fusedNodes,
    edges: gitnexus.edges || [],
    clusters: graphify.clusters || [],
    documentEntities: docGraph.entities || [],
    documentRelations: docGraph.relations || [],
    documentCommunities: docGraph.communities || [],
    metadata: {
      exportedAt: new Date().toISOString(),
      gitnexusNodes: gitnexus.nodes?.length || 0,
      graphifyNodes: graphify.nodes?.length || 0,
      documentEntities: docGraph.entities?.length || 0,
      documentRelations: docGraph.relations?.length || 0,
      fusedNodes: fusedNodes.length,
      entityCodeLinks: linkCount
    }
  };
}

function main() {
  console.log('🔀 Fusion des graphes GitNexus, Graphify et GraphRAG\n');

  const gitnexus = loadGitNexusGraph();
  const graphify = loadGraphifyGraph();
  const docGraph = loadDocGraph();
  const superGraph = fuseGraphs(gitnexus, graphify, docGraph);

  // Sauvegarder le super-graphe
  fs.mkdirSync(path.dirname(OUTPUT_PATH), { recursive: true });
  fs.writeFileSync(OUTPUT_PATH, JSON.stringify(superGraph, null, 2));
  console.log(`\n✅ Super-graphe sauvegardé : ${OUTPUT_PATH}`);

  // Sauvegarder aussi l'entity-graph (avec focus sur les entités documentaires)
  const entityGraph = {
    nodes: superGraph.nodes.filter(n => n.documentEntities && n.documentEntities.length > 0),
    documentEntities: superGraph.documentEntities,
    documentRelations: superGraph.documentRelations,
    documentCommunities: superGraph.documentCommunities,
    metadata: {
      ...superGraph.metadata,
      description: 'Graphe enrichi avec entités documentaires (GraphRAG)'
    }
  };

  fs.writeFileSync(ENTITY_GRAPH_PATH, JSON.stringify(entityGraph, null, 2));
  console.log(`✅ Entity-graph sauvegardé : ${ENTITY_GRAPH_PATH}`);

  console.log(`\n📊 Statistiques de fusion :`);
  console.log(`   • Nœuds de code : ${superGraph.nodes.length}`);
  console.log(`   • Entités documentaires : ${superGraph.documentEntities.length}`);
  console.log(`   • Relations documentaires : ${superGraph.documentRelations.length}`);
  console.log(`   • Communautés : ${superGraph.documentCommunities.length}`);
  console.log(`   • Liens entité-code : ${superGraph.metadata.entityCodeLinks}`);
}

main();
