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

// Fonction pure extraite pour être facilement testable en unitaire
List<CorbeilleItem> filterRecentCorbeilleItems(List<CorbeilleItem> items, DateTime now) {
  final limitDate = now.subtract(const Duration(days: 30));
  return items.where((i) => !i.deletedAt.isBefore(limitDate)).toList();
}

List<CorbeilleItem> getItemsToPurge(List<CorbeilleItem> items, DateTime now) {
  final limitDate = now.subtract(const Duration(days: 30));
  return items.where((i) => i.deletedAt.isBefore(limitDate)).toList();
}

final corbeilleProvider = FutureProvider.autoDispose<List<CorbeilleItem>>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  ref.watch(appDataProvider);
  
  final items = await isar.corbeilleItems.where().sortByDeletedAtDesc().findAll();
  
  // Purge automatique après 30 jours
  final itemsToPurge = getItemsToPurge(items, DateTime.now());
  
  if (itemsToPurge.isNotEmpty) {
    await isar.writeTxn(() async {
      for (final item in itemsToPurge) {
        await isar.corbeilleItems.delete(item.isarId);
      }
    });
    // On retourne les items récents uniquement
    return filterRecentCorbeilleItems(items, DateTime.now());
  }
  
  return items;
});

class CorbeilleScreen extends ConsumerWidget {
  const CorbeilleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      ),
      body: corbeilleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delete_outline,
                    size: 64,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'La corbeille est vide',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Les éléments sont conservés 30 jours',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final payload = jsonDecode(item.payloadJson);
              
              String titre = '';
              String sousTitre = '';
              IconData icone = Icons.delete;

              if (item.entityType == 'membre') {
                titre = '${payload['prenom']} ${payload['nom']}';
                sousTitre = 'Membre supprimé le ${DateFormat('dd/MM/yyyy').format(item.deletedAt)}';
                icone = Icons.person_off_outlined;
              } else if (item.entityType == 'culte') {
                final dateCulte = DateTime.parse(payload['date_culte']).toLocal();
                titre = payload['titre'] ?? 'Culte du ${DateFormat('dd/MM/yyyy').format(dateCulte)}';
                sousTitre = 'Culte supprimé le ${DateFormat('dd/MM/yyyy').format(item.deletedAt)}';
                icone = Icons.church_outlined;
              }

              // Jours restants
              final joursRestants = 30 - DateTime.now().difference(item.deletedAt).inDays;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icone, color: colorScheme.error),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titre,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              sousTitre,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$joursRestants jours restants',
                              style: const TextStyle(
                                color: AppColors.warning,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Restaurer l\'élément ?'),
                              content: Text('Voulez-vous restaurer "$titre" ?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Annuler'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Restaurer'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            await ref.read(appDataProvider.notifier).restaurerElement(item.isarId);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Élément restauré avec succès')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.restore),
                        tooltip: 'Restaurer',
                        color: colorScheme.primary,
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
