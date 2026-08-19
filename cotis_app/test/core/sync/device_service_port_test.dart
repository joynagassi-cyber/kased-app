import 'package:flutter_test/flutter_test.dart';
import 'package:kased_app/core/sync/device_service_port.dart';

void main() {
  group('DeviceServicePort', () {
    group('RealDeviceService', () {
      test('returns a valid device ID', () async {
        final service = RealDeviceService();
        final id = await service.getDeviceId();
        expect(id, isNotNull);
        expect(id, isNotEmpty);
      });
    });

    group('FakeDeviceService', () {
      test('returns custom device ID', () async {
        final service = FakeDeviceService(deviceId: 'test-123');
        expect(await service.getDeviceId(), equals('test-123'));
      });

      test('returns default device ID when none specified', () async {
        final service = FakeDeviceService();
        expect(await service.getDeviceId(), equals('test-device-0000'));
      });
    });

    group('NoOpDeviceService', () {
      test('returns noop device ID', () async {
        final service = NoOpDeviceService();
        expect(await service.getDeviceId(), equals('noop-device'));
      });

      test('singleton pattern returns same instance', () {
        final a = NoOpDeviceService();
        final b = NoOpDeviceService();
        expect(a, equals(b));
      });
    });
  });
}
