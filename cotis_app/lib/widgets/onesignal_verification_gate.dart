import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/router/app_router.dart';
import '../core/services/onesignal_service.dart';
import '../providers/onesignal_provider.dart';

const _prefsKeyDialogShown = 'onesignal_dialog_shown_v1';

/// Gate de vérification de l'intégration OneSignal.
///
/// Monte un observateur sur l'abonnement push et affiche UNE FOIS le dialogue
/// « Your OneSignal SDK integration is complete! » lorsque le device reçoit un
/// vrai subscription ID serveur. Le bouton « Got it » est le SEUL endroit où
/// la permission de notification push est demandée.
///
/// L'état du dialogue est persisté dans SharedPreferences pour éviter
/// qu'il ne s'affiche à chaque démarrage.
///
/// ⚠️ IMPORTANT : si l'utilisateur a refusé la permission push ou n'a jamais
/// reçu de vrai push OneSignal, le dialogue ne s'affichera JAMAIS. Cela est
/// intentionnel : le dialogue est une vérification d'intégration, pas un
/// prompt de permission.
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
  BuildContext? _safeContext;

  @override
  void initState() {
    super.initState();
    _oneSignal = ref.read(oneSignalServiceProvider);
    _loadDialogState();
    if (!_oneSignal.isInitialized) return;
    _setupSubscriptionObserver();
  }

  Future<void> _loadDialogState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _dialogShown = prefs.getBool(_prefsKeyDialogShown) ?? false;
    } catch (_) {}
  }

  Future<void> _saveDialogState(bool shown) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKeyDialogShown, shown);
    } catch (_) {}
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
    // Ne jamais afficher si le dialogue a déjà été montré
    if (_dialogShown) return;

    // Ne pas afficher si l'app n'est pas initialisée
    if (!_oneSignal.isInitialized) return;

    // Ne pas afficher si le device n'a pas de vrai subscription ID serveur
    if (!_isRegistered(subscriptionId)) return;

    // Le dialogue a été montré → persist l'état et demander la permission
    _dialogShown = true;
    _saveDialogState(true);
    _showIntegrationCompleteDialogAndRequestPermission();
  }

  /// Demande la permission push ET ferme le dialogue en une seule étape.
  Future<void> _showIntegrationCompleteDialogAndRequestPermission() async {
    // Utiliser le contexte le plus sûr disponible :
    // 1. Le contexte de build stocké après le premier build
    // 2. Le contexte rootNavigatorKey si disponible
    final ctx = _safeContext ??
        rootNavigatorKey.currentContext;

    if (ctx == null) {
      debugPrint('[OneSignal] Cannot show dialog — no context available');
      return;
    }

    await showDialog<void>(
      context: ctx,
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
    // Stocker le contexte pour utilisation ultérieure par showDialog
    if (_safeContext == null) {
      _safeContext = context;
    }
    return widget.child;
  }
}
