import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kased_app/providers/auth_provider.dart';
import 'package:kased_app/providers/theme_provider.dart';
import 'package:kased_app/core/theme/app_theme.dart';
import 'package:kased_app/widgets/user_avatar.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    final colorScheme = Theme.of(context).colorScheme;
    final location = GoRouterState.of(context).uri.toString();

    Widget navItem({
      required IconData icon,
      required IconData selectedIcon,
      required String label,
      required String route,
    }) {
      final isSelected = location.startsWith(route);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Material(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Navigator.pop(context);
              if (route == '/corbeille' || route == '/profile') {
                context.push(route);
              } else {
                context.go(route);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    isSelected ? selectedIcon : icon,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    size: 22,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Drawer(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      child: Column(
        children: [
          // Header avec gradient bleu
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primaryMid,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5), width: 2),
                  ),
                  child: UserAvatar(
                    email: authState.userEmail ?? '',
                    radius: 30,
                  ),
                ),
                const SizedBox(height: 12),
                // Email
                Text(
                  authState.userEmail ?? 'Utilisateur',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Administrateur',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8),
              children: [
                navItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: 'Tableau de bord',
                  route: '/dashboard',
                ),
                navItem(
                  icon: Icons.people_outline,
                  selectedIcon: Icons.people,
                  label: 'Membres',
                  route: '/membres',
                ),
                navItem(
                  icon: Icons.church_outlined,
                  selectedIcon: Icons.church,
                  label: 'Cultes',
                  route: '/cultes',
                ),
                navItem(
                  icon: Icons.bar_chart_outlined,
                  selectedIcon: Icons.bar_chart,
                  label: 'Statistiques',
                  route: '/stats',
                ),
                navItem(
                  icon: Icons.warning_amber_outlined,
                  selectedIcon: Icons.warning_amber,
                  label: 'Retards',
                  route: '/retards',
                ),
                navItem(
                  icon: Icons.delete_outline,
                  selectedIcon: Icons.delete,
                  label: 'Corbeille',
                  route: '/corbeille',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Divider(),
                ),
                navItem(
                  icon: Icons.person_outline,
                  selectedIcon: Icons.person,
                  label: 'Mon profil',
                  route: '/profile',
                ),
              ],
            ),
          ),

          // Footer — dark mode toggle + logout
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
            child: Column(
              children: [
                const Divider(),
                const SizedBox(height: 4),
                // Dark / Light mode toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(
                        isDark ? Icons.dark_mode : Icons.light_mode,
                        color: colorScheme.onSurfaceVariant,
                        size: 22,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          isDark ? 'Mode sombre' : 'Mode clair',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Switch(
                        value: isDark,
                        activeThumbColor: colorScheme.primary,
                        onChanged: (val) {
                          ref.read(themeModeProvider.notifier).setThemeMode(
                              val ? ThemeMode.dark : ThemeMode.light);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Déconnexion
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
                        Navigator.pop(context);
                        await ref.read(authProvider.notifier).logout();
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Icon(Icons.logout,
                                color: AppColors.danger, size: 22),
                            SizedBox(width: 16),
                            Text(
                              'Se déconnecter',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
