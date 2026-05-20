# OWASP Top 10 Web – Politiques Axiom-Scaffold

**Version** : 2021  
**Référence** : https://owasp.org/Top10/  
**Statut** : Obligatoire

---

## A01:2021 – Contrôle d'accès défaillant (Broken Access Control)

### Risque
Accès non autorisé à des ressources sensibles, élévation de privilèges, manipulation de données d'autres utilisateurs.

### Contre-mesures obligatoires
- ✅ Toute ressource sensible doit vérifier l'autorisation avant d'être servie
- ✅ Utiliser un middleware d'autorisation (RBAC/ABAC)
- ✅ Interdire l'accès direct aux fichiers de configuration (`.env`, `config.json`)
- ✅ Valider l'autorisation côté serveur (jamais uniquement côté client)
- ✅ Implémenter le principe du moindre privilège
- ✅ Désactiver le listing de répertoires sur le serveur web
- ✅ Journaliser tous les échecs de contrôle d'accès

### Anti-patterns
- ❌ Vérifier l'autorisation uniquement dans l'interface utilisateur
- ❌ Exposer des identifiants séquentiels (IDOR)
- ❌ Permettre l'accès à `/admin` sans authentification

---

## A02:2021 – Défaillances cryptographiques (Cryptographic Failures)

### Risque
Exposition de données sensibles, vol d'identifiants, usurpation d'identité.

### Contre-mesures obligatoires
- ✅ Ne jamais implémenter un algorithme de chiffrement personnalisé
- ✅ Utiliser des bibliothèques éprouvées :
  - Mots de passe : `bcrypt`, `argon2`
  - Chiffrement symétrique : AES-GCM
  - Chiffrement asymétrique : RSA-OAEP, ECDH
- ✅ Forcer HTTPS avec HSTS : `max-age=31536000; includeSubDomains; preload`
- ✅ Ne jamais stocker de mots de passe en clair ou avec MD5/SHA1
- ✅ Utiliser des clés de chiffrement d'au moins 256 bits
- ✅ Stocker les secrets dans un gestionnaire de secrets (Vault, AWS Secrets Manager)
- ✅ Désactiver TLS 1.0 et 1.1

### Anti-patterns
- ❌ Stocker des mots de passe en base64
- ❌ Utiliser `crypto.createCipher()` (déprécié)
- ❌ Transmettre des données sensibles en GET

---

## A03:2021 – Injection

### Risque
Injection SQL, NoSQL, OS, LDAP permettant l'exécution de commandes arbitraires.

### Contre-mesures obligatoires
- ✅ Utiliser des requêtes paramétrées (prepared statements)
- ✅ Valider et échapper toutes les entrées utilisateur
- ✅ Utiliser un ORM avec protection intégrée (Prisma, TypeORM)
- ✅ Appliquer le principe de moindre privilège aux comptes de base de données
- ✅ Utiliser des listes blanches pour les entrées (pas de listes noires)
- ✅ Échapper les caractères spéciaux dans les commandes shell

### Anti-patterns
- ❌ Concaténer des entrées utilisateur dans des requêtes SQL
- ❌ Utiliser `eval()` ou `Function()` avec des données utilisateur
- ❌ Exécuter des commandes shell avec `exec()` sans validation

### Exemple sécurisé (SQL)
```typescript
// ❌ DANGEREUX
const query = `SELECT * FROM users WHERE id = ${userId}`;

// ✅ SÉCURISÉ
const query = 'SELECT * FROM users WHERE id = ?';
db.execute(query, [userId]);
```

---

## A04:2021 – Conception non sécurisée (Insecure Design)

### Risque
Failles architecturales impossibles à corriger par des patchs.

### Contre-mesures obligatoires
- ✅ Modéliser les menaces dès la conception (STRIDE, PASTA)
- ✅ Implémenter la défense en profondeur (plusieurs couches de sécurité)
- ✅ Séparer les environnements (dev, staging, production)
- ✅ Limiter les ressources consommables (rate limiting, quotas)
- ✅ Documenter les décisions de sécurité dans les ADR

---

## A05:2021 – Mauvaise configuration de sécurité (Security Misconfiguration)

### Risque
Exposition de services, de messages d'erreur détaillés, de comptes par défaut.

