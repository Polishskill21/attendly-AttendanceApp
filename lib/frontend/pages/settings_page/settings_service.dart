import 'package:attendly/backend/manager/storage_manager.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:attendly/backend/manager/db_data_manager.dart';
import 'package:attendly/backend/settings_exceptions.dart';

class SettingsService {
  static const String _fileName = "settings.json";
  File? _file;
  Map<String, dynamic>? _settings;

  Future<void> _init() async {
    if (_settings != null) return;

    // NewYearHandler is now responsible for creating the file with defaults.
    // This ensures the file exists before SettingsService is used.
    await AnnualDataManager.create();
    final dir = await StorageManager.getExternalDirectory();
    if (dir == null) {
      throw SettingsDirectoryNotFoundException();
    }

    String settingFilePath = p.join(dir.path, _fileName);
    _file = File(settingFilePath);

    if (await _file!.exists()) {
      String content = await _file!.readAsString();
      if (content.isEmpty) {
        // If the file is empty, it's a corrupted state.
        throw SettingsFileNotFoundException();
      }
      _settings = jsonDecode(content);
    } else {
      // This case should ideally not be reached if NewYearHandler runs first.
      throw SettingsFileNotFoundException();
    }
  }

  Future<ThemeMode> getThemeMode() async {
    await _init();
    String? theme = _settings?['theme'];
    if (theme == null) throw SettingsKeyNotFoundException('theme');

    return theme == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setThemeMode(ThemeMode theme) async {
    await _init();
    _settings!['theme'] = theme == ThemeMode.dark ? 'dark' : 'light';
    await _saveSettings();
  }

  Future<Locale> getLocale() async {
    await _init();
    String? languageCode = _settings?['language'];
    if (languageCode == null) throw SettingsKeyNotFoundException('language');

    return Locale(languageCode);
  }

  Future<void> setLocale(Locale locale) async {
    await _init();
    _settings!['language'] = locale.languageCode;
    await _saveSettings();
  }

  Future<void> _saveSettings() async {
    if (_file == null || _settings == null) {
      throw Exception("Settings not initialized, cannot save.");
    }
    await _file!.writeAsString(jsonEncode(_settings));
  }
}
