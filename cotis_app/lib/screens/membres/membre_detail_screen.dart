import 'package:kased_app/core/theme/app_theme.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/models/cotisation.dart';

import 'package:kased_app/providers/kased_app_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kased_app/widgets/kased_avatar.dart';
import 'membre_report_screen.dart';

class MembreDetailScreen extends ConsumerStatefulWidget {
  final String membreId;
  final Membre? membre;

  const MembreDetailScreen({
    super.key,
    required this.membreId,
    this.membre,
  });

  @override
  ConsumerState<MembreDetailScreen> createState() => _MembreDetailScreenState();
}

class _MembreDetailScreenState extends ConsumerState<MembreDetailScreen> {
  bool _isSavingAvance = false;
  String _searchQuery = '';
  StatutCotisation? _statutFilter;

  @override
  Widget build(BuildContext context) {
    final appDataAsync = ref.watch(kasedAppProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return appDataAsync.when(
      data: (state) {
        // Toujours relire depuis le provider pour être à jour (bugfix: widget.membre
        // est un snapshot de navigation, pas la version la plus recente après ajout d'avance)
        final currentMembre = state.membres.firstWhere(
              (m) => m.id == widget.membreId,
              orElse: () => throw Exception('Membre non trouve'),
            );

        final cotisationsMembre = state.cotisations
            .where((c) => c.membreId == widget.membreId)
            .toList();

        final cultesPayes = cotisationsMembre.where((c) => c.estPaye).length;
        final retards = cotisationsMembre.where((c) => c.statut == StatutCotisation.nonPaye).length;
        final absences = cotisationsMembre.where((c) => c.statut == StatutCotisation.absent).length;

        final totalCultes = state.cultes.where((c) => !c.isDeleted).length;
        final cadence = totalCultes > 0
            ? (cultesPayes / totalCultes) * 100
            : 0.0;
        final totalDons = cotisationsMembre
            .fold<double>(0, (sum, c) => sum + c.montantDon);

        // Historique local : associer chaque cotisation à son culte
        final cultesById = {for (final c in state.cultes) c.id: c};
        final historiqueItems = cotisationsMembre
            .map((cot) {
              final culte = cultesById[cot.culteId];
              return _HistoriqueItem(
                date: culte?.dateCulte,
                titre: culte?.titre ?? 'Culte',
                statut: cot.statut,
                montant: cot.montantPaye,
                datePaiement: cot.datePaiement,
              );
            })
            .where((item) => item.date != null)
            .where((item) {
              if (_statutFilter != null && item.statut != _statutFilter) {
                return false;
              }
              if (_searchQuery.isNotEmpty &&
                  !item.titre.toLowerCase().contains(_searchQuery.toLowerCase())) {
                return false;
              }
              return true;
            })
            .toList()
          ..sort((a, b) {
            if (a.date == null || b.date == null) return 0;
            return b.date!.compareTo(a.date!);
          });

        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            title: const Text('Details du membre', style: TextStyle(fontSize: 16)),
            elevation: 0,
            actions: [
              // Bouton rapport
              IconButton(
                icon: const Icon(Icons.assessment),
                tooltip: 'Voir le rapport complet',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MembreReportScreen(
                      membreId: widget.membreId,
                      membre: currentMembre,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            children: [
              // ── Header Card ─────────────────────────────────────
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
                child: Column(
                  children: [
                    Hero(
                      tag: 'membre_${currentMembre.id}',
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: KasedAvatar(
                          name: currentMembre.nomComplet,
                          size: 80,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      currentMembre.nomComplet,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'INSCRIT LE ${DateFormat('dd MMM yyyy').format(currentMembre.dateAdhesion).toUpperCase()}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Stat Cards Grid (3+2 layout) ──────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Row 1: Cultes, Retards, Absences
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Cultes payes',
                            value: '$cultesPayes',
                            sub: '$totalCultes cultes',
                            icon: Icons.check_circle,
                            iconColor: AppColors.success,
                            cardColor: colorScheme.secondaryContainer,
                            textColor: colorScheme.onSecondaryContainer,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            label: 'Retards',
                            value: '$retards',
                            sub: 'en attente',
                            icon: Icons.schedule,
                            iconColor: AppColors.danger,
                            cardColor: colorScheme.errorContainer,
                            textColor: colorScheme.onErrorContainer,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            label: 'Absences',
                            value: '$absences',
                            sub: 'marques',
                            icon: Icons.person_off,
                            iconColor: AppColors.warning,
                            cardColor: colorScheme.tertiaryContainer,
                            textColor: colorScheme.onTertiaryContainer,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Row 2: Cadence, Dons
                    Row(
                      children: [
                        Expanded(
                          child: _CadenceCard(
                            percentage: cadence,
                            paid: cultesPayes,
                            total: totalCultes,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            label: 'Total Dons',
                            value: '${totalDons.toStringAsFixed(0)}',
                            sub: 'FCFA',
                            icon: Icons.favorite,
                            iconColor: colorScheme.primary,
                            cardColor: colorScheme.primaryContainer,
                            textColor: colorScheme.onPrimaryContainer,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Paiement en avance Section ─────────────────────
              if (currentMembre.montantEnAvance > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.schedule,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Paiement en avance',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${currentMembre.montantEnAvance.toStringAsFixed(0)} F',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          onPressed: _isSavingAvance
                              ? null
                              : () => _showAvanceDialog(context, currentMembre),
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                            foregroundColor: colorScheme.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: _isSavingAvance
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text(
                                  'Ajouter',
                                  style: TextStyle(fontSize: 13),
                                ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
                  child: InkWell(
                    onTap: _isSavingAvance
                        ? null
                        : () => _showAvanceDialog(context, currentMembre),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Aucun paiement en avance',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Ajouter un paiement pour ce membre',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Historique Section ─────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Row(
                  children: [
                    Text(
                      'HISTORIQUE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    // Filter by status
                    SegmentedButton<StatutCotisation?>(
                      segments: const [
                        ButtonSegment(
                          value: null,
                          label: Text('Tout'),
                        ),
                        ButtonSegment(
                          value: StatutCotisation.paye,
                          label: Text('Paye'),
                        ),
                        ButtonSegment(
                          value: StatutCotisation.enAvance,
                          label: Text('Avance'),
                        ),
                        ButtonSegment(
                          value: StatutCotisation.nonPaye,
                          label: Text('En retard'),
                        ),
                        ButtonSegment(
                          value: StatutCotisation.absent,
                          label: Text('Absent'),
                        ),
                      ],
                      selected: {_statutFilter},
                      onSelectionChanged: (Set<StatutCotisation?> s) {
                        setState(() => _statutFilter = s.first);
                      },
                      style: const ButtonStyle(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Search field
                    SizedBox(
                      width: 160,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Rechercher...',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                          prefixIcon: const Icon(Icons.search, size: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorScheme.primary),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 13),
                        onChanged: (v) {
                          setState(() => _searchQuery = v);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (historiqueItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Aucun historique disponible.',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                )
              else
                ...historiqueItems.asMap().entries.map((entry) {
                  final item = entry.value;
                  final estPaye = item.statut == StatutCotisation.paye ||
                      item.statut == StatutCotisation.enAvance;
                  final estAbsent = item.statut == StatutCotisation.absent;

                  return Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.date != null
                                    ? DateFormat('dd/MM/yyyy')
                                        .format(item.date!)
                                    : item.titre,
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                estPaye
                                    ? 'Paiement effectue'
                                    : (estAbsent
                                        ? 'Membre absent'
                                        : 'En attente'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: estPaye
                                      ? AppColors.success
                                      : (estAbsent
                                          ? colorScheme.onSurfaceVariant
                                          : AppColors.danger),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: estPaye
                                ? AppColors.success.withValues(alpha: 0.12)
                                : (estAbsent
                                    ? colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.08)
                                    : AppColors.danger.withValues(alpha: 0.12)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${item.montant.toInt()} F',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: estPaye
                                  ? AppColors.success
                                  : (estAbsent
                                      ? colorScheme.onSurfaceVariant
                                      : AppColors.danger),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 48),
            ],
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text("Impossible d'ajouter le paiement en avance. Veuillez reessayer."))),
    );
  }
  Future<void> _showAvanceDialog(BuildContext context, Membre membre) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Paiement en avance'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Montant en FCFA',
            hintText: 'Ex: 500',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              final montant = double.tryParse(controller.text.trim());
              if (montant != null && montant > 0) {
                Navigator.pop(ctx, controller.text.trim());
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result == null || !context.mounted) return;

    final montant = double.tryParse(result) ?? 0.0;
    if (montant <= 0) return;

    setState(() => _isSavingAvance = true);
    try {
      await ref
          .read(kasedAppProvider.notifier)
          .ajouterPaiementAvance(membreId: membre.id, montant: montant);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Gloire à Dieu ! ${montant.toStringAsFixed(0)} F ajoutes en avance'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Impossible d'ajouter le paiement en avance. Veuillez reessayer.")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingAvance = false);
    }
  }
}

class _HistoriqueItem {
  final DateTime? date;
  final String titre;
  final StatutCotisation statut;
  final double montant;
  final DateTime? datePaiement;

  const _HistoriqueItem({
    this.date,
    required this.titre,
    required this.statut,
    required this.montant,
    this.datePaiement,
  });
}

// ── Stat Card (theme-aware, uses ColorScheme) ────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color iconColor;
  final Color cardColor;
  final Color textColor;
  final bool isDark;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.iconColor,
    required this.cardColor,
    required this.textColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textColor,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: textColor.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cadence Card (progress ring + percentage) ─────────────────────────────────

class _CadenceCard extends StatelessWidget {
  final double percentage;
  final int paid;
  final int total;
  final bool isDark;

  const _CadenceCard({
    required this.percentage,
    required this.paid,
    required this.total,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Circular progress indicator
          SizedBox(
            width: 64,
            height: 64,
            child: CustomPaint(
              painter: _ProgressPainter(percentage, colorScheme),
              child: Center(
                child: Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cadence',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$paid / $total cultes',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: total > 0 ? percentage / 100 : 0,
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(4),
                  backgroundColor: colorScheme
                      .onPrimaryContainer
                      .withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressPainter extends CustomPainter {
  final double percentage;
  final ColorScheme colorScheme;

  _ProgressPainter(this.percentage, this.colorScheme);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 4;

    // Background arc
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = colorScheme.onPrimaryContainer.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );

    // Progress arc
    if (percentage > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -90 * (3.14159265 / 180),
        (percentage / 100) * 2 * 3.14159265,
        false,
        Paint()
          ..color = colorScheme.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressPainter oldDelegate) =>
      oldDelegate.percentage != percentage;
}
