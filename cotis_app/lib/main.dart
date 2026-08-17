import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'core/notifications/notification_service.dart';
import 'core/preferences/app_prefs.dart';
import 'core/realtime/realtime_service.dart';
import 'core/services/onesignal_service.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'widgets/onesignal_verification_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser les préférences légères AVANT toute utilisation
  await AppPrefs.init();

  // Firebase est OPTIONNEL au démarrage : si son initialisation échoue
  // (config absente/invalide, Google Play Services indisponible...),
  // l'application doit quand même se lancer. Un échec ici ne doit JAMAIS
  // provoquer un crash bloquant au lancement.
  var firebaseReady = false;
  try {
    await Firebase.initializeApp();
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    firebaseReady = true;
  } catch (e) {
    debugPrint('[FIREBASE] Initialisation échouée (ignorée, l\'app continue) : $e');
  }

  // Passer les erreurs Flutter à Crashlytics (si Firebase est disponible)
  if (firebaseReady) {
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    // Passer les erreurs non capturées à Crashlytics
    ui.PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  await runZonedGuarded(
    () async {
      await initializeDateFormatting('fr_FR', null);

      try {
        await NotificationService.init().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('[WARN] NotificationService timeout — ignoré');
          },
        );
      } catch (e, stack) {
        debugPrint('[WARN] NotificationService.init() échoué : $e');
        if (firebaseReady) {
          FirebaseCrashlytics.instance.recordError(e, stack);
        }
      }

      // OneSignal (push multi-utilisateurs) — initialisation non bloquante :
      // un échec ne doit jamais empêcher le démarrage de l'application.
      try {
        await OneSignalService.instance.initialize().timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                debugPrint('[WARN] OneSignal initialize timeout — ignoré');
              },
            );
      } catch (e, stack) {
        debugPrint('[ONESIGNAL] Initialisation échouée (ignorée) : $e');
        if (firebaseReady) {
          FirebaseCrashlytics.instance.recordError(e, stack);
        }
      }

      // Realtime (Socket.IO) — initialisation non bloquante :
      // un échec ne doit jamais empêcher le démarrage de l'application.
      try {
        RealtimeService().connect().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('[WARN] RealtimeService.connect timeout — ignoré');
          },
        );
      } catch (e, stack) {
        debugPrint('[REALTIME] Initialisation échouée (ignorée) : $e');
        if (firebaseReady) {
          FirebaseCrashlytics.instance.recordError(e, stack);
        }
      }

      runApp(
        ProviderScope(
          overrides: [
            // Initialiser le coordinateur de notifications
            // Ce provider est utilisé par NotificationCoordinator.init()
          ],
          child: const KasedApp(),
        ),
      );
    },
    (Object error, StackTrace stack) {
      debugPrint('══ ZONE ERROR (non géré) ══');
      debugPrint('Exception : $error');
      if (firebaseReady) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
    },
  );
}

class KasedApp extends ConsumerStatefulWidget {
  const KasedApp({super.key});

  @override
  ConsumerState<KasedApp> createState() => _KasedAppState();
}

class _KasedAppState extends ConsumerState<KasedApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // L'app reprend : forcer une vérification de l'auth pour récupérer
      // la session si elle a été perdue (ex: secure storage réinitialisé).
      ref.read(authProvider.notifier).checkPersistedAuth();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Kased',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: const _BouncingScrollBehavior(),
          child: OneSignalVerificationGate(child: child!),
        );
      },
    );
  }
}

class _BouncingScrollBehavior extends ScrollBehavior {
  const _BouncingScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}
