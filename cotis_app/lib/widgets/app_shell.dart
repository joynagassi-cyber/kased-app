import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kased_app/core/theme/app_theme.dart';
import 'package:kased_app/widgets/app_drawer.dart';
import 'package:kased_app/widgets/spring_nav_icon.dart';
import 'package:kased_app/providers/app_data_provider.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/membres')) return 1;
    if (location.startsWith('/cultes')) return 2;
    if (location.startsWith('/stats')) return 3;
    if (location.startsWith('/retards')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final location = GoRouterState.of(context).uri.toString();
    final isOnDashboard = location.startsWith('/dashboard');

    // On dashboard: AppBar se fond dans l'arc bleu
    final appBarBg = isOnDashboard ? AppColors.primary : colorScheme.surface;
    final appBarFg = isOnDashboard ? Colors.white : colorScheme.onSurface;
    final menuIconColor = isOnDashboard ? Colors.white : colorScheme.onSurface;

    final currentIndex = _currentIndex(context);

    // Watch AppData state to get active delay counts
    final appStateAsync = ref.watch(appDataProvider);
    final stats = appStateAsync.maybeWhen(
      data: (state) => ref.read(appDataProvider.notifier).getDashboardStats(),
      orElse: () => null,
    );
    final retardsCount = stats?.membresEnRetard ?? 0;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: appBarBg,
        foregroundColor: appBarFg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu_rounded,
              color: menuIconColor,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Menu',
          ),
        ),
      ),
      body: child,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                // Premium double shadow system for high visual depth (floating sensation)
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.45)
                      : colorScheme.shadow.withValues(alpha: 0.12),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: isDark
                      ? colorScheme.primary.withValues(alpha: 0.12)
                      : colorScheme.primary.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.surface.withValues(alpha: 0.72)
                        : colorScheme.surface.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : colorScheme.primary.withValues(alpha: 0.14),
                      width: 1.5,
                    ),
                  ),
                  child: TweenAnimationBuilder<Color?>(
                    tween: ColorTween(
                      end: isDark
                          ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                          : colorScheme.primaryContainer.withValues(alpha: 0.5),
                    ),
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                    builder: (context, animatedIndicatorColor, _) {
                      return NavigationBar(
                        backgroundColor: Colors.transparent,
                        surfaceTintColor: Colors.transparent,
                        indicatorColor: animatedIndicatorColor,
                    selectedIndex: currentIndex,
                    onDestinationSelected: (i) {
                      switch (i) {
                        case 0:
                          context.go('/dashboard');
                          break;
                        case 1:
                          context.go('/membres');
                          break;
                        case 2:
                          context.go('/cultes');
                          break;
                        case 3:
                          context.go('/stats');
                          break;
                        case 4:
                          context.go('/retards');
                          break;
                      }
                    },
                    destinations: [
                      NavigationDestination(
                        icon: SpringNavIcon(
                          icon: Icons.home_outlined,
                          selectedIcon: Icons.home,
                          isSelected: currentIndex == 0,
                          label: 'Accueil',
                          selectedColor: colorScheme.primary,
                          unselectedColor: colorScheme.onSurfaceVariant,
                        ),
                        selectedIcon: SpringNavIcon(
                          icon: Icons.home,
                          selectedIcon: Icons.home,
                          isSelected: currentIndex == 0,
                          label: 'Accueil',
                          selectedColor: colorScheme.primary,
                          unselectedColor: colorScheme.onSurfaceVariant,
                        ),
                        label: 'Accueil',
                      ),
                      NavigationDestination(
                        icon: SpringNavIcon(
                          icon: Icons.people_outline,
                          selectedIcon: Icons.people,
                          isSelected: currentIndex == 1,
                          label: 'Membres',
                          selectedColor: colorScheme.primary,
                          unselectedColor: colorScheme.onSurfaceVariant,
                        ),
                        selectedIcon: SpringNavIcon(
                          icon: Icons.people,
                          selectedIcon: Icons.people,
                          isSelected: currentIndex == 1,
                          label: 'Membres',
                          selectedColor: colorScheme.primary,
                          unselectedColor: colorScheme.onSurfaceVariant,
                        ),
                        label: 'Membres',
                      ),
                      NavigationDestination(
                        icon: SpringNavIcon(
                          icon: Icons.church_outlined,
                          selectedIcon: Icons.church,
                          isSelected: currentIndex == 2,
                          label: 'Cultes',
                          selectedColor: colorScheme.primary,
                          unselectedColor: colorScheme.onSurfaceVariant,
                        ),
                        selectedIcon: SpringNavIcon(
                          icon: Icons.church,
                          selectedIcon: Icons.church,
                          isSelected: currentIndex == 2,
                          label: 'Cultes',
                          selectedColor: colorScheme.primary,
                          unselectedColor: colorScheme.onSurfaceVariant,
                        ),
                        label: 'Cultes',
                      ),
                      NavigationDestination(
                        icon: SpringNavIcon(
                          icon: Icons.bar_chart_outlined,
                          selectedIcon: Icons.bar_chart,
                          isSelected: currentIndex == 3,
                          label: 'Stats',
                          selectedColor: colorScheme.primary,
                          unselectedColor: colorScheme.onSurfaceVariant,
                        ),
                        selectedIcon: SpringNavIcon(
                          icon: Icons.bar_chart,
                          selectedIcon: Icons.bar_chart,
                          isSelected: currentIndex == 3,
                          label: 'Stats',
                          selectedColor: colorScheme.primary,
                          unselectedColor: colorScheme.onSurfaceVariant,
                        ),
                        label: 'Stats',
                      ),
                      NavigationDestination(
                        icon: Builder(
                          builder: (context) {
                            final springIcon = SpringNavIcon(
                              icon: Icons.warning_amber_outlined,
                              selectedIcon: Icons.warning_amber,
                              isSelected: currentIndex == 4,
                              label: 'Retards',
                              selectedColor: colorScheme.error,
                              unselectedColor: colorScheme.onSurfaceVariant,
                            );

                            if (retardsCount > 0) {
                              return Badge(
                                label: Text('$retardsCount'),
                                backgroundColor: colorScheme.error,
                                child: springIcon,
                              )
                                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                                  .scale(
                                    duration: const Duration(milliseconds: 900),
                                    begin: const Offset(1.0, 1.0),
                                    end: const Offset(1.08, 1.08),
                                    curve: Curves.easeInOut,
                                  );
                            }
                            return springIcon;
                          },
                        ),
                        selectedIcon: Builder(
                          builder: (context) {
                            final springIcon = SpringNavIcon(
                              icon: Icons.warning_amber,
                              selectedIcon: Icons.warning_amber,
                              isSelected: currentIndex == 4,
                              label: 'Retards',
                              selectedColor: colorScheme.error,
                              unselectedColor: colorScheme.onSurfaceVariant,
                            );

                            if (retardsCount > 0) {
                              return Badge(
                                label: Text('$retardsCount'),
                                backgroundColor: colorScheme.error,
                                child: springIcon,
                              )
                                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                                  .scale(
                                    duration: const Duration(milliseconds: 900),
                                    begin: const Offset(1.0, 1.0),
                                    end: const Offset(1.08, 1.08),
                                    curve: Curves.easeInOut,
                                  );
                            }
                            return springIcon;
                          },
                        ),
                        label: 'Retards',
                      ),
                    ],
                  );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
