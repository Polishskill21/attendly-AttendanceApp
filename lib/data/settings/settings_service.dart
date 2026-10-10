import 'package:attendly/data/settings/settings_exceptions.dart';
import 'package:attendly/data/settings/settings_store.dart';
import 'package:flutter/material.dart';


class SettingsService {
  /// settings.json is created with defaults by [SettingsStore] if it does not exist yet,
  /// so the only remaining failure is an inaccessible storage directory.
  Future<Map<String, dynamic>> _load() async {
    final settings = await SettingsStore.load();
    if (settings == null) throw SettingsDirectoryNotFoundException();
    return settings;
  }

  Future<void> _save(String key, String value) async {
    final saved = await SettingsStore.update({key: value});
    if (!saved) throw SettingsDirectoryNotFoundException();
  }

  Future<ThemeMode> getThemeMode() async {
    final settings = await _load();
    return settings['theme'] == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setThemeMode(ThemeMode theme) {
    return _save('theme', theme == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<Locale> getLocale() async {
    final settings = await _load();
    return Locale(settings['language'] as String);
  }

  Future<void> setLocale(Locale locale) {
    return _save('language', locale.languageCode);
  }
}
