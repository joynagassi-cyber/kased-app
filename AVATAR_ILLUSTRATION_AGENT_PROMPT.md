# AVATAR ILLUSTRATION AUTOMATIQUE — PROMPT AGENT (FLUTTER)

> ⚠️ RÈGLE GLOBALE SUR LES NOMS DE FICHIERS :
> Tous les noms de fichiers mentionnés dans ce prompt sont INDICATIFS.
> Avant chaque micro-tâche, l'agent DOIT scanner le projet réel :
> find lib/ -name "*.dart" | sort
> Ne jamais supposer qu'un fichier existe — le vérifier d'abord.

---

## ██ CONTEXTE MÉTIER

L'application a au moins 10 utilsateur et trois authentifié (le secrétaire) via Google Auth et email.
Objectif : chaque utilisateur qui se connecte reçoit automatiquement une illustration
de profil générée algorithmiquement depuis son email Google.
- L'utilisateur ne fait rien — l'illustration est choisie automatiquement
- Les utilisateurs qui ont déjà un compte obtiennent d'office leur illustration
  au prochain lancement, sans aucune action de leur part
- Aucun stockage cloud de l'illustration — tout est généré localement à la volée
- Même email = toujours même illustration (déterministe)

---

## ██ DÉPENDANCE À AJOUTER

```yaml
# Dans pubspec.yaml, ajouter sous dependencies :
cached_network_image: ^3.3.1   # Cache image local (si pas déjà présent)
```

> Note : Dicebear fonctionne via une URL générée — pas de package Flutter dédié
> nécessaire. L'URL est construite localement, l'image est mise en cache
> sur l'appareil par cached_network_image. Aucune donnée stockée côté serveur.
> L'API Dicebear est gratuite et open source.

```bash
flutter pub get
```

---

## ██ PHASE 0 — CARTOGRAPHIE OBLIGATOIRE

```
TÂCHES (aucune modification en Phase 0) :

  1. Lancer : find lib/ -name "*.dart" | sort
     → Copier la liste complète

  2. Identifier et noter le fichier réel de chaque élément :
     □ Le fichier qui gère l'état d'authentification Google (auth provider/service)
     □ Le fichier qui contient le modèle utilisateur (UserModel ou équivalent)
     □ Le fichier qui affiche le profil ou l'avatar de l'utilisateur connecté
     □ Le fichier AppBar ou header qui affiche l'utilisateur (dashboard, drawer)
     □ Le fichier qui contient le CircleAvatar actuel de l'utilisateur
     □ Le fichier main.dart — lire son contenu

  3. Identifier comment l'email de l'utilisateur est actuellement récupéré :
     - Via FirebaseAuth ? GoogleSignIn ? Supabase ? Autre ?
     - Quel est le nom exact de la variable/propriété qui contient l'email ?
     - Exemple : user.email / currentUser.email / authState.user?.email

  4. Vérifier si cached_network_image est déjà dans pubspec.yaml

CONFIRMATION REQUISE :
  Écrire "PHASE 0 VALIDÉE" avec :
  - Liste des fichiers réels identifiés
  - La variable exacte qui contient l'email de l'utilisateur connecté
  - Si cached_network_image est déjà présent ou non
```

---

## ██ PHASE 1 — SERVICE AVATAR

