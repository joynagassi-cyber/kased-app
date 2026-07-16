import 'package:flutter/material.dart';

/// Boîte de dialogue réutilisable pour modifier le montant de cotisation d'un culte.
///
/// Affiche un champ de saisie numérique avec validation (montant > 0).
/// [onSave] est appelée avec le nouveau montant si la validation réussit.
/// La dialog se ferme automatiquement après un `onSave` réussi.
///
/// Utilisation typique :
/// ```dart
/// final montant = await EditMontantDialog.show(
///   context,
///   currentMontant: 50.0,
///   onSave: (newMontant) async {
///     await ref.read(appDataProvider.notifier).updateCulte(
///       id: culte.id,
///       montantCotisation: newMontant,
///     );
///   },
/// );
/// ```
class EditMontantDialog {
  /// Affiche la boîte de dialogue de modification du montant.
  ///
  /// Retourne `true` si la modification a été enregistrée, `false` si annulée.
  /// [onSave] reçoit le nouveau montant et doit lever une exception en cas d'erreur.
  static Future<bool> show(
    BuildContext context, {
    required double currentMontant,
    required Future<void> Function(double newMontant) onSave,
  }) async {
    final controller = TextEditingController(
      text: currentMontant.toInt().toString(),
    );
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Modifier le montant'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Montant (FCFA)',
                prefixIcon: Icon(Icons.monetization_on_outlined),
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              validator: (value) {
                final parsed = int.tryParse((value ?? '').trim()) ?? 0;
                if (parsed <= 0) return 'Montant invalide';
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final newMontant = double.tryParse(controller.text.trim());
                if (newMontant == null || newMontant <= 0) return;
                try {
                  await onSave(newMontant);
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext, true);
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

    controller.dispose();
    return saved ?? false;
  }
}
