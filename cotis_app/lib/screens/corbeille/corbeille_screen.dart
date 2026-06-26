import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:kased_app/models/corbeille_item.dart';
import 'package:kased_app/providers/app_data_provider.dart';
import 'package:kased_app/providers/isar_provider.dart';
import 'package:kased_app/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

List<CorbeilleItem> filterRecent(List<CorbeilleItem> items, DateTime now) {
  final limit = now.subtract(const Duration(days: 30));
  return items.where((i) => !i.deletedAt.isBefore(limit)).toList();
}

List<CorbeilleItem> getItemsToPurge(List<CorbeilleItem> items, DateTime now) {
  final limit = now.subtract(const Duration(days: 30));
  return items.where((i) => i.deletedAt.isBefore(limit)).toList();
}

enum CorbeilleTri {
  suppressionDesc('Suppression ↓', 'deletedAt'),
  suppressionAsc('Suppression ↑', 'deletedAt_asc'),
  modificationDesc('Modification ↓', 'updatedAt'),
  modificationAsc('Modification ↑', 'updatedAt_asc');

  final String label;
  final String field;
  const CorbeilleTri(this.label, this.field);
}

final corbeilleProvider =
    FutureProvider.autoDispose<List<CorbeilleItem>>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  ref.watch(appDataProvider);

  final items = await isar.corbeilleItems.where().sortByDeletedAtDesc().findAll();

  final toPurge = getItemsToPurge(items, DateTime.now());
  if (toPurge.isNotEmpty) {
    await isar.writeTxn(() async {
      for (final item in toPurge) {
        await isar.corbeilleItems.delete(item.isarId);
      }
    });
    return filterRecent(items, DateTime.now());
  }

  return items;
});

/// Raccourci pour rafraîchir la liste corbeille après une mutation.
void _refreshCorbeille(WidgetRef ref) {
  ref.invalidate(corbeilleProvider);
}

// ── Écran ────────────────────────────────────────────────────────────────────

class CorbeilleScreen extends ConsumerStatefulWidget {
  const CorbeilleScreen({super.key});

  @override
  ConsumerState<CorbeilleScreen> createState() => _CorbeilleScreenState();
}

class _CorbeilleScreenState extends ConsumerState<CorbeilleScreen> {
  CorbeilleTri _tri = CorbeilleTri.suppressionDesc;
  final Set<int> _selectedIds = {};

  List<CorbeilleItem> _trier(List<CorbeilleItem> items, CorbeilleTri tri) {
    final sorted = [...items];
    switch (tri) {
      case CorbeilleTri.suppressionDesc:
        sorted.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
      case CorbeilleTri.suppressionAsc:
        sorted.sort((a, b) => a.deletedAt.compareTo(b.deletedAt));
      case CorbeilleTri.modificationDesc:
        sorted.sort((a, b) => b.derniereModification.compareTo(a.derniereModification));
      case CorbeilleTri.modificationAsc:
        sorted.sort((a, b) => a.derniereModification.compareTo(b.derniereModification));
    }
    return sorted;
  }

  /// Nettoie les ids sélectionnés qui ne sont plus dans la liste affichée
  /// (après une restauration ou suppression définitive).
  void _purgerSelectionAbsente(List<CorbeilleItem> items) {
    final validIds = items.map((i) => i.isarId).toSet();
    if (_selectedIds.any((id) => !validIds.contains(id))) {
      _selectedIds.removeWhere((id) => !validIds.contains(id));
    }
  }

  Future<void> _restaurer(int isarId) async {
    await ref.read(appDataProvider.notifier).restaurerElement(isarId);
    _refreshCorbeille(ref);
    if (mounted) {
      setState(() => _selectedIds.remove(isarId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Élément restauré avec succès')),
      );
    }
  }

  Future<void> _restaurerSelection() async {
    final count = _selectedIds.length;
    for (final id in _selectedIds.toList()) {
      await ref.read(appDataProvider.notifier).restaurerElement(id);
    }
    _refreshCorbeille(ref);
    if (mounted) {
      setState(_selectedIds.clear);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count élément(s) restauré(s)')),
      );
    }
  }

