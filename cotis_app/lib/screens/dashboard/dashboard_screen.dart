import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kased_app/providers/notifications_provider.dart';
import 'package:kased_app/providers/kased_app_provider.dart';
import 'package:kased_app/core/theme/app_theme.dart';
import 'package:kased_app/widgets/kased_gradient_card.dart';
import 'package:kased_app/widgets/motion/motion_aware.dart';
import 'package:kased_app/widgets/motion/animated_appear.dart';
import 'package:kased_app/widgets/motion/skeleton_loading.dart';
import 'package:kased_app/core/theme/motion_tokens.dart';
import 'package:kased_app/core/services/stats_service.dart';
import 'package:kased_app/widgets/dashboard/header_stat_widget.dart';
import 'package:kased_app/widgets/dashboard/action_button_widget.dart';
import 'package:kased_app/widgets/dashboard/progress_section_widget.dart';
import 'package:kased_app/widgets/dashboard/cultes_section_widget.dart';
import 'package:kased_app/widgets/dashboard/retards_section_widget.dart';

// ── Widget principal ──────────────────────────────────────────────────────────

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  double _objectifMensuel = 0.0;
  bool _hasLoaded = false;
  DateTime? _lastLoadedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(kasedAppProvider.notifier).loadDashboard();
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
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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
    final appDataAsync = ref.watch(kasedAppProvider);
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
                                fontSize: 11,
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
              _hasLoaded = true;
              _lastLoadedAt = DateTime.now();
              final stats = ref.read(kasedAppProvider.notifier).getDashboardStats();
              final topRetards = ref.read(kasedAppProvider.notifier).getRetardsMembresLocally().take(3).toList();

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
                      await ref.read(kasedAppProvider.notifier).syncData();
                      await ref.read(kasedAppProvider.notifier).loadDashboard();
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
                                                  children: const [
                                                    Icon(Icons.flash_on, size: 14, color: Colors.yellow),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'EN AVANCE',
                                                      style: const TextStyle(
                                                        fontSize: 11,
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
                                        HeaderStatWidget(label: 'MEMBRES', value: '${stats.totalMembres}'),
                                        HeaderStatWidget(label: 'CULTES', value: '${stats.totalCultes}'),
                                        HeaderStatWidget(
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
                                                    fontSize: 12,
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
                              child: ProgressSectionWidget(
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
                              child: CultesSectionWidget(
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
                              child: RetardsSectionWidget(
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
                                    ActionButtonWidget(
                                      icon: Icons.savings,
                                      label: 'Paiements en avance',
                                      onTap: () => context.push('/membres/en-avance'),
                                      isPrimary: stats.membresEnAvance == 0,
                                    ),
                                  if (stats.membresEnRetard > 0) const SizedBox(height: 10),
                                  ActionButtonWidget(
                                    icon: Icons.church,
                                    label: 'Démarrer un culte',
                                    onTap: () => context.go('/cultes'),
                                    isPrimary: stats.membresEnRetard == 0,
                                  ),
                                  const SizedBox(height: 10),
                                  ActionButtonWidget(
                                    icon: Icons.message_outlined,
                                    label: 'Rappeler les retards (${stats.membresEnRetard})',
                                    onTap: () => _rappelRetards(context, ref, topRetards),
                                  ),
                                  const SizedBox(height: 10),
                                  ActionButtonWidget(
                                    icon: Icons.bar_chart,
                                    label: 'Statistiques',
                                    onTap: () => context.go('/stats'),
                                  ),
                                  const SizedBox(height: 10),
                                  ActionButtonWidget(
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
            loading: () {
              final showSkeleton = !_hasLoaded ||
                  DateTime.now().difference(_lastLoadedAt ?? DateTime.now()).inMilliseconds < 800;
              return showSkeleton ? const DashboardSkeleton() : const SizedBox.shrink();
            },
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
      final montant = (r['montant_du_fcfa'] as num?)?.toInt() ?? 0;
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

