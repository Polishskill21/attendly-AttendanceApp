import 'package:sqflite/sqflite.dart';

class DbInitResult {
  final Database? db;
  final bool yearChangeDetected;
  final String? oldDbPath;

  DbInitResult({this.db, this.yearChangeDetected = false, this.oldDbPath});
}