import '../../models/cotisation.dart';
import '../../models/culte.dart';

/// Logique métier pure pour le calcul des cotisations et des retards.
/// Ces fonctions sont indépendantes de tout framework (testables sans Flutter).
class CotisationLogic {
  /// Calcule le nombre de cultes "dus" (non payés et non absents) pour un membre,
  /// en ne comptant que les cultes qui ont lieu APRÈS [dateAdhesion].
  ///
  /// [cultes] : tous les cultes de l'application.
  /// [cotisations] : toutes les cotisations du membre.
  /// [dateAdhesion] : date d'adhésion du membre (on ignore les cultes antérieurs).
  static int calculerNombreRetards({
    required List<Culte> cultes,
    required List<Cotisation> cotisations,
    required DateTime dateAdhesion,
  }) {
    int retards = 0;
    final cotisationsMap = {for (final c in cotisations) c.culteId: c};

    for (final culte in cultes) {
      // On ignore les cultes antérieurs à l'adhésion
      if (culte.dateCulte.isBefore(dateAdhesion)) continue;

      final cotisation = cotisationsMap[culte.id];

      if (cotisation == null) {
        // Aucune cotisation enregistrée : retard implicite
        retards++;
      } else if (cotisation.statut == StatutCotisation.nonPaye) {
        retards++;
      }
      // absent, paye, enAvance : ne comptent PAS comme retard
    }
    return retards;
  }

  /// Calcule le montant total dû en FCFA à partir du nombre de retards.
  /// Par défaut 50 FCFA par culte manqué.
  static double calculerMontantDu(int nombreRetards, {double montantParCulte = 50.0}) {
    return nombreRetards * montantParCulte;
  }

  /// Détermine le statut d'une cotisation selon la date de paiement
  /// par rapport à la date du culte.
  ///
  /// - [datePaiement] : quand le paiement a été effectué.
  /// - [dateCulte] : date du culte concerné.
  ///
  /// Retourne [StatutCotisation.enAvance] si le paiement précède le culte,
  /// sinon [StatutCotisation.paye].
  static StatutCotisation determinerStatut({
    required DateTime datePaiement,
    required DateTime dateCulte,
  }) {
    // On compare uniquement les dates (ignore l'heure)
    final paiementDay = DateTime(datePaiement.year, datePaiement.month, datePaiement.day);
    final culteDay = DateTime(dateCulte.year, dateCulte.month, dateCulte.day);

    return paiementDay.isBefore(culteDay)
        ? StatutCotisation.enAvance
        : StatutCotisation.paye;
  }
}
