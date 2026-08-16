import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/core/utils/storage_helper.dart';

/// Service pour générer des rapports PDF complets sur les membres
class MemberReportPdfService {

  // Couleurs du thème
  static const PdfColor _primary = PdfColor.fromInt(0xFF2962FF);
  static const PdfColor _primaryLight = PdfColor.fromInt(0xFFE3F2FD);
  static const PdfColor _success = PdfColor.fromInt(0xFF00C853);
  static const PdfColor _warning = PdfColor.fromInt(0xFFFF9100);
  static const PdfColor _danger = PdfColor.fromInt(0xFFFF1744);
  static const PdfColor _textPrimary = PdfColor.fromInt(0xFF0F172A);
  static const PdfColor _textSecondary = PdfColor.fromInt(0xFF64748B);
  static const PdfColor _border = PdfColor.fromInt(0xFFE2E8F0);

  /// Génère un rapport PDF complet pour un membre spécifique
  static Future<String> generateMembreRapport({
    required Membre membre,
    required List<Cotisation> cotisations,
    required List<Culte> cultes,
  }) async {
    final pdf = pw.Document();

    // Calculs des statistiques
    final cultesPayes = cotisations.where((c) => c.estPaye).length;
    final retards = cotisations.where((c) => c.statut == StatutCotisation.nonPaye).length;
    final absences = cotisations.where((c) => c.statut == StatutCotisation.absent).length;
    final totalDons = cotisations.fold<double>(0, (sum, c) => sum + c.montantDon);
    final totalPaye = cotisations.where((c) => c.estPaye).fold<double>(0, (sum, c) => sum + c.montantPaye);
    final totalDu = cotisations.fold<double>(0, (sum, c) => sum + (c.montantObligatoire - c.montantPaye));
    final cadence = cultes.isNotEmpty ? (cultesPayes / cultes.length * 100).toDouble() : 0.0;

    final maintenant = DateTime.now();
    final age = membre.dateNaissance != null
        ? maintenant.year - membre.dateNaissance!.year -
            (DateTime(maintenant.year, maintenant.month, maintenant.day).isBefore(
                DateTime(maintenant.year, membre.dateNaissance!.month, membre.dateNaissance!.day))
                ? 1 : 0)
        : null;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // En-tête avec logo et titre
            _buildHeader(context),
            pw.SizedBox(height: 30),

            // Section Informations Personnelles
            _buildSectionTitle('Informations Personnelles'),
            _buildMembreInfoCard(membre, age),
            pw.SizedBox(height: 25),

            // Section Résumé Financier
            _buildSectionTitle('Résumé Financier'),
            _buildFinancialSummary(
              totalPaye: totalPaye,
              totalDu: totalDu,
              totalDons: totalDons,
              montantEnAvance: membre.montantEnAvance,
            ),
            pw.SizedBox(height: 25),

            // Section Statistiques de Participation
            _buildSectionTitle('Statistiques de Participation'),
            _buildParticipationStats(
              cultesPayes: cultesPayes,
              retards: retards,
              absences: absences,
              totalCultes: cultes.length,
              cadence: cadence,
            ),
            pw.SizedBox(height: 25),

            // Section Historique des Cotisations
            _buildSectionTitle('Historique des Cotisations'),
            _buildCotisationsTable(cotisations, cultes),
            pw.SizedBox(height: 25),

            // Section Paiements en Avance
            if (membre.montantEnAvance > 0) ...[
              _buildSectionTitle('Paiements en Avance'),
              _buildAvanceCard(membre.montantEnAvance),
              pw.SizedBox(height: 25),
            ],

            // Section Dons
            if (totalDons > 0) ...[
              _buildSectionTitle('Dons'),
              _buildDonCard(totalDons),
              pw.SizedBox(height: 25),
            ],

            // Footer
            pw.Container(
              margin: const pw.EdgeInsets.only(top: 40),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'Rapport généré le ${DateFormat('dd MMMM yyyy à HH:mm', 'fr_FR').format(DateTime.now())} • Kased App',
                style: const pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xFF94A3B8)),
              ),
            ),
          ];
        },
      ),
    );

    return await _saveAndShare(pdf, 'rapport_membre_${membre.nomComplet.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf');
  }

  /// Génère un rapport PDF regroupant tous les membres
  static Future<String> generateRapportGlobalMembres({
    required List<Membre> membres,
    required List<Cotisation> cotisations,
    required List<Culte> cultes,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            _buildHeader(context),
            pw.SizedBox(height: 30),
            pw.Header(level: 1, child: pw.Text('Rapport Global des Membres', style: const pw.TextStyle(fontSize: 20))),
            pw.SizedBox(height: 20),

            // Résumé global
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                _buildGlobalStat('Total Membres', membres.length.toString(), _primary),
                _buildGlobalStat('Total Collecté', '${cotisations.where((c) => c.estPaye).fold<double>(0, (s, c) => s + c.montantPaye).toInt()} F', _success),
                _buildGlobalStat('En Retard', '${cotisations.where((c) => c.statut == StatutCotisation.nonPaye).length}', _warning),
              ],
            ),
            pw.SizedBox(height: 30),

            // Tableau des membres
            pw.TableHelper.fromTextArray(
              headers: ['Nom', 'Prénom', 'Date Adhésion', 'Cotisations Payées', 'Retards', 'Dons', 'Status'],
              data: membres.where((m) => !m.isDeleted).map((membre) {
                final membreCotisations = cotisations.where((c) => c.membreId == membre.id).toList();
                final cultesPayes = membreCotisations.where((c) => c.estPaye).length;
                final retards = membreCotisations.where((c) => c.statut == StatutCotisation.nonPaye).length;
                final totalDons = membreCotisations.fold<double>(0, (sum, c) => sum + c.montantDon);

                return [
                  membre.nom,
                  membre.prenom,
                  DateFormat('dd/MM/yyyy').format(membre.dateAdhesion),
                  '$cultesPayes / ${cultes.length}',
                  retards > 0 ? '$retards' : '-',
                  totalDons > 0 ? '${totalDons.toInt()} F' : '-',
                  membre.isActive ? 'Actif' : 'Inactif',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _primary),
              headerDecoration: pw.BoxDecoration(color: _primaryLight),
            ),
          ];
        },
      ),
    );

    return await _saveAndShare(pdf, 'rapport_global_membres_${DateTime.now().millisecondsSinceEpoch}.pdf');
  }

  // ── Helpers de construction ─────────────────────────────────────────────

  static pw.Widget _buildHeader(pw.Context context) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'KASED',
                  style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: _primary),
                ),
                pw.Text(
                  'Gestion des Cotisations',
                  style: const pw.TextStyle(fontSize: 12, color: _textSecondary),
                ),
              ],
            ),
            pw.Text(
              DateFormat('dd MMMM yyyy', 'fr_FR').format(DateTime.now()),
              style: pw.TextStyle(color: _textSecondary),
            ),
          ],
        ),
        pw.Divider(color: _border),
      ],
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: pw.BoxDecoration(
        color: _primaryLight,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _primary),
      ),
    );
  }

  static pw.Widget _buildMembreInfoCard(Membre membre, int? age) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF8F9FE),
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: _border),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 50,
                height: 50,
                decoration: pw.BoxDecoration(
                  color: _primary,
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Center(
                  child: pw.Text(
                    membre.initiales,
                    style: pw.TextStyle(color: PdfColor.fromInt(0xFFFFFFFF), fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      membre.nomComplet,
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Membre depuis le ${DateFormat('dd MMMM yyyy', 'fr_FR').format(membre.dateAdhesion)}',
                      style: pw.TextStyle(color: _textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(color: _border),
          pw.SizedBox(height: 8),
          _buildInfoRow('Téléphone', membre.telephone ?? 'Non renseigné'),
          _buildInfoRow('Date de naissance', membre.dateNaissance != null ? DateFormat('dd MMMM yyyy', 'fr_FR').format(membre.dateNaissance!) : 'Non renseignée'),
          if (age != null) _buildInfoRow('Âge', '$age ans'),
          _buildInfoRow('Notes', membre.notes ?? 'Aucune'),
          _buildInfoRow('Status', membre.isActive ? 'Actif' : 'Inactif'),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        children: [
          pw.Text('$label: ', style: pw.TextStyle(color: _textSecondary, fontSize: 11)),
          pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 11))),
        ],
      ),
    );
  }

  static pw.Widget _buildFinancialSummary({
    required double totalPaye,
    required double totalDu,
    required double totalDons,
    required double montantEnAvance,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: _border),
      columnWidths: const {
        0: pw.FixedColumnWidth(120),
        1: pw.FixedColumnWidth(100),
        2: pw.FixedColumnWidth(120),
        3: pw.FixedColumnWidth(100),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _primaryLight),
          children: [
            _buildCell('Total Payé', isHeader: true),
            _buildCell('${totalPaye.toInt()} FCFA', isHeader: true),
            _buildCell('Total en Retard', isHeader: true),
            _buildCell('${totalDu.toInt()} FCFA', isHeader: true),
          ],
        ),
        pw.TableRow(children: [
          _buildCell('Total Dons'),
          _buildCell('${totalDons.toInt()} FCFA', color: _success),
          _buildCell('Paiement en Avance'),
          _buildCell('${montantEnAvance.toInt()} FCFA', color: _warning),
        ]),
      ],
    );
  }

  static pw.Widget _buildParticipationStats({
    required int cultesPayes,
    required int retards,
    required int absences,
    required int totalCultes,
    required double cadence,
  }) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            _buildStatBox('Cultes Payés', '$cultesPayes', _success),
            _buildStatBox('Retards', '$retards', _danger),
            _buildStatBox('Absences', '$absences', _textSecondary),
            _buildStatBox('Cadence', '${cadence.toStringAsFixed(0)}%', _primary),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          height: 8,
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFE2E8F0),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Container(
            width: (cadence / 100 * 300),
            decoration: pw.BoxDecoration(
              color: _primary,
              borderRadius: pw.BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildStatBox(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: color),
        ),
        pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: _textSecondary)),
      ],
    );
  }

  static pw.Widget _buildCotisationsTable(List<Cotisation> cotisations, List<Culte> cultes) {
    final cultesMap = {for (var c in cultes) c.id: c};

    return pw.TableHelper.fromTextArray(
      headers: ['Date Culte', 'Montant dû', 'Montant payé', 'Statut', 'Don', 'Date paiement'],
      data: cotisations.map((cot) {
        final culte = cultesMap[cot.culteId];
        final statutText = _getStatutText(cot.statut);
        final statutColor = _getStatutColor(cot.statut);

        return [
          culte != null ? DateFormat('dd/MM/yyyy').format(culte.dateCulte) : '-',
          '${cot.montantObligatoire.toInt()} F',
          '${cot.montantPaye.toInt()} F',
          pw.Text(statutText, style: pw.TextStyle(color: statutColor)),
          cot.montantDon > 0 ? '${cot.montantDon.toInt()} F' : '-',
          cot.datePaiement != null ? DateFormat('dd/MM/yyyy').format(cot.datePaiement!) : '-',
        ];
      }).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _primary),
      headerDecoration: pw.BoxDecoration(color: _primaryLight),
    );
  }

  static String _getStatutText(StatutCotisation statut) {
    switch (statut) {
      case StatutCotisation.paye: return 'Payé';
      case StatutCotisation.enAvance: return 'En avance';
      case StatutCotisation.nonPaye: return 'Non payé';
      case StatutCotisation.absent: return 'Absent';
    }
  }

  static PdfColor _getStatutColor(StatutCotisation statut) {
    switch (statut) {
      case StatutCotisation.paye:
      case StatutCotisation.enAvance: return _success;
      case StatutCotisation.nonPaye: return _warning;
      case StatutCotisation.absent: return _textSecondary;
    }
  }

  static pw.Widget _buildAvanceCard(double montant) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFFFF3E0),
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: _warning),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Paiement en avance', style: pw.TextStyle(color: _textSecondary)),
          pw.Text('${montant.toInt()} FCFA', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _warning)),
        ],
      ),
    );
  }

  static pw.Widget _buildDonCard(double totalDons) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFE8F5E9),
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: _success),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Total des dons', style: pw.TextStyle(color: _textSecondary)),
          pw.Text('${totalDons.toInt()} FCFA', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _success)),
        ],
      ),
    );
  }

  static pw.Widget _buildGlobalStat(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: color)),
        pw.Text(label, style: const pw.TextStyle(fontSize: 11, color: _textSecondary)),
      ],
    );
  }

  static pw.Widget _buildCell(String text, {bool isHeader = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? (isHeader ? _primary : _textPrimary),
        ),
      ),
    );
  }

  static Future<String> _saveAndShare(pw.Document pdf, String fileName) async {
    final bytes = await pdf.save();
    final file = await StorageHelper.saveFileToStorage(bytes: bytes, fileName: fileName);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: 'Rapport Membre Kased'));
    return file.path;
  }
}
