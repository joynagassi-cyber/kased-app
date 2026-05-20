import 'package:kased_app/core/theme/app_theme.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/providers/app_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kased_app/widgets/kased_avatar.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
  List<Map<String, dynamic>> historique = [];
  List<Map<String, dynamic>> retards = [];
  MembreRetard? retard;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final retardsData =
          await ref.read(appDataProvider.notifier).loadRetardsMembres();
      final retardData = retardsData.firstWhere(
        (r) => r['membre_id'] == widget.membreId,
        orElse: () => {
          'membre_id': widget.membreId,
          'nombre_retards': 0,
          'montant_du_fcfa': 0.0
        },
      );
      final currentMembre = widget.membre ??
          ref.read(appDataProvider).value!.membres.firstWhere(
                (m) => m.id == widget.membreId,
                orElse: () => throw Exception('Membre non trouvé'),
              );

      setState(() {
        retards = retardsData;
        retard = MembreRetard(
          membre: currentMembre,
          nombreRetards: (retardData['nombre_retards'] as num?)?.toInt() ?? 0,
          montantDu: (retardData['montant_du_fcfa'] as num?)?.toDouble() ?? 0.0,
          cultesManquants: [],
        );
      });
    } catch (e) {
      debugPrint('Erreur chargement retards: $e');
    }

    try {
      final historiqueData = await ref
          .read(appDataProvider.notifier)
          .getHistoriqueMembre(widget.membreId);
      final historique = historiqueData.map((h) {
        return {
          'date': h['culte_date'] != null
              ? DateTime.tryParse(h['culte_date'].toString())
              : null,
          'titre': h['culte_titre'],
          'statut': h['statut'],
          'montant': (h['montant'] as num?)?.toDouble() ?? 0.0,
          'datePaiement': h['date_paiement'] != null
              ? DateTime.tryParse(h['date_paiement'].toString())
              : null,
        };
      }).toList()
        ..sort((a, b) {
          final dateA = a['date'] as DateTime?;
          final dateB = b['date'] as DateTime?;
          if (dateA == null || dateB == null) return 0;
          return dateB.compareTo(dateA);
        });

      setState(() {
        this.historique = historique;
      });
    } catch (e) {
      debugPrint('Erreur chargement historique: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appDataAsync = ref.watch(appDataProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final currentMembre = widget.membre ??
        appDataAsync.value!.membres.firstWhere(
          (m) => m.id == widget.membreId,
          orElse: () => throw Exception('Membre non trouvé'),
        );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Détails du membre', style: TextStyle(fontSize: 16)),
        elevation: 0,
      ),
      body: ListView(
        children: [
          // ── Gradient Profile Header ──────────────────────────────
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

          // ── Floating Gradient Stat Cards ────────────────────────
          Transform.translate(
            offset: const Offset(0, -24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _GradientStatCard(
                      label: 'Cultes',
                      value: '${historique.length}',
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
                      value: '${retard?.nombreRetards ?? 0}',
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
                      label: 'Dette',
                      value: '${retard?.montantDu.toInt() ?? 0} F',
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

          // ── Historique Section ──────────────────────────────────
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
          if (historique.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Aucun historique disponible.',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            )
          else
            ...historique.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final date = item['date'] as DateTime?;
              final titre = item['titre'] as String?;
              final statut = item['statut'] as String?;
              final montant = item['montant'] as double?;
              final estPaye = statut == 'paye';

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
                            date != null
                                ? DateFormat('dd/MM/yyyy').format(date)
                                : titre ?? 'Culte inconnu',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            estPaye
                                ? 'Paiement effectué'
                                : (statut == 'absent'
                                    ? 'Membre absent'
                                    : 'En attente'),
                            style: TextStyle(
                              fontSize: 12,
                              color: estPaye
                                  ? AppColors.success
                                  : (statut == 'absent'
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
                            : (statut == 'absent'
                                ? colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.08)
                                : AppColors.danger.withValues(alpha: 0.12)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${montant?.toInt() ?? 0} F',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: estPaye
                              ? AppColors.success
                              : (statut == 'absent'
                                  ? colorScheme.onSurfaceVariant
                                  : AppColors.danger),
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  .animate(delay: (index * 30).ms)
                  .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                  .slideX(
                      begin: 0.05,
                      end: 0.0,
                      duration: 300.ms,
                      curve: Curves.easeOut);
            }),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
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
