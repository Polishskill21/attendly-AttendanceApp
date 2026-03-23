import 'package:attendly/data/local/config/i_database_manager.dart';

/// Immutable snapshot of what database is currently open.
/// Held inside [DatabaseManagerNotifier].
class AppDatabaseState {
  final IDatabaseManager? manager;
  final bool isTemporaryDb;
  final bool showNewYearBanner;
  final bool isReady;
  final Object? dbError;

  const AppDatabaseState({
    this.manager,
    this.isTemporaryDb = false,
    this.showNewYearBanner = false,
    this.isReady = false,
    this.dbError
  });

  // Convenience getters that delegate to the manager
  String? get currentDbPath => manager?.currentDbPath;
  int?    get dbYear         => manager?.dbYear;

  AppDatabaseState copyWith({
    IDatabaseManager? manager,
    bool? isTemporaryDb,
    bool? showNewYearBanner,
    bool? isReady,
    Object? dbError
  }) {
    return AppDatabaseState(
      manager:           manager           ?? this.manager,
      isTemporaryDb:     isTemporaryDb     ?? this.isTemporaryDb,
      showNewYearBanner: showNewYearBanner ?? this.showNewYearBanner,
      isReady:           isReady           ?? this.isReady,
      dbError:           dbError           ?? this.dbError
    );
  }
}