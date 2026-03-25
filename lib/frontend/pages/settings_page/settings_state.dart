import 'package:attendly/backend/settings_exceptions.dart';
import 'package:flutter/material.dart';
 
class SettingsState {
  final ThemeMode themeMode;
  final Locale locale;
  final SettingsException? error;
  final bool isLoaded;
 
  const SettingsState({
    this.themeMode = ThemeMode.light,
    this.locale = const Locale('en'),
    this.error,
    this.isLoaded = false,
  });
 
  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    SettingsException? error,
    bool? isLoaded,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale:    locale    ?? this.locale,
      error:     error     ?? this.error,
      isLoaded:  isLoaded  ?? this.isLoaded,
    );
  }
}