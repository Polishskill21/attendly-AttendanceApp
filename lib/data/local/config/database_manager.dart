import 'dart:io';
import 'dart:convert';
import 'package:attendly/data/local/config/exceptions/db_exceptions.dart';
import 'package:attendly/data/local/config/i_database_manager.dart';
import 'package:attendly/data/local/config/storage_manager.dart';
import 'package:attendly/global/global_function_collection.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:attendly/data/local/config/database.dart';


class DatabaseManager implements IDatabaseManager {
  final String _fileName = "settings.json";
  
  AppDatabase? _db;
  File? _settingsFile;
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
    _settingsFile ??= await _initJsonFile();
    if (_settingsFile == null) return false;

    final data = await _getFileData(_settingsFile!);
    String yearFromFile = data['current_year'];
    _currentDbFile = File(data['file_path']);

    if (int.parse(yearFromFile) < getCurrentYearAsInt()) {
      _oldDbFile = _currentDbFile;
      return true;
    }

    return false;
  }

  @override
  Future<void> openDatabase({File? file, Future<void> Function()? onMigrationStarted}) async {
    if (file == null && _currentDbFile == null) {
      _settingsFile ??= await _initJsonFile();
      if (_settingsFile != null) {
        final data = await _getFileData(_settingsFile!);
        _currentDbFile = File(data['file_path']);
      }
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

    await _updateFile(_settingsFile, newDbPath, newYear);
    //debugPrint("updating file with $newDbFile and $newYear");
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
      final file = await _initJsonFile();
      if (file == null || !await file.exists()) return '{}';
      final content = await file.readAsString();
      if (content.trim().isEmpty) return '{}';
      final json = jsonDecode(content);
      return const JsonEncoder.withIndent('  ').convert(json);
    } catch (e) {
      return '{ "error": "${e.toString()}" }';
    }
  }

  // =======================================================================
  // PRIVATE JSON HELPERS
  // =======================================================================

  Future<File?> _initJsonFile() async {
    Directory? documentsDir = await StorageManager.getExternalDocumentsDir();
    if (documentsDir == null) return null;

    String settingFilePath = p.join(documentsDir.path, _fileName);
    File file = File(settingFilePath);
    Map<String, dynamic> data = {};

    if (await file.exists()) {
      String content = await file.readAsString();
      data = content.isNotEmpty ? jsonDecode(content) : {};
    }

    bool needsSave = false;

    if (!data.containsKey('file_path')) {
      String dbYear = yearToString(getCurrentYear());
      data['file_path'] = p.join(documentsDir.path, "db_$dbYear.db");
      needsSave = true;
    }

    if (!data.containsKey('current_year')) {
      data['current_year'] = yearToString(getCurrentYear());
      needsSave = true;
    }

    if (!data.containsKey('theme')) {
      data['theme'] = 'light';
      needsSave = true;
    }

    if (!data.containsKey('language')) {
      data['language'] = 'en';
      needsSave = true;
    }

    if (needsSave) {
      await file.writeAsString(jsonEncode(data));
    }

    return file;
  }

  Future<void> _updateFile(File? file, String dbPath, String newYear) async {
    if (file == null) return;
    final Map<String, dynamic> data = await _getFileData(file);
    
    data['current_year'] = newYear;
    data['file_path'] = dbPath;

    await file.writeAsString(jsonEncode(data));
  }

  Future<Map<String, dynamic>> _getFileData(File file) async {
    String fileString = await file.readAsString();
    if (fileString.isEmpty) return {};
    return jsonDecode(fileString);
  }
}