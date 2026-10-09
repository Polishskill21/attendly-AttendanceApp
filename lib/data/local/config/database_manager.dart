import 'dart:io';
import 'dart:convert';
import 'package:attendly/data/local/config/exceptions/db_exceptions.dart';
import 'package:attendly/data/local/config/i_database_manager.dart';
import 'package:attendly/data/local/config/settings_store.dart';
import 'package:attendly/data/local/config/storage_manager.dart';
import 'package:attendly/global/global_function_collection.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:attendly/data/local/config/database.dart';


class DatabaseManager implements IDatabaseManager {
  AppDatabase? _db;
  File? _oldDbFile;
  File? _currentDbFile;

  @override
  String? get currentDbPath => _currentDbFile?.path;

  @override
  int? get dbYear {
    final path = currentDbPath;
    if (path == null) return null;

    final match = RegExp(r'db_(\d{4})').firstMatch(path);
    final yearStr = match?.group(1);

    return yearStr != null ? int.tryParse(yearStr) : null;
  }

  @override
  AppDatabase get databaseConnection {
    if (_db == null) {
      throw DatabaseFailedInit("Database not initialized!");
    }
    return _db!;
  }

  @override
  Future<bool> checkForYearRollover() async {
    final data = await _loadSettings();
    _currentDbFile = File(data['file_path']);
    final yearFromFile = int.tryParse(data['current_year'].toString()) ?? getCurrentYearAsInt();

    // A rollover only makes sense if there is an old database to carry people over from.
    if (yearFromFile < getCurrentYearAsInt() && await _currentDbFile!.exists()) {
      _oldDbFile = _currentDbFile;
      return true;
    }

    return false;
  }

  @override
  Future<bool> needsInitialSetup() async {
    if (_currentDbFile == null) {
      final data = await _loadSettings();
      _currentDbFile = File(data['file_path']);
    }
    if (await _currentDbFile!.exists()) return false;

    final dbFiles = await StorageManager.listDbFiles();
    return dbFiles.isEmpty;
  }

  @override
  Future<void> openDatabase({File? file, Future<void> Function()? onMigrationStarted}) async {
    if (file == null && _currentDbFile == null) {
      final data = await _loadSettings();
      _currentDbFile = File(data['file_path']);
    }

    File targetFile = file ?? _currentDbFile!;

    if (!await targetFile.exists()) {
      debugPrint("Failed to open db because it does not exist");
      throw FileSystemException(
        "Database file does not exist. It must be created explicitly.",
        targetFile.path,
      );
    }

    debugPrint("Trying to open ${targetFile.path}");

    await closeDatabase();
    _currentDbFile = targetFile;
    _db = AppDatabase(AppDatabase.openConnection(targetFile), onMigrationStarted: onMigrationStarted);
    debugPrint("Opened Database");
    await _db!.forceOpen();
  }

  @override
  Future<void> createDatabase() async {
    final dir = await StorageManager.getExternalDocumentsDir();
    if (dir == null) throw Exception("Could not access external storage");

    String newYear = yearToString(getCurrentYear());
    String newDbPath = p.join(dir.path, "db_$newYear.db");
    File newDbFile = File(newDbPath);

    await closeDatabase();

    _db = AppDatabase(AppDatabase.openConnection(newDbFile));
    await _db!.forceOpen();

    await SettingsStore.update({'current_year': newYear, 'file_path': newDbPath});
    _currentDbFile = newDbFile;
    debugPrint("created new db");
  }

  @override
  Future<void> performYearRolloverAndOpen({Future<void> Function()? onMigrationStarted}) async {

    if (_oldDbFile == null) {
      debugPrint("No old database found to rollover from.");
      await createDatabase();
      return;
    }

    debugPrint("Pre-migrating old database to ensure schemas match...");
    final tempOldDb = AppDatabase(AppDatabase.openConnection(_oldDbFile!), onMigrationStarted: onMigrationStarted);

    await tempOldDb.forceOpen();
    await tempOldDb.close();
    debugPrint("Old database migration complete.");

    await createDatabase();

    debugPrint("Performing a copy");
    await _db!.copyPersonDirFromOldDatabase(_oldDbFile!.path);
  }

  @override
  Future<void> closeDatabase() async {
    if (_db != null) {
      debugPrint("Closing Db");
      await _db!.close();
      _db = null;
    }
  }

  @override
  Future<String> getSettingsJsonContent() async {
    try {
      final json = await SettingsStore.load();
      if (json == null) return '{}';
      return const JsonEncoder.withIndent('  ').convert(json);
    } catch (e) {
      return '{ "error": "${e.toString()}" }';
    }
  }

  // =======================================================================
  // PRIVATE JSON HELPERS
  // =======================================================================

  /// settings.json is created with defaults if it does not exist yet.
  Future<Map<String, dynamic>> _loadSettings() async {
    final data = await SettingsStore.load();
    if (data == null) {
      throw DatabaseFailedInit("Could not access the storage directory. Please check app permissions.");
    }
    return data;
  }
}
