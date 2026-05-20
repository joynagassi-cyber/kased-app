#!/usr/bin/env node

/**
 * validate-colors.js
 * 
 * Extrait les couleurs hexadécimales d'un fichier HTML et valide qu'elles sont
 * toutes présentes dans le design system (design/design-system.json).
 * 
 * Usage:
 *   node scripts/validate-colors.js design/screens/login.html
 *   node scripts/validate-colors.js design/screens/*.html
 */

const fs = require('fs');
const path = require('path');

// Charger le design system
const designSystemPath = path.join(__dirname, '..', 'design', 'design-system.json');
const designSystem = JSON.parse(fs.readFileSync(designSystemPath, 'utf-8'));

/**
 * Extrait toutes les couleurs hexadécimales autorisées du design system
 */
function extractAuthorizedColors() {
    const colors = new Set();

    // Parcourir toutes les catégories de couleurs
    for (const [category, shades] of Object.entries(designSystem.color)) {
        if (typeof shades === 'object' && shades !== null) {
            for (const [shade, data] of Object.entries(shades)) {
                if (data && data.value) {
                    // Normaliser en minuscules
                    colors.add(data.value.toLowerCase());
                }
            }
        }
    }

    return colors;
}

/**
 * Extrait toutes les couleurs hexadécimales d'un fichier HTML
 */
function extractColorsFromHTML(htmlContent) {
    const colors = new Set();

    // Regex pour capturer les couleurs hex (#RGB, #RRGGBB, #RRGGBBAA)
    const hexRegex = /#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})\b/g;

    let match;
    while ((match = hexRegex.exec(htmlContent)) !== null) {
        // Normaliser en minuscules et format 6 caractères
        let color = match[0].toLowerCase();

        // Convertir #RGB en #RRGGBB
        if (color.length === 4) {
            color = '#' + color[1] + color[1] + color[2] + color[2] + color[3] + color[3];
        }

        colors.add(color);
    }

    return colors;
}

/**
 * Valide les couleurs d'un fichier HTML
 */
function validateHTMLFile(filePath) {
    // Lire le fichier HTML
    const htmlContent = fs.readFileSync(filePath, 'utf-8');

    // Extraire les couleurs
    const usedColors = extractColorsFromHTML(htmlContent);
    const authorizedColors = extractAuthorizedColors();

    // Trouver les couleurs non autorisées
    const unauthorized = [];
    for (const color of usedColors) {
        if (!authorizedColors.has(color)) {
            unauthorized.push(color);
        }
    }

    return {
        file: path.basename(filePath),
        totalColors: usedColors.size,
        authorizedCount: usedColors.size - unauthorized.length,
        unauthorizedCount: unauthorized.length,
        unauthorized: unauthorized,
        valid: unauthorized.length === 0,
    };
}

/**
 * Formate le résultat en JSON
 */
function formatResult(results) {
    const allValid = results.every(r => r.valid);

    return {
        success: allValid,
        summary: {
            totalFiles: results.length,
            validFiles: results.filter(r => r.valid).length,
            invalidFiles: results.filter(r => !r.valid).length,
        },
        files: results,
        message: allValid
            ? '✅ Toutes les couleurs sont conformes au design system'
            : '❌ Certaines couleurs ne sont pas dans le design system',
    };
}

/**
 * Main
 */
function main() {
    const args = process.argv.slice(2);

    if (args.length === 0) {
        console.error('❌ Erreur: Aucun fichier spécifié');
        console.error('Usage: node scripts/validate-colors.js <fichier.html> [fichier2.html ...]');
        process.exit(1);
    }

    // Valider chaque fichier
    const results = [];
    for (const filePath of args) {
        if (!fs.existsSync(filePath)) {
            console.error(`❌ Erreur: Fichier introuvable: ${filePath}`);
            continue;
        }

        try {
            const result = validateHTMLFile(filePath);
            results.push(result);
        } catch (error) {
            console.error(`❌ Erreur lors de la validation de ${filePath}:`, error.message);
        }
    }

    if (results.length === 0) {
        console.error('❌ Aucun fichier valide à traiter');
        process.exit(1);
    }

    // Formater et afficher le résultat
    const output = formatResult(results);
    console.log(JSON.stringify(output, null, 2));

    // Code de sortie
    process.exit(output.success ? 0 : 1);
}

// Exécuter si appelé directement
if (require.main === module) {
    main();
}

module.exports = { extractAuthorizedColors, extractColorsFromHTML, validateHTMLFile };
