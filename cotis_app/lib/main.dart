import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'core/notifications/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase初始化
  await Firebase.initializeApp();

  // Passer les erreurs Flutter à Crashlytics
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  // Passer les erreurs non capturées à Crashlytics
  ui.PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await runZonedGuarded(
    () async {
      await initializeDateFormatting('fr_FR', null);

      // Activer Crashlytics en mode debug pour capturer les erreurs en développement
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

      try {
        await NotificationService.init().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('[WARN] NotificationService timeout — ignoré');
          },
        );
      } catch (e, stack) {
        debugPrint('[WARN] NotificationService.init() échoué : $e');
        FirebaseCrashlytics.instance.recordError(e, stack);
      }

      runApp(
        const ProviderScope(
          child: KasedApp(),
        ),
      );
    },
    (Object error, StackTrace stack) {
      debugPrint('══ ZONE ERROR (non géré) ══');
      debugPrint('Exception : $error');
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
  );
}

class KasedApp extends ConsumerWidget {
  const KasedApp({super.key});

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
          child: child!,
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
