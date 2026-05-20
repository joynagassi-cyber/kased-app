import 'package:fl_chart/fl_chart.dart';
import 'package:kased_app/core/export/cotisation_export_service.dart';
import 'package:kased_app/core/pdf/registre_pdf_service.dart';
import 'package:kased_app/core/theme/app_theme.dart';
import 'package:kased_app/core/theme/motion_tokens.dart';
import 'package:kased_app/providers/app_data_provider.dart';
import 'package:kased_app/providers/stats_graphiques_provider.dart';
import 'package:kased_app/widgets/motion/motion_aware.dart';
import 'package:kased_app/widgets/motion/animated_appear.dart';
import 'package:kased_app/widgets/spring_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kased_app/widgets/kased_card.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appDataAsync = ref.watch(appDataProvider);
    final donnees = ref.watch(statsGraphiquesProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Calculs réels pour les stats rapides
    final totalCollecte = donnees.collecteParMois.fold<double>(0, (sum, item) => sum + item.montant);
    final moyenneCollecte = donnees.collecteParMois.where((m) => m.montant > 0).isEmpty 
        ? 0.0 
        : totalCollecte / donnees.collecteParMois.where((m) => m.montant > 0).length;
    
    // Simplification : le taux de croissance se base sur le mois en cours vs mois précédent.
    double tauxCroissance = 0;
    if (donnees.collecteParMois.length >= 2) {
      final montantActuel = donnees.collecteParMois.last.montant;
      final montantPrecedent = donnees.collecteParMois[donnees.collecteParMois.length - 2].montant;
      if (montantPrecedent > 0) {
        tauxCroissance = ((montantActuel - montantPrecedent) / montantPrecedent) * 100;
      }
    }

    return MotionAware(
      builder: (context, reduceMotion) {
        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            title: const Text('Statistiques'),
            backgroundColor: colorScheme.surface,
            elevation: 0,
            foregroundColor: colorScheme.onSurface,
            titleTextStyle: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
            actions: [
              if (appDataAsync.hasValue)
                IconButton(
                  icon: const Icon(Icons.file_download),
                  tooltip: 'Exporter au format CSV',
                  onPressed: () async {
                    try {
                      final path = await CotisationExportService.exporterCotisationsEtCultes(appDataAsync.value!);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Données exportées avec succès dans :\n$path'),
                            duration: const Duration(seconds: 5),
                            action: SnackBarAction(
                              label: 'OK',
                              onPressed: () {},
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur d\'exportation: $e')),
                        );
                      }
                    }
                  },
                ),
              IconButton(
                icon: const Icon(Icons.sync),
                onPressed: () => ref.read(appDataProvider.notifier).syncData(),
              ),
            ],
          ),
          body: appDataAsync.isLoading && donnees.collecteParMois.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedAppear(
                        reduceMotion: reduceMotion,
                        child: Text('VUE ANALYTIQUE', style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2, 
                          color: colorScheme.primary,
                        )),
                      ),
                      const SizedBox(height: 24),

                      // Cartes de statistiques rapides
                      AnimatedAppear(
                        delay: MotionStagger.standard,
                        reduceMotion: reduceMotion,
                        child: Row(
                          children: [
                            Expanded(child: _buildStatCard(colorScheme, 'Moyenne / Mois', '${moyenneCollecte.toStringAsFixed(0)} F', Icons.analytics)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildStatCard(
                              colorScheme, 
                              'Croissance', 
                              '${tauxCroissance >= 0 ? '+' : ''}${tauxCroissance.toStringAsFixed(1)}%', 
                              tauxCroissance >= 0 ? Icons.trending_up : Icons.trending_down,
                              isPositive: tauxCroissance >= 0,
                            )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Graphique en barres (Collectes)
                      AnimatedAppear(
                        delay: MotionStagger.standard * 2,
                        reduceMotion: reduceMotion,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Collectes sur 12 mois', style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800, color: colorScheme.onSurface,
                              )),
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 200,
                                child: LineChart(
                                  LineChartData(
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      horizontalInterval: 1000,
                                      getDrawingHorizontalLine: (value) {
                                        return FlLine(
                                          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                                          strokeWidth: 1,
                                          dashArray: [4, 4],
                                        );
                                      },
                                    ),
                                    titlesData: FlTitlesData(
                                      show: true,
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 30,
                                          getTitlesWidget: (value, meta) {
                                            final index = value.toInt();
                                            if (value != index.toDouble() || index < 0 || index >= donnees.collecteParMois.length) {
                                              return const SizedBox.shrink();
                                            }
                                            return SideTitleWidget(
                                              meta: meta,
                                              space: 8,
                                              child: Text(
                                                donnees.collecteParMois[index].libelle.substring(0, 3), // short month
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      leftTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    minX: 0,
                                    maxX: (donnees.collecteParMois.length - 1).toDouble(),
                                    minY: 0,
                                    maxY: donnees.collecteParMois.isEmpty 
                                        ? 100 
                                        : (donnees.collecteParMois.map((e) => e.montant).reduce((a, b) => a > b ? a : b) * 1.15),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: List.generate(donnees.collecteParMois.length, (index) {
                                          return FlSpot(index.toDouble(), donnees.collecteParMois[index].montant);
                                        }),
                                        isCurved: true,
                                        curveSmoothness: 0.35,
                                        gradient: const LinearGradient(
                                          colors: [AppColors.gradientStart, AppColors.gradientEnd],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        barWidth: 4,
                                        isStrokeCapRound: true,
                                        dotData: FlDotData(
                                          show: true,
                                          getDotPainter: (spot, percent, barData, index) {
                                            return FlDotCirclePainter(
                                              radius: 4,
                                              color: colorScheme.surface,
                                              strokeWidth: 2,
                                              strokeColor: AppColors.gradientEnd,
                                            );
                                          },
                                        ),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0x4D2962FF), // gradientStart 30%
                                              Color(0x267C4DFF), // gradientEnd 15%
                                              Color(0x007C4DFF), // transparent
                                            ],
                                            stops: [0.0, 0.5, 1.0],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                        ),
                                      ),
                                    ],
                                    lineTouchData: LineTouchData(
                                      touchTooltipData: LineTouchTooltipData(
                                        getTooltipColor: (touchedSpot) => colorScheme.secondaryContainer,
                                        getTooltipItems: (touchedSpots) {
                                          return touchedSpots.map((spot) {
                                            final month = donnees.collecteParMois[spot.x.toInt()].libelle;
                                            return LineTooltipItem(
                                              '$month\n',
                                              TextStyle(
                                                color: colorScheme.onSecondaryContainer,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: '${spot.y.toStringAsFixed(0)} F',
                                                  style: TextStyle(
                                                    color: colorScheme.primary,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            );
                                          }).toList();
                                        }
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Top Membres Assidus
                      if (donnees.topMembres.isNotEmpty)
                        AnimatedAppear(
                          delay: MotionStagger.standard * 3,
                          reduceMotion: reduceMotion,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Top Membres Assidus', style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800, color: colorScheme.onSurface,
                              )),
                              const SizedBox(height: 16),
                              KasedCard(
                                padding: EdgeInsets.zero,
                                child: Column(
                                  children: donnees.topMembres.map((assidu) {
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: colorScheme.primaryContainer,
                                        child: Text(
                                          assidu.membre.nom[0].toUpperCase(),
                                          style: TextStyle(color: colorScheme.onPrimaryContainer),
                                        ),
                                      ),
                                      title: Text(assidu.membre.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      subtitle: Text('${assidu.cultesPayes}/${assidu.cultesConcernes} cultes payés'),
                                      trailing: Text(
                                        '${assidu.pourcentage.toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: assidu.pourcentage >= 80 ? Colors.green : colorScheme.onSurface,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 48),

                      // Bouton Exporter
                      AnimatedAppear(
                        delay: MotionStagger.standard * 4,
                        reduceMotion: reduceMotion,
                        child: SpringButton(
                          onTap: () => _exportRegistre(context, ref, appDataAsync.value!),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                )
                              ]
                            ),
                            child: FilledButton(
                              onPressed: () {}, // Géré par SpringButton
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.picture_as_pdf, color: Colors.white),
                                  SizedBox(width: 12),
                                  Text('Exporter le rapport PDF', style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white,
                                  )),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
        );
      }
    );
  }

  Widget _buildStatCard(ColorScheme colorScheme, String title, String value, IconData icon, {bool? isPositive}) {
    final valueColor = isPositive == null
        ? colorScheme.onSurface
        : (isPositive ? AppColors.gradientEnd : colorScheme.error);

    return KasedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colorScheme.primary, size: 20),
          ),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant,
          )),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w800, color: valueColor,
          )),
        ],
      ),
    );
  }
  Future<void> _exportRegistre(BuildContext context, WidgetRef ref, AppState state) async {
    final selection = await showDialog<_MonthYearSelection>(
      context: context,
      builder: (dialogContext) => const _MonthYearPickerDialog(),
    );

    if (selection == null || !context.mounted) return;

    try {
      final path = await RegistrePdfService.genererEtPartager(
        membres: state.membres,
        cultes: state.cultes,
        cotisations: state.cotisations,
        mois: selection.mois,
        annee: selection.annee,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rapport PDF enregistré dans :\n$path'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }
}

class _MonthYearSelection {
  final int mois;
  final int annee;

  const _MonthYearSelection({required this.mois, required this.annee});
}

class _MonthYearPickerDialog extends StatefulWidget {
  const _MonthYearPickerDialog();

  @override
  State<_MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<_MonthYearPickerDialog> {
  int _mois = DateTime.now().month;
  int _annee = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choisir le mois'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            initialValue: _mois,
            decoration: const InputDecoration(labelText: 'Mois'),
            items: const [
              DropdownMenuItem(value: 1, child: Text('Janvier')),
              DropdownMenuItem(value: 2, child: Text('Février')),
              DropdownMenuItem(value: 3, child: Text('Mars')),
              DropdownMenuItem(value: 4, child: Text('Avril')),
              DropdownMenuItem(value: 5, child: Text('Mai')),
              DropdownMenuItem(value: 6, child: Text('Juin')),
              DropdownMenuItem(value: 7, child: Text('Juillet')),
              DropdownMenuItem(value: 8, child: Text('Août')),
              DropdownMenuItem(value: 9, child: Text('Septembre')),
              DropdownMenuItem(value: 10, child: Text('Octobre')),
              DropdownMenuItem(value: 11, child: Text('Novembre')),
              DropdownMenuItem(value: 12, child: Text('Décembre')),
            ],
            onChanged: (value) => setState(() => _mois = value ?? _mois),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _annee,
            decoration: const InputDecoration(labelText: 'Année'),
            items: List.generate(
              5,
              (index) => DropdownMenuItem(value: DateTime.now().year - 2 + index, child: Text('${DateTime.now().year - 2 + index}')),
            ),
            onChanged: (value) => setState(() => _annee = value ?? _annee),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _MonthYearSelection(mois: _mois, annee: _annee),
          ),
          child: const Text('Exporter'),
        ),
      ],
    );
  }
}

