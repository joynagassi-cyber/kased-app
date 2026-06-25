import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kased_app/core/theme/app_theme.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/providers/app_data_provider.dart';
import 'package:kased_app/widgets/empty_state.dart';
import 'package:kased_app/widgets/kased_card.dart';
import 'package:kased_app/widgets/kased_status_badge.dart';
import 'package:kased_app/widgets/kased_gradient_card.dart';
import 'package:intl/intl.dart';
import 'package:kased_app/widgets/spring_button.dart';

class CultesScreen extends ConsumerWidget {
  const CultesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appDataAsync = ref.watch(appDataProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Cultes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Synchroniser',
            onPressed: () => ref.read(appDataProvider.notifier).syncData(),
          ),
        ],
      ),
      body: appDataAsync.when(
        data: (state) {
          final cultes = state.cultes;
          final membres = state.membres;

          if (cultes.isEmpty) {
            return const EmptyState(
              icon: Icons.event_note,
              titre: 'Aucun culte enregistré',
              sousTitre: 'Démarrer un culte pour commencer le suivi.',
            );
          }

          final totalCultes = cultes.length;
           final totalGlobalCollecte = state.cotisations
               .where((c) => c.estPaye)
               .fold(0.0, (sum, c) => sum + c.montantPaye);

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                sliver: SliverToBoxAdapter(
                  child: KasedGradientCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL HISTORIQUE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${totalGlobalCollecte.toInt()} FCFA',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Icon(Icons.church, color: Colors.white.withValues(alpha: 0.9), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '$totalCultes cultes organisés',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final culte = cultes[index];
                      final cotisations = state.cotisations
                          .where((c) => c.culteId == culte.id)
                          .toList();

                      final payeursCount = cotisations.where((c) => c.estPaye).length;
                      final totalMembres = membres.length;
                      final percentage =
                          totalMembres > 0 ? payeursCount / totalMembres : 0.0;
                       final totalCollecte = cotisations
                           .where((c) => c.estPaye)
                           .fold(0.0, (sum, c) => sum + c.montantPaye);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Hero(
                          tag: 'culte_${culte.id}',
                          child: KasedCard(
                            padding: EdgeInsets.zero,
                            onTap: () => context.push('/cultes/${culte.id}'),
                            child: Material(
                              type: MaterialType.transparency,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: colorScheme.primaryContainer,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.event,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                culte.dateFormatee,
                                                style: theme.textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color: colorScheme.onSurface,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${totalCollecte.toInt()} FCFA',
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: colorScheme.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          icon: Icon(
                                            Icons.more_vert,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          onSelected: (value) {
                                            if (value == 'edit') {
                                              _showEditCulteDialog(context, ref, culte);
                                            } else if (value == 'delete') {
                                              _confirmDeleteCulte(context, ref, culte);
                                            }
                                          },
                                          itemBuilder: (_) {
                                            final isOlderThan30 = DateTime.now().difference(culte.dateCulte).inDays > 30;
                                            return [
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit_outlined, size: 18),
                                                    SizedBox(width: 8),
                                                    Text('Modifier'),
                                                  ],
                                                ),
                                              ),
                                              if (!isOlderThan30)
                                                const PopupMenuItem(
                                                  value: 'delete',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.delete_outline,
                                                          size: 18, color: AppColors.danger),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        'Supprimer',
                                                        style: TextStyle(color: AppColors.danger),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              else
                                                const PopupMenuItem(
                                                  enabled: false,
                                                  value: 'delete_locked',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.lock_outline,
                                                          size: 18, color: Colors.grey),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        'Verrouillé (>30j)',
                                                        style: TextStyle(color: Colors.grey),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ];
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '$payeursCount / $totalMembres payés',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        if (percentage == 1.0)
                                          KasedStatusBadge.success('Complet')
                                        else
                                          KasedStatusBadge.info('${(percentage * 100).toInt()}%'),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: percentage,
                                        backgroundColor: colorScheme.surfaceContainerHighest,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          percentage == 1.0
                                              ? AppColors.gradientEnd
                                              : colorScheme.primary,
                                        ),
                                        minHeight: 8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: cultes.length,
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
      floatingActionButton: SpringButton(
        onTap: () => _showAddCulteDialog(context, ref),
        child: FloatingActionButton(
          onPressed: () {}, // Géré par SpringButton
          tooltip: 'Nouveau culte',
          child: const Icon(Icons.add_task),
        ),
      ),
    );
  }

  // ────────────────────── Dialogs ──────────────────────

  void _showAddCulteDialog(BuildContext context, WidgetRef ref) async {
    final theme = Theme.of(context);
    final formKey = GlobalKey<FormState>();
    final montantController = TextEditingController(text: '50');
    DateTime selectedDate = DateTime.now();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Nouveau culte'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DatePickerTile(
                      theme: theme,
                      selectedDate: selectedDate,
                      dialogContext: dialogContext,
                      onDateChanged: (d) => setState(() => selectedDate = d),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: montantController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Montant de cotisation (FCFA)',
                        hintText: '50',
                      ),
                      validator: (value) {
                        final montant =
                            int.tryParse((value ?? '').trim()) ?? 0;
                        if (montant <= 0) return 'Montant invalide';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    try {
                      await ref.read(appDataProvider.notifier).addCulte(
                            date: selectedDate,
                            titre: null,
                            montant: double.tryParse(
                                    montantController.text.trim()) ??
                                50.0,
                          );
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    } catch (e) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text('Erreur: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Créer'),
                ),
              ],
            );
          },
        );
      },
    );
    montantController.dispose();
  }

  void _showEditCulteDialog(
      BuildContext context, WidgetRef ref, Culte culte) async {
    final theme = Theme.of(context);
    final formKey = GlobalKey<FormState>();
    final montantController =
        TextEditingController(text: culte.montantCotisation.toInt().toString());
    DateTime selectedDate = culte.dateCulte;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Modifier le culte'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DatePickerTile(
                      theme: theme,
                      selectedDate: selectedDate,
                      dialogContext: dialogContext,
                      onDateChanged: (d) => setState(() => selectedDate = d),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: montantController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Montant de cotisation (FCFA)',
                      ),
                      validator: (value) {
                        final montant =
                            int.tryParse((value ?? '').trim()) ?? 0;
                        if (montant <= 0) return 'Montant invalide';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    try {
                      await ref.read(appDataProvider.notifier).updateCulte(
                            id: culte.id,
                            dateCulte: selectedDate,
                            montantCotisation:
                                double.tryParse(montantController.text.trim()) ??
                                    culte.montantCotisation,
                          );
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    } catch (e) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text('Erreur: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
    montantController.dispose();
  }

  void _confirmDeleteCulte(
      BuildContext context, WidgetRef ref, Culte culte) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer ce culte ?'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le culte du ${culte.dateFormatee} ? '
          'Toutes les cotisations associées seront également supprimées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(appDataProvider.notifier).deleteCulte(culte.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Culte supprimé'),
            backgroundColor: AppColors.gradientEnd,
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

// ────────────────────── Helpers ──────────────────────

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.theme,
    required this.selectedDate,
    required this.dialogContext,
    required this.onDateChanged,
  });

  final ThemeData theme;
  final DateTime selectedDate;
  final BuildContext dialogContext;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline),
      ),
      child: ListTile(
        title: Text(
          'Date du culte',
          style:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          DateFormat('dd MMMM yyyy', 'fr_FR').format(selectedDate),
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        trailing: const Icon(Icons.calendar_today),
        onTap: () async {
          final pickedDate = await showDatePicker(
            context: dialogContext,
            initialDate: selectedDate,
            firstDate: DateTime(2000),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (pickedDate != null) onDateChanged(pickedDate);
        },
      ),
    );
  }
}