### Micro-tâche 1.1 — Créer le service de génération d'avatar
```
Créer dans lib/core/ un fichier nommé avatar_service.dart (ou équivalent)

Contenu exact :

class AvatarService {

  // Style Dicebear utilisé : "adventurer"
  // Autres options possibles : big-smile, lorelei, notionists, personas
  // Changer _style pour changer l'illustration de toute l'app
  static const String _style = 'adventurer';
  static const String _baseUrl = 'https://api.dicebear.com/7.x';

  /// Génère l'URL de l'avatar depuis l'email de l'utilisateur.
  /// Même email → même illustration toujours (déterministe).
  /// L'utilisateur n'a rien à faire.
  static String generateFromEmail(String email) {
    // On utilise l'email encodé comme seed — garantit l'unicité par compte
    final seed = Uri.encodeComponent(email.toLowerCase().trim());
    return '$_baseUrl/$_style/svg?seed=$seed'
        '&backgroundColor=b6e3f4,c0aede,d1d4f9,ffd5dc,ffdfbf'
        '&backgroundType=gradientLinear'
        '&radius=50';
  }

  /// Fallback : initiales si l'image ne charge pas
  static String initialsFromEmail(String email) {
    final parts = email.split('@').first.split('.');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return email.substring(0, 2).toUpperCase();
  }

  /// Fallback couleur de fond déterministe (même email = même couleur)
  static Color colorFromEmail(String email) {
    final colors = [
      const Color(0xFF5C35D9),
      const Color(0xFF1D9E75),
      const Color(0xFFD85A30),
      const Color(0xFF378ADD),
      const Color(0xFFBA7517),
    ];
    final index = email.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[index];
  }
}
```

### Micro-tâche 1.2 — Créer le widget UserAvatar réutilisable
```
Créer dans lib/shared/widgets/ un fichier nommé user_avatar.dart (ou équivalent)

Ce widget :
  - Prend l'email de l'utilisateur en paramètre
  - Affiche l'illustration Dicebear générée automatiquement
  - Affiche les initiales en fallback si l'image échoue (hors ligne)
  - Accepte un paramètre radius pour s'adapter à tous les contextes

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
// importer AvatarService depuis son chemin réel

class UserAvatar extends StatelessWidget {
  final String email;
  final double radius;

  const UserAvatar({
    super.key,
    required this.email,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final url = AvatarService.generateFromEmail(email);
    final initials = AvatarService.initialsFromEmail(email);
    final bgColor = AvatarService.colorFromEmail(email);

    return CachedNetworkImage(
      imageUrl: url,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
        backgroundColor: Colors.transparent,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        backgroundColor: bgColor.withOpacity(0.15),
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: bgColor,
        ),
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.7,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
```

CONFIRMATION REQUISE avant Phase 2.

---

## ██ PHASE 2 — INTÉGRATION DANS L'APPLICATION

### Micro-tâche 2.1 — Remplacer l'avatar existant dans l'AppBar / header
```
FICHIER : trouver le fichier réel qui affiche l'avatar utilisateur (Phase 0)

Identifier l'endroit exact où l'avatar actuel est affiché.
Cas possibles :
  A) CircleAvatar avec initiales → remplacer par UserAvatar
  B) Image.network avec photo Google → remplacer par UserAvatar
  C) Icon(Icons.person) générique → remplacer par UserAvatar

Transformation :

AVANT (exemple indicatif) :
  CircleAvatar(
    backgroundImage: NetworkImage(user.photoUrl ?? ''),
    child: Text(user.name[0]),
  )

APRÈS :
  UserAvatar(
    email: email_reel_de_lutilisateur,  // variable réelle trouvée en Phase 0
    radius: 18,                          // adapter selon le contexte
  )

⚠️ Utiliser la variable email exacte identifiée en Phase 0.
   Ne pas hardcoder une valeur de test.
```

### Micro-tâche 2.2 — Intégrer dans l'écran de profil (si il existe)
```
FICHIER : trouver le fichier écran profil ou settings réel (Phase 0)
          Si cet écran n'existe pas, passer cette micro-tâche.

Remplacer l'avatar actuel par UserAvatar avec un radius plus grand :
  UserAvatar(
    email: email_reel_de_lutilisateur,
    radius: 40,
  )

En dessous, afficher le nom et l'email de l'utilisateur Google
récupérés depuis le provider auth existant.
```

