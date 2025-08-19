import 'package:flutter/material.dart';
import 'package:attendly/frontend/pages/settings_page/settings_service.dart';
import 'package:attendly/backend/settings_exceptions.dart';

class SettingsProvider with ChangeNotifier {
  final SettingsService _settingsService;
  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('en');
  SettingsException? _error;

  SettingsProvider(this._settingsService) {
    _loadSettings();
  }

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  SettingsException? get error => _error;

  Future<void> _loadSettings() async {
    try {
      _themeMode = await _settingsService.getThemeMode();
      _locale = await _settingsService.getLocale();
    } on SettingsException catch (e) {
      _error = e;
    } catch (e) {
      // Catch any other unexpected error during init
      _error = SettingsFileNotFoundException();
    } finally {
      notifyListeners();
    }
  }

  void updateTheme(ThemeMode themeMode) {
    _themeMode = themeMode;
    _settingsService.setThemeMode(themeMode);
    notifyListeners();
  }

  void updateLocale(Locale locale) {
    _locale = locale;
    _settingsService.setLocale(locale);
    notifyListeners();
  }
}
