import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'core/notifications/notification_service.dart';
import 'core/preferences/app_prefs.dart';
import 'core/realtime/realtime_service.dart';
import 'core/services/onesignal_service.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/update_provider.dart';
import 'widgets/onesignal_verification_gate.dart';
import 'widgets/update_dialog.dart';
import 'core/updates/app_update_model.dart';

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

  // Sentry est OPTIONNEL : si son initialisation échoue, l'app continue.
  // Sentry capture les erreurs Flutter/Dart + les crashs natifs.
  var sentryReady = false;
  try {
    await SentryFlutter.init(
      (options) {
        options
          ..dsn = const String.fromEnvironment(
            'SENTRY_DSN',
            defaultValue: '',
          )
          ..environment = const String.fromEnvironment(
            'FLUTTER_ENV',
            defaultValue: 'production',
          )
          ..release = 'kased@1.1.9+1'
          ..dist = '1.1.9+1'
          ..tracesSampleRate = 0.1
          ..beforeSend = (event, hint) {
            // Ne pas envoyer les erreurs de timeout OneSignal/Realtime
            final exception = event.exceptions?.firstOrNull?.toString() ?? '';
            if (exception.contains('timeout') ||
                exception.contains('TimeoutException')) {
              return null;
            }
            return event;
          };
      },
      appRunner: () async {
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
    );
    sentryReady = true;
  } catch (e) {
    debugPrint('[SENTRY] Initialisation échouée (ignorée, l\'app continue) : $e');
  }

  await runZonedGuarded(
    () async {},
    (Object error, StackTrace stack) {
      debugPrint('══ ZONE ERROR (non géré) ══');
      debugPrint('Exception : $error');
      if (firebaseReady) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
      if (sentryReady) {
        Sentry.captureException(error, stackTrace: stack);
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
      // L'app reprend : vérifier seulement si l'auth a changé (pas de refresh auto)
      // Le timer de 2 min gère déjà le refresh proactif
      // On force juste un re-read du storage pour gérer les cas où
      // le storage a été restauré (ex: après un crash AndroidKeyStore)
      ref.read(authProvider.notifier).checkPersistedAuth();
      ref.read(updateNotifierProvider.notifier).checkNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final updateState = ref.watch(updateNotifierProvider);

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
          child: UpdateCheckWrapper(
            updateState: updateState,
            child: OneSignalVerificationGate(child: child!),
          ),
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

/// Wrapper qui affiche le dialogue de mise à jour si nécessaire.
class UpdateCheckWrapper extends ConsumerWidget {
  final Widget child;
  final AsyncValue<AppUpdateCheckResult> updateState;

  const UpdateCheckWrapper({
    super.key,
    required this.child,
    required this.updateState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return updateState.when(
      data: (result) {
        if (result.hasUpdate && result.update != null) {
          // Afficher le dialogue de mise à jour
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              showDialog(
                context: context,
                barrierDismissible: !result.isRequired,
                builder: (ctx) => UpdateDialog(
                  update: result.update!,
                  forceUpdate: result.isRequired,
                ),
              );
            }
          });
        }
        return child;
      },
      loading: () => child,
      error: (_, __) => child,
    );
  }
}
