import 'dart:async';
import 'dart:io';

import 'package:attendly/app/startup/startup_decision.dart';
import 'package:attendly/app/startup/startup_state.dart';
import 'package:attendly/core/logging/app_logger.dart';
import 'package:attendly/core/permissions/storage_permission_service.dart';
import 'package:attendly/data/database/database_provider.dart';
import 'package:attendly/data/database/database_state.dart';
import 'package:attendly/features/settings/providers/settings_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Decides what the app shows from launch until a database is open, and
/// handles every later database switch (picker, return to main, errors).
class AppStartupNotifier extends AsyncNotifier<StartupState> {
  static const String _tag = 'Startup';

  /// A migration screen that flashes for a few milliseconds looks like a
  /// glitch, so it stays visible at least this long.
  static const Duration _minimumMigrationDuration = Duration(seconds: 1);

  DateTime? _migrationStartedAt;

  /// Startup actions run one at a time. Coming back from the Android 11+
  /// "All files access" screen completes the permission request and resumes
  /// the app at the same moment; without this, both opened the database and
  /// the second open closed the first one in the middle of its migration.
  Future<void> _queue = Future.value();
  int _running = 0;

  Future<void> _serialized(Future<void> Function() action) {
    _running++;
    final result = _queue.then((_) => action()).whenComplete(() => _running--);
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  DatabaseNotifier get _database => ref.read(databaseProvider.notifier);
  StoragePermissionService get _permission => ref.read(storagePermissionServiceProvider);

  @override
  Future<StartupState> build() async {
    // A page reported a database error while the app was running.
    ref.listen<DatabaseState>(databaseProvider, (previous, next) {
      if (next.dbError != null && previous?.dbError == null) {
        AppLogger.w(_tag, 'Showing error screen for a reported database error');
        state = AsyncData(StartupFailed(next.dbError!));
      }
    });

    return _start();
  }

  // ── Permission ────────────────────────────────────────────────────────────

  Future<void> grantPermission() => _serialized(() async {
    final result = await _permission.request();
    if (result == PermissionState.granted) {
      state = const AsyncLoading();
      state = AsyncData(await _start());
    } else {
      state = AsyncData(StartupNeedsPermission(
        permanentlyDenied: result == PermissionState.permanentlyDenied,
      ));
    }
  });

  Future<void> openPermissionSettings() => _permission.openSettings();

  /// Called when the app comes back to the foreground, e.g. from the system
  /// settings where the user may have granted the permission.
  Future<void> recheckPermission() async {
    // A permission request or another startup step is already running.
    if (_running > 0) return;
    return _serialized(() async {
      if (state.valueOrNull is! StartupNeedsPermission) return;
      if (await _permission.status() != PermissionState.granted) return;

      AppLogger.i(_tag, 'Storage permission granted in the system settings');
      state = const AsyncLoading();
      state = AsyncData(await _start());
    });
  }

  // ── Database ──────────────────────────────────────────────────────────────

  /// Creates the database for the current year (first launch, or "create
  /// new" after a failure). On failure the previous screen stays and the
  /// error is rethrown so the view can show it.
  Future<void> createDatabase() => _serialized(() async {
    final previous = state;
    AppLogger.i(_tag, 'User requested a new database');
    state = const AsyncLoading<StartupState>().copyWithPrevious(previous);
    try {
      await _database.createDatabase();
      state = AsyncData(await _ready());
    } catch (e, stackTrace) {
      AppLogger.e(_tag, 'Creating a new database failed', e, stackTrace);
      state = previous;
      rethrow;
    }
  });

  Future<void> confirmRollover() => _serialized(() async {
    AppLogger.i(_tag, 'Year change: user chose to create the new database');
    await _onMigrationStarted();
    try {
      await _database.performYearRolloverAndOpen();
      state = AsyncData(await _ready());
    } catch (e, stackTrace) {
      AppLogger.e(_tag, 'Year rollover failed, asking user to retry', e, stackTrace);
      _migrationStartedAt = null;
      state = AsyncData(StartupRolloverFailed(e));
    }
  });

  /// Keeps the old year's database for now and shows the new-year banner.
  Future<void> declineRollover() => _serialized(() async {
    AppLogger.i(_tag, 'Year change: user stays on the old database');
    state = const AsyncLoading();
    try {
      await _database.openDatabaseWithBanner(onMigrationStarted: _onMigrationStarted);
      state = AsyncData(await _ready());
    } catch (e, stackTrace) {
      AppLogger.e(_tag, 'Opening the old database failed', e, stackTrace);
      state = AsyncData(StartupFailed(e));
    }
  });

  Future<void> retry() async {
    AppLogger.i(_tag, 'User tapped retry');
    final current = state.valueOrNull;
    final selectedDb = current is StartupFailed ? current.selectedDb : null;
    if (selectedDb != null) return openDatabaseFile(selectedDb);
    return openDefault();
  }

  /// Opens the database configured in settings.json, running the year and
  /// first-launch checks again.
  Future<void> openDefault() => _serialized(() async {
    AppLogger.i(_tag, 'Opening the default database');
    state = const AsyncLoading();
    await _closeQuietly();
    state = AsyncData(await _openDefault());
  });

  /// Switches to a database picked in the database list.
  Future<void> openDatabaseFile(File file) => _serialized(() async {
    AppLogger.i(_tag, 'Startup: switching to selected database ${file.path}');
    state = const AsyncLoading();
    try {
      await _database.closeDatabase();
      await _database.openDatabase(file: file, onMigrationStarted: _onMigrationStarted);
      state = AsyncData(await _ready());
    } catch (e, stackTrace) {
      AppLogger.e(_tag, 'Opening ${file.path} failed, showing error screen', e, stackTrace);
      _migrationStartedAt = null;
      state = AsyncData(StartupFailed(e, selectedDb: file));
    }
  });

  // ── Internals ─────────────────────────────────────────────────────────────

  Future<StartupState> _start() async {
    final permission = await _permission.status();
    if (permission != PermissionState.granted) {
      AppLogger.w(_tag, 'Storage permission ${permission.name}, showing permission screen');
      return StartupNeedsPermission(
        permanentlyDenied: permission == PermissionState.permanentlyDenied,
      );
    }

    // settings.json lives in the storage folder, so it can only be read now.
    unawaited(ref.read(settingsProvider.notifier).load());
    return _openDefault();
  }

  Future<StartupState> _openDefault() async {
    try {
      switch (await decideStartup(_database)) {
        case StartupDecision.needsSetup:
          AppLogger.i(_tag, 'Startup: no database yet, showing setup screen');
          return const StartupNeedsSetup();
        case StartupDecision.askForRollover:
          return const StartupRolloverAvailable();
        case StartupDecision.openDefaultDatabase:
          AppLogger.i(_tag, 'Startup: opening default database');
          await _database.openDatabase(onMigrationStarted: _onMigrationStarted);
          return await _ready();
      }
    } catch (e, stackTrace) {
      AppLogger.e(_tag, 'Startup failed, showing error screen', e, stackTrace);
      _migrationStartedAt = null;
      return StartupFailed(e);
    }
  }

  Future<void> _onMigrationStarted() async {
    _migrationStartedAt = DateTime.now();
    state = const AsyncData(StartupMigrating());
  }

  Future<StartupState> _ready() async {
    final startedAt = _migrationStartedAt;
    _migrationStartedAt = null;
    if (startedAt != null) {
      final remaining = _minimumMigrationDuration - DateTime.now().difference(startedAt);
      if (remaining > Duration.zero) await Future.delayed(remaining);
    }
    return const StartupReady();
  }

  Future<void> _closeQuietly() async {
    try {
      await _database.closeDatabase();
    } catch (e, stackTrace) {
      AppLogger.e(_tag, 'Closing the database before reopening failed', e, stackTrace);
    }
  }
}

final appStartupProvider =
    AsyncNotifierProvider<AppStartupNotifier, StartupState>(AppStartupNotifier.new);
