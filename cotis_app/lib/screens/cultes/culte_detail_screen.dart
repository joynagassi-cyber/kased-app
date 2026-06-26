import 'package:kased_app/core/pdf/pdf_service.dart';
import 'package:kased_app/core/theme/app_theme.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/providers/app_data_provider.dart';
import 'package:kased_app/screens/cultes/saisie_rapide_screen.dart';
import 'package:kased_app/widgets/empty_state.dart';
import 'package:kased_app/widgets/member_pay_tile.dart';
import 'package:flutter/material.dart';
import 'package:kased_app/widgets/motion/skeleton_loading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kased_app/widgets/spring_button.dart';

class CulteDetailScreen extends ConsumerStatefulWidget {
  final String culteId;
  const CulteDetailScreen({super.key, required this.culteId});

  @override
  ConsumerState<CulteDetailScreen> createState() => _CulteDetailScreenState();
}

class _CulteDetailScreenState extends ConsumerState<CulteDetailScreen> {
  String _searchQuery = '';
  String _filter = 'Tous';
  bool _celebrationShown = false;

  @override
  Widget build(BuildContext context) {
    final appDataAsync = ref.watch(appDataProvider);
    final theme = Theme.of(context);

    return appDataAsync.when(
      data: (state) {
        final culteIndex = state.cultes.indexWhere((c) => c.id == widget.culteId);
        if (culteIndex == -1) {
          return const Scaffold(body: Center(child: Text('Culte introuvable')));
        }
        final culte = state.cultes[culteIndex];

        final cotisations = state.cotisations.where((c) => c.culteId == widget.culteId).toList();
        final membres = state.membres.where((m) => m.isActive).toList();
        final payes = cotisations.where((c) => c.estPaye).length;
        final total = membres.length;
         final totalCollecte = cotisations.where((c) => c.estPaye).fold(0.0, (sum, c) => sum + c.montantPaye);
        final membresPayesIds = cotisations.where((c) => c.estPaye).map((c) => c.membreId).toSet();
        final membresNonPayes = membres.where((m) => !membresPayesIds.contains(m.id)).toList();
        final tousPayes = membres.isNotEmpty && membresNonPayes.isEmpty;

        if (tousPayes && !_celebrationShown) {
          _celebrationShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.stars, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tout le monde a payé ! 🌟 Célébration !',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 4),
              ),
            );
          });
        }

        // Verrouillage à 30 jours : interdit de modifier les paiements validés
        final isOlderThan30Days = DateTime.now().difference(culte.dateCulte).inDays > 30;
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  culte.dateFormatee,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '$payes / $total - ${totalCollecte.toInt()} FCFA',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textInverse.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.flash_on),
                tooltip: 'Mode saisie rapide',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => SaisieRapideScreen(culteId: widget.culteId),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Modifier le montant',
                onPressed: () => _editMontant(context, culte),
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: 'Exporter en PDF',
                onPressed: () async {
                  final statuses = membres
                      .map(
                        (m) => MembrePaiementStatus(
                          membre: m,
                          estPaye: cotisations.any((c) => c.membreId == m.id && c.estPaye),
                        ),
                      )
                      .toList();

                  try {
                    final path = await PdfService.generateCultePdf(
                      culte: culte,
                      statuses: statuses,
                      totalCollecte: totalCollecte,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Rapport de culte enregistré dans :\n$path'),
                          duration: const Duration(seconds: 5),
                          action: SnackBarAction(
                            label: 'OK',
                            onPressed: () {},
                          ),
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
                },
              ),
              IconButton(
                icon: const Icon(Icons.sync),
                onPressed: () => ref.read(appDataProvider.notifier).syncData(),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Hero(
                tag: 'culte_${culte.id}',
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.gradientStart, AppColors.gradientEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gradientEnd.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Objectif et progression',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: AppColors.textInverse,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (culte.montantCotisation != 50.0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Spécial: ${culte.montantCotisation.toInt()} F',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.textInverse,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Collecté',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textInverse.withValues(alpha: 0.8),
                                  ),
                                ),
                                Text(
                                  '${totalCollecte.toInt()} FCFA',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    color: AppColors.textInverse,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Membres',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textInverse.withValues(alpha: 0.8),
                                  ),
                                ),
                                Text(
                                  '$payes / $total',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: AppColors.textInverse,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: total > 0 ? payes / total : 0,
                            minHeight: 8,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (membresNonPayes.isNotEmpty || tousPayes) ...[
                Row(
                  children: [
                    if (membresNonPayes.isNotEmpty)
                      Expanded(
                        child: SpringButton(
                          onTap: () => _confirmBulkAction(
                            context,
                            title: 'Tout valider',
                            message: 'Marquer les ${membresNonPayes.length} membres restants comme payés ?',
                            onConfirm: () => ref.read(appDataProvider.notifier).bulkSetPaiements(
                                  culteId: widget.culteId,
                                  newStatut: StatutCotisation.paye,
                                  membreIds: membresNonPayes.map((m) => m.id).toList(),
                                ),
                          ),
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.done_all),
                            label: Text('Tout valider (${membresNonPayes.length})'),
                            onPressed: () {}, // Géré par SpringButton
                          ),
                        ),
                      ),
                    if (membresNonPayes.isNotEmpty && tousPayes) const SizedBox(width: 12),
                    if (tousPayes)
                      Expanded(
                        child: SpringButton(
                          onTap: () => _confirmBulkAction(
                            context,
                            title: 'Tout annuler',
                            message: 'Supprimer tous les paiements de ce culte ?',
                            onConfirm: () => ref.read(appDataProvider.notifier).bulkSetPaiements(
                                  culteId: widget.culteId,
                                  newStatut: StatutCotisation.nonPaye,
                                  membreIds: cotisations
                                      .where((c) => c.estPaye)
                                      .map((c) => c.membreId)
                                      .toList(),
                                ),
                          ),
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: const BorderSide(color: AppColors.danger),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.remove_done),
                            label: const Text('Tout annuler'),
                            onPressed: () {}, // Géré par SpringButton
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher un membre...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: ['Tous', 'Payés', 'Non payés', 'Absents'].map((filter) {
                    final selected = _filter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: selected,
                        label: Text(filter),
                        onSelected: (_) => setState(() => _filter = filter),
                        backgroundColor: AppColors.surface,
                        selectedColor: AppColors.primary.withValues(alpha: 0.15),
                        checkmarkColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: selected ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: selected ? AppColors.primary : AppColors.border,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              if (membres.isEmpty)
                const EmptyState(
                  icon: Icons.people_outline,
                  titre: 'Aucun membre enregistré',
                  sousTitre: 'Ajoutez des membres pour gérer les paiements.',
                )
              else
                ...(() {
                  final filteredMembres = membres.where((m) {
                    final matchesSearch = m.nomComplet.toLowerCase().contains(_searchQuery);
                    final cotisation = cotisations.firstWhere(
                      (c) => c.membreId == m.id,
                      orElse: () => Cotisation()
                        ..membreId = m.id
                        ..culteId = widget.culteId
                        ..statut = StatutCotisation.nonPaye,
                    );
                    final estPaye = cotisation.estPaye;

                    if (!matchesSearch) return false;
                    if (_filter == 'Payés') return estPaye;
                    if (_filter == 'Non payés') return cotisation.statut == StatutCotisation.nonPaye;
                    if (_filter == 'Absents') return cotisation.statut == StatutCotisation.absent;
                    return true;
                  }).toList();

                  if (filteredMembres.isEmpty) {
                    return [
                      const Padding(
                        padding: EdgeInsets.only(top: 32),
                        child: EmptyState(
                          icon: Icons.search_off,
                          titre: 'Aucun membre trouvé',
                          sousTitre: 'Essayez une autre recherche ou un autre filtre.',
                        ),
                      ),
                    ];
                  }

                  return filteredMembres.asMap().entries.map((entry) {
                    final index = entry.key;
                    final membre = entry.value;
                    final cotisation = cotisations.firstWhere(
                      (c) => c.membreId == membre.id,
                      orElse: () => Cotisation()
                        ..membreId = membre.id
                        ..culteId = widget.culteId
                        ..statut = StatutCotisation.nonPaye,
                    );
                    // Le paiement est verrouillé si le culte a > 30 jours ET qu'il est payé
                    final memberIsLocked = isOlderThan30Days && cotisation.estPaye;

                    return MemberPayTile(
                      membre: membre,
                      statut: cotisation.statut,
                      isLocked: memberIsLocked,
                      montantPaye: cotisation.montantPaye,
                      montantObligatoire: cotisation.montantObligatoire,
                      onToggle: () {
                        if (memberIsLocked) return;
                        ref.read(appDataProvider.notifier).togglePaiement(
                              membreId: membre.id,
                              culteId: widget.culteId,
                            );
                      },
                      onMarkAbsent: () {
                        if (memberIsLocked) return;
                        ref.read(appDataProvider.notifier).marquerAbsent(
                              membreId: membre.id,
                              culteId: widget.culteId,
                            );
                      },
                      onCustomPayment: memberIsLocked
                          ? null
                          : () => _showCustomPaymentDialog(
                                context,
                                membre: membre,
                                culteId: widget.culteId,
                                montantObligatoire: cotisation.montantObligatoire,
                                montantActuel: cotisation.montantPaye,
                              ),
                    )
                    .animate(delay: (index * 40).ms)
                    .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                    .slideX(begin: 0.1, end: 0.0, duration: 300.ms, curve: Curves.easeOut);
                  }).toList();
                }()),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: CulteDetailSkeleton()),
      error: (e, _) => Scaffold(body: Center(child: Text('Erreur: $e'))),
    );
  }

  /// Boîte de dialogue pour encaisser un paiement personnalisé (montant libre
  /// >= montant obligatoire). L'excédent est automatiquement comptabilisé
  /// comme un don via [AppData.enregistrerPaiementPersonnel].
  Future<void> _showCustomPaymentDialog(
    BuildContext context, {
    required Membre membre,
    required String culteId,
    required double montantObligatoire,
    required double montantActuel,
  }) async {
    final controller = TextEditingController(
      text: montantActuel > 0 ? montantActuel.toStringAsFixed(0) : '',
    );
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Paiement — ${membre.nomComplet}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Montant obligatoire : ${montantObligatoire.toStringAsFixed(0)} F',
                style: Theme.of(dialogContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Montant payé (F)',
                  hintText: 'Ex. 100',
                  prefixIcon: Icon(Icons.payments_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final raw = value?.trim() ?? '';
                  final montant = double.tryParse(raw);
                  if (montant == null) return 'Montant invalide';
                  if (montant <= 0) return 'Le montant doit être positif';
                  if (montant < montantObligatoire) {
                    return 'Minimum : ${montantObligatoire.toStringAsFixed(0)} F';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Tout montant supérieur à l\'obligation sera enregistré comme don.',
                style: Theme.of(dialogContext).textTheme.bodySmall,
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
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(
                  dialogContext,
                  double.parse(controller.text.trim()),
                );
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (result == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(appDataProvider.notifier).enregistrerPaiementPersonnel(
            membreId: membre.id,
            culteId: culteId,
            montant: result,
          );
      final don = result - montantObligatoire;
      messenger.showSnackBar(
        SnackBar(
          content: Text(don > 0
              ? 'Paiement de ${result.toStringAsFixed(0)} F enregistré (don : ${don.toStringAsFixed(0)} F).'
              : 'Paiement de ${result.toStringAsFixed(0)} F enregistré.'),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Future<void> _confirmBulkAction(
    BuildContext context, {
    required String title,
    required String message,
    required Future<({int success, int total})> Function() onConfirm,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final nav = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const AlertDialog(
        content: SizedBox(
          height: 90,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );

    try {
      final result = await onConfirm();
      nav.pop();
      if (result.success == result.total) {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('$title : ${result.success}/${result.total} effectué'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (result.success > 0) {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info, color: Colors.black, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Partiel : ${result.success}/${result.total} réussis'),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Aucune opération n\'a abouti'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      nav.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Erreur: $e'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editMontant(BuildContext context, Culte culte) async {
    final controller = TextEditingController(text: culte.montantCotisation.toInt().toString());
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Modifier le montant'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Montant (FCFA)'),
              validator: (value) {
                final parsed = int.tryParse((value ?? '').trim()) ?? 0;
                if (parsed <= 0) return 'Montant invalide';
                return null;
              },
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
                        montantCotisation: double.tryParse(controller.text.trim()) ?? culte.montantCotisation,
                      );
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
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

    controller.dispose();
  }
}

