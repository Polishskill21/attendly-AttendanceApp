import 'dart:io';
import 'package:attendly/data/local/config/database.dart';
import 'package:attendly/data/local/config/database_manager.dart';
import 'package:attendly/data/local/config/exceptions/db_exceptions.dart';
import 'package:attendly/data/local/config/i_database_manager.dart';
import 'package:attendly/frontend/app_database_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
 
 
class DatabaseManagerNotifier extends StateNotifier<AppDatabaseState> {
  DatabaseManagerNotifier() : super(const AppDatabaseState());

  final IDatabaseManager _manager = DatabaseManager();
 
 
  /// Normal startup: check if we need a year rollover first.
  /// Returns true if a rollover is needed, false if not.
  Future<bool> checkForYearRollover() {
    return _manager.checkForYearRollover();
  }
 
  /// Opens the default DB (path comes from settings.json inside the manager).
  /// Marks state as ready when done.
  Future<void> openDatabase({File? file, Future<void> Function()? onMigrationStarted}) async {
    await _manager.openDatabase(file: file, onMigrationStarted: onMigrationStarted);
    state = AppDatabaseState(
      manager:           _manager,
      isTemporaryDb:     file != null, 
      showNewYearBanner: false,
      isReady:           true,
    );
  }
 
  /// Opens the default DB but keeps the "new year banner" visible.
  Future<void> openDatabaseWithBanner({Future<void> Function()? onMigrationStarted}) async {
    await _manager.openDatabase(onMigrationStarted: onMigrationStarted);
    state = AppDatabaseState(
      manager:           _manager,
      isTemporaryDb:     false,
      showNewYearBanner: true,
      isReady:           true,
    );
  }
 
  /// Creates a fresh DB for the current year.
  Future<void> createDatabase() async {
    await _manager.createDatabase();
    state = AppDatabaseState(
      manager:           _manager,
      isTemporaryDb:     false,
      showNewYearBanner: false,
      isReady:           true,
    );
  }
 
  /// Year rollover: migrates people from the old DB into a brand-new one.
  /// On success the banner stays hidden; on failure the caller shows a banner.
  Future<void> performYearRolloverAndOpen({Future<void> Function()? onMigrationStarted}) async {
    await _manager.performYearRolloverAndOpen(onMigrationStarted: onMigrationStarted);
    state = AppDatabaseState(
      manager:           _manager,
      isTemporaryDb:     false,
      showNewYearBanner: false,
      isReady:           true,
    );
  }
 
  /// Marks the new-year banner as dismissed without changing anything else.
  void setShowNewYearBanner(bool value) {
    if (state.showNewYearBanner == value) return;
    state = state.copyWith(showNewYearBanner: value);
  }
 
  /// Read the raw settings.json for the secret debug menu.
  Future<String> getSettingsJsonContent() {
    return _manager.getSettingsJsonContent();
  }
 
  /// Closes the underlying DB and resets state to "not ready".
  /// Called before switching to a different DB file.
  Future<void> closeDatabase() async {
    state = const AppDatabaseState(); // isReady = false immediately
    await _manager.closeDatabase();
  }

  void reportDatabaseError(Object error) {
    state = AppDatabaseState(dbError: error); // manager=null, isReady=false
  }
}
/// The provider you read / watch everywhere.
final databaseManagerProvider =
    StateNotifierProvider<DatabaseManagerNotifier, AppDatabaseState>(
  (ref) => DatabaseManagerNotifier(),
);
 


final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final state = ref.watch(databaseManagerProvider);
  
  if (state.manager == null || !state.isReady) {
    throw const DatabaseNotReadyException();
  }
  
  return state.manager!.databaseConnection;
});