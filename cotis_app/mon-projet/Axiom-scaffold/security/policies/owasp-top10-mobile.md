# OWASP Mobile Top 10 – Politiques Axiom-Scaffold

**Version** : 2024  
**Référence** : https://owasp.org/www-project-mobile-top-10/  
**Statut** : Obligatoire pour les applications mobiles

---

## M1 – Improper Credential Usage

### Risque
Stockage non sécurisé des identifiants, tokens, clés API dans l'application.

### Contre-mesures obligatoires
- ✅ Utiliser le Keychain (iOS) ou Keystore (Android) pour les secrets
- ✅ Ne jamais stocker de secrets en clair dans SharedPreferences/UserDefaults
- ✅ Utiliser des tokens avec expiration courte
- ✅ Implémenter un refresh token avec rotation
- ✅ Chiffrer les données sensibles au repos

### Exemple sécurisé (Android)
```kotlin
// ❌ DANGEREUX
val prefs = getSharedPreferences("app", MODE_PRIVATE)
prefs.edit().putString("api_key", "sk-1234567890").apply()

// ✅ SÉCURISÉ
val keyStore = KeyStore.getInstance("AndroidKeyStore")
keyStore.load(null)
// Utiliser EncryptedSharedPreferences
```

---

## M2 – Inadequate Supply Chain Security

### Risque
Dépendances malveillantes, bibliothèques compromises, SDK non sécurisés.

### Contre-mesures obligatoires
- ✅ Auditer toutes les dépendances
- ✅ Utiliser des versions épinglées
- ✅ Vérifier les checksums des bibliothèques
- ✅ Utiliser des registres de confiance uniquement
- ✅ Implémenter une revue de code pour les SDK tiers

---

## M3 – Insecure Authentication/Authorization

### Risque
Authentification faible, absence de MFA, tokens non sécurisés.

### Contre-mesures obligatoires
- ✅ Implémenter une authentification forte (biométrie + PIN)
- ✅ Utiliser OAuth 2.0 / OpenID Connect
- ✅ Implémenter un rate limiting côté serveur
- ✅ Invalider les sessions lors de la déconnexion
- ✅ Implémenter la détection de jailbreak/root

---

## M4 – Insufficient Input/Output Validation

### Risque
Injection SQL, XSS, path traversal via des entrées non validées.

### Contre-mesures obligatoires
- ✅ Valider toutes les entrées utilisateur
- ✅ Utiliser des requêtes paramétrées
- ✅ Échapper les sorties avant affichage
- ✅ Utiliser des schémas de validation stricts
- ✅ Limiter la taille des entrées

---

## M5 – Insecure Communication

### Risque
Interception de données via des connexions non chiffrées, man-in-the-middle.

### Contre-mesures obligatoires
- ✅ Forcer HTTPS pour toutes les communications
- ✅ Implémenter le certificate pinning
- ✅ Désactiver les connexions HTTP claires
- ✅ Utiliser TLS 1.3 minimum
- ✅ Valider les certificats serveur

### Configuration Android
```xml
<!-- network_security_config.xml -->
<network-security-config>
  <base-config cleartextTrafficPermitted="false">
    <trust-anchors>
      <certificates src="system" />
    </trust-anchors>
  </base-config>
  <domain-config>
    <domain includeSubdomains="true">api.example.com</domain>
    <pin-set>
      <pin digest="SHA-256">base64==</pin>
    </pin-set>
  </domain-config>
</network-security-config>
```

---

## M6 – Inadequate Privacy Controls

### Risque
Collecte excessive de données, absence de consentement, non-conformité RGPD.

### Contre-mesures obligatoires
- ✅ Implémenter le consentement explicite
- ✅ Minimiser la collecte de données
- ✅ Anonymiser les données analytiques
- ✅ Implémenter le droit à l'oubli
- ✅ Chiffrer les données personnelles

---

## M7 – Insufficient Binary Protections

### Risque
Reverse engineering, modification du binaire, extraction de secrets.

### Contre-mesures obligatoires
- ✅ Activer l'obfuscation (ProGuard, R8)
- ✅ Implémenter la détection de tampering
- ✅ Utiliser le code signing
- ✅ Implémenter la détection de debugger
- ✅ Chiffrer les ressources sensibles

### Configuration ProGuard
```proguard
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-dontpreverify
-verbose
-optimizations !code/simplification/arithmetic,!field/*,!class/merging/*
```

---

## M8 – Security Misconfiguration

### Risque
Permissions excessives, logs en production, debug activé.

### Contre-mesures obligatoires
- ✅ Demander uniquement les permissions nécessaires
- ✅ Désactiver les logs en production
- ✅ Désactiver le mode debug en production
- ✅ Configurer les Content Providers en privé
- ✅ Désactiver les backups automatiques pour les données sensibles

### Configuration Android
```xml
<application
    android:allowBackup="false"
    android:debuggable="false"
    android:usesCleartextTraffic="false">
</application>
```

---

## M9 – Insecure Data Storage

### Risque
Stockage non sécurisé de données sensibles, accès non autorisé.

### Contre-mesures obligatoires
- ✅ Chiffrer toutes les données sensibles
- ✅ Utiliser EncryptedSharedPreferences (Android)
- ✅ Utiliser Data Protection API (iOS)
- ✅ Ne jamais stocker de mots de passe en clair
- ✅ Effacer les données sensibles de la mémoire après utilisation

---

## M10 – Insufficient Cryptography

### Risque
Chiffrement faible, algorithmes obsolètes, clés hardcodées.

### Contre-mesures obligatoires
- ✅ Utiliser AES-256-GCM pour le chiffrement symétrique
- ✅ Utiliser RSA-OAEP ou ECDH pour le chiffrement asymétrique
- ✅ Générer des clés aléatoires (SecureRandom)
- ✅ Ne jamais hardcoder de clés de chiffrement
- ✅ Utiliser des bibliothèques éprouvées (Tink, CryptoKit)

---

## Validation et conformité

### Outils de vérification
- **SAST** : MobSF, Semgrep
- **DAST** : Frida, Objection
- **Pentest** : Drozer, Burp Suite

### Tests obligatoires
- ✅ Test de stockage sécurisé
- ✅ Test de communication chiffrée
- ✅ Test de détection de root/jailbreak
- ✅ Test de certificate pinning
- ✅ Test d'obfuscation

---

**Dernière mise à jour** : 2026-05-08  
**Responsable** : Équipe Sécurité Axiom-Scaffold
