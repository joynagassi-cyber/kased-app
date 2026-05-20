# Couche 6 — Visualisation Vivante : Documentation Complète

**Version** : 1.0.0  
**Date** : 2026-05-08  
**Statut** : ✅ Implémenté

---

## 📋 Table des Matières

1. [Introduction](#introduction)
2. [Objectifs](#objectifs)
3. [Architecture](#architecture)
4. [Installation](#installation)
5. [Utilisation](#utilisation)
6. [Fonctionnalités](#fonctionnalités)
7. [Intégration](#intégration)
8. [Performance](#performance)
9. [Personnalisation](#personnalisation)
10. [Dépannage](#dépannage)

---

## 1. Introduction

La **Couche 6 (Visualisation Vivante)** d'Axiom-Scaffold transforme le super-graphe de connaissances (Couche 1) en une **carte interactive du code**, accessible dans n'importe quel navigateur.

### Principe Fondamental

> **Rendre le code visible.** Une représentation visuelle claire permet de comprendre l'architecture, identifier les dépendances, et naviguer dans la complexité.

### Innovation Majeure

La fusion de **deux paradigmes** :
- **Moteur de graphe algorithmique** (AntV G6 ou Cosmos.gl) : calcul automatique des positions, clusters, et flux
- **Calque de dessin libre** (Excalidraw) : annotations manuelles, comme sur un tableau blanc

### Résultat

Un **fichier HTML unique** (`graph.html`) :
- ✅ Autonome (pas de serveur requis)
- ✅ Interactif (zoom, recherche, navigation)
- ✅ Annotable (dessins, notes, post-its)
- ✅ Performant (jusqu'à 1M de nœuds avec GPU)

---

## 2. Objectifs

### Objectifs Principaux

1. **Représenter le super-graphe** avec nœuds (fichiers/fonctions) et arêtes (dépendances)
2. **Mettre en évidence les clusters** fonctionnels par code couleur
3. **Afficher le score d'impact** de chaque nœud (taille proportionnelle au risque)
4. **Animer les flux d'exécution** pour suivre le chemin d'une fonctionnalité
5. **Permettre l'annotation libre** avec Excalidraw (sauvegardée en JSON Canvas)
6. **Aider au débogage** : nœuds en erreur clignotent en rouge
7. **Rester performant** : G6 pour <10k nœuds, Cosmos.gl (GPU) pour >10k
8. **Être auto-suffisant** : un seul fichier HTML avec toutes les ressources
9. **Faciliter la compréhension** : infobulles avec résumés IA
10. **Utiliser Pretext** pour des infobulles ultra-rapides (500× plus rapide)

### Bénéfices

- **Développeurs** : comprendre l'architecture, identifier les dépendances critiques
- **Architectes** : visualiser les clusters, détecter les couplages forts
- **Non-techniciens** : explorer le code visuellement, comprendre les flux
- **Débogage** : identifier rapidement les nœuds problématiques
- **Documentation** : annoter et partager des vues personnalisées

---

## 3. Architecture

### Vue d'Ensemble

```
┌─────────────────────────────────────────────────────────────────┐
│               COUCHE 6 – VISUALISATION VIVANTE                  │
│                                                                  │
│  graph/super-graph.json   (Couche 1)                            │
│        │                                                         │
│        ▼                                                         │
│  build-visualizer.sh                                             │
│        │                                                         │
│        ├─→ Détermine le nombre de nœuds                         │
│        │      ├─ < 10 000 → utilise G6 (SVG/Canvas)            │
│        │      └─ ≥ 10 000 → utilise Cosmos.gl (WebGL/WebGPU)   │
│        │                                                         │
│        ├─→ Calcule les layouts (force, dagre, radial)           │
│        ├─→ Colore les clusters (via Graphify)                   │
│        ├─→ Intègre Pretext pour les mesures rapides             │
│        ├─→ Embarque Excalidraw en overlay                       │
│        └─→ Sauvegarde les annotations dans design/canvas.json   │
│                                                                  │
│  Sortie : graph.html (fichier unique, prêt à ouvrir)           │
└─────────────────────────────────────────────────────────────────┘
```

### Composants

#### 1. Script de Génération
- **`scripts/build-visualizer.sh`** : Génère `graph.html` à partir du super-graphe
- Détecte automatiquement le nombre de nœuds
- Sélectionne le moteur de rendu approprié
- Injecte les données JSON dans le template HTML

#### 2. Templates HTML
- **`templates/g6-excalidraw-template.html`** : Pour graphes <10k nœuds
  - AntV G6 pour le rendu
  - Excalidraw pour les annotations
  - Layouts : force, dagre, radial
- **`templates/cosmos-template.html`** : Pour graphes ≥10k nœuds
  - Cosmos.gl pour le rendu GPU
  - Performance optimale (>30 FPS pour 1M nœuds)

#### 3. Données
- **`graph/super-graph.json`** : Source de données (Couche 1)
- **`design/canvas.json`** : Annotations Excalidraw (JSON Canvas)

#### 4. Sortie
- **`graph.html`** : Visualiseur autonome (généré, peut être gitignoré)

---

## 4. Installation

### Prérequis

- Couche 1 (Mémoire Universelle) installée
- Super-graphe généré (`graph/super-graph.json`)
- Python 3 ou jq (pour l'injection de données)

### Installation

Aucune installation spécifique requise. Le script utilise des CDN pour les librairies.

### Vérification

```bash
# Vérifier que le super-graphe existe
ls -lh graph/super-graph.json

# Vérifier que les templates existent
ls -lh templates/
```

---

## 5. Utilisation

### Génération du Visualiseur

```bash
# Générer graph.html
./scripts/build-visualizer.sh
```

**Sortie** :
```
ℹ Génération du visualiseur à partir de graph/super-graph.json...
ℹ Nombre de nœuds détectés : 1234
ℹ 🎨 Utilisation de G6 + Excalidraw pour 1234 nœuds
✓ Template copié
ℹ Injection des données du graphe...
✓ Données injectées avec succès
ℹ Taille du fichier généré : 2.3M
✓ ✨ graph.html généré avec succès !
ℹ Ouvrez-le dans un navigateur : file:///path/to/graph.html
```

### Ouverture du Visualiseur

```bash
# Linux
xdg-open graph.html

# macOS
open graph.html

# Windows
start graph.html

# Ou double-cliquez sur graph.html
```

### Mise à Jour Automatique

Le visualiseur est automatiquement régénéré après chaque modification du code (via `script/after-agent.sh`).

---

## 6. Fonctionnalités

### 6.1 Navigation

#### Zoom
- **Molette de la souris** : Zoom avant/arrière
- **Pinch** (tactile) : Zoom avant/arrière
- **Bouton "Ajuster"** : Ajuste la vue pour afficher tout le graphe

#### Déplacement
- **Cliquer-glisser** (fond) : Déplacer la vue
- **Cliquer-glisser** (nœud) : Déplacer un nœud

#### Sélection
- **Clic** sur un nœud : Sélectionner
- **Clic** sur le fond : Désélectionner

### 6.2 Recherche

#### Barre de Recherche
- Tapez le nom d'un symbole
- Le graphe zoome automatiquement sur le nœud correspondant
- Les nœuds correspondants sont mis en surbrillance

**Exemple** :
```
🔍 validateEmail
→ Zoome sur le nœud "validateEmail"
```

### 6.3 Layouts

#### Force Layout (par défaut)
- Simulation physique (forces d'attraction/répulsion)
- Idéal pour visualiser les clusters naturels
- **Bouton** : "Force"

#### Dagre Layout
- Disposition hiérarchique (top-down)
- Idéal pour visualiser les dépendances
- **Bouton** : "Dagre"

#### Radial Layout
- Disposition radiale (centre → périphérie)
- Idéal pour visualiser l'importance des nœuds
- **Bouton** : "Radial"

### 6.4 Clusters

#### Légende
- Liste des clusters avec leur couleur
- Résumé IA de chaque cluster
- Nombre de nœuds par cluster

#### Focus sur un Cluster
- **Clic** sur un cluster dans la légende
- Les nœuds du cluster sont mis en surbrillance
- Les autres nœuds sont atténués (3 secondes)

### 6.5 Mode Flux

#### Activation
- **Bouton** : "🔀 Mode Flux"
- Permet de visualiser le chemin entre deux nœuds

#### Utilisation
1. Cliquez sur le nœud de départ
2. Cliquez sur le nœud d'arrivée
3. Le chemin est animé (surbrillance progressive)

**Exemple** :
```
Clic sur "login" → Clic sur "database"
→ Affiche le chemin : login → auth → validateToken → database
```

### 6.6 Annotations (Excalidraw)

#### Activation
- **Bouton** : "✏️ Annoter"
- Active le calque Excalidraw en superposition

#### Outils Disponibles
- **Sélection** : Sélectionner et déplacer
- **Rectangle** : Dessiner un rectangle
- **Ellipse** : Dessiner une ellipse
- **Flèche** : Dessiner une flèche
- **Ligne** : Dessiner une ligne
- **Texte** : Ajouter du texte
- **Dessin libre** : Dessiner à main levée

#### Sauvegarde
- **Bouton** : "💾 Sauvegarder"
- Télécharge un fichier `canvas.json`
- Copiez ce fichier dans `design/canvas.json`
- Les annotations seront chargées au prochain lancement

**Format** : JSON Canvas (compatible Obsidian)

### 6.7 Infobulles

#### Affichage
- **Survol** d'un nœud : Affiche une infobulle

#### Contenu
- **Nom** du symbole
- **Cluster** d'appartenance
- **Score d'impact** (risque de changement)
- **Chemin** du fichier
- **Résumé** IA (si disponible)

**Exemple** :
```
validateEmail
Cluster: utils
Impact: 0.85
Chemin: src/utils/validation.ts
Résumé: Valide les adresses email avec regex RFC 5322
```

### 6.8 Statistiques

#### Affichage
- **Coin inférieur gauche** : Statistiques en temps réel

#### Métriques
- **Nœuds** : Nombre total de nœuds
- **Arêtes** : Nombre total d'arêtes
- **Clusters** : Nombre de clusters
- **FPS** : Images par seconde (Cosmos.gl uniquement)

---

## 7. Intégration

### 7.1 Couche 0 (Harness Engineering)

**Intégration** : `script/after-agent.sh` appelle `build-visualizer.sh`

```bash
# Extrait de after-agent.sh
echo "🎨 Régénération du visualiseur..."
./scripts/build-visualizer.sh
```

### 7.2 Couche 1 (Mémoire Universelle)

**Source de données** : `graph/super-graph.json`

Le super-graphe contient :
- **Nœuds** : fichiers, fonctions, classes
- **Arêtes** : dépendances, appels, imports
- **Clusters** : modules fonctionnels (via Graphify)
- **Résumés IA** : descriptions générées par LLM
- **Scores d'impact** : risque de changement (centralité)

### 7.3 Couche 2 (Spécifications & Skills)

**Validation** : Les règles de design sont vérifiées visuellement
- Pas de nœud trop petit (lisibilité)
- Contraste respecté (accessibilité)
- Couleurs du design system

### 7.4 Couche 4 (Design & UI)

**Maquettes** : Les maquettes HTML peuvent être affichées en infobulle
- Lien vers les screenshots
- Aperçu de l'interface

### 7.5 Couche 5 (Exécution Zero-Trust)

**Débogage** : En cas d'échec de validation
- Les symboles fautifs sont marqués en rouge
- Le chemin d'exécution est mis en évidence
- L'infobulle affiche l'erreur

**Exemple** :
```javascript
// Dans execute-task.sh
if [ $VALIDATION_FAILED ]; then
  echo '{"errorNodes": ["validateEmail", "checkFormat"]}' > logs/execution/errors.json
fi
```

Le visualiseur lit ce fichier et marque les nœuds en rouge.

### 7.6 Couche 7 (Apprentissage)

**Patterns de navigation** : Les chemins fréquents sont enregistrés
- Suggestion de vues prédéfinies
- Raccourcis vers les clusters importants

### 7.7 Couche 8 (Sécurité)

**Vulnérabilités** : Les nœuds vulnérables affichent une icône d'alerte
- Lien vers le rapport de sécurité
- Niveau de criticité (high, medium, low)

---

## 8. Performance

### 8.1 Seuils de Performance

| Nœuds      | Moteur      | FPS   | Temps de Chargement |
| ---------- | ----------- | ----- | ------------------- |
| < 1 000    | G6 (SVG)    | 60    | < 1s                |
| 1k - 10k   | G6 (Canvas) | 30-60 | 1-3s                |
| 10k - 100k | Cosmos.gl   | 30-60 | 3-10s               |
| > 100k     | Cosmos.gl   | 30+   | 10-30s              |

### 8.2 Optimisations

#### G6 (< 10k nœuds)
- Rendu Canvas (plus rapide que SVG)
- Culling (nœuds hors écran non rendus)
- LOD (Level of Detail) : simplification à distance

#### Cosmos.gl (≥ 10k nœuds)
- Rendu GPU (WebGL/WebGPU)
- Instancing (rendu de milliers de nœuds en une seule passe)
- Compute shaders (calculs de layout sur GPU)

#### Pretext (Infobulles)
- Mesure de texte sans DOM (500× plus rapide)
- Cache des mesures
- Pas de layout thrashing

### 8.3 Limites

| Métrique                 | Limite    | Recommandation                    |
| ------------------------ | --------- | --------------------------------- |
| Taille du fichier        | 5 Mo      | Compresser ou filtrer les données |
| Nombre de nœuds (G6)     | 10 000    | Basculer vers Cosmos.gl           |
| Nombre de nœuds (Cosmos) | 1 000 000 | Filtrer les nœuds peu importants  |
| FPS minimum              | 30        | Réduire le nombre de nœuds        |

---

## 9. Personnalisation

### 9.1 Couleurs des Clusters

Éditer `templates/g6-excalidraw-template.html` :

```javascript
const CLUSTER_COLORS = [
    '#4a9eff', // Bleu
    '#2ecc71', // Vert
    '#e74c3c', // Rouge
    '#f39c12', // Orange
    '#9b59b6', // Violet
    // Ajouter vos couleurs ici
];
```

### 9.2 Taille des Nœuds

Éditer la fonction `processGraphData` :

```javascript
size: Math.max(20, Math.min(60, (node.impactScore || 1) * 30)),
//             ^^           ^^                              ^^
//             min          max                             facteur
```

### 9.3 Layouts

Éditer la configuration du layout :

```javascript
layout: {
    type: 'force',
    preventOverlap: true,
    nodeSpacing: 50,      // Espacement entre nœuds
    linkDistance: 150     // Distance des arêtes
}
```

### 9.4 Styles des Arêtes

Éditer la fonction `processGraphData` :

```javascript
style: {
    stroke: '#666',                    // Couleur
    lineWidth: 2,                      // Épaisseur
    endArrow: {                        // Flèche
        path: G6.Arrow.triangle(8, 10, 0),
        fill: '#666'
    }
}
```

---

## 10. Dépannage

### Problème : Le fichier graph.html n'est pas généré

**Cause** : Le super-graphe n'existe pas

**Solution** :
```bash
# Générer le super-graphe
./scripts/index-memory.sh

# Puis régénérer le visualiseur
./scripts/build-visualizer.sh
```

### Problème : Le graphe est vide

**Cause** : Les données ne sont pas injectées correctement

**Solution** :
```bash
# Vérifier que Python 3 est installé
python3 --version

# Ou installer jq
sudo apt-get install jq  # Linux
brew install jq          # macOS
```

### Problème : Le graphe est lent

**Cause** : Trop de nœuds pour G6

**Solution** :
```bash
# Forcer l'utilisation de Cosmos.gl
# Éditer build-visualizer.sh et changer le seuil :
if [ "$NODE_COUNT" -ge 5000 ]; then  # Au lieu de 10000
```

### Problème : Les annotations ne se sauvegardent pas

**Cause** : Le fichier `canvas.json` n'est pas copié

**Solution** :
```bash
# Après avoir cliqué sur "💾 Sauvegarder"
# Copier le fichier téléchargé dans design/
cp ~/Downloads/canvas.json design/canvas.json

# Régénérer le visualiseur
./scripts/build-visualizer.sh
```

### Problème : Les infobulles ne s'affichent pas

**Cause** : Les métadonnées sont manquantes dans le super-graphe

**Solution** :
```bash
# Vérifier le contenu du super-graphe
jq '.nodes[0]' graph/super-graph.json

# Régénérer le super-graphe avec Graphify
./scripts/index-memory.sh
```

### Problème : Le fichier est trop volumineux (>5 Mo)

**Cause** : Trop de données dans le super-graphe

**Solution** :
```bash
# Filtrer les nœuds peu importants
jq '.nodes |= map(select(.impactScore > 0.1))' graph/super-graph.json > graph/filtered.json

# Utiliser le graphe filtré
./scripts/build-visualizer.sh graph/filtered.json
```

---

## 📚 Ressources

### Documentation
- **[AntV G6](https://g6.antv.vision/)** : Documentation officielle de G6
- **[Cosmos.gl](https://cosmograph.app/)** : Documentation officielle de Cosmos.gl
- **[Excalidraw](https://excalidraw.com/)** : Documentation officielle d'Excalidraw
- **[JSON Canvas](https://jsoncanvas.org/)** : Spécification du format JSON Canvas

### Exemples
- **`templates/g6-excalidraw-template.html`** : Template G6 + Excalidraw
- **`templates/cosmos-template.html`** : Template Cosmos.gl
- **`scripts/build-visualizer.sh`** : Script de génération

### Support
- **Issues** : Consultez les issues fermées similaires
- **Wiki** : Généré automatiquement par GitNexus
- **Skills** : Activez un skill spécialisé si nécessaire

---

## 🎉 Conclusion

La **Couche 6 (Visualisation Vivante)** transforme le super-graphe en une carte interactive du code, accessible dans n'importe quel navigateur.

**Vous pouvez maintenant** :
- ✅ Visualiser l'architecture de votre projet
- ✅ Identifier les dépendances critiques
- ✅ Explorer les clusters fonctionnels
- ✅ Suivre les flux d'exécution
- ✅ Annoter et partager des vues personnalisées
- ✅ Déboguer visuellement
- ✅ Comprendre le code sans le lire

**Prochaine étape** : Couche 7 (Apprentissage) 🚀

---

**Date** : 2026-05-08  
**Version** : 1.7.0  
**Auteur** : Axiom-Scaffold Team
