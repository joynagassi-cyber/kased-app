# Procédure de Veille de Sécurité (Threat Intelligence)

**Version** : 1.0.0  
**Responsable** : Équipe Sécurité Axiom-Scaffold  
**Fréquence** : Quotidienne (automatisée)

---

## Objectif

Maintenir une veille continue des vulnérabilités affectant les dépendances et les technologies utilisées dans Axiom-Scaffold.

---

## Sources de veille

### 1. Bases de données de vulnérabilités

- **NVD (National Vulnerability Database)** : https://nvd.nist.gov/
- **CVE (Common Vulnerabilities and Exposures)** : https://cve.mitre.org/
- **GitHub Security Advisories** : https://github.com/advisories
- **npm Security Advisories** : https://www.npmjs.com/advisories
- **Snyk Vulnerability Database** : https://snyk.io/vuln/

### 2. Flux RSS et alertes

- **CERT-FR** : https://www.cert.ssi.gouv.fr/
- **US-CERT** : https://www.cisa.gov/uscert/
- **OWASP** : https://owasp.org/
- **Security Focus** : http://www.securityfocus.com/

### 3. Outils automatisés

- **VulnWatchdog** : Surveillance automatique des CVE
- **Dependabot** : Alertes GitHub pour les dépendances
- **Snyk** : Scan continu des vulnérabilités
- **npm audit** : Audit quotidien des dépendances npm
- **pip-audit** : Audit quotidien des dépendances Python

---

## Processus de veille automatisée

### 1. Scan quotidien des dépendances

```bash
#!/bin/bash
# Script exécuté quotidiennement via cron

# Scan npm
npm audit --json > security/reports/npm-audit-$(date +%Y%m%d).json

# Scan Python
pip-audit --format=json --output=security/reports/pip-audit-$(date +%Y%m%d).json

# Analyser les résultats
node scripts/analyze-vulnerabilities.js
```

### 2. Surveillance des CVE

**VulnWatchdog** surveille automatiquement :
- Les nouvelles CVE affectant nos dépendances
- Les mises à jour de sévérité des CVE existantes
- Les correctifs disponibles

**Actions automatiques** :
- Création d'un ticket GitHub pour chaque nouvelle vulnérabilité
- Notification sur Slack/Teams
- Mise à jour du tableau de bord de sécurité

### 3. Analyse des tendances

**Métriques suivies** :
- Nombre de vulnérabilités par sévérité
- Temps moyen de correction
- Dépendances les plus vulnérables
- Évolution du score de sécurité

---

## Processus de traitement des vulnérabilités

### 1. Triage (< 2h)

Dès qu'une vulnérabilité est détectée :

1. **Évaluer la sévérité** selon CVSS v3.1 :
   - **CRITIQUE** (9.0-10.0) : Action immédiate
   - **HAUTE** (7.0-8.9) : Action sous 24h
   - **MOYENNE** (4.0-6.9) : Action sous 7 jours
   - **BASSE** (0.1-3.9) : Action sous 30 jours

2. **Vérifier l'exploitabilité** :
   - Existe-t-il un exploit public ?
   - La vulnérabilité est-elle exploitable dans notre contexte ?
   - Quelles sont les conditions d'exploitation ?

3. **Évaluer l'impact** :
   - Quels composants sont affectés ?
   - Quelles données sont exposées ?
   - Quel est l'impact sur la disponibilité ?

### 2. Planification (< 4h)

1. **Identifier les solutions** :
   - Mise à jour de la dépendance
   - Patch de sécurité
   - Workaround temporaire
   - Remplacement de la dépendance

2. **Créer un ticket** avec :
   - CVE ID
   - Sévérité
   - Description de la vulnérabilité
   - Composants affectés
   - Solution proposée
   - Échéance

3. **Assigner un responsable**

### 3. Correction

