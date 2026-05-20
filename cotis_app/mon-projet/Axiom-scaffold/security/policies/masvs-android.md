# MASVS – Mobile Application Security Verification Standard (Android)

**Version** : 2.0  
**Référence** : https://mas.owasp.org/MASVS/  
**Statut** : Obligatoire pour les applications Android

---

## MASVS-STORAGE – Secure Data Storage

### Objectif
Protéger les données sensibles stockées sur l'appareil.

### Exigences obligatoires

#### MASVS-STORAGE-1 : Utiliser le stockage sécurisé
- ✅ Utiliser `EncryptedSharedPreferences` pour les préférences sensibles
- ✅ Utiliser `EncryptedFile` pour les fichiers sensibles
- ✅ Stocker les clés dans Android Keystore
- ✅ Ne jamais stocker de secrets en clair

#### MASVS-STORAGE-2 : Protéger les données en cache
- ✅ Désactiver le cache pour les données sensibles
- ✅ Chiffrer les données en cache
- ✅ Nettoyer le cache lors de la déconnexion

### Exemple sécurisé
```kotlin
// ✅ SÉCURISÉ
val masterKey = MasterKey.Builder(context)
    .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
    .build()

val encryptedPrefs = EncryptedSharedPreferences.create(
    context,
    "secure_prefs",
    masterKey,
    EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
    EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
)

encryptedPrefs.edit().putString("api_token", token).apply()
```

---

## MASVS-CRYPTO – Cryptography

### Objectif
Utiliser des algorithmes cryptographiques robustes et des implémentations sécurisées.

### Exigences obligatoires

#### MASVS-CRYPTO-1 : Utiliser des algorithmes approuvés
- ✅ AES-256-GCM pour le chiffrement symétrique
- ✅ RSA-OAEP ou ECDH pour le chiffrement asymétrique
- ✅ SHA-256 ou SHA-3 pour le hachage
- ✅ Argon2 ou bcrypt pour les mots de passe

#### MASVS-CRYPTO-2 : Générer des clés sécurisées
- ✅ Utiliser `SecureRandom` pour la génération aléatoire
- ✅ Stocker les clés dans Android Keystore
- ✅ Utiliser des clés de 256 bits minimum

### Exemple sécurisé
```kotlin
val keyGenerator = KeyGenerator.getInstance(
    KeyProperties.KEY_ALGORITHM_AES,
    "AndroidKeyStore"
)

val keyGenParameterSpec = KeyGenParameterSpec.Builder(
    "my_key",
    KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
)
    .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
    .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
    .setKeySize(256)
    .build()

keyGenerator.init(keyGenParameterSpec)
keyGenerator.generateKey()
```

---

## MASVS-AUTH – Authentication and Session Management

### Objectif
Implémenter une authentification forte et une gestion sécurisée des sessions.

### Exigences obligatoires

#### MASVS-AUTH-1 : Authentification forte
- ✅ Implémenter la biométrie (empreinte, visage)
- ✅ Utiliser un PIN ou mot de passe fort
- ✅ Implémenter MFA pour les opérations sensibles

#### MASVS-AUTH-2 : Gestion des sessions
- ✅ Utiliser des tokens JWT avec expiration courte
- ✅ Implémenter un refresh token avec rotation
- ✅ Invalider les sessions lors de la déconnexion
- ✅ Détecter les sessions concurrentes

---

## MASVS-NETWORK – Network Communication

### Objectif
Sécuriser toutes les communications réseau.

### Exigences obligatoires

#### MASVS-NETWORK-1 : Forcer HTTPS
- ✅ Désactiver les connexions HTTP claires
- ✅ Utiliser TLS 1.3 minimum
- ✅ Implémenter le certificate pinning

#### MASVS-NETWORK-2 : Valider les certificats
- ✅ Vérifier la chaîne de certificats
- ✅ Vérifier la date d'expiration
- ✅ Vérifier le nom de domaine

