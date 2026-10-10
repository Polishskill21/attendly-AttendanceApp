import 'package:attendly/data/database/database_provider.dart';

/// What startup has to do next, decided before any dialog is shown.
enum StartupDecision {
  /// A page reported a database error while the app was running.
  showReportedError,

  /// The user picked a database file in the database list.
  openSelectedDatabase,

  /// Fresh install: no database file exists yet.
  needsSetup,

  /// The year changed and the old database exists: ask about the rollover.
  askForRollover,

  /// Normal start: open the database configured in settings.json.
  openDefaultDatabase,
}

/// Runs the startup checks in the order the app relies on: the rollover check
/// first (it also creates settings.json), then the first-launch check.
Future<StartupDecision> decideStartup(
  DatabaseNotifier notifier, {
  bool hasReportedError = false,
  bool hasSelectedDatabase = false,
}) async {
  if (hasReportedError) return StartupDecision.showReportedError;
  if (hasSelectedDatabase) return StartupDecision.openSelectedDatabase;

  final rolloverNeeded = await notifier.checkForYearRollover();
  if (await notifier.needsInitialSetup()) return StartupDecision.needsSetup;

  return rolloverNeeded
      ? StartupDecision.askForRollover
      : StartupDecision.openDefaultDatabase;
}
