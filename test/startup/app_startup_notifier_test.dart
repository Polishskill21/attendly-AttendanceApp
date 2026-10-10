import 'dart:io';

import 'package:attendly/app/startup/app_startup_notifier.dart';
import 'package:attendly/app/startup/startup_state.dart';
import 'package:attendly/core/permissions/storage_permission_service.dart';
import 'package:attendly/data/database/database_provider.dart';
import 'package:attendly/data/settings/settings_service.dart';
import 'package:attendly/features/settings/providers/settings_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_database_manager.dart';
import '../fakes/fake_storage_permission_service.dart';

class _FakeSettingsService extends SettingsService {
  @override
  Future<ThemeMode> getThemeMode() async => ThemeMode.light;

  @override
  Future<Locale> getLocale() async => const Locale('en');
}

void main() {
  late FakeDatabaseManager manager;
  late FakeStoragePermissionService permission;
  late ProviderContainer container;

  setUp(() {
    manager = FakeDatabaseManager();
    permission = FakeStoragePermissionService();
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWith((ref) => DatabaseNotifier(manager)),
      storagePermissionServiceProvider.overrideWithValue(permission),
      settingsProvider.overrideWith((ref) => SettingsNotifier(_FakeSettingsService())),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await manager.closeDatabase();
  });

  AppStartupNotifier notifier() => container.read(appStartupProvider.notifier);
  Future<StartupState> started() => container.read(appStartupProvider.future);
  StartupState current() => container.read(appStartupProvider).requireValue;

  group('permission', () {
    test('a denied permission shows the permission screen and opens nothing', () async {
      permission.current = PermissionState.denied;

      final state = await started();

      expect(state, isA<StartupNeedsPermission>()
          .having((s) => s.permanentlyDenied, 'permanentlyDenied', isFalse));
      expect(manager.calls, isEmpty);
    });

    test('a permanently denied permission asks for the system settings', () async {
      permission.current = PermissionState.permanentlyDenied;

      final state = await started();

      expect(state, isA<StartupNeedsPermission>()
          .having((s) => s.permanentlyDenied, 'permanentlyDenied', isTrue));
    });

    test('granting the permission continues to the database', () async {
      permission.current = PermissionState.denied;
      await started();

      await notifier().grantPermission();

      expect(permission.requests, 1);
      expect(current(), isA<StartupReady>());
      expect(container.read(databaseProvider).isReady, isTrue);
    });

    test('denying it for good switches to the settings hint', () async {
      permission
        ..current = PermissionState.denied
        ..afterRequest = PermissionState.permanentlyDenied;
      await started();

      await notifier().grantPermission();

      expect(current(), isA<StartupNeedsPermission>()
          .having((s) => s.permanentlyDenied, 'permanentlyDenied', isTrue));
    });

    test('returning from the system settings with the permission continues', () async {
      permission.current = PermissionState.permanentlyDenied;
      await started();

      permission.current = PermissionState.granted;
      await notifier().recheckPermission();

      expect(current(), isA<StartupReady>());
    });

    test('a resume without the permission keeps the permission screen', () async {
      permission.current = PermissionState.denied;
      await started();

      await notifier().recheckPermission();

      expect(current(), isA<StartupNeedsPermission>());
    });
  });

  group('first launch', () {
    test('no database shows the setup screen; creating one makes the app ready', () async {
      manager.initialSetupNeeded = true;
      expect(await started(), isA<StartupNeedsSetup>());

      await notifier().createDatabase();

      expect(current(), isA<StartupReady>());
      expect(manager.calls, contains('createDatabase'));
    });
  });

  group('year rollover', () {
    test('a year change asks about the rollover', () async {
      manager.rolloverNeeded = true;
      expect(await started(), isA<StartupRolloverAvailable>());
      expect(manager.calls, isNot(contains('openDatabase')));
    });

    test('confirming runs the rollover and opens the new database', () async {
      manager.rolloverNeeded = true;
      await started();

      await notifier().confirmRollover();

      expect(current(), isA<StartupReady>());
      expect(manager.calls, contains('performYearRolloverAndOpen'));
      expect(container.read(databaseProvider).showNewYearBanner, isFalse);
    });

    test('declining keeps the old database with the new-year banner', () async {
      manager.rolloverNeeded = true;
      await started();

      await notifier().declineRollover();

      expect(current(), isA<StartupReady>());
      expect(container.read(databaseProvider).showNewYearBanner, isTrue);
    });
  });

  group('failures', () {
    test('a broken database shows the failed screen; retry opens it again', () async {
      manager.openError = Exception('file is not a database');
      expect(await started(), isA<StartupFailed>());

      manager.openError = null;
      await notifier().retry();

      expect(current(), isA<StartupReady>());
    });

    test('a database error reported by a page shows the failed screen', () async {
      await started();
      final error = Exception('stream failed');

      container.read(databaseProvider.notifier).reportDatabaseError(error);

      expect(current(), isA<StartupFailed>().having((s) => s.error, 'error', same(error)));
    });
  });

  group('database picker', () {
    final oldDb = File('/storage/emulated/0/Documents/AttendlyDb/db_2025.db');

    test('switching to a picked database opens it as a temporary database', () async {
      await started();

      await notifier().openDatabaseFile(oldDb);

      expect(current(), isA<StartupReady>());
      expect(container.read(databaseProvider).isTemporaryDb, isTrue);
      expect(container.read(databaseProvider).dbYear, 2025);
    });

    test('a picked database that fails keeps the file for retry', () async {
      await started();
      manager.openError = Exception('broken');

      await notifier().openDatabaseFile(oldDb);

      expect(current(), isA<StartupFailed>()
          .having((s) => s.selectedDb?.path, 'selectedDb', oldDb.path));
    });

    test('open default leaves the picked database', () async {
      await started();
      await notifier().openDatabaseFile(oldDb);

      await notifier().openDefault();

      expect(current(), isA<StartupReady>());
      expect(container.read(databaseProvider).isTemporaryDb, isFalse);
      expect(container.read(databaseProvider).dbYear, 2026);
    });
  });
}
