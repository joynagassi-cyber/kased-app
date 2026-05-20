# OWASP Top 10 for Agentic AI Security – Politiques Axiom-Scaffold

**Version** : 2024  
**Référence** : https://genai.owasp.org/  
**Statut** : Obligatoire pour tous les agents IA

---

## AGENT01 – Prompt Injection

### Risque
Manipulation de l'agent via des instructions malveillantes dans les entrées utilisateur ou les données externes.

### Contre-mesures obligatoires
- ✅ Séparer les instructions système des données utilisateur
- ✅ Valider et échapper toutes les entrées avant de les passer à l'agent
- ✅ Utiliser des délimiteurs clairs (XML tags, JSON)
- ✅ Implémenter un filtre de détection de prompt injection
- ✅ Limiter les capacités de l'agent (principe du moindre privilège)
- ✅ Ne jamais inclure de secrets dans les prompts

### Exemple sécurisé
```typescript
// ❌ DANGEREUX
const prompt = `Analyze this user input: ${userInput}`;

// ✅ SÉCURISÉ
const prompt = `
<system>You are a code analyzer. Only analyze the code provided.</system>
<user_input>
${escapeXml(userInput)}
</user_input>
<instruction>Analyze the code above and provide feedback.</instruction>
`;
```

---

## AGENT02 – Insecure Output Handling

### Risque
Exécution de code malveillant généré par l'agent, injection XSS, injection SQL.

### Contre-mesures obligatoires
- ✅ Valider toutes les sorties de l'agent avant utilisation
- ✅ Échapper les sorties avant affichage (HTML, SQL, shell)
- ✅ Utiliser des sandbox pour l'exécution de code généré
- ✅ Implémenter une liste blanche de commandes autorisées
- ✅ Ne jamais exécuter directement du code généré sans validation

### Exemple sécurisé
```typescript
// ❌ DANGEREUX
eval(agentOutput);

// ✅ SÉCURISÉ
const AllowedCommands = ['read_file', 'write_file', 'list_directory'];

function executeAgentAction(action: any) {
  if (!AllowedCommands.includes(action.command)) {
    throw new Error(`Command not allowed: ${action.command}`);
  }
  
  // Valider les paramètres
  const schema = getSchemaForCommand(action.command);
  const validated = schema.parse(action.params);
  
  // Exécuter dans un sandbox
  return sandbox.execute(action.command, validated);
}
```

---

## AGENT03 – Training Data Poisoning

### Risque
Manipulation du comportement de l'agent via des données d'entraînement malveillantes.

### Contre-mesures obligatoires
- ✅ Valider toutes les données avant indexation dans la mémoire
- ✅ Implémenter une revue humaine des données sensibles
- ✅ Utiliser des checksums pour détecter les modifications
- ✅ Séparer les données de confiance des données externes
- ✅ Implémenter un système de réputation pour les sources

---

## AGENT04 – Model Denial of Service

### Risque
Épuisement des ressources via des requêtes coûteuses, déni de service.

### Contre-mesures obligatoires
- ✅ Implémenter un rate limiting par utilisateur et par IP
- ✅ Limiter la longueur des prompts (tokens)
- ✅ Implémenter des timeouts sur toutes les requêtes
- ✅ Utiliser un système de quotas
- ✅ Détecter et bloquer les patterns d'abus

### Configuration recommandée
```typescript
const LIMITS = {
  maxPromptTokens: 4000,
  maxCompletionTokens: 2000,
  requestsPerMinute: 10,
  requestsPerHour: 100,
  timeout: 30000, // 30 secondes
};
```

---

## AGENT05 – Supply Chain Vulnerabilities

### Risque
Compromission via des dépendances malveillantes, des modèles backdoorés, des plugins non sécurisés.

### Contre-mesures obligatoires
- ✅ Auditer toutes les dépendances (`npm audit`, `pip-audit`)
- ✅ Utiliser des versions épinglées
- ✅ Vérifier les checksums des modèles téléchargés
- ✅ Utiliser des registres de confiance uniquement
- ✅ Implémenter une revue de code pour tous les plugins
- ✅ Signer tous les artefacts

---

## AGENT06 – Sensitive Information Disclosure

### Risque
Fuite de données sensibles via les réponses de l'agent, les logs, les prompts.

### Contre-mesures obligatoires
- ✅ Ne jamais inclure de secrets dans les prompts
- ✅ Filtrer les données sensibles dans les réponses
- ✅ Implémenter une détection de PII (Personally Identifiable Information)
- ✅ Chiffrer les logs contenant des données sensibles
- ✅ Implémenter une politique de rétention des données
- ✅ Anonymiser les données de debug

