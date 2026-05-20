import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const _storageKey = 'theme_mode_preference';
  final _storage = const FlutterSecureStorage();

  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final value = await _storage.read(key: _storageKey);
      if (value != null) {
        state = ThemeMode.values.firstWhere(
          (e) => e.name == value,
          orElse: () => ThemeMode.system,
        );
      }
    } catch (_) {
      // En cas d'erreur de lecture, rester sur system
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      await _storage.write(key: _storageKey, value: mode.name);
    } catch (_) {
      // Ignorer les erreurs d'écriture
    }
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

extension ThemeModeExtension on ThemeMode {
  bool get isDark => this == ThemeMode.dark;
}
