import 'dart:typed_data';

import 'package:kased_app/models/culte.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:kased_app/core/utils/storage_helper.dart';

class RegistrePdfService {
  static Future<Uint8List> genererRegistre({
    required List<Membre> membres,
    required List<Culte> cultes,
    required List<Cotisation> cotisations,
    required int mois,
    required int annee,
  }) async {
    final cultesDuMois = cultes
        .where((culte) => culte.dateCulte.month == mois && culte.dateCulte.year == annee)
        .toList()
      ..sort((a, b) => a.dateCulte.compareTo(b.dateCulte));

    final membresTries = [...membres]..sort((a, b) => a.nomComplet.compareTo(b.nomComplet));
    final cotisationsDuMois = cotisations.where((c) => cultesDuMois.any((culte) => c.culteId == culte.id)).toList();
    final cotisationsParCle = <String, Cotisation>{
      for (final cotisation in cotisationsDuMois) '${cotisation.membreId}_${cotisation.culteId}': cotisation,
    };

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(18),
        build: (context) {
          final headers = <String>[
            'Membre',
            ...cultesDuMois.map((culte) => DateFormat('dd MMM', 'fr_FR').format(culte.dateCulte)),
            'Total payé',
            'Retards cumulés',
          ];

          final rows = membresTries.map((membre) {
            final cells = <pw.Widget>[
              _textCell(membre.nomComplet, align: pw.Alignment.centerLeft, bold: true),
              for (final culte in cultesDuMois)
                _statusCell(cotisationsParCle.containsKey('${membre.id}_${culte.id}')),
              _textCell(
                cotisationsDuMois.where((c) => c.membreId == membre.id && c.estPaye).fold(0.0, (sum, c) => sum + c.montant).toInt().toString(),
              ),
              _textCell(
                cultesDuMois.where((culte) => !cotisationsParCle.containsKey('${membre.id}_${culte.id}')).length.toString(),
              ),
            ];
            return cells;
          }).toList();

          final footerTotals = <pw.Widget>[
            _textCell('Total', align: pw.Alignment.centerLeft, bold: true),
            for (final culte in cultesDuMois)
              _textCell(
                cotisationsDuMois.where((c) => c.culteId == culte.id && c.estPaye).fold(0.0, (sum, c) => sum + c.montant).toInt().toString(),
                bold: true,
              ),
            _textCell(
              cotisationsDuMois.where((c) => c.estPaye).fold(0.0, (sum, c) => sum + c.montant).toInt().toString(),
              bold: true,
            ),
            _textCell(''),
          ];

          return [
            pw.Text(
              'KASED - Registre de cotisations ${DateFormat('MMMM yyyy', 'fr_FR').format(DateTime(annee, mois))}',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            if (cultesDuMois.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _borderColor),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Text('Aucun culte enregistré pour ce mois.'),
              )
            else
              pw.Table(
                border: pw.TableBorder.all(color: _borderColor, width: 0.8),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2.6),
                  for (var i = 1; i <= cultesDuMois.length; i++) i: const pw.FlexColumnWidth(1.0),
                  cultesDuMois.length + 1: const pw.FlexColumnWidth(1.1),
                  cultesDuMois.length + 2: const pw.FlexColumnWidth(1.1),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8EEFB)),
                    children: headers.map((header) => _headerCell(header)).toList(),
                  ),
                  ...rows.map(
                    (row) => pw.TableRow(
                      children: row,
                    ),
                  ),
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF7F8FC)),
                    children: footerTotals,
                  ),
                ],
              ),
            pw.SizedBox(height: 12),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Généré le ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())} - Kased-App',
                style: const pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xFF4A5578)),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Future<String> genererEtPartager({
    required List<Membre> membres,
    required List<Culte> cultes,
    required List<Cotisation> cotisations,
    required int mois,
    required int annee,
  }) async {
    final bytes = await genererRegistre(
      membres: membres,
      cultes: cultes,
      cotisations: cotisations,
      mois: mois,
      annee: annee,
    );
    final fileName = 'registre_${annee}_$mois.pdf';
    final file = await StorageHelper.saveFileToStorage(
      bytes: bytes,
      fileName: fileName,
    );
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: 'Registre officiel Kased'));
    return file.path;
  }

  static pw.Widget _headerCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      ),
    );
  }

  static pw.Widget _textCell(String text, {pw.Alignment align = pw.Alignment.center, bool bold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      alignment: align,
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontSize: 9, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
      ),
    );
  }

  static pw.Widget _statusCell(bool paye) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      alignment: pw.Alignment.center,
      child: pw.Text(
        paye ? 'V' : '?',
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: paye ? const PdfColor.fromInt(0xFF059669) : const PdfColor.fromInt(0xFFDC2626),
        ),
      ),
    );
  }

  static const PdfColor _borderColor = PdfColor.fromInt(0xFFE2E6F3);
}

