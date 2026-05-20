# SPRING ANIMATIONS — PROMPT D'EXÉCUTION AGENT (FLUTTER)

> Passe ce fichier à ton agent (Claude Code, Cursor).
> Chaque micro-tâche est indépendante et confirmable.
> Ne jamais modifier du code existant sans lire le fichier d'abord.

\---

## ██ CONTEXTE

Application Flutter Android (kased-app).
Objectif : ajouter des spring animations sur les boutons et les icônes de la BottomNavigationBar
pour donner un feel physique, moelleux et élastique à l'interface.
Aucun backend impliqué. Travail 100% côté UI Flutter.

\---

## ██ DÉPENDANCES À AJOUTER (pubspec.yaml)

```yaml
dependencies:
  flutter\_animate: ^4.5.0       # Animations déclaratives fluides (spring, fade, scale)
  haptic\_feedback: ^0.5.0       # Retour haptique précis (light, medium, heavy, selection)
```

Commande après ajout :

```bash
flutter pub get
```

> Note : Flutter dispose aussi de SpringSimulation en natif (aucun package requis).
> On utilisera les deux : flutter\_animate pour la syntaxe déclarative,
> SpringSimulation natif pour les ressorts custom sur les boutons.

\---

## ██ PHASE 0 — AUDIT (LIRE AVANT TOUT)

```
TÂCHES :
  1. Lire le fichier pubspec.yaml → noter les dépendances actuelles
  2. Lire lib/core/router.dart → identifier la structure de la BottomNavigationBar
  3. Lire lib/shared/widgets/ → lister tous les widgets bouton existants
  4. Identifier quel widget joue le rôle de BottomNavigationBar
     (NavigationBar, BottomNavigationBar, ou custom ShellRoute scaffold)
  5. NE RIEN MODIFIER en Phase 0

CONFIRMATION REQUISE :
  Écrire "PHASE 0 VALIDÉE" + liste des fichiers concernés avant de continuer.
```

\---

## ██ PHASE 1 — DÉPENDANCES + UTILITAIRES PARTAGÉS

### Micro-tâche 1.1 — Ajouter les dépendances

```
1. Ouvrir pubspec.yaml
2. Ajouter flutter\_animate et haptic\_feedback dans dependencies
3. Lancer flutter pub get
4. Vérifier absence d'erreur de conflit de version
```

### Micro-tâche 1.2 — Créer le fichier de constantes d'animation

```
Créer : lib/core/animation\_constants.dart

Contenu exact :

import 'package:flutter/physics.dart';

class AppSprings {
  // Ressort principal — boutons (moelleux, rebond léger)
  static const SpringDescription button = SpringDescription(
    mass: 1.0,
    stiffness: 500.0,
    damping: 28.0,
  );

  // Ressort nav bar — icônes (vif, rebond marqué)
  static const SpringDescription navIcon = SpringDescription(
    mass: 1.0,
    stiffness: 700.0,
    damping: 22.0,
  );

  // Ressort subtil — feedback léger (FAB, chips)
  static const SpringDescription soft = SpringDescription(
    mass: 1.0,
    stiffness: 380.0,
    damping: 32.0,
  );
}

class AppAnimDurations {
  static const fast    = Duration(milliseconds: 180);
  static const normal  = Duration(milliseconds: 280);
  static const slow    = Duration(milliseconds: 420);
}
```

CONFIRMATION REQUISE avant Phase 2.

\---

## ██ PHASE 2 — WIDGET BOUTON AVEC SPRING

### Micro-tâche 2.1 — Créer SpringButton widget

```
Créer : lib/shared/widgets/spring\_button.dart

Ce widget encapsule n'importe quel child et lui applique :
  - Scale down à 0.93 au press (finger down)
  - Scale up avec overshoot (1.06) au release
  - Retour à 1.0 via spring physics
  - Haptic light au press

Implémentation :

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:cotisapp/core/animation\_constants.dart';

class SpringButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enableHaptic;

  const SpringButton({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.enableHaptic = true,
  });

  @override
  State<SpringButton> createState() => \_SpringButtonState();
}

class \_SpringButtonState extends State<SpringButton>
    with SingleTickerProviderStateMixin {
  late AnimationController \_controller;
  late Animation<double> \_scale;

  @override
  void initState() {
    super.initState();
    \_controller = AnimationController(vsync: this);
    \_scale = \_controller.drive(
      Tween<double>(begin: 1.0, end: 0.93),
    );
  }

  void \_onTapDown(TapDownDetails \_) {
    if (widget.enableHaptic) HapticFeedback.lightImpact();
    \_controller.animateTo(
      1.0,
      duration: AppAnimDurations.fast,
      curve: Curves.easeOut,
    );
  }

  void \_onTapUp(TapUpDetails \_) {
    \_springBack();
    widget.onTap?.call();
  }

  void \_onTapCancel() => \_springBack();

  void \_springBack() {
    final simulation = SpringSimulation(
      AppSprings.button,
      \_controller.value,
      0.0,
      -8.0,
    );
    \_controller.animateWith(simulation);
  }

  @override
  void dispose() {
    \_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? \_onTapDown : null,
      onTapUp: widget.onTap != null ? \_onTapUp : null,
      onTapCancel: widget.onTap != null ? \_onTapCancel : null,
      onLongPress: widget.onLongPress,
      child: ScaleTransition(scale: \_scale, child: widget.child),
    );
  }
}
```

