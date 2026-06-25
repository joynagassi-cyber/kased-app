/// Constantes partagées de l'application.
/// Toute valeur magique qui apparaît à plusieurs endroits doit vivre ici.
library;

class KasedConstants {
  KasedConstants._();

  // ── Cotisations ─────────────────────────────────────────────────────────────
  /// Montant par défaut d'une cotisation quand le montant du culte est inconnu.
  static const double cotisationMontantParDefaut = 50.0;

  // ── Corbeille / soft delete ─────────────────────────────────────────────────
  /// Nombre de jours avant qu'un élément de la corbeille soit purgé définitivement.
  static const int joursAvantPurgeCorbeille = 30;

  // ── Verrouillage des cultes ─────────────────────────────────────────────────
  /// Nombre de jours après un culte avant qu'il soit verrouillé (lecture seule).
  static const int joursVerrouillageCulte = 30;

  // ── Sync ────────────────────────────────────────────────────────────────────
  /// Durée minimale entre deux sync complets pour éviter le spam.
  static const Duration syncThrottle = Duration(minutes: 5);

  /// Nombre maximal de tentatives côté client pour pousser une opération.
  static const int syncMaxRetries = 5;

  // ── Pagination InsForge ─────────────────────────────────────────────────────
  static const int defaultPageSize = 200;

  // ── Auth ────────────────────────────────────────────────────────────────────
  /// Timeout pour la récupération du token Google.
  static const Duration googleTimeout = Duration(seconds: 120);
}
