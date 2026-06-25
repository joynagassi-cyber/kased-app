import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  static const _key = 'kased_device_id';

  static Future<String> getDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? id = prefs.getString(_key);
      if (id == null) {
        id = const Uuid().v4();
        await prefs.setString(_key, id);
      }
      return id;
    } catch (_) {
      return 'test-device-${const Uuid().v4()}';
    }
  }
}
