import 'package:kased_app/core/constants.dart';

/// Logique métier pure pour le verrouillage des cultes.
///
/// Ce module centralise la règle des 30 jours : après 30 jours,
/// un culte ne peut plus être modifié et les paiements validés
/// sont verrouillés.
///
/// Les fonctions sont indépendantes de tout framework (testables sans Flutter).
class CulteLock {
  CulteLock._();

  /// Retourne true si le culte a plus de [KasedConstants.joursVerrouillageCulte] jours.
  ///
  /// Le calcul compare les dates sans tenir compte de l'heure
  /// pour éviter les erreurs de bordure.
  static bool isLocked(DateTime dateCulte) {
    final now = DateTime.now();
    final culteDay = DateTime(dateCulte.year, dateCulte.month, dateCulte.day);
    final nowDay = DateTime(now.year, now.month, now.day);
    final daysDiff = nowDay.difference(culteDay).inDays;
    return daysDiff > KasedConstants.joursVerrouillageCulte;
  }

  /// Retourne true si le paiement pour ce membre est verrouillé.
  ///
  /// Un paiement est verrouillé lorsque :
  /// - Le culte a plus de 30 jours
  /// - ET la cotisation est déjà payée
  static bool isPaymentLocked({
    required DateTime dateCulte,
    required bool cotisationEstPaye,
  }) {
    return isLocked(dateCulte) && cotisationEstPaye;
  }

  /// Retourne un message explicatif si le culte est verrouillé, sinon null.
  ///
  /// Utile pour l'UI qui doit afficher un label "Verrouillé".
  static String? lockMessage(DateTime dateCulte, {bool cotisationEstPaye = false}) {
    if (!isLocked(dateCulte)) return null;
    if (cotisationEstPaye) {
      return 'Paiement verrouillé (culte de plus de ${KasedConstants.joursVerrouillageCulte} jours)';
    }
    return 'Culte verrouillé (plus de ${KasedConstants.joursVerrouillageCulte} jours)';
  }
}
