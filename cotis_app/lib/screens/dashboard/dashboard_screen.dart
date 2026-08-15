import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kased_app/providers/notifications_provider.dart';
import 'package:kased_app/providers/app_data_provider.dart';
import 'package:kased_app/core/theme/app_theme.dart';
import 'package:kased_app/widgets/kased_card.dart';
import 'package:kased_app/widgets/kased_gradient_card.dart';
import 'package:kased_app/widgets/motion/motion_aware.dart';
import 'package:kased_app/widgets/motion/animated_appear.dart';
import 'package:kased_app/widgets/motion/skeleton_loading.dart';
import 'package:kased_app/core/theme/motion_tokens.dart';
import 'package:kased_app/core/services/stats_service.dart';
import 'package:kased_app/widgets/batch_payment_dialog.dart';
import 'package:kased_app/models/culte.dart';

// ── Widget principal ──────────────────────────────────────────────────────────

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  double _objectifMensuel = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(appDataProvider.notifier).loadDashboard();
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('kased_objectif_mensuel');
      if (raw != null) {
        final val = double.tryParse(raw);
        if (val != null) setState(() => _objectifMensuel = val);
      }
    });
  }

  void _showNotificationPanel(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.85,
              expand: false,
              builder: (_, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40, height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Notifications',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          TextButton(
                            onPressed: () => ref.read(notificationsProvider.notifier).marquerToutesLues(),
                            child: const Text('Tout marquer lu'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final notifState = ref.watch(notificationsProvider);
                            final notifs = notifState.liste;
                            if (notifs.isEmpty) {
                              return const Center(child: Text('Aucune notification'));
                            }
                            return ListView.separated(
                              controller: scrollController,
                              itemCount: notifs.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (_, i) {
                                final n = notifs[i];
                                return ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: n.isLue
                                          ? Colors.grey.withValues(alpha: 0.1)
                                          : AppColors.primary.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.notifications,
                                      size: 18,
                                      color: n.isLue ? Colors.grey : AppColors.primary,
                                    ),
                                  ),
                                  title: Text(
                                    n.titre,
                                    style: TextStyle(
                                      fontWeight: n.isLue ? FontWeight.normal : FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(n.message, style: const TextStyle(fontSize: 12)),
                                  trailing: Text(
                                    DateFormat('dd/MM').format(n.date),
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                  onTap: () {
                                    if (!n.isLue) {
                                      ref.read(notificationsProvider.notifier).marquerLue(notifs[i].id);
                                    }
                                  },
                                );
                              },
                            );
                        },
                      ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appDataAsync = ref.watch(appDataProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MotionAware(
      builder: (context, reduceMotion) {
        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.gradientStart, AppColors.gradientEnd],
              ).createShader(bounds),
              child: const Text(
                'Dashboard Kased',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
            ),
            actions: [
              Builder(
                builder: (context) {
                  final notifState = ref.watch(notificationsProvider);
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.notifications_outlined,
                          color: colorScheme.onSurface,
                        ),
                        onPressed: () => _showNotificationPanel(context, ref),
                      ),
                      if (notifState.nbNonLues > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              '${notifState.nbNonLues}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
          body: appDataAsync.when(
            data: (state) {
              final stats = ref.read(appDataProvider.notifier).getDashboardStats();
              final topRetards = ref.read(appDataProvider.notifier).getRetardsMembresLocally().take(3).toList();

              return Stack(
                children: [
                  // Gradient overlay for atmospheric depth
                  if (!reduceMotion) ...[
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.06),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Enhanced glowing blurred background blobs for premium glassmorphism
                    Positioned(
                      top: -80,
                      right: -120,
                      child: Container(
                        width: 380,
                        height: 380,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.08),
                        ),
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 280,
                      left: -140,
                      child: Container(
                        width: 420,
                        height: 420,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.gradientEnd.withValues(alpha: isDark ? 0.09 : 0.05),
                        ),
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 110, sigmaY: 110),
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                    ),
                  ],

                  RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async {
                      await ref.read(appDataProvider.notifier).syncData();
                      await ref.read(appDataProvider.notifier).loadDashboard();
                    },
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        // ── Carte Principale (Hero) ─────────────────────────
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          sliver: SliverToBoxAdapter(
                            child: AnimatedAppear(
                              reduceMotion: reduceMotion,
                              child: KasedGradientCard(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Ligne supérieure : Collecte + En avance
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'COLLECTE TOTALE',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 1.5,
                                                color: Colors.white.withValues(alpha: 0.7),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${stats.totalCollecte.toInt()} F',
                                              style: const TextStyle(
                                                fontSize: 36,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: -1.0,
                                                color: Colors.white,
                                                height: 1.1,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (stats.membresEnAvance > 0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.flash_on, size: 14, color: Colors.yellow),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'EN AVANCE',
                                                      style: const TextStyle(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.w700,
                                                        letterSpacing: 1.0,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${stats.membresEnAvance} · ${stats.montantEnAvance.toInt()} F',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    // Sous-stats : Membres | Cultes | Retards
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _HeaderStat(label: 'MEMBRES', value: '${stats.totalMembres}'),
                                        _HeaderStat(label: 'CULTES', value: '${stats.totalCultes}'),
                                        _HeaderStat(
                                          label: 'RETARDS',
                                          value: '${stats.membresEnRetard}',
                                          isAlert: stats.membresEnRetard > 0,
                                        ),
                                      ],
                                    ),
                                    // Prochain culte
                                    if (stats.prochainCulte != null) ...[
                                      const SizedBox(height: 16),
                                      const Divider(color: Colors.white24, height: 1),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(Icons.event, size: 18, color: Colors.white),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Prochain culte',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 1.0,
                                                    color: Colors.white.withValues(alpha: 0.6),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  stats.prochainCulte!.dateFormatee,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '${stats.prochainCulte!.montantCotisation.toStringAsFixed(0)} F',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.yellow,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // ── Progression mensuelle ────────────────────────────
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          sliver: SliverToBoxAdapter(
                            child: AnimatedAppear(
                              delay: MotionStagger.standard * 2,
                              reduceMotion: reduceMotion,
                              child: _ProgressSection(
                                stats: stats,
                                objectifMensuel: _objectifMensuel,
                                onSetObjectif: () => _showObjectifDialog(context, ref),
                              ),
                            ),
                          ),
                        ),

                        // ── Prochains cultes ─────────────────────────────────
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          sliver: SliverToBoxAdapter(
                            child: AnimatedAppear(
                              delay: MotionStagger.standard * 3,
                              reduceMotion: reduceMotion,
                              child: _CultesSection(
                                cultes: state.cultes,
                              ),
                            ),
                          ),
                        ),

                        // ── Membres en retard ────────────────────────────────
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          sliver: SliverToBoxAdapter(
                            child: AnimatedAppear(
                              delay: MotionStagger.standard * 4,
                              reduceMotion: reduceMotion,
                              child: _RetardsSection(
                                topRetards: topRetards,
                                totalRetards: stats.membresEnRetard,
                              ),
                            ),
                          ),
                        ),

                        // ── Actions principales ─────────────────────────────
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                          sliver: SliverToBoxAdapter(
                            child: AnimatedAppear(
                              delay: MotionStagger.standard * 5,
                              reduceMotion: reduceMotion,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Actions rapides',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (stats.membresEnRetard > 0)
                                    _ActionButton(
                                      icon: Icons.flash_on,
                                      label: 'Payer en avance',
                                      onTap: () => _showBatchPaymentDialog(context, ref, stats),
                                      isPrimary: stats.membresEnAvance == 0,
                                    ),
                                  if (stats.membresEnRetard > 0) const SizedBox(height: 10),
                                  _ActionButton(
                                    icon: Icons.church,
                                    label: 'Démarrer un culte',
                                    onTap: () => context.go('/cultes'),
                                    isPrimary: stats.membresEnRetard == 0,
                                  ),
                                  const SizedBox(height: 10),
                                  _ActionButton(
                                    icon: Icons.message_outlined,
                                    label: 'Rappeler les retards (${stats.membresEnRetard})',
                                    onTap: () => _rappelRetards(context, ref, topRetards),
                                  ),
                                  const SizedBox(height: 10),
                                  _ActionButton(
                                    icon: Icons.bar_chart,
                                    label: 'Statistiques',
                                    onTap: () => context.go('/stats'),
                                  ),
                                  const SizedBox(height: 10),
                                  _ActionButton(
                                    icon: Icons.people,
                                    label: 'Gérer les membres',
                                    onTap: () => context.go('/membres'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SliverToBoxAdapter(child: SizedBox(height: 32)),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const DashboardSkeleton(),
            error: (e, _) => Center(child: Text('Erreur: $e')),
          ),
        );
      },
    );
  }

  // ── Méthodes d'action ────────────────────────────────────────────────────────

  void _showObjectifDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(
      text: _objectifMensuel > 0 ? _objectifMensuel.toStringAsFixed(0) : '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Objectif mensuel'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Montant en FCFA',
            prefixIcon: Icon(Icons.flag),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(controller.text.trim());
              if (val != null && val > 0) {
                await StatsService.saveObjectifMensuel(val);
                if (mounted) setState(() => _objectifMensuel = val);
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _showBatchPaymentDialog(BuildContext context, WidgetRef ref, DashboardStats stats) async {
    final state = ref.read(appDataProvider).value;
    if (state == null) return;

    final futureCultes = state.cultes
        .where((c) => !c.isDeleted && c.dateCulte.isAfter(DateTime.now()))
        .take(10)
        .toList();
    if (futureCultes.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucun culte futur disponible'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }
    final montantDefault = futureCultes.first.montantCotisation;
    await BatchPaymentDialog.show(
      context,
      futureCultes: futureCultes,
      montantParCulte: montantDefault,
      onPay: (selectedCultes, totalAmount) async {
        final membres = state.membres
            .where((m) => m.isActive && !m.isDeleted)
            .toList();
        for (final membre in membres) {
          await ref
              .read(appDataProvider.notifier)
              .payerPlusieursCultesEnAvance(
                membreId: membre.id,
                culteIds: selectedCultes.map((c) => c.id).toList(),
                montantTotal: totalAmount,
              );
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ ${selectedCultes.length} culte(s) payé(s) en avance\n'
                'pour ${membres.length} membre(s)',
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
    );
  }

  Future<void> _rappelRetards(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> retards,
  ) async {
    if (retards.isEmpty) return;
    final membres = retards.map((r) => '${r['prenom']} ${r['nom']}').toList();
    final count = membres.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(
          Icons.notifications_active,
          size: 48,
          color: AppColors.primary,
        ),
        title: const Text('Rappeler les membres ?'),
        content: Text(
          'Une notification sera envoyée à $count membre(s) en retard.\n\n'
          '${membres.take(5).join(', ')}${count > 5 ? '…' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    for (final r in retards) {
      final label = '${r['prenom']} ${r['nom']}';
      final montant = (r['montant_du_fcfa'] as num).toInt();
      // Note: using local notification system instead of private push method
      await ref.read(notificationsProvider.notifier).ajouter(
        titre: 'Rappel de paiement',
        message: 'Membre $label a un retard de $montant F',
        typeEvenement: 'rappel_retard',
        entiteId: r['membre_id'],
      );
    }
    await ref.read(notificationsProvider.notifier).ajouter(
      titre: 'Rappel envoyé',
      message: '$count membre(s) en retard ont été notifiés',
      typeEvenement: 'rappel_retard',
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Rappel envoyé à $count membre(s)'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}


// ── Widgets helper ─────────────────────────────────────────────────────────────

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final bool isAlert;

  const _HeaderStat({
    required this.label,
    required this.value,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          transitionBuilder: (child, animation) => child,
          child: Text(
            value,
            key: ValueKey(value),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isAlert
                  ? Colors.orangeAccent
                  : Colors.white,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isPrimary) {
      return SizedBox(
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.gradientStart.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: KasedCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: colorScheme.onSurfaceVariant, size: 14),
          ],
        ),
      ),
    );
  }
}

// ── Widgets section ────────────────────────────────────────────────────────────

class _ProgressSection extends StatelessWidget {
  final DashboardStats stats;
  final double objectifMensuel;
  final VoidCallback onSetObjectif;

  const _ProgressSection({
    required this.stats,
    required this.objectifMensuel,
    required this.onSetObjectif,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalExpected = stats.totalCollecte + stats.totalDu;
    final percentage = totalExpected > 0
        ? (stats.totalCollecte / totalExpected * 100).clamp(0.0, 100.0)
        : 0.0;
    final objectifPct = objectifMensuel > 0
        ? (stats.totalCollecte / objectifMensuel * 100).clamp(0.0, 100.0)
        : null;
    final trend = stats.collecteMoisPrecedent > 0
        ? ((stats.totalCollecte - stats.collecteMoisPrecedent) /
                stats.collecteMoisPrecedent *
                100)
            .round()
        : null;

    return KasedCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progression du mois',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (objectifMensuel > 0)
                InkWell(
                  onTap: onSetObjectif,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flag, size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Modifier',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (objectifMensuel == 0)
                TextButton.icon(
                  onPressed: onSetObjectif,
                  icon: const Icon(Icons.flag, size: 14),
                  label: const Text('Définir objectif', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 10,
              backgroundColor: isDark
                  ? AppColors.surface2Dark
                  : AppColors.surface2,
              valueColor: AlwaysStoppedAnimation(
                AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Ligne de valeurs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${stats.totalCollecte.toInt()} F collecté',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
                  if (trend != null)
                    Text(
                      trend > 0
                          ? '▲ +$trend% vs mois dernier'
                          : trend < 0
                              ? '▼ $trend% vs mois dernier'
                              : '— stable',
                      style: TextStyle(
                        fontSize: 11,
                        color: trend > 0
                            ? AppColors.success
                            : trend < 0
                                ? AppColors.danger
                                : isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                        fontWeight: trend != 0 ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${totalExpected.toInt()} F attendu',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Objectif mensuel
          if (objectifMensuel > 0) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.emoji_events, size: 16, color: AppColors.warning),
                const SizedBox(width: 8),
                Text(
                  'Objectif : ${objectifMensuel.toInt()} F',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${objectifPct!.toStringAsFixed(0)}% atteint',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CultesSection extends StatelessWidget {
  final List<Culte> cultes;

  const _CultesSection({required this.cultes});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final future = cultes
        .where((c) => !c.isDeleted && c.dateCulte.isAfter(now))
        .take(3)
        .toList();
    if (future.isEmpty) return const SizedBox.shrink();

    return KasedCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Prochains cultes',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                TextButton(
                  onPressed: () => {},
                  child: const Text('Tout voir', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          ...future.map((c) => _CulteRow(culte: c, isDark: isDark)),
        ],
      ),
    );
  }
}

class _CulteRow extends StatelessWidget {
  final Culte culte;
  final bool isDark;

  const _CulteRow({required this.culte, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = culte.dateCulte.year == now.year &&
        culte.dateCulte.month == now.month &&
        culte.dateCulte.day == now.day;
    final isTomorrow = culte.dateCulte.difference(now).inDays == 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Date badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isToday
                  ? AppColors.success
                  : isTomorrow
                      ? AppColors.primary
                      : (isDark ? AppColors.surface2Dark : AppColors.background),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${culte.dateCulte.day}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isToday || isTomorrow
                        ? Colors.white
                        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                  ),
                ),
                Text(
                  culte.dateCulte.month.toString(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isToday || isTomorrow
                        ? Colors.white.withValues(alpha: 0.8)
                        : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Titre + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  culte.titre ?? 'Culte du ${culte.dateCulte.day}/${culte.dateCulte.month}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
                Text(
                  culte.dateFormatee,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          // Montant
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface2Dark : AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${culte.montantCotisation.toStringAsFixed(0)} F',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Badges
          if (isToday)
            const Chip(
              label: Text('Aujourd\'hui', style: TextStyle(fontSize: 10)),
              backgroundColor: AppColors.success,
              labelStyle: TextStyle(color: Colors.white, fontSize: 10),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            ),
          if (isTomorrow)
            const Chip(
              label: Text('Demain', style: TextStyle(fontSize: 10)),
              backgroundColor: AppColors.primary,
              labelStyle: TextStyle(color: Colors.white, fontSize: 10),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            ),
        ],
      ),
    );
  }
}

class _RetardsSection extends StatelessWidget {
  final List<Map<String, dynamic>> topRetards;
  final int totalRetards;

  const _RetardsSection({
    required this.topRetards,
    required this.totalRetards,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (topRetards.isEmpty && totalRetards == 0) return const SizedBox.shrink();

    return KasedCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Membres en retard',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (totalRetards > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$totalRetards',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (topRetards.isEmpty && totalRetards == 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text(
                'Aucun membre en retard — tout est à jour !',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                ),
              ),
            ),
          ...topRetards.map((r) => _RetardRow(
                membre: r,
                isDark: isDark,
              )),
          if (topRetards.isNotEmpty && totalRetards > topRetards.length)
            TextButton(
              onPressed: () {},
              child: Text(
                'Voir les ${totalRetards - topRetards.length} autre(s)',
                style: const TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _RetardRow extends StatelessWidget {
  final Map<String, dynamic> membre;
  final bool isDark;

  const _RetardRow({required this.membre, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final nom = '${membre['prenom']} ${membre['nom']}';
    final montant = (membre['montant_du_fcfa'] as num).toInt();
    final cultes = (membre['cultes_en_retard'] as num).toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                nom.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.warning,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Nom
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nom,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
                Text(
                  '$cultes culte(s) en retard',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          // Montant
          Text(
            '${montant} F',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}
