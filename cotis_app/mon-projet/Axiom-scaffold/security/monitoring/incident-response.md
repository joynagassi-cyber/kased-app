# Procédure de Réponse aux Incidents de Sécurité

**Version** : 1.0.0  
**Responsable** : Équipe Sécurité Axiom-Scaffold  
**Statut** : Obligatoire

---

## Objectif

Définir un processus clair et reproductible pour répondre aux incidents de sécurité, minimiser l'impact, et prévenir les récidives.

---

## Définition d'un incident de sécurité

Un incident de sécurité est tout événement qui :
- Compromet la confidentialité, l'intégrité ou la disponibilité des données
- Viole les politiques de sécurité
- Expose des vulnérabilités critiques
- Résulte d'une attaque réussie

### Exemples d'incidents

- **CRITIQUE** :
  - Accès non autorisé à la base de données de production
  - Fuite de secrets (clés API, tokens)
  - Ransomware ou malware détecté
  - Exfiltration de données

- **HAUTE** :
  - Tentatives d'intrusion répétées
  - Vulnérabilité critique exploitable
  - Déni de service (DoS)
  - Élévation de privilèges

- **MOYENNE** :
  - Scan de ports détecté
  - Tentatives de brute force
  - Vulnérabilité haute non exploitée

- **BASSE** :
  - Comportement suspect d'un utilisateur
  - Vulnérabilité moyenne détectée

---

## Phases de réponse

### Phase 1 : Détection et Alerte (0-15 min)

#### 1.1 Sources de détection

- Alertes automatiques (SIEM, IDS/IPS)
- Logs de sécurité
- Rapports d'utilisateurs
- Scans de vulnérabilités
- Outils de monitoring

#### 1.2 Actions immédiates

1. **Documenter** :
   - Date et heure de détection
   - Source de l'alerte
   - Description initiale
   - Sévérité estimée

2. **Notifier** :
   - Équipe de sécurité (immédiat)
   - Responsable technique (< 15 min)
   - Direction (si CRITIQUE)

3. **Créer un ticket** :
   ```
   Titre: [INCIDENT] [SÉVÉRITÉ] Description courte
   Labels: incident, security, [sévérité]
   Priorité: Selon sévérité
   ```

### Phase 2 : Analyse et Évaluation (15-60 min)

#### 2.1 Collecte d'informations

1. **Logs système** :
   ```bash
   # Extraire les logs pertinents
   grep -i "suspicious_pattern" /var/log/syslog > incident-logs.txt
   
   # Logs d'authentification
   grep "Failed password" /var/log/auth.log
   
   # Logs applicatifs
   tail -n 1000 logs/application.log
   ```

2. **État du système** :
   ```bash
   # Processus en cours
   ps aux | grep suspicious
   
   # Connexions réseau
   netstat -tulpn
   
   # Fichiers récemment modifiés
   find / -mtime -1 -type f
   ```

3. **Analyse du super-graphe** (Couche 1) :
   - Identifier les composants affectés
   - Tracer les dépendances
   - Évaluer la portée de l'incident

#### 2.2 Évaluation de l'impact

1. **Confidentialité** :
   - Quelles données ont été exposées ?
   - Combien d'utilisateurs sont affectés ?
   - Y a-t-il des données sensibles (PII, secrets) ?

2. **Intégrité** :
   - Des données ont-elles été modifiées ?
   - Le code a-t-il été altéré ?
   - Les configurations sont-elles compromises ?

3. **Disponibilité** :
   - Les services sont-ils affectés ?
   - Quelle est la durée d'indisponibilité ?
   - Combien d'utilisateurs sont impactés ?

#### 2.3 Classification finale

Réévaluer la sévérité selon l'impact réel :

| Sévérité | Impact                                            | Temps de réponse |
| -------- | ------------------------------------------------- | ---------------- |
| CRITIQUE | Données sensibles exposées, système compromis     | Immédiat         |
| HAUTE    | Vulnérabilité exploitable, tentative d'intrusion  | < 1h             |
| MOYENNE  | Comportement suspect, vulnérabilité non exploitée | < 4h             |
| BASSE    | Anomalie mineure                                  | < 24h            |

### Phase 3 : Containment (Confinement) (1-4h)

#### 3.1 Confinement immédiat

**Pour une compromission de compte** :
```bash
# Révoquer tous les tokens
node scripts/revoke-all-tokens.js --user-id=<user_id>

# Forcer la déconnexion
redis-cli DEL "session:*"

# Désactiver le compte
node scripts/disable-account.js --user-id=<user_id>
```

**Pour une vulnérabilité exploitée** :
```bash
# Désactiver l'endpoint vulnérable
node scripts/disable-endpoint.js --path="/api/vulnerable"

# Déployer un patch d'urgence
git checkout -b hotfix/security-patch
# Appliquer le correctif
git commit -m "fix: security patch for CVE-XXXX"
git push origin hotfix/security-patch
# Déploiement immédiat (bypass CI/CD)
```

**Pour une fuite de secrets** :
```bash
# Révoquer immédiatement les secrets
./scripts/rotate-secrets.sh --emergency

# Invalider tous les tokens JWT
redis-cli FLUSHDB

# Notifier les services tiers
node scripts/notify-secret-rotation.js
```

#### 3.2 Confinement à long terme

1. **Isoler les systèmes affectés**
2. **Bloquer les adresses IP malveillantes**
3. **Renforcer les contrôles d'accès**
4. **Activer une surveillance accrue**

### Phase 4 : Éradication (4-24h)

