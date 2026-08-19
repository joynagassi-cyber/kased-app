import 'package:kased_app/core/sync/device_service.dart';

/// Port d'accès à l'identifiant de l'appareil.
///
/// Sépare la logique métier (obtenir un deviceId) de l'implémentation
/// (SharedPreferences + Uuid), permettant le mock en tests.
abstract class DeviceServicePort {
  /// Retourne l'identifiant unique de l'appareil courant.
  Future<String> getDeviceId();
}

/// Implémentation production qui délègue à [DeviceService].
class RealDeviceService implements DeviceServicePort {
  @override
  Future<String> getDeviceId() => DeviceService.getDeviceId();
}

/// Implémentation fake pour les tests unitaires.
class FakeDeviceService implements DeviceServicePort {
  final String deviceId;

  FakeDeviceService({this.deviceId = 'test-device-0000'});

  @override
  Future<String> getDeviceId() async => deviceId;
}

/// Implémentation no-op pour les tests E2E où le deviceId n'est pas nécessaire.
class NoOpDeviceService implements DeviceServicePort {
  static final NoOpDeviceService _instance = NoOpDeviceService._internal();
  factory NoOpDeviceService() => _instance;
  NoOpDeviceService._internal();

  @override
  Future<String> getDeviceId() async => 'noop-device';
}
