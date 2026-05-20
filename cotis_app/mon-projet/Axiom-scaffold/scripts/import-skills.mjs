#!/usr/bin/env node
/**
 * Import des skills depuis les dépôts externes
 * 
 * Ce script lit les dépôts clonés dans ~/.axiom/skills/,
 * normalise chaque skill au format Axiom, et met à jour le registre.
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import os from 'os';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Configuration
const AXIOM_SKILLS_DIR = path.join(os.homedir(), '.axiom', 'skills');
const PROJECT_SKILLS_DIR = path.join(process.cwd(), 'skills');
const REGISTRY_PATH = path.join(PROJECT_SKILLS_DIR, 'registry.json');

/**
 * Détecte le domaine d'un skill à partir de son contenu
 */
function detectDomain(content, filePath) {
    const lowerContent = content.toLowerCase();
    const lowerPath = filePath.toLowerCase();

    if (lowerContent.includes('security') || lowerContent.includes('owasp') || lowerPath.includes('security')) {
        return 'security';
    }
    if (lowerContent.includes('design') || lowerContent.includes('ui') || lowerPath.includes('design')) {
        return 'design';
    }
    if (lowerContent.includes('devops') || lowerContent.includes('kubernetes') || lowerPath.includes('devops')) {
        return 'devops';
    }
    return 'general';
}

/**
 * Extrait les triggers d'un skill
 */
function extractTriggers(content, title) {
    // Chercher dans le frontmatter YAML
    const frontmatterMatch = content.match(/^---\n([\s\S]*?)\n---/);
    if (frontmatterMatch) {
        const triggersMatch = frontmatterMatch[1].match(/triggers:\s*\[(.*?)\]/);
        if (triggersMatch) {
            return triggersMatch[1].split(',').map(t => t.trim().replace(/['"]/g, ''));
        }
    }

    // Sinon, utiliser le titre
    return [title.toLowerCase().replace(/[^a-z0-9]+/g, '-')];
}

/**
 * Normalise un skill au format Axiom
 */
function normalizeSkill(content, filePath, repoName) {
    // Extraire le titre
    const titleMatch = content.match(/^#\s+(.+)$/m);
    const title = titleMatch ? titleMatch[1] : path.basename(filePath, '.md');

    // Détecter le domaine
    const domain = detectDomain(content, filePath);

    // Extraire les triggers
    const triggers = extractTriggers(content, title);

    // Vérifier si le frontmatter existe déjà
    if (!content.startsWith('---')) {
        // Ajouter le frontmatter
        const frontmatter = `---
title: "${title}"
domain: "${domain}"
complexity: "intermediate"
triggers: [${triggers.map(t => `"${t}"`).join(', ')}]
priority: 5
source: "${repoName}"
---

`;
        content = frontmatter + content;
    }

    return {
        content,
        title,
        domain,
        triggers,
        source: repoName
    };
}

/**
 * Importe les skills d'un dépôt
 */
function importSkillsFromRepo(repoPath, repoName) {
    console.log(`\n📦 Import depuis ${repoName}...`);

    if (!fs.existsSync(repoPath)) {
        console.log(`   ⚠️  Dépôt non trouvé : ${repoPath}`);
        return [];
    }

    const skills = [];

    // Parcourir récursivement les fichiers .md
    function walkDir(dir) {
        const files = fs.readdirSync(dir);

        for (const file of files) {
            const filePath = path.join(dir, file);
            const stat = fs.statSync(filePath);

            if (stat.isDirectory()) {
                // Ignorer node_modules, .git, etc.
                if (!file.startsWith('.') && file !== 'node_modules') {
                    walkDir(filePath);
                }
            } else if (file.endsWith('.md') && file !== 'README.md') {
                try {
                    const content = fs.readFileSync(filePath, 'utf8');
                    const normalized = normalizeSkill(content, filePath, repoName);

                    // Générer un ID unique
                    const id = `${repoName}-${path.basename(file, '.md')}`.toLowerCase().replace(/[^a-z0-9-]/g, '-');

                    // Déterminer le chemin de destination
                    const destPath = path.join(PROJECT_SKILLS_DIR, normalized.domain, `${id}.md`);

                    skills.push({
                        id,
                        path: path.relative(process.cwd(), destPath),
                        triggers: normalized.triggers,
                        priority: 5,
                        domain: normalized.domain,
                        complexity: 'intermediate',
                        source: repoName,
                        content: normalized.content,
                        destPath
                    });
                } catch (error) {
                    console.log(`   ⚠️  Erreur lors de la lecture de ${file}: ${error.message}`);
                }
            }
        }
    }

    walkDir(repoPath);

    console.log(`   ✅ ${skills.length} skills trouvés`);
    return skills;
}

/**
 * Fonction principale
 */
async function main() {
    console.log('📚 Import des skills externes\n');

    // Vérifier que le répertoire des skills existe
    if (!fs.existsSync(AXIOM_SKILLS_DIR)) {
        console.log(`⚠️  Répertoire ${AXIOM_SKILLS_DIR} non trouvé`);
        console.log('   Exécutez d\'abord script/bootstrap.sh pour cloner les dépôts');
        process.exit(0);
    }

    // Lire les dépôts
    const repos = fs.readdirSync(AXIOM_SKILLS_DIR);
    console.log(`📁 ${repos.length} dépôts trouvés dans ${AXIOM_SKILLS_DIR}`);

    // Importer les skills de chaque dépôt
    let allSkills = [];
    for (const repo of repos) {
        const repoPath = path.join(AXIOM_SKILLS_DIR, repo);
        if (fs.statSync(repoPath).isDirectory()) {
            const skills = importSkillsFromRepo(repoPath, repo);
            allSkills = allSkills.concat(skills);
        }
    }

    console.log(`\n📝 ${allSkills.length} skills au total`);

    // Copier les skills dans le projet
    console.log('\n📋 Copie des skills...');
    for (const skill of allSkills) {
        fs.mkdirSync(path.dirname(skill.destPath), { recursive: true });
        fs.writeFileSync(skill.destPath, skill.content);
    }
    console.log(`   ✅ ${allSkills.length} skills copiés`);

    // Mettre à jour le registre
    console.log('\n📊 Mise à jour du registre...');
    const registry = JSON.parse(fs.readFileSync(REGISTRY_PATH, 'utf8'));

    // Ajouter les nouveaux skills (éviter les doublons)
    const existingIds = new Set(registry.skills.map(s => s.id));
    const newSkills = allSkills.filter(s => !existingIds.has(s.id));

    registry.skills.push(...newSkills.map(s => ({
        id: s.id,
        path: s.path,
        triggers: s.triggers,
        priority: s.priority,
        domain: s.domain,
        complexity: s.complexity,
        source: s.source
    })));

    registry.metadata.lastUpdated = new Date().toISOString();
    registry.metadata.totalSkills = registry.skills.length;
    registry.metadata.importedSkills = newSkills.length;

    fs.writeFileSync(REGISTRY_PATH, JSON.stringify(registry, null, 2));
    console.log(`   ✅ Registre mis à jour (${newSkills.length} nouveaux skills)`);

    console.log('\n✅ Import terminé avec succès !');
    console.log(`   Total : ${registry.skills.length} skills disponibles`);
}

main().catch(error => {
    console.error('❌ Erreur:', error);
    process.exit(1);
});
