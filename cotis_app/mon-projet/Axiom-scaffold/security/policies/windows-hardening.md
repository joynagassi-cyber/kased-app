# Windows Security Hardening – Politiques Axiom-Scaffold

**Version** : 2024  
**Référence** : Microsoft Security Baselines  
**Statut** : Obligatoire pour les environnements Windows

---

## 1. Gestion des comptes et authentification

### 1.1 Comptes utilisateurs

#### Exigences obligatoires
- ✅ Désactiver le compte Administrateur intégré
- ✅ Renommer le compte Administrateur
- ✅ Utiliser des comptes standards pour les tâches quotidiennes
- ✅ Activer UAC (User Account Control) au niveau maximum
- ✅ Implémenter une politique de mots de passe forts

#### Politique de mots de passe
```
Longueur minimale : 14 caractères
Complexité : Activée
Historique : 24 mots de passe
Durée de vie maximale : 90 jours
Durée de vie minimale : 1 jour
Verrouillage : 5 tentatives / 30 minutes
```

### 1.2 Authentification

#### Exigences obligatoires
- ✅ Activer Windows Hello for Business
- ✅ Désactiver l'authentification NTLM (utiliser Kerberos)
- ✅ Activer l'authentification multi-facteurs
- ✅ Désactiver le stockage des mots de passe en clair

---

## 2. Mises à jour et correctifs

### Exigences obligatoires
- ✅ Activer Windows Update automatique
- ✅ Installer les mises à jour de sécurité dans les 48h
- ✅ Activer Microsoft Defender Antivirus
- ✅ Maintenir les applications tierces à jour

### Configuration Windows Update
```powershell
# Activer les mises à jour automatiques
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -Value 0

# Installer les mises à jour quotidiennement
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "ScheduledInstallDay" -Value 0
```

---

## 3. Pare-feu et réseau

### 3.1 Windows Defender Firewall

#### Exigences obligatoires
- ✅ Activer le pare-feu pour tous les profils (Domaine, Privé, Public)
- ✅ Bloquer toutes les connexions entrantes par défaut
- ✅ Autoriser uniquement les applications nécessaires
- ✅ Journaliser les connexions bloquées

### Configuration PowerShell
```powershell
# Activer le pare-feu pour tous les profils
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True

# Bloquer les connexions entrantes par défaut
Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block

# Activer la journalisation
Set-NetFirewallProfile -Profile Domain,Public,Private -LogAllowed True -LogBlocked True
```

### 3.2 Réseau

#### Exigences obligatoires
- ✅ Désactiver SMBv1
- ✅ Activer SMB Encryption
- ✅ Désactiver NetBIOS sur TCP/IP
- ✅ Désactiver LLMNR et mDNS

```powershell
# Désactiver SMBv1
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol

# Activer SMB Encryption
Set-SmbServerConfiguration -EncryptData $true -Force

# Désactiver NetBIOS
Get-WmiObject Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True" | ForEach-Object { $_.SetTcpipNetbios(2) }
```

---

## 4. Chiffrement et protection des données

### 4.1 BitLocker

#### Exigences obligatoires
- ✅ Activer BitLocker sur tous les disques
- ✅ Utiliser un TPM 2.0
- ✅ Sauvegarder les clés de récupération dans Azure AD
- ✅ Utiliser AES-256 pour le chiffrement

### Configuration BitLocker
```powershell
# Activer BitLocker sur le disque C:
Enable-BitLocker -MountPoint "C:" -EncryptionMethod Aes256 -UsedSpaceOnly -TpmProtector

# Sauvegarder la clé de récupération
Backup-BitLockerKeyProtector -MountPoint "C:" -KeyProtectorId $KeyProtectorId
```

### 4.2 EFS (Encrypting File System)

#### Exigences obligatoires
- ✅ Chiffrer les dossiers contenant des données sensibles
- ✅ Sauvegarder les certificats EFS
- ✅ Utiliser des clés de 256 bits

---

## 5. Contrôle d'application et Device Guard

### 5.1 AppLocker

#### Exigences obligatoires
- ✅ Activer AppLocker pour contrôler les applications
- ✅ Autoriser uniquement les applications signées
- ✅ Bloquer l'exécution depuis les dossiers temporaires
- ✅ Journaliser toutes les tentatives d'exécution bloquées

