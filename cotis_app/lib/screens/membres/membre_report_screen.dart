import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kased_app/models/membre.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/providers/kased_app_provider.dart';
import 'package:kased_app/core/pdf/member_report_pdf_service.dart';
import 'package:kased_app/core/export/member_report_export_service.dart';
import 'package:kased_app/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

/// Écran de rapport complet d'un membre avec options d'export
class MembreReportScreen extends ConsumerWidget {
  final String membreId;
  final Membre? membre;

  const MembreReportScreen({
    super.key,
    required this.membreId,
    this.membre,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appDataAsync = ref.watch(kasedAppProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return appDataAsync.when(
      data: (state) {
        final currentMembre = membre ??
            state.membres.firstWhere(
              (m) => m.id == membreId,
              orElse: () => throw Exception('Membre non trouvé'),
            );

        final cotisations = state.cotisations
            .where((c) => c.membreId == membreId)
            .toList();

        final cultes = state.cultes;

        // Calculs des statistiques
        final cultesPayes = cotisations.where((c) => c.estPaye).length;
        final retards = cotisations.where((c) => c.statut == StatutCotisation.nonPaye).length;
        final absences = cotisations.where((c) => c.statut == StatutCotisation.absent).length;
        final totalDons = cotisations.fold<double>(0, (sum, c) => sum + c.montantDon);
        final totalPaye = cotisations.where((c) => c.estPaye).fold<double>(0, (sum, c) => sum + c.montantPaye);
        final totalDu = cotisations.fold<double>(0, (sum, c) => sum + (c.montantObligatoire - c.montantPaye));
        final cadence = cultes.isNotEmpty ? (cultesPayes / cultes.length * 100) : 0;

        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            title: Text('Rapport - ${currentMembre.nomComplet}'),
            actions: [
              // Bouton export PDF
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: 'Exporter en PDF',
                onPressed: () async {
                  try {
                    final path = await MemberReportPdfService.generateMembreRapport(
                      membre: currentMembre,
                      cotisations: cotisations,
                      cultes: cultes,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Rapport PDF enregistré : $path'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Impossible de générer le rapport. Veuillez réessayer.')),
                      );
                    }
                  }
                },
              ),
              // Bouton export CSV
              IconButton(
                icon: const Icon(Icons.table_chart),
                tooltip: 'Exporter en CSV',
                onPressed: () async {
                  try {
                    final path = await MemberReportExportService.exporterRapportMembreCsv(
                      membre: currentMembre,
                      cotisations: cotisations,
                      cultes: cultes,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Rapport CSV enregistré : $path'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Impossible de générer le rapport. Veuillez réessayer.')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Carte d'identité du membre
              _buildIdentityCard(currentMembre, theme),
              const SizedBox(height: 16),

              // Résumé statistique
              _buildStatsSummary(
                cultesPayes: cultesPayes,
                retards: retards,
                absences: absences,
                totalDons: totalDons,
                totalPaye: totalPaye,
                totalDu: totalDu,
                cadence: cadence.toDouble(),
                montantEnAvance: currentMembre.montantEnAvance,
                theme: theme,
              ),
              const SizedBox(height: 16),

              // Historique des cotisations
              _buildCotisationsHistory(cotisations, cultes, theme),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Impossible de générer le rapport. Veuillez réessayer.')),
    );
  }

  Widget _buildIdentityCard(Membre membre, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.gradientStart.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar avec initiales
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Center(
              child: Text(
                membre.initiales,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Nom complet
          Text(
            membre.nomComplet,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),

          // Badge status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: membre.isActive ? AppColors.success : AppColors.danger,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              membre.isActive ? 'Actif' : 'Inactif',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),

          // Informations détaillées
          _buildInfoRow('Membre depuis', DateFormat('dd MMMM yyyy', 'fr_FR').format(membre.dateAdhesion), theme),
          if (membre.dateNaissance != null)
            _buildInfoRow('Date de naissance', DateFormat('dd MMMM yyyy', 'fr_FR').format(membre.dateNaissance!), theme),
          if (membre.telephone != null)
            _buildInfoRow('Téléphone', membre.telephone!, theme),
          if (membre.notes != null)
            _buildInfoRow('Notes', membre.notes!, theme),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildStatsSummary({
    required int cultesPayes,
    required int retards,
    required int absences,
    required double totalDons,
    required double totalPaye,
    required double totalDu,
    required double cadence,
    required double montantEnAvance,
    required ThemeData theme,
  }) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RÉSUMÉ STATISTIQUE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // Grid de statistiques
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatTile('Cultes Payés', '$cultesPayes', AppColors.success, colorScheme),
              _buildStatTile('Retards', '$retards', AppColors.danger, colorScheme),
              _buildStatTile('Absences', '$absences', colorScheme.onSurfaceVariant, colorScheme),
              _buildStatTile('Cadence', '${cadence.toStringAsFixed(0)}%', AppColors.primary, colorScheme),
              _buildStatTile('Total Payé', '${totalPaye.toInt()} F', AppColors.success, colorScheme),
              _buildStatTile('Total Dons', '${totalDons.toInt()} F', const Color(0xFF7C4DFF), colorScheme),
              _buildStatTile('En Avance', '${montantEnAvance.toInt()} F', AppColors.warning, colorScheme),
              _buildStatTile('Total dû', '${totalDu.toInt()} F', AppColors.danger, colorScheme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value, Color color, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCotisationsHistory(List<Cotisation> cotisations, List<Culte> cultes, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final cultesMap = {for (var c in cultes) c.id: c};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HISTORIQUE DES COTISATIONS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          if (cotisations.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Aucune cotisation enregistrée'),
              ),
            )
          else
            ...cotisations.map((cot) {
              final culte = cultesMap[cot.culteId];
              if (culte == null) return const SizedBox.shrink();

              return _buildCotisationTile(cot, culte, colorScheme);
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildCotisationTile(Cotisation cot, Culte culte, ColorScheme colorScheme) {
    final estPaye = cot.estPaye;
    final dateStr = DateFormat('dd/MM/yyyy').format(culte.dateCulte);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: estPaye
            ? AppColors.success.withValues(alpha: 0.08)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: estPaye ? AppColors.success : colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(
            estPaye ? Icons.check_circle : Icons.schedule,
            color: estPaye ? AppColors.success : colorScheme.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  culte.titre ?? 'Culte dominical',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${cot.montantPaye.toInt()} F',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: estPaye ? AppColors.success : colorScheme.onSurface,
                ),
              ),
              if (cot.montantDon > 0)
                Text(
                  '+${cot.montantDon.toInt()} F don',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
