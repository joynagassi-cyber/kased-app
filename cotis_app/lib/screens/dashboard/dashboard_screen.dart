import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kased_app/providers/notifications_provider.dart';
import 'package:kased_app/providers/app_data_provider.dart';
import 'package:kased_app/core/theme/app_theme.dart';
import 'package:kased_app/widgets/kased_card.dart';
import 'package:kased_app/widgets/kased_gradient_card.dart';
import 'package:kased_app/widgets/motion/motion_aware.dart';
import 'package:kased_app/widgets/motion/animated_appear.dart';
import 'package:kased_app/widgets/motion/skeleton_loading.dart';
import 'package:kased_app/core/theme/motion_tokens.dart';

// ── Widget principal ──────────────────────────────────────────────────────────

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appDataProvider.notifier).loadDashboard();
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
                                      ref.read(notificationsProvider.notifier).marquerLue(i);
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

              return Stack(
                children: [
                  // Glowing blurred background blobs for premium glassmorphism
                  if (!reduceMotion) ...[
                    Positioned(
                      top: -60,
                      right: -100,
                      child: Container(
                        width: 320,
                        height: 320,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.04),
                        ),
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 240,
                      left: -120,
                      child: Container(
                        width: 360,
                        height: 360,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.gradientEnd.withValues(alpha: isDark ? 0.06 : 0.03),
                        ),
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'COLLECTE TOTALE',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.5,
                                        color: Colors.white.withValues(alpha: 0.8),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${stats.totalCollecte.toInt()} F',
                                      style: const TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -1.0,
                                        color: Colors.white,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 32),
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
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // ── Cartes stats ────────────────────────────────────
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          sliver: SliverToBoxAdapter(
                            child: AnimatedAppear(
                              delay: MotionStagger.standard * 2,
                              reduceMotion: reduceMotion,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _StatCard(
                                      icon: Icons.account_balance_wallet_outlined,
                                      label: 'Total dû',
                                      value: '${stats.totalDu.toInt()} F',
                                      isAlert: stats.totalDu > 0,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _StatCard(
                                      icon: Icons.trending_up_rounded,
                                      label: 'Taux collecte',
                                      value: (stats.totalCollecte + stats.totalDu) > 0
                                          ? '${(stats.totalCollecte / (stats.totalCollecte + stats.totalDu) * 100).toInt()}%'
                                          : '—',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // ── Actions principales ─────────────────────────────
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                          sliver: SliverToBoxAdapter(
                            child: AnimatedAppear(
                              delay: MotionStagger.standard * 3,
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
                                  _ActionButton(
                                    icon: Icons.church,
                                    label: 'Démarrer un culte',
                                    onTap: () => context.go('/cultes'),
                                    isPrimary: true,
                                  ),
                                  const SizedBox(height: 10),
                                  _ActionButton(
                                    icon: Icons.warning_amber,
                                    label:
                                        'Voir les retards (${stats.membresEnRetard})',
                                    onTap: () => context.go('/retards'),
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
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.5),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isAlert;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isAlert ? AppColors.warning : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isDark ? 0.08 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        accentColor.withValues(alpha: 0.12),
                        accentColor.withValues(alpha: 0.04),
                      ]
                    : [
                        accentColor.withValues(alpha: 0.06),
                        accentColor.withValues(alpha: 0.02),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : accentColor.withValues(alpha: 0.12),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 20, color: accentColor),
                ),
                const SizedBox(height: 16),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.5),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        )),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    value,
                    key: ValueKey(value),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: isAlert ? accentColor : colorScheme.onSurface,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
