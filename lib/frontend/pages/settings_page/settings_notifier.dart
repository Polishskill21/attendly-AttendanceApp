import 'package:attendly/backend/settings_exceptions.dart';
import 'package:attendly/frontend/pages/settings_page/settings_service.dart';
import 'package:attendly/frontend/pages/settings_page/settings_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsService _service;
 
  SettingsNotifier(this._service) : super(const SettingsState()) {
    _loadSettings();
  }
 
  Future<void> _loadSettings() async {
    try {
      final themeMode = await _service.getThemeMode();
      final locale    = await _service.getLocale();
      if (!mounted) return;
      state = SettingsState(
        themeMode: themeMode,
        locale:    locale,
        isLoaded:  true,
      );
    } on SettingsException catch (e) {
      if (!mounted) return;
      state = SettingsState(error: e, isLoaded: true);
    } catch (_) {
      if (!mounted) return;
      state = SettingsState(
        error:    SettingsFileNotFoundException(),
        isLoaded: true,
      );
    }
  }
 
  void updateTheme(ThemeMode themeMode) {
    _service.setThemeMode(themeMode);
    state = state.copyWith(themeMode: themeMode);
  }
 
  void updateLocale(Locale locale) {
    _service.setLocale(locale);
    state = state.copyWith(locale: locale);
  }
}
 
/// The single provider your whole app reads.
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(SettingsService()),
);
