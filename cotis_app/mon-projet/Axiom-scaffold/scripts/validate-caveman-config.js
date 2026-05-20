#!/usr/bin/env node
// Axiom-scaffold/scripts/validate-caveman-config.js
// Valide la configuration caveman-rules.yaml

const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

const CONFIG_PATH = path.join(__dirname, '../config/caveman-rules.yaml');

function validateConfig() {
    console.log('🔍 Validation de caveman-rules.yaml...\n');

    // 1. Vérifier que le fichier existe
    if (!fs.existsSync(CONFIG_PATH)) {
        console.error('❌ Fichier caveman-rules.yaml introuvable');
        process.exit(1);
    }

    // 2. Parser le YAML
    let config;
    try {
        const content = fs.readFileSync(CONFIG_PATH, 'utf8');
        config = yaml.load(content);
        console.log('✅ YAML valide');
    } catch (error) {
        console.error('❌ Erreur de parsing YAML:', error.message);
        process.exit(1);
    }

    // 3. Vérifier les sections obligatoires
    const requiredSections = ['version', 'levels', 'output_rules', 'invariants', 'persistence'];
    const missingSections = requiredSections.filter(section => !config[section]);

    if (missingSections.length > 0) {
        console.error('❌ Sections manquantes:', missingSections.join(', '));
        process.exit(1);
    }
    console.log('✅ Toutes les sections obligatoires présentes');

    // 4. Vérifier les niveaux
    const requiredLevels = ['lite', 'full', 'ultra'];
    const missingLevels = requiredLevels.filter(level => !config.levels[level]);

    if (missingLevels.length > 0) {
        console.error('❌ Niveaux manquants:', missingLevels.join(', '));
        process.exit(1);
    }
    console.log('✅ Tous les niveaux définis (lite, full, ultra)');

    // 5. Vérifier les règles de sortie
    const requiredOutputRules = ['chat_response', 'documentation', 'walkthrough', 'task_file', 'implementation_plan'];
    const missingOutputRules = requiredOutputRules.filter(rule => !config.output_rules[rule]);

    if (missingOutputRules.length > 0) {
        console.error('❌ Règles de sortie manquantes:', missingOutputRules.join(', '));
        process.exit(1);
    }
    console.log('✅ Toutes les règles de sortie définies');

    // 6. Vérifier les invariants
    if (!Array.isArray(config.invariants) || config.invariants.length === 0) {
        console.error('❌ Invariants manquants ou invalides');
        process.exit(1);
    }
    console.log('✅ Invariants définis:', config.invariants.length);

    // 7. Vérifier la persistance
    if (!config.persistence.stop_trigger || !Array.isArray(config.persistence.stop_trigger)) {
        console.error('❌ Triggers de stop manquants');
        process.exit(1);
    }
    console.log('✅ Persistance configurée');

    // 8. Vérifier la structure de sortie
    if (!config.output_structure || !config.output_structure.root) {
        console.error('❌ Structure de sortie manquante');
        process.exit(1);
    }
    console.log('✅ Structure de sortie définie:', config.output_structure.root);

    console.log('\n✅ Configuration caveman valide!\n');

    // Afficher un résumé
    console.log('📊 Résumé:');
    console.log(`   Version: ${config.version}`);
    console.log(`   Niveaux: ${Object.keys(config.levels).join(', ')}`);
    console.log(`   Règles de sortie: ${Object.keys(config.output_rules).length}`);
    console.log(`   Invariants: ${config.invariants.length}`);
    console.log(`   Dossier de sortie: ${config.output_structure.root}`);
}

validateConfig();
