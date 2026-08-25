import 'package:share_plus/share_plus.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/store/app_state.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/core/utils/storage_helper.dart';
import 'package:intl/intl.dart';

/// Service pour exporter les rapports membres en format CSV
class MemberReportExportService {

  /// Exporte les cotisations et cultes d'un membre spécifique en CSV
  static Future<String> exporterRapportMembreCsv({
    required Membre membre,
    required List<Cotisation> cotisations,
    required List<Culte> cultes,
  }) async {
    final cultesMap = {for (var c in cultes) c.id: c};

    // UTF-8 BOM pour Excel
    final buffer = StringBuffer();
    buffer.write('﻿');

    // En-tête principal
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

    // Statistiques
    buffer.writeln('Statistiques');
    buffer.writeln('===========');
    final cultesPayes = cotisations.where((c) => c.estPaye).length;
    final retards = cotisations.where((c) => c.statut == StatutCotisation.nonPaye).length;
    final absences = cotisations.where((c) => c.statut == StatutCotisation.absent).length;
    final totalDons = cotisations.fold<double>(0, (sum, c) => sum + c.montantDon);
    final totalPaye = cotisations.where((c) => c.estPaye).fold<double>(0, (sum, c) => sum + c.montantPaye);
    final totalDu = cotisations.fold<double>(0, (sum, c) => sum + (c.montantObligatoire - c.montantPaye));

    buffer.writeln('Total cultes;${cultes.length}');
    buffer.writeln('Cultes payés;${cultesPayes}');
    buffer.writeln('Retards;${retards}');
    buffer.writeln('Absences;${absences}');
    buffer.writeln('Cadence;${cultes.isNotEmpty ? ((cultesPayes / cultes.length) * 100).toStringAsFixed(1) : '0'}%');
    buffer.writeln('Total payé;${totalPaye.toInt()} FCFA');
    buffer.writeln('Total dû;${totalDu.toInt()} FCFA');
    buffer.writeln('Total dons;${totalDons.toInt()} FCFA');
    buffer.writeln('Montant en avance;${membre.montantEnAvance.toInt()} FCFA');
    buffer.writeln('');

    // Historique des cotisations
    buffer.writeln('Historique des Cotisations');
    buffer.writeln('=========================');
    buffer.writeln('Date culte;Culte;Montant dû;Montant payé;Statut;Don;Date paiement;Notes');

    for (final cot in cotisations) {
      final culte = cultesMap[cot.culteId];
      if (culte == null) continue;

      final dateCulte = DateFormat('dd/MM/yyyy').format(culte.dateCulte);
      final titreCulte = culte.titre ?? 'Culte';
      final statut = _getStatutText(cot.statut);
      final datePaiement = cot.datePaiement != null
          ? DateFormat('dd/MM/yyyy').format(cot.datePaiement!)
          : '-';

      buffer.writeln('$dateCulte;$titreCulte;${cot.montantObligatoire.toInt()};${cot.montantPaye.toInt()};$statut;${cot.montantDon.toInt()};$datePaiement;${cot.notes ?? "-"}');
    }

    final csvContent = buffer.toString();
    final fileName = 'rapport_membre_${membre.nomComplet.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.csv';

    final file = await StorageHelper.saveStringFileToStorage(
      content: csvContent,
      fileName: fileName,
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Rapport Membre - ${membre.nomComplet}',
      ),
    );

    return file.path;
  }

  /// Exporte tous les membres en CSV avec leurs statistiques
  static Future<String> exporterTousLesMembresCsv({
    required AppState state,
  }) async {
    final buffer = StringBuffer();
    buffer.write('﻿');

    // En-tête
    buffer.writeln('RAPPORT GLOBAL DES MEMBRES');
    buffer.writeln('');
    buffer.writeln('Date d\'export;${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}');
    buffer.writeln('Total membres;${state.membres.length}');
    buffer.writeln('Total cultes;${state.cultes.length}');
    buffer.writeln('');

    // En-têtes du tableau
    buffer.writeln('Nom;Prénom;Date adhésion;Status;Cultes payés;Retards;Absences;Cadence;Total payé;Total dons;En avance');

    for (final membre in state.membres.where((m) => !m.isDeleted)) {
      final membreCotisations = state.cotisations.where((c) => c.membreId == membre.id).toList();
      final cultesPayes = membreCotisations.where((c) => c.estPaye).length;
      final retards = membreCotisations.where((c) => c.statut == StatutCotisation.nonPaye).length;
      final absences = membreCotisations.where((c) => c.statut == StatutCotisation.absent).length;
      final totalDons = membreCotisations.fold<double>(0, (sum, c) => sum + c.montantDon);
      final totalPaye = membreCotisations.where((c) => c.estPaye).fold<double>(0, (sum, c) => sum + c.montantPaye);
      final cadence = state.cultes.isNotEmpty ? ((cultesPayes / state.cultes.length) * 100).toStringAsFixed(0) : '0';

      buffer.writeln('${membre.nom};${membre.prenom};${DateFormat('dd/MM/yyyy').format(membre.dateAdhesion)};${membre.isActive ? 'Actif' : 'Inactif'};$cultesPayes;$retards;$absences;$cadence%;${totalPaye.toInt()};${totalDons.toInt()};${membre.montantEnAvance.toInt()}');
    }

    final csvContent = buffer.toString();
    final fileName = 'rapport_global_membres_${DateTime.now().millisecondsSinceEpoch}.csv';

    final file = await StorageHelper.saveStringFileToStorage(
      content: csvContent,
      fileName: fileName,
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Rapport Global des Membres',
      ),
    );

    return file.path;
  }

  static String _getStatutText(StatutCotisation statut) {
    switch (statut) {
      case StatutCotisation.paye: return 'Payé';
      case StatutCotisation.enAvance: return 'En avance';
      case StatutCotisation.nonPaye: return 'Non payé';
      case StatutCotisation.absent: return 'Absent';
    }
  }
}