### Exemple sécurisé
```typescript
function sanitizeOutput(output: string): string {
  // Supprimer les patterns de secrets
  output = output.replace(/sk-[a-zA-Z0-9]{48}/g, '[REDACTED_API_KEY]');
  output = output.replace(/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/g, '[REDACTED_EMAIL]');
  output = output.replace(/\b\d{3}-\d{2}-\d{4}\b/g, '[REDACTED_SSN]');
  
  return output;
}
```

---

## AGENT07 – Insecure Plugin Design

### Risque
Exécution de code malveillant via des plugins non sécurisés, élévation de privilèges.

### Contre-mesures obligatoires
- ✅ Implémenter un système de permissions pour les plugins
- ✅ Exécuter les plugins dans des sandbox isolés
- ✅ Valider toutes les entrées et sorties des plugins
- ✅ Implémenter une liste blanche de plugins autorisés
- ✅ Auditer le code de tous les plugins avant activation
- ✅ Utiliser MCP Shield pour intercepter les appels

### Architecture sécurisée
```
Agent → MCP Shield → Plugin (Sandbox)
         ↓
    Validation
    Autorisation
    Rate Limiting
```

---

## AGENT08 – Excessive Agency

### Risque
Agent avec trop de permissions, capable d'effectuer des actions destructrices.

### Contre-mesures obligatoires
- ✅ Implémenter le principe du moindre privilège
- ✅ Requérir une confirmation humaine pour les actions sensibles
- ✅ Limiter les capacités de l'agent au strict nécessaire
- ✅ Implémenter un système d'approbation pour les actions critiques
- ✅ Journaliser toutes les actions de l'agent
- ✅ Implémenter un kill switch

### Actions nécessitant confirmation humaine
- Suppression de fichiers
- Modification de la base de données de production
- Déploiement en production
- Modification des permissions
- Accès aux secrets

---

## AGENT09 – Overreliance

### Risque
Confiance aveugle dans les sorties de l'agent, absence de validation humaine.

### Contre-mesures obligatoires
- ✅ Ne jamais faire confiance aux sorties de l'agent sans validation
- ✅ Implémenter un pipeline de validation déterministe (Couche 5)
- ✅ Requérir une revue humaine pour le code critique
- ✅ Afficher des avertissements sur les limitations de l'agent
- ✅ Implémenter des tests automatisés pour tout code généré

### Pipeline Zero-Trust
```
Agent → Code généré → Validation (6 étapes) → Revue humaine → Merge
                      ↓
                  Compilation
                  Linting
                  Tests unitaires (100%)
                  Tests de mutation (100%)
                  Scan de sécurité
                  Tests visuels
```

---

## AGENT10 – Model Theft

### Risque
Vol du modèle via des requêtes répétées, extraction des poids, reverse engineering.

### Contre-mesures obligatoires
- ✅ Implémenter un rate limiting strict
- ✅ Détecter les patterns d'extraction (requêtes répétitives)
- ✅ Utiliser des watermarks dans les réponses
- ✅ Limiter la taille des réponses
- ✅ Implémenter une authentification forte
- ✅ Surveiller les comportements anormaux

---

## Gouvernance des agents (Agent Governance Toolkit)

### Outils de protection
- **MCP Shield** : Proxy de sécurité pour les outils MCP
- **Sage** : Interception des commandes système
- **Agent Governance Toolkit** : Validation des 10 risques en <1ms

### Configuration MCP Shield
```json
{
  "allowedTools": ["read_file", "write_file", "list_directory"],
  "blockedPaths": ["/etc", "/sys", "/proc", "~/.ssh"],
  "maxFileSize": "10MB",
  "requireApproval": ["delete_file", "execute_command"],
  "rateLimit": {
    "requestsPerMinute": 60,
    "requestsPerHour": 1000
  }
}
```

---

## Validation et conformité

### Outils de vérification
- **Agent Governance Toolkit** : Validation automatique des 10 risques
- **MCP Shield** : Protection en temps réel
- **Sage** : Interception système
- **Prompt injection detector** : Détection de manipulation

### Tests obligatoires
- ✅ Test de prompt injection
- ✅ Test d'exécution de code malveillant
- ✅ Test de fuite de données sensibles
- ✅ Test de déni de service
- ✅ Test d'élévation de privilèges

---

**Dernière mise à jour** : 2026-05-08  
**Responsable** : Équipe Sécurité Axiom-Scaffold
