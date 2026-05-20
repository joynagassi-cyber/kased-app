import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kased_app/providers/app_data_provider.dart';
import 'package:kased_app/core/theme/app_theme.dart';
import 'package:kased_app/widgets/empty_state.dart';
import 'package:kased_app/widgets/kased_avatar.dart';
import 'package:kased_app/widgets/kased_card.dart';
import 'package:intl/intl.dart';
import 'package:kased_app/core/pdf/pdf_service.dart';

class RetardsScreen extends ConsumerWidget {
  const RetardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Surveille l'état global — l'écran se reconstruit automatiquement
    // après un togglePaiement/marquerAbsent car appDataProvider est invalidé.
    final appDataAsync = ref.watch(appDataProvider);
    final theme = Theme.of(context);

    return appDataAsync.when(
      data: (state) {
        // Calcul local depuis Isar — fonctionne offline
        final retards =
            ref.read(appDataProvider.notifier).getRetardsMembresLocally();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Membres en Retard'),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: 'Exporter en PDF',
                onPressed: retards.isNotEmpty
                    ? () async {
                        try {
                          final path =
                              await PdfService.generateRetardsPdf(retards);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Rapport des retards enregistré dans :\n$path'),
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
                      }
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.sync),
                onPressed: () async {
                  await ref.read(appDataProvider.notifier).syncData();
                },
              ),
            ],
          ),
          body: retards.isEmpty
              ? const EmptyState(
                  icon: Icons.check_circle_outline,
                  titre: 'Tout le monde est à jour !',
                  sousTitre: 'Aucun retard détecté pour le moment.',
                  iconColor: AppColors.success,
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(appDataProvider.notifier).syncData();
                  },
                  child: ListView.separated(
                    itemCount: retards.length,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final retard = retards[index];
                      final nom = retard['nom'] ?? '';
                      final prenom = retard['prenom'] ?? '';
                      final cultesEnRetard =
                          (retard['cultes_en_retard'] as num?)?.toInt() ?? 0;
                      final montantDu =
                          (retard['montant_du_fcfa'] as num?)?.toDouble() ??
                              0.0;
                      final dernierPaiement = retard['dernier_paiement'] != null
                          ? DateTime.tryParse(
                              retard['dernier_paiement'].toString())
                          : null;

                      return KasedCard(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            KasedAvatar(
                              name: '$prenom $nom',
                              size: 40,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$prenom $nom',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    '$cultesEnRetard culte${cultesEnRetard > 1 ? 's' : ''} en retard',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (dernierPaiement != null)
                                    Text(
                                      'Dernier paiement : ${DateFormat('dd/MM/yy').format(dernierPaiement)}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textTertiary,
                                      ),
                                    )
                                  else
                                    Text(
                                      'Jamais payé',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.danger,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '${montantDu.toInt()} F',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                      color: AppColors.textInverse,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'À RÉGLER',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.textTertiary,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Erreur: $e')),
      ),
    );
  }
}