  Future<void> _restaurerTout(List<CorbeilleItem> items) async {
    for (final item in items) {
      await ref.read(appDataProvider.notifier).restaurerElement(item.isarId);
    }
    _refreshCorbeille(ref);
    if (mounted) {
      setState(_selectedIds.clear);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${items.length} élément(s) restauré(s)')),
      );
    }
  }

  Future<void> _supprimerDefinitivement(int isarId, String titre) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suppression définitive'),
        content: Text('Supprimer définitivement « $titre » ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await ref.read(appDataProvider.notifier).supprimerDefinitivement(isarId);
    _refreshCorbeille(ref);
    if (mounted) {
      setState(() => _selectedIds.remove(isarId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Élément supprimé définitivement')),
      );
    }
  }

  Future<void> _viderCorbeille(List<CorbeilleItem> items) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vider la corbeille'),
        content: Text('Supprimer définitivement les ${items.length} élément(s) ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Vider'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await ref.read(appDataProvider.notifier).viderCorbeille();
    _refreshCorbeille(ref);
    if (mounted) {
      setState(_selectedIds.clear);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Corbeille vidée')),
      );
    }
  }

  Future<void> _supprimerSelection(List<CorbeilleItem> items) async {
    final selectedItems = items.where((i) => _selectedIds.contains(i.isarId)).toList();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suppression définitive'),
        content: Text('Supprimer définitivement les ${selectedItems.length} élément(s) sélectionné(s) ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    for (final item in selectedItems) {
      await ref.read(appDataProvider.notifier).supprimerDefinitivement(item.isarId);
    }
    _refreshCorbeille(ref);
    if (mounted) {
      setState(_selectedIds.clear);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selectedItems.length} élément(s) supprimé(s) définitivement')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final corbeilleAsync = ref.watch(corbeilleProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Corbeille', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: colorScheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_selectedIds.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.restore_page),
              tooltip: 'Restaurer la sélection',
              onPressed: _restaurerSelection,
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Supprimer la sélection',
              onPressed: () {
                final items = _trier(
                  ref.read(corbeilleProvider).value ?? <CorbeilleItem>[],
                  _tri,
                );
                _supprimerSelection(items);
              },
            ),
          ],
        ],
      ),
      body: corbeilleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
        data: (rawItems) {
          if (rawItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline, size: 64,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text('La corbeille est vide',
                      style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Text('Les elements sont conserves 30 jours',
                      style: TextStyle(fontSize: 12,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7))),
                ],
              ),
            );
          }

          final items = _trier(rawItems, _tri);
          // Nettoyer la sélection des ids qui ne sont plus présents.
          _purgerSelectionAbsente(items);
          final toutSelectionne = items.isNotEmpty && _selectedIds.length == items.length;

          return Column(
            children: [
              // ── Barre d'outils ────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    // Checkbox "Tout selectionner"
                    if (items.isNotEmpty)
                      Checkbox(
                        value: toutSelectionne,
                        onChanged: (_) => setState(() {
                          if (toutSelectionne) {
                            _selectedIds.clear();
                          } else {
                            _selectedIds.addAll(items.map((i) => i.isarId));
                          }
                        }),
                      ),
                    const SizedBox(width: 4),
                    // Tri
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<CorbeilleTri>(
                          value: _tri,
                          isExpanded: true,
                          icon: const Icon(Icons.sort, size: 20),
                          items: CorbeilleTri.values.map((t) {
                            return DropdownMenuItem(value: t, child: Text(t.label, style: const TextStyle(fontSize: 13)));
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _tri = v);
                          },
                        ),
                      ),
                    ),
                    // Tout restaurer
                    TextButton.icon(
                      icon: const Icon(Icons.restore, size: 18),
                      label: Text('Tout restaurer (${items.length})', style: const TextStyle(fontSize: 12)),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Tout restaurer'),
                            content: Text('Restaurer les ${items.length} élément(s) ?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restaurer tout')),
                            ],
                          ),
                        );
                        if (ok == true) await _restaurerTout(items);
                      },
                    ),
                    // Vider la corbeille
                    TextButton.icon(
                      icon: Icon(Icons.delete_forever, size: 18, color: colorScheme.error),
                      label: Text('Vider', style: TextStyle(fontSize: 12, color: colorScheme.error)),
                      onPressed: () => _viderCorbeille(items),
                    ),
                  ],
                ),
              ),
              const Divider(height: 16),
              // ── Liste ──────────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: items.length,
                  itemBuilder: (_, index) {
                    final item = items[index];
                    final payload = jsonDecode(item.payloadJson);
                    final isSelected = _selectedIds.contains(item.isarId);

                    String titre;
                    String sousTitre;
                    IconData icone;

                    if (item.entityType == 'membre') {
                      titre = '${payload['prenom'] ?? ''} ${payload['nom'] ?? ''}'.trim();
                      sousTitre = 'Membre supprime le ${DateFormat('dd/MM/yyyy').format(item.deletedAt)}';
                      icone = Icons.person_off_outlined;
                    } else {
                      final dateCulte = payload['date_culte'] != null
                          ? DateTime.tryParse(payload['date_culte'] as String)
                          : null;
                      titre = payload['titre'] ?? (dateCulte != null
                          ? 'Culte du ${DateFormat('dd/MM/yyyy').format(dateCulte)}'
                          : 'Culte');
                      sousTitre = 'Culte supprime le ${DateFormat('dd/MM/yyyy').format(item.deletedAt)}';
                      icone = Icons.church_outlined;
                    }

                    final joursRestants = 30 - DateTime.now().difference(item.deletedAt).inDays;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outlineVariant.withValues(alpha: 0.5),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => setState(() {
                          if (isSelected) {
                            _selectedIds.remove(item.isarId);
                          } else {
                            _selectedIds.add(item.isarId);
                          }
                        }),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isSelected,
                                onChanged: (_) => setState(() {
                                  if (isSelected) {
                                    _selectedIds.remove(item.isarId);
                                  } else {
                                    _selectedIds.add(item.isarId);
                                  }
                                }),
                              ),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: colorScheme.errorContainer.withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icone, color: colorScheme.error, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(titre,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(height: 2),
                                    Text(sousTitre,
                                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                                    Text('$joursRestants jours restants',
                                        style: const TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Restaurer'),
                                      content: Text('Restaurer "$titre" ?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restaurer')),
                                      ],
                                    ),
                                  );
                                  if (ok == true) await _restaurer(item.isarId);
                                },
                                icon: const Icon(Icons.restore),
                                tooltip: 'Restaurer',
                                color: colorScheme.primary,
                                style: IconButton.styleFrom(
                                  backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _supprimerDefinitivement(item.isarId, titre),
                                icon: const Icon(Icons.delete_forever),
                                tooltip: 'Supprimer définitivement',
                                color: colorScheme.error,
                                style: IconButton.styleFrom(
                                  backgroundColor: colorScheme.errorContainer.withValues(alpha: 0.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
