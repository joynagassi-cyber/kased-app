import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kased_app/core/theme/app_theme.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/providers/kased_app_provider.dart';
import 'package:kased_app/widgets/empty_state.dart';
import 'package:kased_app/widgets/kased_card.dart';
import 'package:kased_app/widgets/kased_status_badge.dart';
import 'package:kased_app/widgets/kased_gradient_card.dart';
import 'package:intl/intl.dart';
import 'package:kased_app/widgets/spring_button.dart';

class CultesScreen extends ConsumerStatefulWidget {
  const CultesScreen({super.key});

  @override
  ConsumerState<CultesScreen> createState() => _CultesScreenState();
}

// Enums pour le tri des cultes
enum CultesSortOption { dateAsc, dateDesc }

class _CultesScreenState extends ConsumerState<CultesScreen> {
  bool _isCreatingCulte = false;

  // Filter/sort state
  String _searchQuery = '';
  CultesSortOption _sortOption = CultesSortOption.dateDesc;
  bool _showFilters = false;

  @override
  Widget build(BuildContext context) {
    final appDataAsync = ref.watch(kasedAppProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Cultes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Synchroniser',
            onPressed: () => ref.read(kasedAppProvider.notifier).syncData(),
          ),
          // Bouton filtre
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_alt : Icons.filter_alt_outlined),
            tooltip: 'Filtres et tri',
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: appDataAsync.when(
        data: (state) {
          final membres = state.membres;
          // Appliquer le tri et filtrage
          var cultes = List<Culte>.from(state.cultes);

          // Filtre par recherche (sur la date)
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            cultes = cultes.where((c) {
              final dateStr = c.dateFormatee.toLowerCase();
              return dateStr.contains(q);
            }).toList();
          }

          // Tri
          switch (_sortOption) {
            case CultesSortOption.dateAsc:
              cultes.sort((a, b) => a.dateCulte.compareTo(b.dateCulte));
              break;
            case CultesSortOption.dateDesc:
              cultes.sort((a, b) => b.dateCulte.compareTo(a.dateCulte));
              break;
          }

          // Barre de filtres
          final filterBar = AnimatedSlide(
            offset: Offset(0, _showFilters ? 0 : -1),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _showFilters ? 1.0 : 0,
              child: _buildFilterBar(theme),
            ),
          );

