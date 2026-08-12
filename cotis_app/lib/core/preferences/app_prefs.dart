import 'package:shared_preferences/shared_preferences.dart';

abstract class AppPrefsKey {
  static const String hasSeenOnboarding = 'has_seen_onboarding_v1';
}

class AppPrefs {
  AppPrefs._();

  static SharedPreferences? _cache;

  static Future<void> init() async {
    _cache ??= await SharedPreferences.getInstance();
  }

  static SharedPreferences _check() {
    if (_cache == null) throw StateError('AppPrefs.init() must be called first');
    return _cache!;
  }

  static Future<bool> markOnboardingSeen() async {
    return _check().setBool(AppPrefsKey.hasSeenOnboarding, true);
  }

  static bool get hasSeenOnboarding =>
      _check().getBool(AppPrefsKey.hasSeenOnboarding) ?? false;
}