### Micro-tâche 2.2 — Appliquer SpringButton aux boutons existants

```
Pour chaque bouton dans l'app (ElevatedButton, FilledButton, custom GestureDetector) :
  - Wrapper avec SpringButton
  - Supprimer l'ancien GestureDetector si doublon
  - Conserver le onTap existant via SpringButton.onTap

Exemple de transformation :

AVANT :
  ElevatedButton(
    onPressed: () => marquerPaye(),
    child: Text('Payer 50F'),
  )

APRÈS :
  SpringButton(
    onTap: () => marquerPaye(),
    child: ElevatedButton(
      onPressed: null,   // désactivé car SpringButton gère le tap
      child: Text('Payer 50F'),
    ),
  )

RÈGLE : Ne jamais retirer le onPressed du ElevatedButton complètement
si cela change le style disabled du bouton. Dans ce cas, garder un
onPressed: () {} vide et laisser SpringButton gérer l'action.
```

CONFIRMATION REQUISE avant Phase 3.

\---

## ██ PHASE 3 — NAVBAR ICONS AVEC SPRING

### Micro-tâche 3.1 — Créer SpringNavIcon widget

```
Créer : lib/shared/widgets/spring\_nav\_icon.dart

Ce widget anime l'icône de la navigation bar :
  - Scale up + légère rotation au select (0° → 8° → 0°)
  - Spring overshoot sur le scale (1.0 → 1.35 → 1.0)
  - Haptic selection au tap
  - Color transition de grey → primary

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter\_animate/flutter\_animate.dart';
import 'package:cotisapp/core/animation\_constants.dart';

class SpringNavIcon extends StatefulWidget {
  final IconData icon;
  final IconData selectedIcon;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final String label;

  const SpringNavIcon({
    super.key,
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    required this.label,
    this.selectedColor = const Color(0xFF5C35D9),
    this.unselectedColor = const Color(0xFF9E9E9E),
  });

  @override
  State<SpringNavIcon> createState() => \_SpringNavIconState();
}

class \_SpringNavIconState extends State<SpringNavIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController \_controller;
  late Animation<double> \_scale;
  late Animation<double> \_rotation;
  bool \_wasSelected = false;

  @override
  void initState() {
    super.initState();
    \_controller = AnimationController(vsync: this, duration: AppAnimDurations.normal);
    \_scale = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: \_controller, curve: Curves.easeOut),
    );
    \_rotation = Tween<double>(begin: 0.0, end: 0.07).animate(
      CurvedAnimation(parent: \_controller, curve: Curves.easeOut),
    );
    \_wasSelected = widget.isSelected;
  }

  @override
  void didUpdateWidget(SpringNavIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected \&\& !\_wasSelected) {
      HapticFeedback.selectionClick();
      \_triggerSpring();
    }
    \_wasSelected = widget.isSelected;
  }

  void \_triggerSpring() {
    \_controller.forward(from: 0.0).then((\_) {
      final sim = SpringSimulation(
        AppSprings.navIcon,
        1.0,
        0.0,
        -12.0,
      );
      \_controller.animateWith(sim);
    });
  }

  @override
  void dispose() {
    \_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isSelected
        ? widget.selectedColor
        : widget.unselectedColor;

    return ScaleTransition(
      scale: \_scale,
      child: RotationTransition(
        turns: \_rotation,
        child: AnimatedSwitcher(
          duration: AppAnimDurations.fast,
          child: Icon(
            widget.isSelected ? widget.selectedIcon : widget.icon,
            key: ValueKey(widget.isSelected),
            color: color,
            size: 26,
          ),
        ),
      ),
    );
  }
}
```

### Micro-tâche 3.2 — Intégrer SpringNavIcon dans la BottomNavigationBar

```
Ouvrir le fichier contenant le NavigationBar / BottomNavigationBar (AppShell ou équivalent).

Remplacer chaque NavigationDestination par un custom widget utilisant SpringNavIcon.

Exemple de transformation :

AVANT :
  NavigationBar(
    destinations: \[
      NavigationDestination(icon: Icon(Icons.home\_outlined), label: 'Accueil'),
      NavigationDestination(icon: Icon(Icons.calendar\_today), label: 'Séance'),
      NavigationDestination(icon: Icon(Icons.warning\_outlined), label: 'Retards'),
      NavigationDestination(icon: Icon(Icons.people\_outlined), label: 'Membres'),
    ],
  )

APRÈS :
  NavigationBar(
    destinations: \[
      NavigationDestination(
        icon: SpringNavIcon(
          icon: Icons.home\_outlined,
          selectedIcon: Icons.home,
          isSelected: currentIndex == 0,
          label: 'Accueil',
        ),
        label: 'Accueil',
      ),
      // ... même pattern pour les 3 autres onglets
    ],
  )

RÈGLE : currentIndex doit être le vrai index actuel du router GoRouter,
         pas une variable locale — lire le provider de navigation existant.
```