### Contre-mesures obligatoires
- ✅ Désactiver les fonctionnalités inutilisées
- ✅ Changer tous les mots de passe par défaut
- ✅ Désactiver les messages d'erreur détaillés en production
- ✅ Configurer les en-têtes de sécurité HTTP (CSP, HSTS, X-Frame-Options)
- ✅ Maintenir les dépendances à jour
- ✅ Utiliser un processus de durcissement automatisé

### En-têtes de sécurité obligatoires
```http
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Content-Security-Policy: default-src 'self'
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: geolocation=(), microphone=(), camera=()
```

---

## A06:2021 – Composants vulnérables et obsolètes

### Risque
Exploitation de vulnérabilités connues dans les dépendances.

### Contre-mesures obligatoires
- ✅ Auditer les dépendances à chaque commit (`npm audit`, `pip-audit`)
- ✅ Utiliser des versions épinglées (pas de `^` ou `~`)
- ✅ Surveiller les CVE avec VulnWatchdog
- ✅ Supprimer les dépendances inutilisées
- ✅ Préférer les bibliothèques activement maintenues

---

## A07:2021 – Identification et authentification de mauvaise qualité

### Risque
Usurpation d'identité, prise de contrôle de compte.

### Contre-mesures obligatoires
- ✅ Implémenter l'authentification multi-facteurs (MFA)
- ✅ Utiliser des sessions sécurisées (HttpOnly, Secure, SameSite)
- ✅ Implémenter un rate limiting sur les endpoints d'authentification
- ✅ Forcer des mots de passe forts (longueur ≥12, complexité)
- ✅ Invalider les sessions côté serveur lors de la déconnexion
- ✅ Utiliser des tokens JWT avec expiration courte (<15 min)

### Anti-patterns
- ❌ Stocker les tokens JWT dans localStorage (XSS)
- ❌ Permettre des mots de passe faibles
- ❌ Ne pas limiter les tentatives de connexion

---

## A08:2021 – Manque d'intégrité des données et du logiciel

### Risque
Injection de code malveillant, compromission de la chaîne d'approvisionnement.

### Contre-mesures obligatoires
- ✅ Vérifier l'intégrité des dépendances (checksums, signatures)
- ✅ Utiliser des pipelines CI/CD sécurisés
- ✅ Signer les commits Git
- ✅ Utiliser Subresource Integrity (SRI) pour les CDN
- ✅ Implémenter une revue de code obligatoire

---

## A09:2021 – Carence des systèmes de contrôle et de journalisation

### Risque
Impossibilité de détecter et d'investiguer les incidents.

### Contre-mesures obligatoires
- ✅ Journaliser tous les événements de sécurité (authentification, autorisation, erreurs)
- ✅ Utiliser un format structuré (JSON)
- ✅ Protéger les logs contre la modification
- ✅ Implémenter des alertes en temps réel
- ✅ Conserver les logs pendant au moins 90 jours

### Événements à journaliser
- Tentatives de connexion (succès et échecs)
- Modifications de privilèges
- Accès aux données sensibles
- Erreurs de validation
- Tentatives d'injection

---

## A10:2021 – Falsification de requête côté serveur (SSRF)

### Risque
Accès à des ressources internes, scan de ports, exfiltration de données.

### Contre-mesures obligatoires
- ✅ Valider et filtrer toutes les URL fournies par l'utilisateur
- ✅ Utiliser une liste blanche de domaines autorisés
- ✅ Désactiver les redirections HTTP
- ✅ Bloquer l'accès aux plages IP privées (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16)
- ✅ Utiliser un proxy sortant avec filtrage

---

## Validation et conformité

### Outils de vérification
- **SAST** : Semgrep avec règles OWASP
- **DAST** : Strix, Pathfinder-AI
- **SCA** : npm audit, Snyk

### Seuils de blocage
- Vulnérabilité **CRITIQUE** : blocage immédiat
- Vulnérabilité **HAUTE** : blocage immédiat
- Vulnérabilité **MOYENNE** : avertissement, correction sous 7 jours
- Vulnérabilité **BASSE** : avertissement, correction sous 30 jours

---

**Dernière mise à jour** : 2026-05-08  
**Responsable** : Équipe Sécurité Axiom-Scaffold
