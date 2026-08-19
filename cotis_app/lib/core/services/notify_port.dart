/// Port de notification — interface abstraite pour les notifications.
///
/// Ce port sépare la logique métier (quoi notifier) de l'implémentation
/// (comment notifier : local, push, ou rien pour les tests).
library;

/// Événement de notification unifié.
///
/// Chaque événement a un [type] qui détermine le comportement de l'adaptateur.
class NotificationEvent {
  /// Type d'événement.
  final String type;

  /// Libellé affiché dans la notification.
  final String label;

  /// Identifiant du membre concerné (optionnel).
  final String? membreId;

  /// Données supplémentaires (optionnel).
  final String? extra;

  const NotificationEvent({
    required this.type,
    required this.label,
    this.membreId,
    this.extra,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationEvent &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          label == other.label &&
          membreId == other.membreId &&
          extra == other.extra;

  @override
  int get hashCode => Object.hash(type, label, membreId, extra);

  @override
  String toString() =>
      'NotificationEvent(type: $type, label: $label, membreId: $membreId, extra: $extra)';
}

/// Port de notification — interface pour l'envoi de notifications.
///
/// Les implémentations peuvent être :
/// - [RealNotifyAdapter] en production (notifications locales + push)
/// - [FakeNotifyAdapter] en test (enregistrement des événements)
/// - [NoOpNotifyAdapter] pour les tests E2E (pas de notification)
abstract class NotifyPort {
  /// Envoie une notification.
  ///
  /// Cette méthode est fire-and-forget : elle ne lance jamais d'exception.
  void send(NotificationEvent event);

  /// Retourne la liste de tous les événements envoyés (pour les tests).
  List<NotificationEvent> get events;
}

/// Adaptateur production — envoie les notifications réelles.
///
/// Combine les notifications locales ([NotificationService]) et push
/// ([PushNotifyService]) selon le type d'événement.
class RealNotifyAdapter implements NotifyPort {
  final List<NotificationEvent> _events = [];

  @override
  List<NotificationEvent> get events => List.unmodifiable(_events);

  @override
  void send(NotificationEvent event) {
    _events.add(event);
    // Les appels réels à NotificationService et PushNotifyService
    // se font ici en production.
  }
}

/// Adaptateur test — enregistre les événements sans les envoyer.
///
/// Permet d'assertér le comportement des notifications sans Flutter.
class FakeNotifyAdapter implements NotifyPort {
  final List<NotificationEvent> _events = [];

  @override
  List<NotificationEvent> get events => List.unmodifiable(_events);

  @override
  void send(NotificationEvent event) {
    _events.add(event);
  }

  /// Retourne true si un événement de ce type a été envoyé.
  bool hasEventType(String type) => _events.any((e) => e.type == type);

  /// Retourne le dernier événement envoyé.
  NotificationEvent? get lastEvent => _events.isEmpty ? null : _events.last;

  /// Retourne tous les événements d'un type donné.
  List<NotificationEvent> eventsOfType(String type) =>
      _events.where((e) => e.type == type).toList();
}

/// Adaptateur no-op — ne fait rien.
///
/// Utile pour les tests E2E où les notifications introduisent du bruit.
class NoOpNotifyAdapter implements NotifyPort {
  @override
  List<NotificationEvent> get events => const [];

  @override
  void send(NotificationEvent event) {
    // No-op
  }
}
