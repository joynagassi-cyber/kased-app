import 'package:share_plus/share_plus.dart';
import 'package:kased_app/providers/app_data_provider.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/core/utils/storage_helper.dart';

class CotisationExportService {
  static Future<String> exporterCotisationsEtCultes(AppState state) async {
    // 1. Dictionnaires pour accès rapide O(1)
    final membresMap = {for (var m in state.membres) m.id: m};
    final cultesMap = {for (var c in state.cultes) c.id: c};

    final buffer = StringBuffer();
    // UTF-8 BOM pour assurer le bon décodage des accents sous Microsoft Excel (Windows)
    buffer.write('\uFEFF');

    // En-tête du CSV avec délimiteur ;
    buffer.writeln('Nom;Prénom;Date Culte;Culte;Montant Cotisation;Montant Payé;Statut;Date Paiement;Notes');

    for (final cot in state.cotisations) {
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
      
      final notes = (cot.notes ?? '').replaceAll(';', ',').replaceAll('\n', ' ');

      buffer.writeln('$nom;$prenom;$dateCulte;$titreCulte;$montantCotisation;$montantPaye;$statutStr;$datePaiement;$notes');
    }

    final csvContent = buffer.toString();
    
    final fileName = 'export_cotisations_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = await StorageHelper.saveStringFileToStorage(
      content: csvContent,
      fileName: fileName,
    );

    // Partager le fichier via share_plus
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Export des Cotisations',
      ),
    );
    return file.path;
  }
}