### Règles AppLocker recommandées
```xml
<RuleCollection Type="Exe">
  <FilePathRule Id="..." Name="Block Temp" Action="Deny">
    <Conditions>
      <FilePathCondition Path="%TEMP%\*" />
    </Conditions>
  </FilePathRule>
  
  <PublisherRule Id="..." Name="Allow Signed" Action="Allow">
    <Conditions>
      <PublisherCondition PublisherName="*" ProductName="*" BinaryName="*">
        <BinaryVersionRange LowSection="*" HighSection="*" />
      </PublisherCondition>
    </Conditions>
  </PublisherRule>
</RuleCollection>
```

### 5.2 Windows Defender Application Control (WDAC)

#### Exigences obligatoires
- ✅ Activer WDAC en mode audit puis en mode appliqué
- ✅ Autoriser uniquement les binaires signés par Microsoft
- ✅ Créer des règles personnalisées pour les applications tierces

---

## 6. Audit et journalisation

### Exigences obligatoires
- ✅ Activer l'audit avancé
- ✅ Journaliser tous les événements de sécurité
- ✅ Transférer les logs vers un SIEM
- ✅ Conserver les logs pendant au moins 90 jours

### Événements à auditer
```
- Connexions (succès et échecs)
- Modifications de comptes
- Modifications de groupes
- Accès aux objets sensibles
- Modifications de stratégies
- Utilisation de privilèges
- Création de processus
- Modifications du registre
```

### Configuration PowerShell
```powershell
# Activer l'audit avancé
auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable
auditpol /set /category:"Account Management" /success:enable /failure:enable
auditpol /set /category:"Privilege Use" /success:enable /failure:enable
auditpol /set /category:"Object Access" /success:enable /failure:enable
```

---

## 7. Services et fonctionnalités

### Services à désactiver
- ✅ Remote Registry
- ✅ Telnet
- ✅ FTP
- ✅ SNMP (si non utilisé)
- ✅ Print Spooler (si non utilisé)

### Fonctionnalités à désactiver
- ✅ SMBv1
- ✅ PowerShell v2
- ✅ Windows Media Player
- ✅ Internet Explorer

```powershell
# Désactiver les services inutiles
Stop-Service -Name "RemoteRegistry" -Force
Set-Service -Name "RemoteRegistry" -StartupType Disabled

# Désactiver PowerShell v2
Disable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2Root
```

---

## 8. Protection contre les malwares

### 8.1 Microsoft Defender Antivirus

#### Exigences obligatoires
- ✅ Activer la protection en temps réel
- ✅ Activer la protection cloud
- ✅ Activer la protection contre les ransomwares
- ✅ Planifier des analyses quotidiennes

### Configuration PowerShell
```powershell
# Activer toutes les protections
Set-MpPreference -DisableRealtimeMonitoring $false
Set-MpPreference -MAPSReporting Advanced
Set-MpPreference -SubmitSamplesConsent SendAllSamples
Set-MpPreference -EnableControlledFolderAccess Enabled

# Planifier une analyse quotidienne
Set-MpPreference -ScanScheduleDay Everyday
Set-MpPreference -ScanScheduleTime 02:00:00
```

### 8.2 Attack Surface Reduction (ASR)

#### Exigences obligatoires
- ✅ Activer toutes les règles ASR en mode bloc
- ✅ Bloquer l'exécution de scripts malveillants
- ✅ Bloquer les macros Office
- ✅ Bloquer les processus créés via PsExec et WMI

---

## 9. Accès à distance

### Exigences obligatoires
- ✅ Désactiver RDP si non nécessaire
- ✅ Utiliser NLA (Network Level Authentication)
- ✅ Limiter les utilisateurs autorisés
- ✅ Utiliser des mots de passe forts
- ✅ Activer le chiffrement au niveau le plus élevé

### Configuration RDP sécurisée
```powershell
# Activer NLA
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -Value 1

# Niveau de chiffrement élevé
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "MinEncryptionLevel" -Value 3
```

---

## 10. Sécurité du navigateur

### Microsoft Edge

#### Exigences obligatoires
- ✅ Activer SmartScreen
- ✅ Bloquer les téléchargements potentiellement dangereux
- ✅ Désactiver les plugins obsolètes (Flash, Java)
- ✅ Activer la protection contre le tracking

---

## Validation et conformité

### Outils de vérification
- **Microsoft Security Compliance Toolkit**
- **CIS Benchmark for Windows**
- **STIG (Security Technical Implementation Guide)**

### Audits obligatoires
- ✅ Audit mensuel de la configuration
- ✅ Scan de vulnérabilités hebdomadaire
- ✅ Revue des logs quotidienne
- ✅ Test de pénétration annuel

---

**Dernière mise à jour** : 2026-05-08  
**Responsable** : Équipe Sécurité Axiom-Scaffold
