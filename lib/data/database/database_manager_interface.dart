import 'dart:io';
import 'package:attendly/data/database/app_database.dart';

abstract interface class IDatabaseManager {
  AppDatabase get databaseConnection;

  String? get currentDbPath;

  int? get dbYear;

  Future<bool> checkForYearRollover();

  /// True on a fresh install: the configured database does not exist and
  /// there are no other database files in the storage directory either.
  Future<bool> needsInitialSetup();

  Future<void> openDatabase({File? file, Future<void> Function()? onMigrationStarted});

  Future<void> createDatabase();

  Future<void> performYearRolloverAndOpen({Future<void> Function()? onMigrationStarted});

  Future<void> closeDatabase();

  Future<String> getSettingsJsonContent();
}