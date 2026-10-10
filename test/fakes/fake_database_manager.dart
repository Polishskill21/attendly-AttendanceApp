import 'dart:io';

import 'package:attendly/data/local/config/database.dart';
import 'package:attendly/data/local/config/exceptions/db_exceptions.dart';
import 'package:attendly/data/local/config/i_database_manager.dart';

import '../helpers/test_database.dart';

/// [IDatabaseManager] backed by an in-memory database, without touching
/// storage, permissions or settings.json.
///
/// Every call is recorded in [calls], so tests can check the order in which
/// startup asks its questions.
class FakeDatabaseManager implements IDatabaseManager {
  FakeDatabaseManager({
    this.rolloverNeeded = false,
    this.initialSetupNeeded = false,
    this.openError,
    this.defaultPath = '/storage/emulated/0/Documents/AttendlyDb/db_2026.db',
  });

  bool rolloverNeeded;
  bool initialSetupNeeded;

  /// Thrown by [openDatabase] while set.
  Object? openError;

  final String defaultPath;
  final List<String> calls = [];

  AppDatabase? _db;
  String? _currentPath;

  @override
  AppDatabase get databaseConnection {
    final db = _db;
    if (db == null) throw DatabaseFailedInit('Database not initialized!');
    return db;
  }

  @override
  String? get currentDbPath => _currentPath;

  @override
  int? get dbYear {
    final match = RegExp(r'db_(\d{4})').firstMatch(_currentPath ?? '');
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  @override
  Future<bool> checkForYearRollover() async {
    calls.add('checkForYearRollover');
    return rolloverNeeded;
  }

  @override
  Future<bool> needsInitialSetup() async {
    calls.add('needsInitialSetup');
    return initialSetupNeeded;
  }

  @override
  Future<void> openDatabase({File? file, Future<void> Function()? onMigrationStarted}) async {
    calls.add(file == null ? 'openDatabase' : 'openDatabase(${file.path})');
    if (openError != null) throw openError!;
    await closeDatabase();
    _db = createTestDatabase();
    _currentPath = file?.path ?? defaultPath;
  }

  @override
  Future<void> createDatabase() async {
    calls.add('createDatabase');
    await closeDatabase();
    _db = createTestDatabase();
    _currentPath = defaultPath;
  }

  @override
  Future<void> performYearRolloverAndOpen({Future<void> Function()? onMigrationStarted}) async {
    calls.add('performYearRolloverAndOpen');
    await createDatabase();
  }

  @override
  Future<void> closeDatabase() async {
    await _db?.close();
    _db = null;
  }

  @override
  Future<String> getSettingsJsonContent() async => '{}';
}