### Configuration Network Security
```xml
<network-security-config>
  <base-config cleartextTrafficPermitted="false">
    <trust-anchors>
      <certificates src="system" />
    </trust-anchors>
  </base-config>
  
  <domain-config>
    <domain includeSubdomains="true">api.example.com</domain>
    <pin-set expiration="2027-01-01">
      <pin digest="SHA-256">base64==</pin>
      <pin digest="SHA-256">backup-base64==</pin>
    </pin-set>
  </domain-config>
</network-security-config>
```

---

## MASVS-PLATFORM – Platform Interaction

### Objectif
Utiliser les APIs de la plateforme de manière sécurisée.

### Exigences obligatoires

#### MASVS-PLATFORM-1 : Permissions minimales
- ✅ Demander uniquement les permissions nécessaires
- ✅ Utiliser les permissions runtime
- ✅ Expliquer pourquoi chaque permission est nécessaire

#### MASVS-PLATFORM-2 : IPC sécurisé
- ✅ Protéger les Content Providers avec des permissions
- ✅ Valider toutes les données reçues via Intent
- ✅ Utiliser des Broadcast Receivers privés

---

## MASVS-CODE – Code Quality

### Objectif
Maintenir un code de haute qualité et sécurisé.

### Exigences obligatoires

#### MASVS-CODE-1 : Obfuscation
- ✅ Activer ProGuard/R8 en production
- ✅ Obfusquer les noms de classes et méthodes
- ✅ Supprimer les logs de debug

#### MASVS-CODE-2 : Protection contre le tampering
- ✅ Détecter le root/jailbreak
- ✅ Détecter les debuggers
- ✅ Vérifier l'intégrité du code

### Configuration ProGuard
```proguard
-optimizationpasses 5
-dontusemixedcaseclassnames
-verbose
-optimizations !code/simplification/arithmetic

# Garder les classes de sécurité
-keep class com.example.security.** { *; }

# Obfusquer tout le reste
-repackageclasses ''
-allowaccessmodification
```

---

## MASVS-RESILIENCE – Resilience Against Reverse Engineering

### Objectif
Rendre le reverse engineering difficile.

### Exigences obligatoires

#### MASVS-RESILIENCE-1 : Détection d'environnement
- ✅ Détecter les émulateurs
- ✅ Détecter le root/jailbreak
- ✅ Détecter les frameworks de hooking (Frida, Xposed)

#### MASVS-RESILIENCE-2 : Protection du code
- ✅ Utiliser le native code (NDK) pour le code critique
- ✅ Implémenter des checksums de code
- ✅ Chiffrer les ressources sensibles

### Exemple de détection de root
```kotlin
fun isDeviceRooted(): Boolean {
    val paths = arrayOf(
        "/system/app/Superuser.apk",
        "/sbin/su",
        "/system/bin/su",
        "/system/xbin/su",
        "/data/local/xbin/su",
        "/data/local/bin/su",
        "/system/sd/xbin/su",
        "/system/bin/failsafe/su",
        "/data/local/su"
    )
    
    return paths.any { File(it).exists() }
}
```

---

## Validation et conformité

### Niveaux de sécurité MASVS
- **MASVS-L1** : Standard (obligatoire pour toutes les apps)
- **MASVS-L2** : Défense en profondeur (recommandé)
- **MASVS-R** : Résilience contre le reverse engineering (apps sensibles)

### Outils de vérification
- **MobSF** : Analyse statique et dynamique
- **Drozer** : Test de sécurité Android
- **Frida** : Analyse dynamique

### Tests obligatoires
- ✅ Test de stockage sécurisé
- ✅ Test de communication chiffrée
- ✅ Test de certificate pinning
- ✅ Test de détection de root
- ✅ Test d'obfuscation

---

**Dernière mise à jour** : 2026-05-08  
**Responsable** : Équipe Sécurité Axiom-Scaffold
