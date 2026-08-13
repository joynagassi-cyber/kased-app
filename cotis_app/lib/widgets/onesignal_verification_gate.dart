import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../core/router/app_router.dart';
import '../core/services/onesignal_service.dart';
import '../providers/onesignal_provider.dart';

/// Gate de vérification de l'intégration OneSignal.
///
/// Monte un observateur sur l'abonnement push et affiche UNE FOIS le dialogue
/// « Your OneSignal SDK integration is complete! » lorsque le device reçoit un
/// vrai subscription ID serveur. Le bouton « Got it » est le SEUL endroit où
/// la permission de notification push est demandée.
///
/// L'observateur est conservé dans un champ State (référence forte) pour la
/// durée de vie du widget, comme recommandé par le guide OneSignal.
class OneSignalVerificationGate extends ConsumerStatefulWidget {
  const OneSignalVerificationGate({super.key, required this.child});

  /// Contenu de l'application (monté sous le MaterialApp, au-dessus du
  /// Navigator — le dialogue utilise la navigatorKey racine).
  final Widget child;

  @override
  ConsumerState<OneSignalVerificationGate> createState() =>
      _OneSignalVerificationGateState();
}

class _OneSignalVerificationGateState
    extends ConsumerState<OneSignalVerificationGate> {
  late final OneSignalService _oneSignal;
  OnPushSubscriptionChangeObserver? _observer;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    _oneSignal = ref.read(oneSignalServiceProvider);
    if (!_oneSignal.isInitialized) return;
    _setupSubscriptionObserver();
  }

  void _setupSubscriptionObserver() {
    // Référence forte conservée dans le State (le SDK garde les observateurs
    // en mémoire, mais on suit la recommandation du guide OneSignal).
    _observer = (OSPushSubscriptionChangedState changes) {
      _maybeShowDialog(changes.current.id);
    };
    _oneSignal.addPushSubscriptionObserver(_observer!);

    // L'ID peut déjà être assigné AVANT que l'observateur ne soit attaché :
    // évaluer la valeur courante immédiatement aussi.
    _maybeShowDialog(_oneSignal.pushSubscriptionId);
  }

  /// Un device est enregistré uniquement si l'ID est un vrai ID serveur :
  /// non vide et ne commençant pas par le placeholder local 'local-'.
  bool _isRegistered(String? id) =>
      id != null && id.isNotEmpty && !id.startsWith('local-');

  void _maybeShowDialog(String? subscriptionId) {
    if (_dialogShown || !_isRegistered(subscriptionId)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final navigator = rootNavigatorKey.currentState;
      if (navigator == null || !navigator.mounted) {
        // Navigator pas encore prêt — le prochain événement d'abonnement
        // (ou la prochaine évaluation) déclenchera un nouvel essai.
        return;
      }
      _dialogShown = true;
      _showIntegrationCompleteDialog(navigator.context);
    });
  }

  Future<void> _showIntegrationCompleteDialog(BuildContext navigatorContext) async {
    await showDialog<void>(
      context: navigatorContext,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Your OneSignal SDK integration is complete!'),
        content: const Text(
          'You can now send Push Notifications & In-App Messages through '
          'OneSignal. Tap below to enable push notifications.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              // Seul endroit où la permission push est demandée (guide OneSignal).
              await _oneSignal.requestPermission();
            },
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
