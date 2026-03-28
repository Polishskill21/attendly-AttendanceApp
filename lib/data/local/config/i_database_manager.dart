import 'dart:io';
import 'package:attendly/data/local/config/database.dart';

abstract interface class IDatabaseManager {
  AppDatabase get databaseConnection;

  String? get currentDbPath;

  int? get dbYear;

  Future<bool> checkForYearRollover();

  Future<void> openDatabase({File? file, Future<void> Function()? onMigrationStarted});

  Future<void> createDatabase();

  Future<void> performYearRolloverAndOpen({Future<void> Function()? onMigrationStarted});

  Future<void> closeDatabase();

  Future<String> getSettingsJsonContent();
}