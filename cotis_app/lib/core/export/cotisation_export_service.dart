import 'package:share_plus/share_plus.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/core/export/export_service.dart';
import 'package:kased_app/core/utils/storage_helper.dart';
import 'package:intl/intl.dart';

/// Export des cotisations en CSV.
///
/// Implémente [KasedExportService] pour les exports de type CSV.
class CotisationExportService implements KasedExportService {
  @override
  Future<String> exportCotisationsCsv(
    List<Cotisation> cotisations,
    List<Membre> membres,
    List<Culte> cultes,
  ) async {
    final membresMap = {for (var m in membres) m.id: m};
    final cultesMap = {for (var c in cultes) c.id: c};

    final buffer = StringBuffer();
    buffer.write('﻿');
    buffer.writeln('Nom;Prénom;Date Culte;Culte;Montant Cotisation;Montant Payé;Statut;Date Paiement;Notes');

    for (final cot in cotisations) {
      final membre = membresMap[cot.membreId];
      final culte = cultesMap[cot.culteId];
      if (membre == null || culte == null) continue;

      final nom = membre.nom.replaceAll(';', ',');
      final prenom = membre.prenom.replaceAll(';', ',');
      final dateCulte = culte.dateCulte.toIso8601String().substring(0, 10);
      final titreCulte = (culte.titre ?? 'Culte').replaceAll(';', ',');
      final montantCotisation = culte.montantCotisation.toStringAsFixed(0);
      final montantPaye = cot.estPaye ? cot.montantPaye.toStringAsFixed(0) : '0';

      String statutStr = 'Non Payé';
      if (cot.statut == StatutCotisation.paye) statutStr = 'Payé';
      if (cot.statut == StatutCotisation.enAvance) statutStr = 'Payé en avance';
      if (cot.statut == StatutCotisation.absent) statutStr = 'Absent';

      final datePaiement = cot.datePaiement != null
          ? cot.datePaiement!.toIso8601String().substring(0, 10)
          : '';

      buffer.writeln('$nom;$prenom;$dateCulte;$titreCulte;$montantCotisation;$montantPaye;$statutStr;$datePaiement;');
    }

    return _saveAndShareCsv(buffer, 'cotisations.csv');
  }

  @override
  Future<String> exportMembreRapportCsv({
    required Membre membre,
    required List<Cotisation> cotisations,
    required List<Culte> cultes,
  }) async {
    final cultesMap = {for (var c in cultes) c.id: c};
    final buffer = StringBuffer();
    buffer.write('﻿');

    buffer.writeln('RAPPORT MEMBRE COMPLET');
    buffer.writeln('');
    buffer.writeln('Informations Personnelles');
    buffer.writeln('========================');
    buffer.writeln('Nom;${membre.nom}');
    buffer.writeln('Prénom;${membre.prenom}');
    buffer.writeln('Nom complet;${membre.nomComplet}');
    buffer.writeln('Date d\'adhésion;${DateFormat('dd/MM/yyyy').format(membre.dateAdhesion)}');
    if (membre.dateNaissance != null) {
      buffer.writeln('Date de naissance;${DateFormat('dd/MM/yyyy').format(membre.dateNaissance!)}');
    }
    if (membre.telephone != null) {
      buffer.writeln('Téléphone;${membre.telephone}');
    }
    buffer.writeln('Status;${membre.isActive ? 'Actif' : 'Inactif'}');
    if (membre.notes != null) {
      buffer.writeln('Notes;${membre.notes}');
    }
    buffer.writeln('');
    buffer.writeln('Historique des Cotisations');
    buffer.writeln('===========================');

    final membreCotisations = cotisations.where((c) => c.membreId == membre.id).toList();
    for (final cot in membreCotisations) {
      final culte = cultesMap[cot.culteId];
      if (culte == null) continue;
      buffer.writeln('${DateFormat('dd/MM/yyyy').format(culte.dateCulte)};${culte.titre ?? 'Culte'};${cot.montantObligatoire.toStringAsFixed(0)};${cot.montantPaye.toStringAsFixed(0)};${cot.statut.name}');
    }

    return _saveAndShareCsv(buffer, 'rapport_${membre.nomComplet.replaceAll(' ', '_')}.csv');
  }

  @override
  Future<String> exportTousLesMembresCsv({
    required List<Membre> membres,
    required List<Cotisation> cotisations,
    required List<Culte> cultes,
  }) async {
    final buffer = StringBuffer();
    buffer.write('﻿');
    buffer.writeln('Nom;Prénom;Status;Montant Total Cotisé;Nombre de Cultes');

    for (final membre in membres) {
      final membreCotisations = cotisations.where((c) => c.membreId == membre.id).toList();
      final totalCotise = membreCotisations.fold(0.0, (sum, c) => sum + c.montantPaye);
      buffer.writeln('${membre.nom};${membre.prenom};${membre.isActive ? 'Actif' : 'Inactif'};${totalCotise.toStringAsFixed(0)};${membreCotisations.length}');
    }

    return _saveAndShareCsv(buffer, 'tous_membres.csv');
  }

  @override
  Future<String> exportRetardsPdf(List<Map<String, dynamic>> retards) async => '';

  @override
  Future<String> exportCultePdf({
    required Culte culte,
    required List<Map<String, dynamic>> statuses,
    required double totalCollecte,
  }) async => '';

  @override
  Future<String> exportMembreRapportPdf({
    required Membre membre,
    required List<Cotisation> cotisations,
    required List<Culte> cultes,
  }) async => '';

  @override
  Future<String> exportRegistrePdf({
    required List<Membre> membres,
    required List<Culte> cultes,
    required List<Cotisation> cotisations,
    required int mois,
    required int annee,
  }) async => '';

  Future<String> _saveAndShareCsv(StringBuffer buffer, String fileName) async {
    return saveFileToStorage(
      content: buffer.toString(),
      fileName: fileName,
      mimeType: 'text/csv',
    );
  }
}
