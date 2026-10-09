import 'package:attendly/data/local/config/exceptions/settings_exceptions.dart';
import 'package:attendly/frontend/pages/settings_page/settings_service.dart';
import 'package:attendly/frontend/pages/settings_page/settings_state.dart';
import 'package:attendly/global/app_logger.dart';
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
      AppLogger.i('Settings', 'Loaded settings: theme=${themeMode.name}, language=${locale.languageCode}');
      if (!mounted) return;
      state = SettingsState(
        themeMode: themeMode,
        locale:    locale,
        isLoaded:  true,
      );
    } on SettingsException catch (e, stackTrace) {
      AppLogger.e('Settings', 'Loading settings failed, showing critical settings screen', e, stackTrace);
      if (!mounted) return;
      state = SettingsState(error: e, isLoaded: true);
    } catch (e, stackTrace) {
      AppLogger.e('Settings', 'Unexpected error while loading settings', e, stackTrace);
      if (!mounted) return;
      state = SettingsState(
        error:    SettingsFileNotFoundException(),
        isLoaded: true,
      );
    }
  }
 
  void updateTheme(ThemeMode themeMode) {
    _service.setThemeMode(themeMode).catchError((Object e, StackTrace stackTrace) =>
        AppLogger.e('Settings', 'Saving theme failed', e, stackTrace));
    state = state.copyWith(themeMode: themeMode);
  }

  void updateLocale(Locale locale) {
    _service.setLocale(locale).catchError((Object e, StackTrace stackTrace) =>
        AppLogger.e('Settings', 'Saving language failed', e, stackTrace));
    state = state.copyWith(locale: locale);
  }
}
 
/// The single provider your whole app reads.
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(SettingsService()),
);