#### 4.1 Éliminer la cause racine

1. **Corriger la vulnérabilité** :
   - Appliquer les patchs
   - Mettre à jour les dépendances
   - Modifier les configurations

2. **Supprimer les artefacts malveillants** :
   - Backdoors
   - Malwares
   - Comptes non autorisés

3. **Renforcer la sécurité** :
   - Durcir les configurations
   - Ajouter des contrôles supplémentaires
   - Mettre à jour les règles de pare-feu

#### 4.2 Vérification

```bash
# Scan de sécurité complet
./scripts/security-scan.sh

# Vérifier l'intégrité des fichiers
sha256sum -c checksums.txt

# Scanner les malwares
clamscan -r /var/www/
```

### Phase 5 : Récupération (24-72h)

#### 5.1 Restauration des services

1. **Restaurer depuis les sauvegardes** (si nécessaire)
2. **Réactiver les services**
3. **Vérifier le fonctionnement**
4. **Surveiller les anomalies**

#### 5.2 Rotation des secrets

```bash
# Rotation complète des secrets
./scripts/rotate-secrets.sh --all

# Régénérer les clés de chiffrement
./scripts/regenerate-encryption-keys.sh

# Mettre à jour les configurations
./scripts/update-configs.sh
```

#### 5.3 Communication

**Interne** :
- Notification à toute l'équipe
- Mise à jour du statut de l'incident
- Documentation des actions prises

**Externe** (si applicable) :
- Notification aux utilisateurs affectés
- Publication d'un bulletin de sécurité
- Notification aux autorités (CNIL, etc.)

### Phase 6 : Post-Incident (72h-1 semaine)

#### 6.1 Analyse post-mortem

Réunion d'équipe pour analyser :

1. **Chronologie** :
   - Quand l'incident a-t-il commencé ?
   - Quand a-t-il été détecté ?
   - Combien de temps pour le résoudre ?

2. **Cause racine** :
   - Quelle était la vulnérabilité ?
   - Comment a-t-elle été exploitée ?
   - Pourquoi n'a-t-elle pas été détectée avant ?

3. **Réponse** :
   - Qu'est-ce qui a bien fonctionné ?
   - Qu'est-ce qui pourrait être amélioré ?
   - Les procédures ont-elles été suivies ?

4. **Impact** :
   - Combien d'utilisateurs affectés ?
   - Quelles données ont été exposées ?
   - Quel est le coût de l'incident ?

#### 6.2 Rapport d'incident

Créer un rapport détaillé contenant :

```markdown
# Rapport d'Incident de Sécurité

## Résumé exécutif
- Date et heure
- Sévérité
- Impact
- Statut

## Chronologie
- [HH:MM] Détection
- [HH:MM] Notification
- [HH:MM] Confinement
- [HH:MM] Éradication
- [HH:MM] Récupération

## Cause racine
Description détaillée de la vulnérabilité

## Actions prises
Liste des actions de réponse

## Leçons apprises
Ce qui a bien fonctionné / ce qui doit être amélioré

## Actions correctives
Liste des actions pour prévenir la récidive
```

#### 6.3 Actions correctives

1. **Mettre à jour les politiques de sécurité**
2. **Améliorer les contrôles**
3. **Former l'équipe**
4. **Mettre à jour la documentation**
5. **Générer un skill de sécurité** (Couche 7) :
   ```bash
   # Créer un événement d'apprentissage
   cat > learning/events/incident-$(date +%Y%m%d).yaml <<EOF
   id: incident-$(date +%Y%m%d)
   type: security_incident
   severity: high
   problem: |
     Description de la vulnérabilité
   solution: |
     Description de la correction
   keywords:
     - security
     - vulnerability
     - [type de vulnérabilité]
   EOF
   
   # Générer le skill automatiquement
   ./scripts/learn.sh learning/events
   ```

---

## Contacts d'urgence

### Équipe de sécurité
- **Responsable sécurité** : security@axiom-scaffold.com
- **Équipe technique** : tech@axiom-scaffold.com
- **Direction** : management@axiom-scaffold.com

### Externes
- **CERT-FR** : cert-fr.cossi@ssi.gouv.fr
- **CNIL** : https://www.cnil.fr/
- **Hébergeur** : support@hosting-provider.com

---

## Outils de réponse

### Analyse
- **Logs** : ELK Stack, Splunk
- **Réseau** : Wireshark, tcpdump
- **Forensics** : Autopsy, Volatility

### Confinement
- **Pare-feu** : iptables, ufw
- **WAF** : UUSEC UUWAF
- **IDS/IPS** : Snort, Suricata

### Communication
- **Interne** : Slack, Teams
- **Externe** : Email, site web

---

## Checklist de réponse

### Détection
- [ ] Incident documenté
- [ ] Équipe notifiée
- [ ] Ticket créé

### Analyse
- [ ] Logs collectés
- [ ] Impact évalué
- [ ] Sévérité confirmée

### Confinement
- [ ] Systèmes isolés
- [ ] Accès révoqués
- [ ] Surveillance accrue

### Éradication
- [ ] Vulnérabilité corrigée
- [ ] Artefacts supprimés
- [ ] Sécurité renforcée

### Récupération
- [ ] Services restaurés
- [ ] Secrets rotés
- [ ] Communication effectuée

### Post-Incident
- [ ] Post-mortem réalisé
- [ ] Rapport rédigé
- [ ] Actions correctives planifiées
- [ ] Skill de sécurité généré

---

**Dernière mise à jour** : 2026-05-08  
**Prochaine revue** : 2026-06-08
