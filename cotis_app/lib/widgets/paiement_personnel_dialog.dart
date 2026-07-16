import 'package:flutter/material.dart';

/// Boîte de dialogue réutilisable pour encaisser un paiement personnalisé.
///
/// Affiche un champ de saisie pour le montant payé, avec validation :
/// - Le montant doit être >= [montantObligatoire]
/// - L'excédent est présenté comme un don
///
/// Retourne le montant saisi (`double`) ou `null` si l'utilisateur annule.
///
/// Utilisation typique :
/// ```dart
/// final montant = await PaiementPersonnelDialog.show(
///   context,
///   membreNom: 'Jean Dupont',
///   montantObligatoire: 50.0,
///   montantActuel: 0.0,
/// );
/// if (montant != null) {
///   // Appeler le service de paiement
/// }
/// ```
class PaiementPersonnelDialog {
  /// Affiche la boîte de dialogue de paiement personnalisé.
  ///
  /// [membreNom] : Nom complet du membre (affiché dans le titre)
  /// [montantObligatoire] : Montant minimum requis
  /// [montantActuel] : Montant déjà payé (pour préremplir le champ)
  ///
  /// Retourne le montant saisi, ou `null` si annulé.
  static Future<double?> show(
    BuildContext context, {
    required String membreNom,
    required double montantObligatoire,
    double montantActuel = 0.0,
  }) {
    final controller = TextEditingController(
      text: montantActuel > 0 ? montantActuel.toStringAsFixed(0) : '',
    );
    final formKey = GlobalKey<FormState>();

    return showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Paiement — $membreNom'),
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
    ).then((result) {
      controller.dispose();
      return result;
    });
  }
}
