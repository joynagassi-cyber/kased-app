import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kased_app/models/membre.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    
    try {
      tz.initializeTimeZones();

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      const settings = InitializationSettings(android: android, iOS: ios);
      
      final result = await _plugin.initialize(settings: settings);
      if (result != true) {
        debugPrint('Échec de l\'initialisation des notifications');
        return;
      }

      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      
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
            channelDescription: 'Notifications d anniversaire des membres',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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
}
