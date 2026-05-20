import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/core/utils/storage_helper.dart';

class PdfService {
  static const PdfColor _primary = PdfColor.fromInt(0xFF1246C8);
  static const PdfColor _primaryLight = PdfColor.fromInt(0xFFE8EEFB);
  static const PdfColor _danger = PdfColor.fromInt(0xFFDC2626);
  static const PdfColor _textPrimary = PdfColor.fromInt(0xFF0E1631);
  static const PdfColor _textSecondary = PdfColor.fromInt(0xFF4A5578);
  static const PdfColor _border = PdfColor.fromInt(0xFFE2E6F3);

  static Future<String> generateRetardsPdf(List<Map<String, dynamic>> retards) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Kased - Rapport des Retards',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                  pw.Text(
                    DateFormat('dd/MM/yyyy').format(DateTime.now()),
                    style: const pw.TextStyle(color: _textSecondary),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Membre', 'Retards (Dimanches)', 'Dette (FCFA)'],
              data: retards.map((r) {
                final nom = r['nom'] ?? '';
                final prenom = r['prenom'] ?? '';
                final nombreRetards = (r['cultes_en_retard'] as num?)?.toInt() ?? 0;
                final montantDu = (r['montant_du_fcfa'] as num?)?.toDouble() ?? 0.0;
                return [
                  '$prenom $nom'.trim(),
                  '$nombreRetards',
                  '${montantDu.toInt()} F',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: _primary,
              ),
              headerDecoration: const pw.BoxDecoration(color: _primaryLight),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                1: pw.Alignment.center,
                2: pw.Alignment.centerRight,
              },
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Total des impayés: ${retards.fold<double>(0.0, (sum, r) => sum + ((r['montant_du_fcfa'] as num?)?.toDouble() ?? 0.0)).toInt()} FCFA',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: _danger,
                ),
              ),
            ),
          ];
        },
      ),
    );

    return await _saveAndShare(pdf, 'rapport_retards_${DateTime.now().millisecondsSinceEpoch}.pdf');
  }

  static Future<String> generateCultePdf({
    required Culte culte,
    required List<MembrePaiementStatus> statuses,
    required double totalCollecte,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Kased - Rapport de Culte',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                  pw.Text(
                    'Date: ${culte.dateFormatee}',
                    style: const pw.TextStyle(fontSize: 16, color: _textSecondary),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Total Collecté: ${totalCollecte.toInt()} FCFA',
                  style: pw.TextStyle(color: _primary, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'Membres présents: ${statuses.where((s) => s.estPaye).length} / ${statuses.length}',
                  style: const pw.TextStyle(color: _textSecondary),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Membre', 'Statut', 'Montant'],
              data: statuses.map((s) => [
                s.membre.nomComplet,
                s.estPaye ? 'PAYÉ' : 'NON PAYÉ',
                s.estPaye ? '${culte.montantCotisation.toInt()} F' : '0 F',
              ]).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: _primary,
              ),
              headerDecoration: const pw.BoxDecoration(color: _primaryLight),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: _border)),
              ),
            ),
          ];
        },
      ),
    );

    return await _saveAndShare(pdf, 'rapport_culte_${culte.id.substring(0, 8)}.pdf');
  }

  static Future<String> _saveAndShare(pw.Document pdf, String fileName) async {
    final bytes = await pdf.save();
    final file = await StorageHelper.saveFileToStorage(
      bytes: bytes,
      fileName: fileName,
    );
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: 'Rapport CotisApp'));
    return file.path;
  }
}

class MembrePaiementStatus {
  final Membre membre;
  final bool estPaye;

  MembrePaiementStatus({required this.membre, required this.estPaye});
}

