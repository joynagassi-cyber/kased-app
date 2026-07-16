import 'package:flutter/material.dart';

/// Résultat d'une action groupée exécutée via [ConfirmActionDialog].
class ConfirmActionResult {
  final int success;
  final int total;
  final String title;

  const ConfirmActionResult({
    required this.success,
    required this.total,
    required this.title,
  });

  /// Si toutes les opérations ont réussi.
  bool get isComplete => success == total;

  /// Si au moins une opération a réussi (mais pas toutes).
  bool get isPartial => success > 0 && success < total;

  /// Si aucune opération n'a réussi.
  bool get isFailed => success == 0;
}

/// Boîte de dialogue réutilisable pour confirmer puis exécuter une action groupée.
///
/// Flux :
/// 1. Affiche une confirmation avec [title] et [message]
/// 2. Si confirmé, affiche un indicateur de chargement
/// 3. Exécute [onConfirm] (async)
/// 4. Referme le chargement et retourne le résultat
///
/// Utilisation typique :
/// ```dart
/// final result = await ConfirmActionDialog.show(
///   context,
///   title: 'Tout valider',
///   message: 'Marquer tous les membres comme payés ?',
///   onConfirm: () => ref.read(appDataProvider.notifier).bulkSetPaiements(...),
/// );
/// if (result != null) {
///   // Afficher le snackbar correspondant
/// }
/// ```
class ConfirmActionDialog {
  /// Affiche la boîte de dialogue de confirmation avec exécution.
  ///
  /// Retourne le résultat de l'action, ou `null` si l'utilisateur a annulé.
  /// [title] est utilisé à la fois pour le titre de la confirmation
  /// et pour le message de résultat.
  static Future<ConfirmActionResult?> show(
    BuildContext context, {
    required String title,
    required String message,
    required Future<({int success, int total})> Function() onConfirm,
  }) async {
    // Étape 1 : Confirmation
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

    if (confirmed != true) return null;

    // Étape 2 : Loading + exécution
    final nav = Navigator.of(context, rootNavigator: true);

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
      nav.pop(); // ferme le loading
      return ConfirmActionResult(
        success: result.success,
        total: result.total,
        title: title,
      );
    } catch (e) {
      nav.pop(); // ferme le loading
      rethrow;
    }
  }

  /// Affiche un [SnackBar] coloré correspondant au résultat.
  ///
  /// - Vert si tout a réussi
  /// - Orange si partiel
  /// - Rouge si échec total
  static void showResultSnackBar(
    BuildContext context,
    ConfirmActionResult result,
  ) {
    final messenger = ScaffoldMessenger.of(context);

    if (result.isComplete) {
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    '${result.title} : ${result.success}/${result.total} effectué'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else if (result.isPartial) {
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info, color: Colors.black, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    'Partiel : ${result.success}/${result.total} réussis'),
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
                child: Text("Aucune opération n'a abouti"),
              ),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
