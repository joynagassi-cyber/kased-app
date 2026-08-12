import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kased_app/models/membre.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static AndroidFlutterLocalNotificationsPlugin? _androidPlugin;
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    
    try {
      tz.initializeTimeZones();

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      const settings = InitializationSettings(android: android, iOS: ios);
      
      // `initialize` peut retourner null sur certaines plateformes : seul un
      // `false` explicite est un échec. (Avant, un null désactivait
      // silencieusement TOUTES les notifications.)
      final result = await _plugin.initialize(settings: settings);
      if (result == false) {
        debugPrint('Échec de l\'initialisation des notifications');
        return;
      }

      _androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      // 🔴 CORRECTION 1 : définir le fuseau horaire LOCAL.
      // Sans `tz.setLocalLocation(...)`, tz.local reste UTC et les
      // notifications planifiées (anniversaires) partent à la mauvaise
      // heure sur l'appareil.
      if (_androidPlugin != null) {
        try {
          final timeZoneName = DateTime.now().timeZoneName.split(" ").last;
          if (timeZoneName.isNotEmpty) {
            tz.setLocalLocation(tz.getLocation(timeZoneName));
          }
        } catch (e) {
          debugPrint('Impossible de détecter le fuseau horaire: $e');
        }
      }

      // Android 13+ : permission runtime POST_NOTIFICATIONS obligatoire.
      await _androidPlugin?.requestNotificationsPermission();
      
      _initialized = true;
      debugPrint('Service de notifications initialisé avec succès');
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation des notifications: $e');
      // Ne pas relancer l'erreur pour éviter les crashes
    }
  }

  static int _notificationIdFor(String membreId) => membreId.hashCode.abs();

  static Future<void> planifierAnniversaire(Membre membre) async {
    if (!_initialized) {
      debugPrint('Service de notifications non initialisé');
      return;
    }
    
    final birth = membre.dateNaissance;
    if (birth == null) return;
    
    try {
      final now = DateTime.now();
      var prochainAnniversaire = DateTime(now.year, birth.month, birth.day, 8);
      if (prochainAnniversaire.isBefore(now)) {
        prochainAnniversaire = DateTime(now.year + 1, birth.month, birth.day, 8);
      }

      final age = prochainAnniversaire.year - birth.year;

      // 🔴 CORRECTION 2 : depuis Android 14 (targetSdk 34+), la permission
      // d'alarme EXACTE (SCHEDULE_EXACT_ALARM) est refusée par défaut pour
      // les nouvelles installations. Appeler zonedSchedule en mode
      // `exactAllowWhileIdle` sans cette permission lève une
      // PlatformException → AUCUNE notification n'est planifiée.
      // On bascule automatiquement sur le mode inexact si nécessaire
      // (la notification part avec un léger décalage, mais elle part).
      final canExact = await _androidPlugin?.canScheduleExactNotifications() ?? false;
      final scheduleMode = canExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      await _plugin.cancel(id: _notificationIdFor(membre.id));
      await _plugin.zonedSchedule(
        id: _notificationIdFor(membre.id),
        title: 'Anniversaire de ${membre.prenom} !',
        body: '${membre.prenom} fête ses $age ans aujourd\'hui.',
        scheduledDate: tz.TZDateTime.from(prochainAnniversaire, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'anniversaires',
            'Anniversaires',
            channelDescription: 'Notifications d\'anniversaire des membres',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: scheduleMode,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
    } catch (e) {
      debugPrint('Erreur lors de la planification d\'anniversaire: $e');
    }
  }

  static Future<void> annulerAnniversaire(String membreId) async {
    if (!_initialized) return;
    
    try {
      await _plugin.cancel(id: _notificationIdFor(membreId));
    } catch (e) {
      debugPrint('Erreur lors de l\'annulation d\'anniversaire: $e');
    }
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    String channelId = 'default',
    String? channelName = 'Général',
    int? id,
  }) async {
    if (!_initialized) return;
    
    try {
      // Ensure channel exists if not default
      if (_androidPlugin != null && channelId != 'default') {
        await _androidPlugin!.createNotificationChannel(
          AndroidNotificationChannel(
            channelId,
            channelName ?? 'Général',
            importance: Importance.high,
            enableLights: true,
          ),
        );
      }

      await _plugin.show(
        id: id ?? DateTime.now().hashCode.abs(),
        title: title,
        body: body,
        payload: null,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName ?? 'Général',
            channelDescription: 'Notifications générales',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentSound: true,
            badgeNumber: 1,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Erreur lors de l\'affichage de notification: $e');
    }
  }
}
