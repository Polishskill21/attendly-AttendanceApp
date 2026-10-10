import 'package:attendly/data/database/database_manager_interface.dart';

/// Immutable snapshot of what database is currently open.
/// Held inside [DatabaseNotifier].
class DatabaseState {
  final DatabaseManagerInterface? manager;
  final bool isTemporaryDb;
  final bool showNewYearBanner;
  final bool isReady;
  final Object? dbError;

  const DatabaseState({
    this.manager,
    this.isTemporaryDb = false,
    this.showNewYearBanner = false,
    this.isReady = false,
    this.dbError
  });

  // Convenience getters that delegate to the manager
  String? get currentDbPath => manager?.currentDbPath;
  int?    get dbYear         => manager?.dbYear;

  DatabaseState copyWith({
    DatabaseManagerInterface? manager,
    bool? isTemporaryDb,
    bool? showNewYearBanner,
    bool? isReady,
    Object? dbError
  }) {
    return DatabaseState(
      manager:           manager           ?? this.manager,
      isTemporaryDb:     isTemporaryDb     ?? this.isTemporaryDb,
      showNewYearBanner: showNewYearBanner ?? this.showNewYearBanner,
      isReady:           isReady           ?? this.isReady,
      dbError:           dbError           ?? this.dbError
    );
  }
}