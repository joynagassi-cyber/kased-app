import 'package:kased_app/core/sync/device_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('getDeviceId returns a valid UUID format', () async {
      final id = await DeviceService.getDeviceId();
      expect(id.isNotEmpty, true);
      // Should be a UUID v4 format
      expect(id.length, 36); // UUID format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    });

    test('getDeviceId returns same ID on second call', () async {
      final id1 = await DeviceService.getDeviceId();
      final id2 = await DeviceService.getDeviceId();
      expect(id1, id2);
    });

    test('resetDeviceId generates a new ID', () async {
      final id1 = await DeviceService.getDeviceId();
      await DeviceService.resetDeviceId();
      final id2 = await DeviceService.getDeviceId();
      expect(id1, isNot(id2));
    });

    test('deviceId persists across calls', () async {
      const expectedId = 'test-device-persist';
      SharedPreferences.setMockInitialValues({
        'kased_device_id': expectedId,
      });
      final id = await DeviceService.getDeviceId();
      expect(id, expectedId);
    });
  });
}
