///
/// Permet de changer de format ou d'implémentation sans modifier les écrans.
library;


import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/models/membre.dart';

/// Interface pour l'export de données Kased.
abstract class KasedExportService {
  /// Exporte les cotisations et cultes en CSV.
  Future<String> exportCotisationsCsv(
    List<Cotisation> cotisations,
    List<Membre> membres,
    List<Culte> cultes,
  );

  /// Exporte le rapport d'un membre en CSV.
  Future<String> exportMembreRapportCsv({
    required Membre membre,
    required List<Cotisation> cotisations,
    required List<Culte> cultes,
  });

  /// Exporte le rapport de tous les membres en CSV.
  Future<String> exportTousLesMembresCsv({
    required List<Membre> membres,
    required List<Cotisation> cotisations,
    required List<Culte> cultes,
  });

  /// Génère le PDF des retards.
  Future<String> exportRetardsPdf(List<Map<String, dynamic>> retards);

  /// Génère le PDF d'un culte avec ses membres.
  Future<String> exportCultePdf({
    required Culte culte,
    required List<Map<String, dynamic>> statuses,
    required double totalCollecte,
  });

  /// Génère le PDF du rapport d'un membre.
  Future<String> exportMembreRapportPdf({
    required Membre membre,
    required List<Cotisation> cotisations,
    required List<Culte> cultes,
  });

  /// Génère le PDF du registre de cotisations.
  Future<String> exportRegistrePdf({
    required List<Membre> membres,
    required List<Culte> cultes,
    required List<Cotisation> cotisations,
    required int mois,
    required int annee,
  });
}
