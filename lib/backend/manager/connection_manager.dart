import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:attendly/backend/db_exceptions.dart';

class DBConnectionManager{
  static Database? _database;
  static String? filePath;
  static int? dbYear;

  //private constructor
  DBConnectionManager._();

  static Database? get db => _database;

  static Future<bool> isConnectionValid() async {
    if (_database == null) return false;
    
    try {
      await _database!.rawQuery('SELECT 1');
      return true;
    } catch (e) {
      debugPrint('Database connection validation failed: $e');
      return false;
    }
  }

  static Future<Database> getInstance(String dbPath) async{
    if (_database != null && _database!.isOpen) {
      await _database!.close();
    }
    
    try {
      _database = await openDatabase(
        dbPath, 
        version: 1, 
        onOpen: (db) async {
          await db.execute('PRAGMA foreign_keys = ON;');
        } 
      );
      filePath = dbPath;
      _setDbYear(dbPath);
      
      // Validate the connection after opening
      if (!await isConnectionValid()) {
        throw DbConnectionException('Failed to establish valid database connection');
      }
      
      return _database!;
    } catch (e) {
      debugPrint('Error opening database: $e');
      if (e is DbConnectionException) {
        rethrow;
      }
      throw DbConnectionException('Failed to open database: ${e.toString()}');
    }
  }

  static void _setDbYear(String path) {
    try {
      final baseName = p.basenameWithoutExtension(path); // e.g., db_2023
      final yearString = baseName.split('_').last;
      dbYear = int.tryParse(yearString);
    } catch (e) {
      debugPrint("Could not parse year from db path: $path. Error: $e");
      dbYear = DateTime.now().year; // Fallback to current year
    }
  }

  static Future<void> close() async{
    if (_database != null && _database!.isOpen) {
      await _database?.close();
    }
    _database = null;
    filePath = null;
    dbYear = null;
    debugPrint("closing");
  }
}