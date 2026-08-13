import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/onesignal_service.dart';

/// Fournit l'accès au wrapper centralisé OneSignal.
///
/// Provider simple (pas de codegen) : le service est un singleton, ce
/// provider sert uniquement de point d'accès idiomatique Riverpod.
final oneSignalServiceProvider = Provider<OneSignalService>((ref) {
  return OneSignalService.instance;
});
