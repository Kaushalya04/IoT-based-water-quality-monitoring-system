import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _darkModeKey = 'darkMode';

  static final SharedPreferencesAsync _prefs =
      SharedPreferencesAsync();

  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier(ThemeMode.light);

  static bool get isDark =>
      themeMode.value == ThemeMode.dark;

  static Future<void> loadTheme() async {
    final bool savedDarkMode =
        await _prefs.getBool(_darkModeKey) ?? false;

    themeMode.value = savedDarkMode
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  static Future<void> setDarkMode(bool value) async {
    themeMode.value =
        value ? ThemeMode.dark : ThemeMode.light;

    await _prefs.setBool(
      _darkModeKey,
      value,
    );
  }
}