**Pour les vulnérabilités CRITIQUES** :
1. Créer une branche de correction
2. Appliquer le correctif
3. Exécuter les tests
4. Déployer en urgence (bypass du processus normal)
5. Documenter dans le CHANGELOG

**Pour les vulnérabilités HAUTES** :
1. Créer une branche de correction
2. Appliquer le correctif
3. Exécuter les tests complets
4. Revue de code
5. Déploiement via le pipeline normal

**Pour les vulnérabilités MOYENNES/BASSES** :
1. Planifier la correction dans le prochain sprint
2. Suivre le processus de développement normal

### 4. Vérification

Après correction :
1. Exécuter `npm audit` / `pip-audit`
2. Vérifier que la vulnérabilité n'apparaît plus
3. Exécuter les tests de sécurité
4. Mettre à jour la documentation

### 5. Communication

1. **Interne** :
   - Notification à l'équipe
   - Mise à jour du tableau de bord
   - Documentation dans le wiki

2. **Externe** (si applicable) :
   - Notification aux clients
   - Publication d'un bulletin de sécurité
   - Mise à jour du changelog public

---

## Outils de veille

### VulnWatchdog

Configuration dans `.github/workflows/vuln-watchdog.yml` :

```yaml
name: Vulnerability Watchdog

on:
  schedule:
    - cron: '0 */6 * * *' # Toutes les 6 heures
  workflow_dispatch:

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Scan vulnerabilities
        run: |
          npm audit --json > vuln-report.json
          
      - name: Analyze and create issues
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const report = JSON.parse(fs.readFileSync('vuln-report.json'));
            
            for (const vuln of report.vulnerabilities) {
              if (vuln.severity === 'high' || vuln.severity === 'critical') {
                await github.rest.issues.create({
                  owner: context.repo.owner,
                  repo: context.repo.repo,
                  title: `[SECURITY] ${vuln.name}: ${vuln.title}`,
                  body: `**Severity**: ${vuln.severity}\n**CVE**: ${vuln.cve}\n\n${vuln.overview}`,
                  labels: ['security', vuln.severity]
                });
              }
            }
```

### Dependabot

Configuration dans `.github/dependabot.yml` :

```yaml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "daily"
    open-pull-requests-limit: 10
    labels:
      - "dependencies"
      - "security"
    
  - package-ecosystem: "pip"
    directory: "/"
    schedule:
      interval: "daily"
    open-pull-requests-limit: 10
    labels:
      - "dependencies"
      - "security"
```

---

## Tableau de bord de sécurité

### Métriques clés

- **Score de sécurité global** : 0-100
- **Nombre de vulnérabilités actives** par sévérité
- **Temps moyen de correction** par sévérité
- **Tendance** : amélioration ou dégradation
- **Dépendances obsolètes** : nombre et pourcentage

### Alertes

- **Alerte CRITIQUE** : Notification immédiate (Slack, email, SMS)
- **Alerte HAUTE** : Notification sous 1h
- **Alerte MOYENNE** : Notification quotidienne
- **Alerte BASSE** : Rapport hebdomadaire

---

## Checklist de veille quotidienne

- [ ] Exécuter `npm audit` et `pip-audit`
- [ ] Vérifier les nouvelles CVE sur NVD
- [ ] Consulter les alertes GitHub Security
- [ ] Vérifier les notifications Dependabot
- [ ] Mettre à jour le tableau de bord
- [ ] Traiter les vulnérabilités CRITIQUES/HAUTES
- [ ] Planifier les corrections MOYENNES/BASSES

---

## Références

- [NIST NVD](https://nvd.nist.gov/)
- [CVSS Calculator](https://www.first.org/cvss/calculator/3.1)
- [OWASP Dependency Check](https://owasp.org/www-project-dependency-check/)
- [GitHub Security Advisories](https://github.com/advisories)

---

**Dernière mise à jour** : 2026-05-08  
**Prochaine revue** : 2026-06-08
