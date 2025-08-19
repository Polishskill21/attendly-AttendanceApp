import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import 'package:attendly/backend/db_exceptions.dart';
import 'dart:io';

abstract class DbBaseHandler {
  final Database? db;

  DbBaseHandler(this.db);

  Future<bool> validateConnection() async {
    try {
      // First check if database object exists
      if (db == null) {
        debugPrint('Database object is null');
        return false;
      }
      
      // Check if database is open and accessible
      if (!db!.isOpen) {
        debugPrint('Database is not open');
        return false;
      }
      
      // Check if the actual database file still exists
      final dbPath = db!.path;
      if (!await File(dbPath).exists()) {
        debugPrint('Database file was deleted: $dbPath');
        return false;
      }
      
      // Try a simple query to test if the database is still accessible
      await db!.rawQuery('SELECT 1');
      return true;
    } catch (e) {
      debugPrint('Database connection validation failed: $e');
      return false;
    }
  }

  Future<void> ensureConnection() async {
    if (!await validateConnection()) {
      throw DbConnectionException('Database connection lost or file deleted');
    }
  }
}
