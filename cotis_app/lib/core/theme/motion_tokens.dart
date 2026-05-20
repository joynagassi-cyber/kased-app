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
