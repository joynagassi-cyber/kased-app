# Documentation de Sécurité — Axiom-Scaffold

**Version** : 1.0.0  
**Date** : 2026-05-08  
**Statut** : Obligatoire

---

## Table des matières

1. [Introduction](#introduction)
2. [Architecture de sécurité](#architecture-de-sécurité)
3. [Politiques de sécurité](#politiques-de-sécurité)
4. [Outils automatisés](#outils-automatisés)
5. [Skills de sécurité](#skills-de-sécurité)
6. [Protection et gouvernance](#protection-et-gouvernance)
7. [Workflow de développement sécurisé](#workflow-de-développement-sécurisé)
8. [Réponse aux incidents](#réponse-aux-incidents)
9. [Checklist de sécurité](#checklist-de-sécurité)
10. [Références](#références)

---

## Introduction

La **Couche 8 – Sécurité Chirurgicale** d'Axiom-Scaffold est une membrane protectrice qui garantit que chaque ligne de code, chaque dépendance, et chaque configuration respecte les plus hauts standards de sécurité.

### Principes fondamentaux

1. **Zero-Trust** : Ne jamais faire confiance, toujours vérifier
2. **Defense in Depth** : Plusieurs couches de protection
3. **Least Privilege** : Privilèges minimaux nécessaires
4. **Fail Secure** : Échouer de manière sécurisée
5. **Security by Design** : Sécurité dès la conception

---

## Architecture de sécurité

```
┌─────────────────────────────────────────────────────────────────┐
│               COUCHE 8 – SÉCURITÉ CHIRURGICALE                  │
│                                                                  │
│  1. POLITIQUES DE SÉCURITÉ                                      │
│     - OWASP Top 10 (Web, Mobile, API, Agentic)                  │
│     - MASVS (Mobile Application Security Verification Standard) │
│     - Durcissement Windows / Linux                               │
│                                                                  │
│  2. OUTILS AUTOMATISÉS                                          │
│     - SAST : Semgrep                                             │
│     - DAST : Strix, Pathfinder-AI                               │
│     - SCA  : npm audit, pip-audit                               │
│     - Secrets : detect-secrets                                   │
│                                                                  │
│  3. COMPÉTENCES AGENTIQUES (SKILLS)                             │
│     - Skills de sécurité (OWASP, auth, crypto)                  │
│     - Skills spécifiques (API, mobile, cloud)                   │
│                                                                  │
│  4. PROTECTION & GOUVERNANCE                                    │
│     - MCP Shield (proxy de sécurité)                             │
│     - Agent Governance Toolkit                                   │
│     - Veille continue (VulnWatchdog)                             │
└─────────────────────────────────────────────────────────────────┘
```

---

## Politiques de sécurité

Les politiques de sécurité sont des documents Markdown dans `security/policies/` qui définissent les règles à suivre.

### Politiques disponibles

| Politique            | Fichier                  | Statut                  |
| -------------------- | ------------------------ | ----------------------- |
| OWASP Top 10 Web     | `owasp-top10-web.md`     | Obligatoire             |
| OWASP API Security   | `owasp-api-security.md`  | Obligatoire             |
| OWASP Mobile Top 10  | `owasp-top10-mobile.md`  | Obligatoire (mobile)    |
| OWASP Agentic Top 10 | `owasp-agentic-top10.md` | Obligatoire (agents IA) |
| MASVS Android        | `masvs-android.md`       | Obligatoire (Android)   |
| Windows Hardening    | `windows-hardening.md`   | Obligatoire (Windows)   |

### Comment utiliser les politiques

Les politiques sont automatiquement chargées par le minimiseur (Couche 3) lorsque vous travaillez sur du code sensible.

**Exemple** : Si vous créez un endpoint API, la politique `owasp-api-security.md` sera automatiquement injectée dans le contexte de l'agent.

---

## Outils automatisés

### 1. SAST (Static Application Security Testing)

**Outil** : Semgrep  
**Déclenchement** : Chaque commit  
**Configuration** : `security/tools/sast-config.yml`

```bash
# Lancer manuellement
semgrep --config=auto --config=p/owasp-top-ten .
```

### 2. SCA (Software Composition Analysis)

**Outils** : npm audit, pip-audit  
**Déclenchement** : Chaque commit  
**Seuil de blocage** : Vulnérabilités haute/critique

```bash
# npm
npm audit --audit-level=high

# Python
pip-audit
```

### 3. Détection de secrets

**Outil** : detect-secrets  
**Déclenchement** : Chaque commit  
**Configuration** : `security/tools/secrets-patterns.yml`

```bash
# Créer une baseline
detect-secrets scan > .secrets.baseline

# Scanner
detect-secrets scan --baseline .secrets.baseline
```

### 4. DAST (Dynamic Application Security Testing)

**Outils** : Strix, Pathfinder-AI  
**Déclenchement** : Planifié ou à la demande  
**Environnement** : Bac à sable uniquement

```bash
# Activer DAST
export AXIOM_DAST_ENABLED=true
export AXIOM_TARGET_URL=https://staging.example.com

# Lancer le scan
./scripts/security-scan.sh
```

---

## Skills de sécurité

Les skills de sécurité sont des compétences spécialisées que l'agent IA peut activer automatiquement.

### Skills disponibles

| Skill           | Fichier                              | Triggers                     |
| --------------- | ------------------------------------ | ---------------------------- |
| API Security    | `security/skills/api-security.md`    | api, endpoint, rest, graphql |
| Web Security    | `security/skills/web-security.md`    | web, html, xss, csrf         |
| Mobile Security | `security/skills/mobile-security.md` | android, ios, mobile         |
| Cloud Security  | `security/skills/cloud-security.md`  | aws, gcp, azure, cloud       |
| Agent Security  | `security/skills/agent-security.md`  | agent, llm, prompt           |

### Comment activer un skill

Les skills sont activés automatiquement selon les mots-clés de votre tâche. Vous pouvez aussi les activer manuellement :

```markdown
@skill api-security

Créer un endpoint POST /api/users
```

---

## Protection et gouvernance

### MCP Shield

**Rôle** : Proxy de sécurité entre l'agent IA et les outils MCP  
**Configuration** : `security/governance/mcp-shield-config.json`

**Fonctionnalités** :
- Validation des entrées/sorties
- Rate limiting
- Détection de secrets
- Filtrage de contenu malveillant
- Workflow d'approbation

### Agent Governance Toolkit

**Rôle** : Applique les 10 risques OWASP Agentic Top 10  
**Configuration** : `security/governance/agent-governance-policy.yaml`

**Fonctionnalités** :
- Détection de prompt injection
- Validation des sorties
- Protection contre le DoS
- Détection de fuites de données
- Contrôle des permissions

---

## Workflow de développement sécurisé

### 1. Avant de coder

- [ ] Lire les politiques de sécurité pertinentes
- [ ] Activer les skills de sécurité appropriés
- [ ] Vérifier les dépendances (`npm audit`)

### 2. Pendant le développement

- [ ] Suivre les bonnes pratiques de sécurité
- [ ] Valider toutes les entrées utilisateur
- [ ] Ne jamais hardcoder de secrets
- [ ] Utiliser des bibliothèques éprouvées

### 3. Avant de commiter

```bash
# Lancer le scan de sécurité
./scripts/security-scan.sh

# Vérifier qu'il n'y a pas de secrets
detect-secrets scan --baseline .secrets.baseline

# Vérifier les dépendances
npm audit --audit-level=high
```

### 4. Pull Request

Le workflow CI/CD exécute automatiquement :
- SAST (Semgrep)
- SCA (npm audit)
- Détection de secrets
- Vérification de configuration
- Agent Governance

### 5. Après le merge

- [ ] Vérifier les alertes de sécurité
- [ ] Mettre à jour la documentation
- [ ] Générer un skill si nécessaire (Couche 7)

---

## Réponse aux incidents

### Signaler un incident

1. **Créer un ticket** avec le label `security`
2. **Notifier** : security@axiom-scaffold.com
3. **Documenter** : date, heure, description, sévérité

### Procédure de réponse

Voir la procédure complète dans `security/monitoring/incident-response.md`.

**Phases** :
1. Détection et Alerte (0-15 min)
2. Analyse et Évaluation (15-60 min)
3. Confinement (1-4h)
4. Éradication (4-24h)
5. Récupération (24-72h)
6. Post-Incident (72h-1 semaine)

### Contacts d'urgence

- **Équipe sécurité** : security@axiom-scaffold.com
- **Équipe technique** : tech@axiom-scaffold.com
- **Direction** : management@axiom-scaffold.com

---

## Checklist de sécurité

### Pour chaque endpoint API

- [ ] Authentification implémentée
- [ ] Autorisation au niveau objet vérifiée
- [ ] Validation des entrées avec schéma strict
- [ ] Rate limiting configuré
- [ ] En-têtes de sécurité configurés
- [ ] CORS configuré de manière restrictive
- [ ] Gestion d'erreurs sécurisée
- [ ] Journalisation des événements de sécurité
- [ ] Protection SSRF si applicable
- [ ] Tests de sécurité écrits

### Pour chaque composant

- [ ] Pas de secrets hardcodés
- [ ] Dépendances à jour
- [ ] Validation des entrées
- [ ] Échappement des sorties
- [ ] Gestion d'erreurs appropriée
- [ ] Logs de sécurité
- [ ] Tests de sécurité

### Pour chaque déploiement

- [ ] Scan de sécurité passé
- [ ] Secrets rotés
- [ ] Configurations vérifiées
- [ ] Pare-feu configuré
- [ ] Monitoring activé
- [ ] Sauvegardes à jour

---

## Commandes utiles

### Scan complet

```bash
# Scan de sécurité complet
./scripts/security-scan.sh

# Voir les rapports
ls -lh security/reports/
```

### Scan des dépendances

```bash
# npm
npm audit
npm audit fix

# Python
pip-audit
pip-audit --fix
```

### Détection de secrets

```bash
# Scanner
detect-secrets scan

# Auditer la baseline
detect-secrets audit .secrets.baseline
```

### Analyse statique

```bash
# Semgrep
semgrep --config=auto .

# Avec règles OWASP
semgrep --config=p/owasp-top-ten .
```

---

## Références

### Standards et frameworks

- [OWASP Top 10](https://owasp.org/Top10/)
- [OWASP API Security Top 10](https://owasp.org/API-Security/)
- [OWASP Mobile Top 10](https://owasp.org/www-project-mobile-top-10/)
- [OWASP Agentic AI Top 10](https://genai.owasp.org/)
- [MASVS](https://mas.owasp.org/MASVS/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)

### Outils

- [Semgrep](https://semgrep.dev/)
- [detect-secrets](https://github.com/Yelp/detect-secrets)
- [npm audit](https://docs.npmjs.com/cli/v8/commands/npm-audit)
- [pip-audit](https://github.com/pypa/pip-audit)

### Documentation interne

- [Politiques de sécurité](../security/policies/)
- [Skills de sécurité](../security/skills/)
- [Procédure de veille](../security/monitoring/threat-intel.md)
- [Procédure de réponse aux incidents](../security/monitoring/incident-response.md)

---

## Support

Pour toute question sur la sécurité :

- **Email** : security@axiom-scaffold.com
- **Slack** : #security
- **Documentation** : https://docs.axiom-scaffold.com/security

---

**Dernière mise à jour** : 2026-05-08  
**Prochaine revue** : 2026-06-08  
**Responsable** : Équipe Sécurité Axiom-Scaffold
