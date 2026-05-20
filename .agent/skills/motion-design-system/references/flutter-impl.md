# 📱 Implémentation Flutter — Motion Design System

> **Contexte** : Implémentation des tokens et micro-interactions du motion design system dans un projet Flutter. Lire ce fichier **uniquement** si la plateforme cible est Flutter ou cross-platform avec Flutter.

---

## 1. Structure de fichiers recommandée

```
lib/
└── design_system/
    └── motion/
        ├── motion_tokens.dart        ← Tokens (durées, courbes, offsets)
        ├── motion_aware.dart         ← Widget prefers-reduced-motion
        ├── animated_appear.dart      ← appear-fade-slide
        ├── animated_press.dart       ← press-shrink
        ├── animated_stagger.dart     ← Staggered list helper
        └── page_transitions.dart     ← Transitions de page
```

---

## 2. Fichier `motion_tokens.dart`

```dart
// lib/design_system/motion/motion_tokens.dart
import 'dart:ui';
import 'package:flutter/material.dart';

/// Durées standardisées du design system motion
abstract class MotionDuration {
  static const instant    = Duration(milliseconds: 100);
  static const short      = Duration(milliseconds: 150);
  static const standard   = Duration(milliseconds: 250);
  static const long       = Duration(milliseconds: 400);
  static const deliberate = Duration(milliseconds: 500);
}

/// Courbes d'easing du design system motion
abstract class MotionCurve {
  /// Mouvement par défaut — décélération naturelle
  static const standard   = Curves.easeOut;

  /// Entrée d'éléments — freine à l'arrivée
  static const decelerate = Curves.easeOutCubic;

  /// Sortie d'éléments — accélère en partant
  static const accelerate = Curves.easeInCubic;

  /// Transitions importantes — in-out équilibré
  static const emphasized = Curves.easeInOut;

  /// Célébrations — légère élasticité
  static const bounce = Curves.elasticOut;

  /// Physique réelle pour drag
  static const spring = SpringDescription(
    mass: 1,
    stiffness: 200,
    damping: 20,
  );
}

/// Décalages de translation
abstract class MotionOffset {
  static const shiftXs = Offset(0, 4);
  static const shiftSm = Offset(0, 8);
  static const shiftMd = Offset(0, 24);
  static const shiftLg = Offset(0, 48);
}

/// Facteurs d'échelle
abstract class MotionScale {
  static const press   = 0.97;
  static const hover   = 1.02;
  static const success = 1.05;
}

/// Délais de staggering
abstract class MotionStagger {
  static const tight    = Duration(milliseconds: 20);
  static const standard = Duration(milliseconds: 40);
  static const loose    = Duration(milliseconds: 60);
  static const child    = Duration(milliseconds: 15);
}
```

---

## 3. Widget `MotionAware` — Prefers Reduced Motion

```dart
// lib/design_system/motion/motion_aware.dart
import 'package:flutter/material.dart';

/// Wrapper qui expose la préférence de mouvement réduit
class MotionAware extends StatelessWidget {
  final Widget Function(BuildContext context, bool reduceMotion) builder;

  const MotionAware({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return builder(context, reduceMotion);
  }
}

/// Extension utilitaire sur Duration
extension MotionDurationExtension on Duration {
  /// Retourne Duration.zero si reduceMotion est actif
  Duration reduced(bool reduceMotion) =>
      reduceMotion ? Duration.zero : this;
}
```

---

## 4. Widget `AnimatedAppear` — `appear-fade-slide`

```dart
// lib/design_system/motion/animated_appear.dart
import 'package:flutter/material.dart';
import 'motion_tokens.dart';

/// Implémentation du pattern appear-fade-slide
/// Opacité 0→1 + glissement vertical 24px→0
class AnimatedAppear extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final bool reduceMotion;

  const AnimatedAppear({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.reduceMotion = false,
  });

  @override
  State<AnimatedAppear> createState() => _AnimatedAppearState();
}

class _AnimatedAppearState extends State<AnimatedAppear>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.reduceMotion
          ? Duration.zero
          : MotionDuration.standard,
    );

    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: MotionCurve.decelerate),
    );

    _offset = Tween<Offset>(
      begin: widget.reduceMotion ? Offset.zero : const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: MotionCurve.decelerate),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}
```

---

## 5. Widget `AnimatedPress` — `press-shrink`

```dart
// lib/design_system/motion/animated_press.dart
import 'package:flutter/material.dart';
import 'motion_tokens.dart';

/// Implémentation du pattern press-shrink
/// Scale 1.0 → 0.97 au tap, retour à 1.0 au relâchement
class AnimatedPress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const AnimatedPress({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<AnimatedPress> createState() => _AnimatedPressState();
}

class _AnimatedPressState extends State<AnimatedPress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MotionDuration.instant,
      reverseDuration: MotionDuration.short,
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: MotionScale.press,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: MotionCurve.accelerate,
      reverseCurve: MotionCurve.decelerate,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (!reduceMotion) _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onLongPress: widget.onLongPress,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
```

---

## 6. Helper `AnimatedStagger` — Listes stagées

```dart
// lib/design_system/motion/animated_stagger.dart
import 'package:flutter/material.dart';
import 'animated_appear.dart';
import 'motion_tokens.dart';

/// Applique un staggering à une liste d'éléments
class AnimatedStaggerList extends StatelessWidget {
  final List<Widget> children;
  final Duration staggerDelay;

  const AnimatedStaggerList({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 40), // stagger-standard
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Column(
      children: [
        for (int i = 0; i < children.length; i++)
          AnimatedAppear(
            delay: reduceMotion
                ? Duration.zero
                : Duration(milliseconds: staggerDelay.inMilliseconds * i),
            reduceMotion: reduceMotion,
            child: children[i],
          ),
      ],
    );
  }
}
```

---

## 7. Transitions de page

```dart
// lib/design_system/motion/page_transitions.dart
import 'package:flutter/material.dart';
import 'motion_tokens.dart';

/// Transition de page slide-from-right (navigation forward)
class SlideRightPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlideRightPageRoute({required this.page})
      : super(
          transitionDuration: MotionDuration.long,
          reverseTransitionDuration: MotionDuration.standard,
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final reduceMotion =
                MediaQuery.of(context).disableAnimations;

            if (reduceMotion) {
              return FadeTransition(opacity: animation, child: child);
            }

            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: MotionCurve.emphasized,
              )),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.5, end: 1.0).animate(animation),
                child: child,
              ),
            );
          },
        );
}
```

---

## 8. Intégration avec les autres skills

| Situation | Action |
|-----------|--------|
| Besoin d'un design system complet | → Invoquer `ui-ux-pro-max` avec `--stack flutter` |
| Besoin de principes UX mobiles | → Lire `mobile-design/SKILL.md` |
| Besoin de prototyper une animation | → Invoquer `huashu-design` |
| Audit des animations existantes | → Utiliser `audit-checklist.md` |
