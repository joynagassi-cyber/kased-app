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
