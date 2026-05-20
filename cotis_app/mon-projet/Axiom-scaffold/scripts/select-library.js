#!/usr/bin/env node

/**
 * select-library.js
 * 
 * Sélectionne la meilleure bibliothèque de composants UI selon les critères fournis.
 * 
 * Usage:
 *   node scripts/select-library.js --framework react --style modern
 *   node scripts/select-library.js --framework react --style minimal --accessibility excellent
 *   node scripts/select-library.js --framework solid
 */

const fs = require('fs');
const path = require('path');

// Charger la base de données des bibliothèques
const dbPath = path.join(__dirname, '..', 'skills', 'design', 'bibliotheques.json');
const db = JSON.parse(fs.readFileSync(dbPath, 'utf-8'));

/**
 * Parse les arguments de ligne de commande
 */
function parseArgs() {
    const args = process.argv.slice(2);
    const options = {
        framework: null,
        style: null,
        accessibility: null,
        performance: false,
    };

    for (let i = 0; i < args.length; i++) {
        const arg = args[i];
        const nextArg = args[i + 1];

        if (arg === '--framework' && nextArg) {
            options.framework = nextArg.toLowerCase();
            i++;
        } else if (arg === '--style' && nextArg) {
            options.style = nextArg.toLowerCase();
            i++;
        } else if (arg === '--accessibility' && nextArg) {
            options.accessibility = nextArg.toLowerCase();
            i++;
        } else if (arg === '--performance') {
            options.performance = true;
        }
    }

    return options;
}

/**
 * Filtre les bibliothèques selon les critères
 */
function filterLibraries(libraries, options) {
    let filtered = [...libraries];

    // Filtre par framework
    if (options.framework) {
        filtered = filtered.filter(lib =>
            lib.technos.some(tech => tech.toLowerCase().includes(options.framework))
        );
    }

    // Filtre par style
    if (options.style) {
        filtered = filtered.filter(lib =>
            lib.style.toLowerCase() === options.style
        );
    }

    // Filtre par accessibilité
    if (options.accessibility) {
        filtered = filtered.filter(lib =>
            lib.accessibility.toLowerCase() === options.accessibility
        );
    }

    return filtered;
}

/**
 * Calcule un score de similarité pour chaque bibliothèque
 */
function scoreLibraries(libraries, options) {
    return libraries.map(lib => {
        let score = 0;
        let details = [];

        // Score d'accessibilité (poids: 3)
        if (lib.score.accessibility >= 9) {
            score += 30;
            details.push('Accessibilité excellente (+30)');
        } else if (lib.score.accessibility >= 7) {
            score += 20;
            details.push('Accessibilité bonne (+20)');
        } else {
            score += 10;
            details.push('Accessibilité moyenne (+10)');
        }

        // Score de personnalisation (poids: 2)
        if (lib.score.customization >= 9) {
            score += 20;
            details.push('Personnalisation excellente (+20)');
        } else if (lib.score.customization >= 7) {
            score += 15;
            details.push('Personnalisation bonne (+15)');
        } else {
            score += 10;
            details.push('Personnalisation limitée (+10)');
        }

        // Score de performance (poids: 2 si demandé, sinon 1)
        const perfWeight = options.performance ? 2 : 1;
        if (lib.score.performance >= 9) {
            score += 20 * perfWeight;
            details.push(`Performance excellente (+${20 * perfWeight})`);
        } else if (lib.score.performance >= 7) {
            score += 15 * perfWeight;
            details.push(`Performance bonne (+${15 * perfWeight})`);
        } else {
            score += 10 * perfWeight;
            details.push(`Performance moyenne (+${10 * perfWeight})`);
        }

        // Score de documentation (poids: 1)
        if (lib.score.documentation >= 9) {
            score += 10;
            details.push('Documentation excellente (+10)');
        } else if (lib.score.documentation >= 7) {
            score += 7;
            details.push('Documentation bonne (+7)');
        } else {
            score += 5;
            details.push('Documentation moyenne (+5)');
        }

        // Bonus pour correspondance exacte du style
        if (options.style && lib.style.toLowerCase() === options.style) {
            score += 10;
            details.push('Style correspondant (+10)');
        }

        return {
            ...lib,
            totalScore: score,
            scoreDetails: details,
        };
    });
}

/**
 * Sélectionne la meilleure bibliothèque
 */
function selectBestLibrary(libraries) {
    if (libraries.length === 0) {
        return null;
    }

    // Trier par score décroissant
    const sorted = libraries.sort((a, b) => b.totalScore - a.totalScore);

    return sorted[0];
}

/**
 * Formate le résultat en JSON
 */
function formatResult(library, allCandidates) {
    if (!library) {
        return {
            success: false,
            error: 'Aucune bibliothèque ne correspond aux critères',
            candidates: [],
        };
    }

    return {
        success: true,
        selected: {
            id: library.id,
            name: library.name,
            technos: library.technos,
            style: library.style,
            accessibility: library.accessibility,
            url: library.url,
            score: library.totalScore,
            scoreDetails: library.scoreDetails,
            strengths: library.strengths,
            weaknesses: library.weaknesses,
        },
        alternatives: allCandidates
            .filter(lib => lib.id !== library.id)
            .slice(0, 3)
            .map(lib => ({
                id: lib.id,
                name: lib.name,
                score: lib.totalScore,
                reason: lib.scoreDetails[0],
            })),
    };
}

/**
 * Main
 */
function main() {
    const options = parseArgs();

    // Validation
    if (!options.framework) {
        console.error('❌ Erreur: --framework est requis');
        console.error('Usage: node scripts/select-library.js --framework react --style modern');
        process.exit(1);
    }

    // Filtrer les bibliothèques
    const filtered = filterLibraries(db.libraries, options);

    if (filtered.length === 0) {
        console.error(JSON.stringify({
            success: false,
            error: `Aucune bibliothèque trouvée pour framework="${options.framework}" style="${options.style}"`,
            availableFrameworks: Object.keys(db.technoIndex),
            availableStyles: Object.keys(db.styleCategories),
        }, null, 2));
        process.exit(1);
    }

    // Scorer les bibliothèques
    const scored = scoreLibraries(filtered, options);

    // Sélectionner la meilleure
    const best = selectBestLibrary(scored);

    // Formater et afficher le résultat
    const result = formatResult(best, scored);
    console.log(JSON.stringify(result, null, 2));

    process.exit(0);
}

// Exécuter si appelé directement
if (require.main === module) {
    main();
}

module.exports = { filterLibraries, scoreLibraries, selectBestLibrary };
