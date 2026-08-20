/// Événement temps réel reçu depuis InsForge.
///
/// Représente un changement sur une entité spécifique (membre, culte,
/// cotisation) reçu via le canal Socket.IO.
class RealtimeEvent {
  /// Type d'opération : create, update, delete
  final String action;

  /// Nom de la table : membres, cultes, cotisations
  final String table;

  /// ID de l'entité concernée
  final String id;

  /// Données complètes de l'entité (pour les actions create/update)
  final Map<String, dynamic>? data;

  const RealtimeEvent({
    required this.action,
    required this.table,
    required this.id,
    this.data,
  });

  factory RealtimeEvent.fromJson(Map<String, dynamic> json) {
    return RealtimeEvent(
      action: json['action'] as String? ?? 'update',
      table: json['table'] as String? ?? 'unknown',
      id: json['id'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  RealtimeEvent copyWith({
    String? action,
    String? table,
    String? id,
    Map<String, dynamic>? data,
  }) {
    return RealtimeEvent(
      action: action ?? this.action,
      table: table ?? this.table,
      id: id ?? this.id,
      data: data ?? this.data,
    );
  }
}

/// Méta-données de présence d'un appareil connecté.
class DevicePresence {
  final String deviceId;
  final String userEmail;
  final DateTime connectedAt;
  final DateTime lastActivity;
  final String platform;

  const DevicePresence({
    required this.deviceId,
    required this.userEmail,
    required this.connectedAt,
    required this.lastActivity,
    this.platform = 'unknown',
  });

  bool get isOnline =>
      DateTime.now().difference(lastActivity).inSeconds < 60;

  DevicePresence copyWith({
    String? deviceId,
    String? userEmail,
    DateTime? connectedAt,
    DateTime? lastActivity,
    String? platform,
  }) {
    return DevicePresence(
      deviceId: deviceId ?? this.deviceId,
      userEmail: userEmail ?? this.userEmail,
      connectedAt: connectedAt ?? this.connectedAt,
      lastActivity: lastActivity ?? this.lastActivity,
      platform: platform ?? this.platform,
    );
  }
}

/// État de présence global (multi-utilisateurs).
class PresenceState {
  final Map<String, DevicePresence> devices;
  final int totalOnline;
  final int totalUsers;

  const PresenceState({
    this.devices = const {},
    this.totalOnline = 0,
    this.totalUsers = 0,
  });

  PresenceState copyWith({
    Map<String, DevicePresence>? devices,
    int? totalOnline,
    int? totalUsers,
  }) {
    return PresenceState(
      devices: devices ?? this.devices,
      totalOnline: totalOnline ?? this.totalOnline,
      totalUsers: totalUsers ?? this.totalUsers,
    );
  }
}
