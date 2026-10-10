import 'package:attendly/app/startup/startup_decision.dart';
import 'package:attendly/data/database/database_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_database_manager.dart';

void main() {
  group('decideStartup', () {
    late FakeDatabaseManager manager;
    late DatabaseNotifier notifier;

    setUp(() {
      manager = FakeDatabaseManager();
      notifier = DatabaseNotifier(manager);
    });

    tearDown(() async {
      notifier.dispose();
      await manager.closeDatabase();
    });

    // rolloverNeeded, initialSetupNeeded -> decision
    final table = <(bool, bool, StartupDecision)>[
      (false, true, StartupDecision.needsSetup),
      (true, true, StartupDecision.needsSetup),
      (true, false, StartupDecision.askForRollover),
      (false, false, StartupDecision.openDefaultDatabase),
    ];

    for (final (rollover, setup, expected) in table) {
      test('rollover=$rollover setup=$setup -> ${expected.name}', () async {
        manager
          ..rolloverNeeded = rollover
          ..initialSetupNeeded = setup;

        expect(await decideStartup(notifier), expected);
      });
    }

    test('checks the rollover before the first-launch setup', () async {
      await decideStartup(notifier);
      expect(manager.calls, ['checkForYearRollover', 'needsInitialSetup']);
    });
  });

  group('DatabaseNotifier', () {
    late FakeDatabaseManager manager;
    late DatabaseNotifier notifier;

    setUp(() {
      manager = FakeDatabaseManager();
      notifier = DatabaseNotifier(manager);
    });

    tearDown(() async {
      notifier.dispose();
      await manager.closeDatabase();
    });

    test('openDatabase marks the state ready', () async {
      await notifier.openDatabase();
      expect(notifier.state.isReady, isTrue);
      expect(notifier.state.isTemporaryDb, isFalse);
      expect(notifier.state.showNewYearBanner, isFalse);
      expect(notifier.state.dbYear, 2026);
    });

    test('openDatabaseWithBanner keeps the new-year banner visible', () async {
      await notifier.openDatabaseWithBanner();
      expect(notifier.state.isReady, isTrue);
      expect(notifier.state.showNewYearBanner, isTrue);
    });

    test('a failing open leaves the state not ready', () async {
      manager.openError = Exception('broken file');
      await expectLater(notifier.openDatabase(), throwsException);
      expect(notifier.state.isReady, isFalse);
    });

    test('reportDatabaseError drops the database and keeps the error', () async {
      await notifier.openDatabase();
      final error = Exception('stream failed');
      notifier.reportDatabaseError(error);
      expect(notifier.state.isReady, isFalse);
      expect(notifier.state.manager, isNull);
      expect(notifier.state.dbError, same(error));
    });
  });
}
