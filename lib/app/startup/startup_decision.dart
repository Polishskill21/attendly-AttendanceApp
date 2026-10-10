import 'package:attendly/data/database/database_provider.dart';

/// What a normal start has to do next, decided before any screen is shown.
enum StartupDecision {
  /// Fresh install: no database file exists yet.
  needsSetup,

  /// The year changed and the old database exists: ask about the rollover.
  askForRollover,

  /// Normal start: open the database configured in settings.json.
  openDefaultDatabase,
}

/// Runs the startup checks in the order the app relies on: the rollover check
/// first (it also creates settings.json), then the first-launch check.
Future<StartupDecision> decideStartup(DatabaseNotifier notifier) async {
  final rolloverNeeded = await notifier.checkForYearRollover();
  if (await notifier.needsInitialSetup()) return StartupDecision.needsSetup;

  return rolloverNeeded
      ? StartupDecision.askForRollover
      : StartupDecision.openDefaultDatabase;
}