CONFIRMATION REQUISE avant Phase 4.

\---

## ██ PHASE 4 — ANIMATIONS ADDITIONNELLES flutter\_animate

### Micro-tâche 4.1 — Chip de validation de payement (Payer)

```
Sur le chip de paiement dans culte\_detail\_screen.dart ou équivalent :

Quand isPaid passe à true :
  chip
    .animate(key: ValueKey(isPaid))
    .scale(begin: const Offset(0.85, 0.85), duration: 220.ms, curve: Curves.elasticOut)
    .fadeIn(duration: 150.ms)

Quand isPaid passe à false :
  chip
    .animate(key: ValueKey(isPaid))
    .scale(begin: const Offset(1.1, 1.1), duration: 200.ms, curve: Curves.easeOut)
    .fadeIn(duration: 120.ms)
```

### Micro-tâche 4.2 — Entrée des items de liste (ListTile membres)

```
Dans members\_screen.dart ou le vrai nom du fichier  et session\_detail\_screen.dart (cherche le svrai fichie correspondant ce sont des fichier a titre explicatif) :

Chaque ListTile reçoit une animation d'entrée avec délai indexé :

ListView.builder(
  itemBuilder: (context, index) {
    return MemberTile(...)
      .animate(delay: (index \* 40).ms)
      .fadeIn(duration: 250.ms)
      .slideX(begin: 0.04, duration: 280.ms, curve: Curves.easeOut);
  },
)

RÈGLE : délai maximum 40ms × index — au-delà de 10 items le délai est plafonné à 400ms.
```

### Micro-tâche 4.3 — Badge retard sur l'icône nav

```
Si le compteur de retards > 0, ajouter un badge pulsant sur l'icône Retards :

Badge(
  label: Text('$count'),
  child: SpringNavIcon(...),
)
.animate(onPlay: (c) => c.repeat(reverse: true))
.scaleXY(begin: 1.0, end: 1.08, duration: 900.ms, curve: Curves.easeInOut)
```

CONFIRMATION REQUISE avant Phase 5.

\---

## ██ PHASE 5 — VÉRIFICATION ET BUILD

### Micro-tâche 5.1 — Tests visuels (checklist)

```
□ Tapper un bouton "Payer 50F" → compression visible + rebond + haptic
□ Changer d'onglet nav → icône sélectionnée saute avec overshoot
□ Marquer un membre payé → chip change avec animation scale élastique
□ Ouvrir l'écran Membres → items entrent en cascade avec slide + fade
□ Badge retard visible et pulsant si compteur > 0
□ Aucune animation sur les éléments disabled (boutons inactifs)
□ Pas de jank (saccade) sur device réel — tester sur APK debug
```

### Micro-tâche 5.2 — Analyse statique et buildr\_runner 

Lances flutter analyze et corrige toute les issues
Lance ensuite build\_runner pour synhrosier le code et générer les fichier .g.dart


MICRO-TACHES 5.3: Build APK RELEASE

```bash
flutter build apk --debug
```

Vérifier : build/app/outputs/flutter-apk/app-debug.apk généré sans erreur.

\---

## ██ RÈGLES ANTI-RÉGRESSION

```
1. LIRE chaque fichier avant de le modifier (read-before-write obligatoire)
2. NE JAMAIS supprimer un onTap/onPressed existant — le déplacer dans SpringButton
3. NE JAMAIS animer un widget rebuild à chaque frame sans AnimationController
   (pas d'animation dans build() sans controller)
4. SI flutter\_animate entre en conflit avec une lib existante → utiliser
   uniquement SpringSimulation natif Flutter (aucun package requis)
5. UNE micro-tâche à la fois — confirmer avant de passer à la suivante
6. Les fichiers .g.dart ne sont jamais touchés
```

\---

## ██ RÉFÉRENCE RAPIDE — VALEURS DES RESSORTS

```
                  stiffness   damping   effet
button            500         28        moelleux, rebond léger
navIcon           700         22        vif, rebond marqué
soft (FAB/chips)  380         32        doux, quasi sans rebond

Règle : plus stiffness est haut → plus rapide
        plus damping est bas   → plus de rebond (overshoot)
        masse = 1.0 toujours
```

\---

## ██ MESSAGE DE DÉMARRAGE POUR L'AGENT

```
Applique les spring animations sur kased-app selon les specs ci-dessus.
Commence par PHASE 0 : lis les fichiers concernés et confirme ta compréhension
avant d'écrire la moindre ligne de code.
Respecte l'ordre des phases et des micro-tâches.
Une confirmation écrite est requise entre chaque phase.
```

\---

*Fichier généré pour Ok · kased-app · Spring Animations
Stack : Flutter + flutter\_animate + SpringSimulation natif
Cibles : boutons + BottomNavigationBar icons*

