# Installation de Kased App

## Problèmes courants d'installation

### 1. "L'installation a échoué"
**Cause** : Le téléphone bloque l'installation des apps inconnues.

**Solution** :
1. Allez dans **Paramètres** → **Applications** → **Accès spécial**
2. Activez **"Installer des apps inconnues"** pour votre navigateur/téléchargement
3. Ou allez dans **Paramètres** → **Sécurité** → **"Sources inconnues"** → Autoriser

### 2. "Le package semble invalide"
**Cause** : APK corrompu ou incompatible.

**Solution** :
- Téléchargez à nouveau l'APK depuis GitHub
- Vérifiez l'intégrité : SHA256 doit être `6f99e4c7...`

### 3. "Incompatible avec votre appareil"
**Cause** : Votre téléphone utilise une architecture non supportée.

**Solution** :
L'APK contient 3 architectures :
- ✅ arm64-v8a (téléphones récents)
- ✅ armeabi-v7a (téléphones anciens)
- ✅ x86_64 (émulateurs)

### 4. Erreur Google Play Protect
**Cause** : Google bloque l'installation.

**Solution** :
1. Pendant l'installation, cliquez sur **"Plus de détails"**
2. Cliquez sur **"Installer quand même"**

## Installation pas à pas

1. **Télécharger**
   ```
   https://github.com/joynagassi-cyber/kased-app/releases/download/v1.1.9%2B3/kased-v1.1.9%2B3.apk
   ```

2. **Activer les sources inconnues**
   ```
   Paramètres → Applications → Installer des apps inconnues → Autoriser
   ```

3. **Installer**
   - Ouvrir le fichier téléchargé
   - Cliquer sur "Installer"
   - Accepter les permissions

4. **Ouvrir**
   - Cliquer sur "Terminé"
   - L'app devrait s'ouvrir

## Vérification de l'intégrité

```bash
# Vérifier le SHA256
sha256sum kased-v1.1.9+3.apk
# Doit retourner: 6f99e4c7eb10b4d6bbaef817be3be257e65e41aa504e9e0883befeee9e832ced
```

## Dépannage

Si l'installation échoue toujours :
1. Désinstaller toute version précédente
2. Redémarrer le téléphone
3. Réessayer l'installation
4. Vérifier l'espace disque (il faut ~150MB libre)
