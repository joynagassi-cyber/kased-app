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

class MembresScreen extends ConsumerStatefulWidget {
  const MembresScreen({super.key});

  @override
  ConsumerState<MembresScreen> createState() => _MembresScreenState();
}

class _MembresScreenState extends ConsumerState<MembresScreen> {
  List<Map<String, dynamic>> retards = [];

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

  @override
  Widget build(BuildContext context) {
    final appDataAsync = ref.watch(kasedAppProvider);
    final theme = Theme.of(context);
    final retardsById = {for (final r in retards) r['membre_id']: r};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Membres'),
        actions: [
          // Bouton « Membres en avance »
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
        ],
      ),
      body: appDataAsync.when(
        data: (state) {
          final membres = state.membres;

          if (membres.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline,
              titre: 'Aucun membre enregistré',
              sousTitre: 'Appuyez sur le bouton + pour ajouter un membre.',
            );
          }

          return ListView.builder(
            itemCount: membres.length,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemBuilder: (context, index) {
              final membre = membres[index];
              final retard = retardsById[membre.id];
              final bool enRetard = (retard != null) &&
                  (((retard['nombre_retards'] as num?)?.toInt() ?? 0) > 0);

              return Slidable(
                key: ValueKey(membre.id),
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (context) =>
                          _confirmDelete(context, ref, membre),
                      backgroundColor: AppColors.danger,
                      foregroundColor: AppColors.textInverse,
                      icon: Icons.delete,
                      label: 'Supprimer',
                      spacing: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    SlidableAction(
                      onPressed: (context) =>
                          _showEditDialog(context, ref, membre),
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textInverse,
                      icon: Icons.edit,
                      label: 'Modifier',
                      spacing: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: KasedCard(
                    padding: EdgeInsets.zero,
                    onTap: () => context.push('/membres/${membre.id}', extra: membre),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: enRetard ? AppColors.warning : AppColors.success,
                            width: 6,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.all(20),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  membre.nomComplet,
                                  style: theme.textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Membre depuis ${DateFormat('MMM yyyy').format(membre.dateAdhesion)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          if (enRetard)
                            Text(
                              '${(retard['montant_du_fcfa'] as num?)?.toDouble() ?? 0.0} F',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.danger),
                            ),
                          if (membre.anniversaireAujourdHui)
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Icon(Icons.cake,
                                  color: AppColors.warning, size: 16),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ).animate(delay: (index * 40).ms).fadeIn(duration: 400.ms, curve: Curves.easeOutCubic).slideX(begin: 0.1, end: 0.0, duration: 400.ms, curve: Curves.easeOutCubic);
            },
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
                // ignore: dead_code
                onPressed: isDeleting
                    // ignore: dead_code
                    ? null
                    : () async {
                        setLocalState(() => isDeleting = true);
                        try {
                          await ref
                              .read(kasedAppProvider.notifier)
                              .deleteMembre(membre.id);

                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text('${membre.nomComplet} supprimé avec succès'),
                                    ),
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
                                    Expanded(
                                      child: Text('Erreur lors de la suppression: $e'),
                                    ),
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
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Supprimer',
                        style: TextStyle(color: AppColors.danger)),
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
                    labelText: 'Prénom',
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
                // ignore: dead_code
                onPressed: isSaving
                    // ignore: dead_code
                    ? null
                    : () async {
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
                                    Expanded(
                                      child: Text('Membre modifié avec succès'),
                                    ),
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
                                    Expanded(
                                      child: Text('Erreur lors de la modification: $e'),
                                    ),
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
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
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