          if (cultes.isEmpty) {
            return Column(children: [
              filterBar,
              Expanded(
                child: cultes.isEmpty && state.cultes.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off,
                                size: 64, color: colorScheme.outline),
                            const SizedBox(height: 16),
                            Text('Aucun culte trouvé',
                                style: theme.textTheme.titleSmall),
                            const SizedBox(height: 8),
                            Text('Essayez de modifier vos filtres',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary)),
                            const SizedBox(height: 24),
                            FilledButton.tonal(
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _sortOption = CultesSortOption.dateDesc;
                                });
                              },
                              child: const Text('Reinitialiser'),
                            ),
                          ],
                        ),
                      )
                    : const EmptyState(
                        icon: Icons.event_note,
                        titre: 'Aucun culte enregistré',
                        sousTitre: 'Démarrer un culte pour commencer le suivi.',
                      ),
              ),
            ]);
          }

          final totalCultes = cultes.length;
          final totalGlobalCollecte = state.cotisations
              .where((c) => c.estPaye)
              .fold(0.0, (sum, c) => sum + c.montantPaye);

          return Column(
            children: [
              filterBar,
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      sliver: SliverToBoxAdapter(
                        child: KasedGradientCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL HISTORIQUE',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                  color: Colors.white,
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
                                  Icon(Icons.church, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$totalCultes culte${totalCultes > 1 ? 's' : ''} organise${totalCultes > 1 ? 's' : ''}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
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

                            final payeursCount =
                                cotisations.where((c) => c.estPaye).length;
                            final culteMemberIds = culte.memberIds;
                            final totalMembres = culteMemberIds.isNotEmpty
                                ? membres
                                    .where((m) =>
                                        culteMemberIds.contains(m.id))
                                    .length
                                : membres.length;
                            final percentage =
                                totalMembres > 0
                                    ? payeursCount / totalMembres
                                    : 0.0;
                            final totalCollecte = cotisations
                                .where((c) => c.estPaye)
                                .fold(0.0, (sum, c) => sum + c.montantPaye);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Hero(
                                tag: 'culte_${culte.id}',
                                child: KasedCard(
                                  padding: EdgeInsets.zero,
                                  onTap: () =>
                                      context.push('/cultes/${culte.id}'),
                                  child: Material(
                                    type: MaterialType.transparency,
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 48,
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  color: colorScheme
                                                      .primaryContainer,
                                                  shape:
                                                      BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Icon(
                                                    Icons.event,
                                                    color: colorScheme
                                                        .primary,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                  children: [
                                                    Text(
                                                      culte.dateFormatee,
                                                      style: theme
                                                          .textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w800,
                                                            color:
                                                                colorScheme
                                                                    .onSurface,
                                                          ),
                                                    ),
                                                    const SizedBox(
                                                        height: 4),
                                                    Text(
                                                      '${totalCollecte.toInt()} FCFA',
                                                      style: theme
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w700,
                                                            color:
                                                                colorScheme
                                                                    .primary,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuButton<String>(
                                                icon: Icon(
                                                  Icons.more_vert,
                                                  color:
                                                      colorScheme
                                                          .onSurfaceVariant,
                                                ),
                                                onSelected: (value) {
                                                  if (value == 'edit') {
                                                    _showEditCulteDialog(
                                                        context, ref, culte);
                                                  } else if (value ==
                                                      'delete') {
                                                    _confirmDeleteCulte(
                                                        context, ref, culte);
                                                  }
                                                },
                                                itemBuilder: (_) {
                                                  final isOlderThan30 =
                                                      DateTime.now()
                                                          .difference(
                                                              culte.dateCulte)
                                                          .inDays >
                                                      30;
                                                  return [
                                                    if (!isOlderThan30)
                                                      const PopupMenuItem(
                                                        value: 'edit',
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons
                                                                .edit_outlined,
                                                                size: 18),
                                                            SizedBox(
                                                                width: 8),
                                                            Text('Modifier'),
                                                          ],
                                                        ),
                                                      )
                                                    else
                                                      const PopupMenuItem(
                                                        enabled: false,
                                                        value:
                                                            'edit_locked',
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons
                                                                .lock_outline,
                                                                size: 18,
                                                                color:
                                                                    Colors
                                                                        .grey),
                                                            SizedBox(
                                                                width: 8),
                                                            Text(
                                                                'Verrouillé (>30j)',
                                                                style: TextStyle(
                                                                    color:
                                                                        Colors
                                                                            .grey)),
                                                          ],
                                                        ),
                                                      ),
                                                    if (!isOlderThan30)
                                                      const PopupMenuItem(
                                                        value: 'delete',
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons
                                                                .delete_outline,
                                                                size: 18,
                                                                color: AppColors
                                                                    .danger),
                                                            SizedBox(
                                                                width: 8),
                                                            Text(
                                                                'Supprimer',
                                                                style: TextStyle(
                                                                    color: AppColors
                                                                        .danger)),
                                                          ],
                                                        ),
                                                      )
                                                    else
                                                      const PopupMenuItem(
                                                        enabled: false,
                                                        value:
                                                            'delete_locked',
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons
                                                                .lock_outline,
                                                                size: 18,
                                                                color:
                                                                    Colors
                                                                        .grey),
                                                            SizedBox(
                                                                width: 8),
                                                            Text(
                                                                'Verrouillé (>30j)',
                                                                style: TextStyle(
                                                                    color:
                                                                        Colors
                                                                            .grey)),
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
                                            mainAxisAlignment:
                                                MainAxisAlignment
                                                    .spaceBetween,
                                            children: [
                                              Text(
                                                '$payeursCount / $totalMembres payes',
                                                style: theme.textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color:
                                                          colorScheme
                                                              .onSurfaceVariant,
                                                    ),
                                              ),
                                              if (percentage == 1.0)
                                                KasedStatusBadge.success(
                                                    'Complet')
                                              else
                                                KasedStatusBadge.info(
                                                    '${(percentage * 100).toInt()}%'),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: LinearProgressIndicator(
                                              value: percentage,
                                              backgroundColor:
                                                  colorScheme
                                                      .surfaceContainerHighest,
                                              valueColor:
                                                  AlwaysStoppedAnimation<
                                                      Color>(
                                                percentage == 1.0
                                                    ? AppColors
                                                        .gradientEnd
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
                    const SliverPadding(
                        padding: EdgeInsets.only(bottom: 24)),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Impossible de supprimer le culte. Verifiez votre connexion.')),
      ),
      floatingActionButton: SpringButton(
        onTap: () => _showAddCulteDialog(context, ref),
        child: FloatingActionButton(
          onPressed: () {},
          tooltip: 'Nouveau culte',
          child: const Icon(Icons.add_task),
        ),
      ),
    );
  }

  // -- Barre de filtres et tri --
  Widget _buildFilterBar(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher par date...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () =>
                          setState(() => _searchQuery = ''),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: theme.colorScheme.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: theme.colorScheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: theme.colorScheme.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.sort,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: SegmentedButton<CultesSortOption>(
                  segments: CultesSortOption.values
                      .map((opt) => ButtonSegment<CultesSortOption>(
                            value: opt,
                            label: Text(opt.label),
                          ))
                      .toList(),
                  selected: {_sortOption},
                  onSelectionChanged: (s) =>
                      setState(() => _sortOption = s.first),
                ),
              ),
            ],
          ),
          // Indicateur nombre de resultats
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Affiche ${_getFilteredCultes(
                  ref.read(kasedAppProvider).value?.cultes ?? []).length}'
                  ' sur ${ref.read(kasedAppProvider).value?.cultes.length ?? 0} cultes',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary),
            ),
          ),
        ],
      ),
    );
  }

  // -- Filtre / Tri --
  List<Culte> _getFilteredCultes(List<Culte> cultes) {
    var result = List<Culte>.from(cultes);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((c) {
        final dateStr = c.dateFormatee.toLowerCase();
        return dateStr.contains(q);
      }).toList();
    }

    switch (_sortOption) {
      case CultesSortOption.dateAsc:
        result.sort((a, b) => a.dateCulte.compareTo(b.dateCulte));
        break;
      case CultesSortOption.dateDesc:
        result.sort((a, b) => b.dateCulte.compareTo(a.dateCulte));
        break;
    }

    return result;
  }

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
                        final montant = int.tryParse((value ?? '').trim()) ?? 0;
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
                  onPressed: _isCreatingCulte ? null : () async {
                    if (!formKey.currentState!.validate()) return;
                    setState(() => _isCreatingCulte = true);
                    try {
                      await ref.read(kasedAppProvider.notifier).addCulte(
                            date: selectedDate,
                            titre: null,
                            montant: double.tryParse(montantController.text.trim()) ?? 50.0,
                          );
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Gloire à Dieu ! Culte créé avec succès'),
                              backgroundColor: Color(0xFF059669),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                      if (context.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text('Impossible de supprimer le culte. Vérifiez votre connexion.')),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isCreatingCulte = false);
                    }
                  },
                  child: _isCreatingCulte
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Créer'),
                ),
              ],
            );
          },
        );
      },
    );
    montantController.dispose();
  }

  void _showEditCulteDialog(BuildContext context, WidgetRef ref, Culte culte) async {
    final theme = Theme.of(context);
    final formKey = GlobalKey<FormState>();
    final montantController = TextEditingController(text: culte.montantCotisation.toInt().toString());
    DateTime selectedDate = culte.dateCulte;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            
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
                      onDateChanged: (d) => setLocalState(() => selectedDate = d),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: montantController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Montant de cotisation (FCFA)'),
                      validator: (value) {
                        final montant = int.tryParse((value ?? '').trim()) ?? 0;
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
                    // setLocalState(() => isSaving = true); // Dead code - commented to fix CI
                    if (!formKey.currentState!.validate()) return;
                    setLocalState(() => isSaving = true);
                    try {
                      await ref.read(kasedAppProvider.notifier).updateCulte(
                            id: culte.id,
                            dateCulte: selectedDate,
                            montantCotisation: double.tryParse(montantController.text.trim()) ?? culte.montantCotisation,
                          );
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                    } catch (e) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text('Impossible de supprimer le culte. Vérifiez votre connexion.')),
                        );
                      }
                    } finally {
                      if (dialogContext.mounted) setLocalState(() => isSaving = false);
                    }
                  },
                  child: isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
    montantController.dispose();
  }

  void _confirmDeleteCulte(BuildContext context, WidgetRef ref, Culte culte) async {
    bool isDeleting = false;

    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setLocalState) {
          return AlertDialog(
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
                style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                onPressed: isDeleting
                    ? null
                    : () async {
                        setLocalState(() => isDeleting = true);
                        try {
                          await ref.read(kasedAppProvider.notifier).deleteCulte(culte.id);
                          if (ctx.mounted) Navigator.pop(dialogContext, true);
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Impossible de supprimer le culte. Vérifiez votre connexion.')),
                            );
                          }
                        } finally {
                          if (ctx.mounted) setLocalState(() => isDeleting = false);
                        }
                      },
                child: isDeleting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Supprimer'),
              ),
            ],
          );
        },
      ),
    );
  }
}

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
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          DateFormat('dd MMMM yyyy', 'fr_FR').format(selectedDate),
          style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
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
// Extension pour le label du tri
extension _CultesSortOptionLabel on CultesSortOption {
  String get label {
    switch (this) {
      case CultesSortOption.dateAsc:
        return 'Date ancien';
      case CultesSortOption.dateDesc:
        return 'Date recent';
    }
  }
}

