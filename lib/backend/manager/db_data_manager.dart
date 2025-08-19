import 'package:attendly/backend/helpers/db_result.dart';
import 'package:attendly/backend/global/global_func.dart';
import 'package:attendly/backend/manager/storage_manager.dart';
import 'package:flutter/material.dart';
import 'package:attendly/backend/dbLogic/db_create.dart';
import 'package:attendly/backend/manager/connection_manager.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AnnualDataManager {
  final String _fileName = "settings.json";
  final String _currentYear = yearToString(getCurrentYear()); //"2026";
  File? _file;
  late String _dbPath;

  AnnualDataManager._();

  static Future<AnnualDataManager> create() async{
    final instance = AnnualDataManager._();

    instance._file = await instance._initJsonFile();

    return instance;
  }

  Future<Database?> openSpecificDBInstance(String dbPath) async {
    bool dbExists = await File(dbPath).exists();
    if (!dbExists) {
      debugPrint("Selected database file does not exist at path: $dbPath");
      return null;
    }

    try {
      Database db = await DBConnectionManager.getInstance(dbPath);
      await DbCreation(db).init(); // Ensure tables are created if missing
      return db;
    } catch (e) {
      debugPrint("Error opening specific database: $e");
      return null;
    }
  }

  Future<Database?> createDBInstance({String? oldDbPath}) async{
    if(_file == null) return null;

    final dir = await StorageManager.getExternalDirectory();
    if(dir == null) return null;

    _dbPath = _setDBName(dir.path);
    
    Database db = await DBConnectionManager.getInstance(_dbPath);
    final creator = DbCreation(db);
    await creator.init();

    if (oldDbPath != null) {
      try{
        await creator.moveTableContent(oldDbPath, _dbPath);
      }
      catch(e){
        debugPrint("Failed to move table content: $e");
        rethrow; 
      }
    }
    
    await _updateFile(_file, _dbPath);

    return db;
  }


  Future<DbInitResult> returnDBInstance() async{
    if(_file == null) return DbInitResult(db: null);

    final Map<String,dynamic> data = await _getFileData(_file!);
    
    String yearFromFile = data['current_year'];
    String currentDBPath = data['file_path'];

    bool dbExists = await File(currentDBPath).exists();
    if(!dbExists) return DbInitResult(db: null);
   
    Database db = await DBConnectionManager.getInstance(currentDBPath); 
    await DbCreation(db).init();

    if(int.parse(yearFromFile) < int.parse(_currentYear)){
      return DbInitResult(db: db, yearChangeDetected: true, oldDbPath: currentDBPath);
    }

    return DbInitResult(db: db);
  }

  Future<String> getSettingsJsonContent() async {
    if (_file == null || !await _file!.exists()) {
      return "settings.json not found or not initialized.";
    }
    try {
      final content = await _file!.readAsString();
      // Pretty print JSON
      final jsonObject = jsonDecode(content);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(jsonObject);
    } catch (e) {
      return "Error reading settings.json: $e";
    }
  }

  Future<File?> _initJsonFile() async {
    Directory? documentsDir = await StorageManager.getExternalDirectory();
    if (documentsDir == null) return null;

    String settingFilePath = p.join(documentsDir.path, _fileName);
    File file = File(settingFilePath);

    Map<String, dynamic> data;

    if (await file.exists()) {
      String content = await file.readAsString();
      data = content.isNotEmpty ? jsonDecode(content) : {};
    } else {
      data = {};
    }

    bool needsSave = false;

    // Initialize DB path if not present
    if (!data.containsKey('file_path')) {
      _dbPath = _setDBName(documentsDir.path);
      data['file_path'] = _dbPath;
      needsSave = true;
    }

    // Initialize year if not present
    if (!data.containsKey('current_year')) {
      data['current_year'] = yearToString(getCurrentYear()); //"2026"; 
      needsSave = true;
    }

    // Initialize theme if not present
    if (!data.containsKey('theme')) {
      data['theme'] = 'light';
      needsSave = true;
    }

    // Initialize language if not present
    if (!data.containsKey('language')) {
      data['language'] = 'en';
      needsSave = true;
    }

    if (needsSave) {
      await file.writeAsString(jsonEncode(data));
    }

    return file;
  }

  String _setDBName(String directoryPath){

      String dbYear = yearToString(getCurrentYear());//"2026"; 

      String dbName = p.join(directoryPath, "db_$dbYear.db");
      return dbName;
  }

  Future<void> _updateFile(File? file, String dbPath) async{
    if(file == null) return;

    final Map<String,dynamic> data = await _getFileData(file);
    data['current_year'] = yearToString(getCurrentYear());//"2026";
    data['file_path'] = dbPath;

    await file.writeAsString(jsonEncode(data));
  }

  Future<Map<String, dynamic>> _getFileData(File file) async{

      String fileString = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(fileString);
      return data;
  }
}