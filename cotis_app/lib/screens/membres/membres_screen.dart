import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/providers/kased_app_provider.dart';
import 'package:kased_app/core/theme/app_theme.dart';
import 'package:kased_app/widgets/empty_state.dart';
import 'package:kased_app/widgets/kased_avatar.dart';
import 'package:kased_app/widgets/kased_card.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kased_app/widgets/spring_button.dart';
import 'package:kased_app/widgets/motion/skeleton_loading.dart';

// Enums pour le filtrage et le tri des membres
enum MembresSortOption { nameAsc, nameDesc, dateAsc, dateDesc }
enum MembresFilterOption { all, active, inactive }

class MembresScreen extends ConsumerStatefulWidget {
  const MembresScreen({super.key});

  @override
  ConsumerState<MembresScreen> createState() => _MembresScreenState();
}

class _MembresScreenState extends ConsumerState<MembresScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> retards = [];

  // Filter/sort state
  String _searchQuery = '';
  MembresSortOption _sortOption = MembresSortOption.nameAsc;
  MembresFilterOption _filterOption = MembresFilterOption.all;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadRetards();
  }

  Future<void> _loadRetards() async {
    try {
      final data =
          await ref.read(kasedAppProvider.notifier).loadRetardsMembres();
      setState(() {
        retards = data;
      });
    } catch (e) {
      debugPrint('Erreur chargement retards: $e');
    }
  }

  // -- Filtre / Tri --
  List<Membre> _getFilteredMembres(List<Membre> membres) {
    var result = membres;

    // Filtre par statut
    if (_filterOption == MembresFilterOption.active) {
      result = result.where((m) => m.isActive).toList();
    } else if (_filterOption == MembresFilterOption.inactive) {
      result = result.where((m) => !m.isActive).toList();
    }

    // Filtre par recherche
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((m) =>
              m.nomComplet.toLowerCase().contains(q) ||
              m.nom.toLowerCase().contains(q) ||
              m.prenom.toLowerCase().contains(q))
          .toList();
    }

    // Tri
    switch (_sortOption) {
      case MembresSortOption.nameAsc:
        result.sort((a, b) => a.nomComplet.compareTo(b.nomComplet));
        break;
      case MembresSortOption.nameDesc:
        result.sort((a, b) => b.nomComplet.compareTo(a.nomComplet));
        break;
      case MembresSortOption.dateAsc:
        result.sort((a, b) => a.dateAdhesion.compareTo(b.dateAdhesion));
        break;
      case MembresSortOption.dateDesc:
        result.sort((a, b) => b.dateAdhesion.compareTo(a.dateAdhesion));
        break;
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final appDataAsync = ref.watch(kasedAppProvider);
    final theme = Theme.of(context);
    final retardsById = {for (final r in retards) r['membre_id']: r};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Membres'),
        actions: [
          // Bouton Membres en avance
          IconButton(
            icon: const Icon(Icons.savings),
            tooltip: 'Membres en avance',
            onPressed: () => context.push('/membres/en-avance'),
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              await ref.read(kasedAppProvider.notifier).syncData();
              await _loadRetards();
            },
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
          final filtered = _getFilteredMembres(membres);

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

          if (membres.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline,
              titre: 'Aucun membre enregistré',
              sousTitre: 'Appuyez sur le bouton + pour ajouter un membre.',
            );
          }

          return Column(
            children: [
              filterBar,
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off,
                                size: 64, color: theme.colorScheme.outline),
                            const SizedBox(height: 16),
                            Text('Aucun membre trouve',
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
                                  _sortOption = MembresSortOption.nameAsc;
                                  _filterOption = MembresFilterOption.all;
                                });
                              },
                              child: const Text('Reinitialiser'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        padding:
                            const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemBuilder: (context, index) {
                          final membre = filtered[index];
                          final retard =
                              retardsById[membre.id];
                          final bool enRetard = (retard != null) &&
                              (((retard['nombre_retards'] as num?)
                                      ?.toInt() ??
                                  0) > 0);

                          return Slidable(
                            key: ValueKey(membre.id),
                            endActionPane: ActionPane(
                              motion: const ScrollMotion(),
                              children: [
                                SlidableAction(
                                  onPressed: (context) =>
                                      _confirmDelete(context, ref, membre),
                                  backgroundColor: AppColors.danger,
                                  foregroundColor:
                                      AppColors.textInverse,
                                  icon: Icons.delete,
                                  label: 'Supprimer',
                                  spacing: 16,
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 20),
                                  borderRadius:
                                      BorderRadius.circular(16),
                                ),
                                SlidableAction(
                                  onPressed: (context) =>
                                      _showEditDialog(context, ref, membre),
                                  backgroundColor: AppColors.primary,
                                  foregroundColor:
                                      AppColors.textInverse,
                                  icon: Icons.edit,
                                  label: 'Modifier',
                                  spacing: 16,
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 20),
                                  borderRadius:
                                      BorderRadius.circular(16),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 12),
                              child: KasedCard(
                                padding: EdgeInsets.zero,
                                onTap: () =>
                                    context.push('/membres/${membre.id}',
                                        extra: membre),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      left: BorderSide(
                                        color: enRetard
                                            ? AppColors.warning
                                            : AppColors.success,
                                        width: 6,
                                      ),
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(24),
                                  ),
                                  padding:
                                      const EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      Hero(
                                        tag: 'membre_${membre.id}',
                                        child: KasedAvatar(
                                          name: membre.nomComplet,
                                          size: 48,
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
                                                membre.nomComplet,
                                                style: theme
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                        fontWeight:
                                                            FontWeight
                                                                .w700),
                                              ),
                                              const SizedBox(
                                                  height: 2),
                                              Text(
                                                'Membre depuis ${DateFormat('MMM yyyy').format(membre.dateAdhesion)}',
                                                style: theme
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                        color: AppColors
                                                            .textSecondary),
                                              ),
                                            ],
                                          ),
                                      ),
                                      if (enRetard)
                                        Text(
                                            '${(retard['montant_du_fcfa'] as num?)?.toDouble() ?? 0.0} F',
                                            style: const TextStyle(
                                                fontWeight:
                                                    FontWeight.w800,
                                                color: AppColors.danger)),
                                      if (membre.anniversaireAujourdHui)
                                        const Padding(
                                          padding:
                                              EdgeInsets.only(left: 8),
                                          child: Icon(Icons.cake,
                                              color: AppColors.warning,
                                              size: 16),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                              .animate(
                                  delay: (index * 40).ms)
                              .fadeIn(
                                  duration: 400.ms,
                                  curve:
                                      Curves.easeOutCubic)
                              .slideX(
                                  begin: 0.1,
                                  end: 0.0,
                                  duration: 400.ms,
                                  curve:
                                      Curves.easeOutCubic);
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const MembresListSkeleton(),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
      floatingActionButton: SpringButton(
        onTap: () => context.push('/membres/add'),
        child: FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.person_add),
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
          // Barre de recherche
          TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher un membre...',
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
          // Filtres statuts
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MembresFilterOption.values.map((opt) {
              final isSelected = _filterOption == opt;
              final label = opt == MembresFilterOption.all
                  ? 'Tous'
                  : opt == MembresFilterOption.active
                      ? 'Actifs'
                      : 'Inactifs';
              return FilterChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (_) =>
                    setState(() => _filterOption = opt),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                selectedColor: AppColors.primaryLight,
                checkmarkColor: AppColors.primary,
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Tri
          Row(
            children: [
              const Icon(Icons.sort,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: SegmentedButton<MembresSortOption>(
                  segments: MembresSortOption.values
                      .map((opt) => ButtonSegment<MembresSortOption>(
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
              'Affiche ${_getFilteredMembres(
                  ref.read(kasedAppProvider).value?.membres ?? []).length}'
                  ' sur ${ref.read(kasedAppProvider).value?.membres.length ?? 0} membres',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Membre membre) {
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setLocalState) {
          bool isDeleting = false;
          return AlertDialog(
            title: const Text('Supprimer ?'),
            content: Text('Voulez-vous vraiment supprimer ${membre.nomComplet} ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: isDeleting ? null : () async {
                  setLocalState(() => isDeleting = true);
                  try {
                    await ref.read(kasedAppProvider.notifier).deleteMembre(membre.id);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Expanded(child: Text('${membre.nomComplet} supprime avec succes')),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Expanded(child: Text('Erreur lors de la suppression: $e')),
                            ],
                          ),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  } finally {
                    if (ctx.mounted) setLocalState(() => isDeleting = false);
                  }
                },
                child: isDeleting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Supprimer', style: TextStyle(color: AppColors.danger)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Membre membre) {
    final nomController = TextEditingController(text: membre.nom);
    final prenomController = TextEditingController(text: membre.prenom);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setLocalState) {
          bool isSaving = false;
          return AlertDialog(
            title: const Text('Modifier le membre'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: prenomController,
                  decoration: const InputDecoration(
                    labelText: 'Prenom',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nomController,
                  decoration: const InputDecoration(
                    labelText: 'Nom',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: isSaving ? null : () async {
                  setLocalState(() => isSaving = true);
                  try {
                    await ref.read(kasedAppProvider.notifier).updateMembre(
                      id: membre.id,
                      nom: nomController.text.trim(),
                      prenom: prenomController.text.trim(),
                    );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Expanded(child: Text('Membre modifie avec succes')),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Expanded(child: Text('Erreur lors de la modification: $e')),
                            ],
                          ),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  } finally {
                    if (ctx.mounted) setLocalState(() => isSaving = false);
                  }
                },
                child: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Enregistrer'),
              ),
            ],
          );
        },
      ),
    );
    nomController.dispose();
    prenomController.dispose();
  }
}
// Extension pour le label du tri
extension _MembresSortOptionLabel on MembresSortOption {
  String get label {
    switch (this) {
      case MembresSortOption.nameAsc:
        return 'Nom A-Z';
      case MembresSortOption.nameDesc:
        return 'Nom Z-A';
      case MembresSortOption.dateAsc:
        return 'Date ancien';
      case MembresSortOption.dateDesc:
        return 'Date recent';
    }
  }
}