### Micro-tâche 2.3 — Vérifier les utilisateurs existants
```
IMPORTANT — utilisateurs déjà connectés :

Les utilisateurs qui ont déjà un compte voient leur illustration
automatiquement au prochain lancement car :
  - L'email est déjà disponible dans le token Google Auth
  - AvatarService.generateFromEmail() utilise cet email comme seed
  - Même email = même illustration déterministe = aucune migration nécessaire

Vérification à faire :
  1. Lire le provider auth réel (trouvé Phase 0)
  2. Confirmer que l'email est bien accessible via la variable identifiée
  3. S'assurer que UserAvatar est appelé APRÈS que l'état auth est chargé
     (pas pendant l'état de chargement de l'auth)
  4. Si l'email peut être null (utilisateur non connecté) :
     Afficher UserAvatar uniquement si email != null
     Sinon afficher un CircleAvatar générique Icon(Icons.person)
```

CONFIRMATION REQUISE avant Phase 3.

---

## ██ PHASE 3 — CACHE ET MODE HORS LIGNE

### Micro-tâche 3.1 — Configurer le cache de l'illustration
```
cached_network_image met automatiquement en cache l'image sur l'appareil.
L'illustration est téléchargée une seule fois puis réutilisée.

Vérifier dans le fichier main.dart réel que CachedNetworkImage
peut écrire dans le cache (aucune configuration spéciale requise normalement).

Si l'app doit fonctionner 100% hors ligne dès le premier lancement :
  Ajouter dans main() avant runApp() :
    await CachedNetworkImage.evictFromCache('');  // initialise le cache manager

Mode hors ligne après premier lancement :
  Le fallback dans UserAvatar (initiales + couleur) s'affiche automatiquement
  si le cache est vide et le réseau absent. Aucune action supplémentaire.
```

CONFIRMATION REQUISE avant Phase 4.

---

## ██ PHASE 4 — VÉRIFICATION FINALE

### Micro-tâche 4.1 — Checklist de test
```
  □ Lancer l'app avec un compte Google connecté
  □ L'illustration apparaît automatiquement dans l'AppBar / header
  □ L'illustration est cohérente avec l'email (pas aléatoire à chaque lancement)
  □ Couper le réseau → les initiales apparaissent en fallback (pas de crash)
  □ Remettre le réseau → l'illustration réapparaît depuis le cache
  □ Se déconnecter et reconnecter → même illustration (déterministe)
  □ Tester avec un 2ème compte email → illustration différente
  □ Aucun overflow, aucune erreur dans la console Flutter
```

### Micro-tâche 4.2 — Build
```bash
flutter analyze
dart run build_runner build -d
flutter build apk --debug
```

---

## ██ NOTES TECHNIQUES

```
URL Dicebear générée (exemple avec email test@gmail.com) :
https://api.dicebear.com/7.x/adventurer/svg?seed=test%40gmail.com
  &backgroundColor=b6e3f4,c0aede,d1d4f9,ffd5dc,ffdfbf
  &backgroundType=gradientLinear
  &radius=50

Paramètres modifiables dans AvatarService si besoin de changer le style :
  _style = 'adventurer'     → personnage cartoon expressif (recommandé)
  _style = 'big-smile'      → personnage souriant coloré
  _style = 'lorelei'        → illustration épurée minimaliste
  _style = 'notionists'     → style proche de Notion
  _style = 'personas'       → personnage réaliste illustré

Changer _style dans AvatarService suffit pour changer l'illustration
de tous les utilisateurs de l'app en même temps.
```

---

## ██ MESSAGE DE DÉMARRAGE

```
Implémente les avatars illustration automatiques selon ce prompt.
Commence par PHASE 0 : scanne tous les fichiers dart avec
find lib/ -name "*.dart" | sort et identifie les fichiers réels
avant d'écrire la moindre ligne de code.
Confirme la Phase 0 avec les fichiers réels trouvés avant de continuer.
```

---

*Prompt Avatar Illustration · kased-app*
*Stack : Flutter + Dicebear API + cached_network_image*
*Automatique · Déterministe · Zéro stockage cloud*
