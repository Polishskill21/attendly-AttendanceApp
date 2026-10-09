import 'dart:convert';
import 'dart:io';
import 'package:attendly/data/local/config/storage_manager.dart';
import 'package:attendly/global/app_logger.dart';
import 'package:attendly/global/global_function_collection.dart';
import 'package:path/path.dart' as p;

/// Single owner of settings.json.
///
/// Both the theme/language settings and the database manager read and write
/// this file, often at the same time during app start. All access goes
/// through a queue so reads/writes never interleave, and missing files or
/// keys are filled with defaults instead of throwing.
class SettingsStore {
  static const String fileName = "settings.json";
  static const String _tag = "Settings";

  static Future<void> _queue = Future.value();

  static Future<T> _synchronized<T>(Future<T> Function() action) {
    final result = _queue.then((_) => action());
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  /// Returns the settings, creating settings.json with defaults if needed.
  /// Returns null if the storage directory is not accessible.
  static Future<Map<String, dynamic>?> load() {
    return _synchronized(() async {
      final dir = await StorageManager.getExternalDocumentsDir();
      if (dir == null) {
        AppLogger.e(_tag, "Cannot load settings.json: storage directory not accessible");
        return null;
      }
      return _readWithDefaults(dir);
    });
  }

  /// Merges [values] into settings.json, keeping all other keys as they are on disk.
  /// Returns false if the storage directory is not accessible.
  static Future<bool> update(Map<String, dynamic> values) {
    return _synchronized(() async {
      final dir = await StorageManager.getExternalDocumentsDir();
      if (dir == null) {
        AppLogger.e(_tag, "Cannot save $values: storage directory not accessible");
        return false;
      }
      final data = await _readWithDefaults(dir);
      data.addAll(values);
      AppLogger.i(_tag, "Updating settings.json: $values");
      await _fileIn(dir).writeAsString(jsonEncode(data));
      return true;
    });
  }

  static File _fileIn(Directory dir) => File(p.join(dir.path, fileName));

  static Future<Map<String, dynamic>> _readWithDefaults(Directory dir) async {
    final file = _fileIn(dir);
    Map<String, dynamic> data = {};

    if (await file.exists()) {
      final content = await file.readAsString();
      if (content.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(content);
          if (decoded is Map<String, dynamic>) data = decoded;
        } on FormatException catch (e, stackTrace) {
          AppLogger.e(_tag, "settings.json is corrupted, restoring defaults. Content was: $content", e, stackTrace);
        }
      }
    }

    final String currentYear = yearToString(getCurrentYear());
    final defaults = <String, dynamic>{
      'file_path':    p.join(dir.path, "db_$currentYear.db"),
      'current_year': currentYear,
      'theme':        'light',
      'language':     'en',
    };

    final fileExists = await file.exists();
    final filledKeys = <String>[];
    defaults.forEach((key, value) {
      if (data[key] == null) {
        data[key] = value;
        filledKeys.add(key);
      }
    });

    if (!fileExists || filledKeys.isNotEmpty) {
      if (!fileExists) {
        AppLogger.i(_tag, "settings.json not found, creating it at ${file.path}");
      } else {
        AppLogger.w(_tag, "settings.json was missing keys $filledKeys, filled with defaults");
      }
      await file.writeAsString(jsonEncode(data));
    }
    return data;
  }
}
