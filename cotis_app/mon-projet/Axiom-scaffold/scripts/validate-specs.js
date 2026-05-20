#!/usr/bin/env node
/**
 * Validation des spécifications
 * 
 * Ce script vérifie la cohérence des specs :
 * - OpenAPI valide
 * - Liens non cassés
 * - Frontmatter YAML valide
 */

const fs = require('fs');
const path = require('path');

// Configuration
const SPECS_DIR = 'specs';
const SKILLS_DIR = 'skills';

let errors = [];
let warnings = [];

/**
 * Valide un fichier OpenAPI
 */
function validateOpenAPI(filePath) {
    console.log(`🔍 Validation OpenAPI : ${filePath}`);

    try {
        const content = fs.readFileSync(filePath, 'utf8');

        // Vérifier que c'est du YAML valide
        // Note : pour une vraie validation, utiliser swagger-parser
        if (!content.includes('openapi:')) {
            errors.push(`${filePath}: Pas de version OpenAPI spécifiée`);
            return;
        }

        // Vérifications basiques
        if (!content.includes('info:')) {
            errors.push(`${filePath}: Section 'info' manquante`);
        }
        if (!content.includes('paths:')) {
            warnings.push(`${filePath}: Section 'paths' manquante`);
        }

        console.log(`   ✅ ${filePath} valide`);
    } catch (error) {
        errors.push(`${filePath}: ${error.message}`);
    }
}

/**
 * Valide les liens dans un fichier Markdown
 */
function validateMarkdownLinks(filePath) {
    try {
        const content = fs.readFileSync(filePath, 'utf8');
        const dir = path.dirname(filePath);

        // Extraire les liens relatifs
        const linkRegex = /\[([^\]]+)\]\(([^)]+)\)/g;
        let match;

        while ((match = linkRegex.exec(content)) !== null) {
            const linkText = match[1];
            const linkPath = match[2];

            // Ignorer les liens externes
            if (linkPath.startsWith('http://') || linkPath.startsWith('https://')) {
                continue;
            }

            // Ignorer les ancres
            if (linkPath.startsWith('#')) {
                continue;
            }

            // Vérifier que le fichier existe
            const fullPath = path.resolve(dir, linkPath);
            if (!fs.existsSync(fullPath)) {
                warnings.push(`${filePath}: Lien cassé vers ${linkPath}`);
            }
        }
    } catch (error) {
        errors.push(`${filePath}: ${error.message}`);
    }
}

/**
 * Valide le frontmatter YAML d'un skill
 */
function validateSkillFrontmatter(filePath) {
    try {
        const content = fs.readFileSync(filePath, 'utf8');

        // Vérifier le frontmatter
        if (!content.startsWith('---')) {
            warnings.push(`${filePath}: Pas de frontmatter YAML`);
            return;
        }

        const frontmatterMatch = content.match(/^---\n([\s\S]*?)\n---/);
        if (!frontmatterMatch) {
            errors.push(`${filePath}: Frontmatter YAML invalide`);
            return;
        }

        const frontmatter = frontmatterMatch[1];

        // Vérifier les champs obligatoires
        const requiredFields = ['title', 'domain', 'triggers'];
        for (const field of requiredFields) {
            if (!frontmatter.includes(`${field}:`)) {
                errors.push(`${filePath}: Champ '${field}' manquant dans le frontmatter`);
            }
        }
    } catch (error) {
        errors.push(`${filePath}: ${error.message}`);
    }
}

/**
 * Parcourt récursivement un répertoire
 */
function walkDir(dir, callback) {
    if (!fs.existsSync(dir)) {
        return;
    }

    const files = fs.readdirSync(dir);

    for (const file of files) {
        const filePath = path.join(dir, file);
        const stat = fs.statSync(filePath);

        if (stat.isDirectory()) {
            walkDir(filePath, callback);
        } else {
            callback(filePath);
        }
    }
}

/**
 * Fonction principale
 */
function main() {
    console.log('🔍 Validation des spécifications\n');

    // Valider les fichiers OpenAPI
    console.log('📋 Validation des contrats API...');
    walkDir(path.join(SPECS_DIR, 'technical', 'api-contracts'), (filePath) => {
        if (filePath.endsWith('.yaml') || filePath.endsWith('.yml')) {
            validateOpenAPI(filePath);
        }
    });

    // Valider les liens dans les specs
    console.log('\n🔗 Validation des liens...');
    walkDir(SPECS_DIR, (filePath) => {
        if (filePath.endsWith('.md')) {
            validateMarkdownLinks(filePath);
        }
    });

    // Valider les skills
    console.log('\n🧩 Validation des skills...');
    walkDir(SKILLS_DIR, (filePath) => {
        if (filePath.endsWith('.md') && !filePath.includes('.gitkeep')) {
            validateSkillFrontmatter(filePath);
        }
    });

    // Afficher les résultats
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    if (errors.length === 0 && warnings.length === 0) {
        console.log('✅ Toutes les validations sont passées !');
        process.exit(0);
    }

    if (warnings.length > 0) {
        console.log(`\n⚠️  ${warnings.length} avertissement(s) :\n`);
        warnings.forEach(w => console.log(`   - ${w}`));
    }

    if (errors.length > 0) {
        console.log(`\n❌ ${errors.length} erreur(s) :\n`);
        errors.forEach(e => console.log(`   - ${e}`));
        process.exit(1);
    }

    process.exit(0);
}

main();
