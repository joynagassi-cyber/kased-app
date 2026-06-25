import 'package:kased_app/core/theme/app_theme.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/providers/app_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kased_app/widgets/kased_avatar.dart';

class MembreDetailScreen extends ConsumerWidget {
  final String membreId;
  final Membre? membre;

  const MembreDetailScreen({
    super.key,
    required this.membreId,
    this.membre,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appDataAsync = ref.watch(appDataProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return appDataAsync.when(
      data: (state) {
        final currentMembre = membre ??
            state.membres.firstWhere(
              (m) => m.id == membreId,
              orElse: () => throw Exception('Membre non trouvé'),
            );

        // Stats locales depuis les cotisations
        final cotisationsMembre = state.cotisations
            .where((c) => c.membreId == membreId)
            .toList();

        final cultesPayes = cotisationsMembre.where((c) => c.estPaye).length;
        final retards = cotisationsMembre
            .where((c) => c.statut == StatutCotisation.nonPaye)
            .length;
        final absences = cotisationsMembre
            .where((c) => c.statut == StatutCotisation.absent)
            .length;

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
            .where((item) => item.date != null) // ignorer si le culte n'existe plus
            .toList()
          ..sort((a, b) {
            if (a.date == null || b.date == null) return 0;
            return b.date!.compareTo(a.date!);
          });

        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            title: const Text('Détails du membre', style: TextStyle(fontSize: 16)),
            elevation: 0,
          ),
          body: ListView(
            children: [
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

              // ── Floating Stat Cards (2 au lieu de 3) ──────────
              Transform.translate(
                offset: const Offset(0, -24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _GradientStatCard(
                          label: 'Cultes',
                          value: '$cultesPayes',
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00C853), Color(0xFF69F0AE)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shadowColor: const Color(0xFF00C853),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _GradientStatCard(
                          label: 'Retards',
                          value: '$retards',
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF1744), Color(0xFFFF5252)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shadowColor: const Color(0xFFFF1744),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _GradientStatCard(
                          label: 'Absences',
                          value: '$absences',
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF9100), Color(0xFFFFAB40)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shadowColor: const Color(0xFFFF9100),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Historique Section ─────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: Text(
                  'HISTORIQUE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: colorScheme.onSurfaceVariant,
                  ),
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
                  final estPaye = item.statut == StatutCotisation.paye || item.statut == StatutCotisation.enAvance;
                  final estAbsent = item.statut == StatutCotisation.absent;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.border,
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
                                    ? DateFormat('dd/MM/yyyy').format(item.date!)
                                    : item.titre,
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                estPaye
                                    ? 'Paiement effectué'
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: estPaye
                                ? AppColors.success.withValues(alpha: 0.12)
                                : (estAbsent
                                    ? colorScheme.onSurfaceVariant.withValues(alpha: 0.08)
                                    : AppColors.danger.withValues(alpha: 0.12)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${item.montant.toInt()} F',
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
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Erreur: $e'))),
    );
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

// ── Gradient Stat Card ──────────────────────────────────────────────────────

class _GradientStatCard extends StatelessWidget {
  final String label;
  final String value;
  final LinearGradient gradient;
  final Color shadowColor;

  const _GradientStatCard({
    required this.label,
    required this.value,
    required this.gradient,
    required this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
