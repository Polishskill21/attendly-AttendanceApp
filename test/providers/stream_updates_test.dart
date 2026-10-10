import 'package:attendly/data/database/app_database.dart';
import 'package:attendly/data/database/database_provider.dart';
import 'package:attendly/features/daily_log/providers/daily_log_providers.dart';
import 'package:attendly/features/directory/providers/directory_providers.dart';
import 'package:attendly/features/weekly_report/providers/weekly_report_providers.dart';
import 'package:attendly/features/yearly_report/providers/yearly_report_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

/// The tabs have no refresh buttons: every write must reach the screen
/// through the Drift streams on its own.
void main() {
  final monday = DateTime(2026, 3, 2);

  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = createTestDatabase();
    container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  /// Waits until [provider] holds a value that satisfies [matcher].
  Future<void> expectEventually<T>(
    ProviderListenable<AsyncValue<T>> provider,
    bool Function(T value) matcher,
  ) async {
    for (var i = 0; i < 50; i++) {
      final async = container.read(provider);
      if (async.hasValue && matcher(async.requireValue)) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('provider never reached the expected value: ${container.read(provider)}');
  }

  test('a new person shows up in the directory', () async {
    container.listen(filteredDirectoryProvider, (_, _) {});
    await container.read(directoryStreamProvider.future);

    await addTestPerson(db, 'Anna');

    await expectEventually(filteredDirectoryProvider, (people) => people.length == 1);
  });

  test('a new entry shows up in the daily log of that day', () async {
    final anna = await addTestPerson(db, 'Anna');
    container.read(dailyDateProvider.notifier).state = monday;
    container.listen(dailyFilteredLogsProvider, (_, _) {});
    await container.read(dailyRawLogsProvider.future);

    await addTestEntry(db, personId: anna, date: monday);

    await expectEventually(dailyFilteredLogsProvider, (people) => people.length == 1);
  });

  test('a changed countable status updates the week and the year', () async {
    final anna = await addTestPerson(db, 'Anna');
    await addTestEntry(db, personId: anna, date: monday);
    container.listen(weeklyReportProvider(monday), (_, _) {});
    container.listen(yearlyStatsProvider, (_, _) {});
    expect((await container.read(weeklyReportProvider(monday).future))?.countable, isTrue);
    expect((await container.read(yearlyStatsProvider.future))?.weekCount, 1);

    await container.read(weeklyRepositoryProvider).updateCountableStatus(monday, false);

    await expectEventually(weeklyReportProvider(monday), (week) => week?.countable == false);
    await expectEventually(yearlyStatsProvider, (stats) => stats == null);
  });

  test('the yearly report sums the countable weeks', () async {
    final anna = await addTestPerson(db, 'Anna');
    final ben = await addTestPerson(db, 'Ben');
    container.listen(yearlyStatsProvider, (_, _) {});
    expect(await container.read(yearlyStatsProvider.future), isNull);

    await addTestEntry(db, personId: anna, date: monday);
    await addTestEntry(db, personId: ben, date: monday.add(const Duration(days: 7)));

    await expectEventually(yearlyStatsProvider,
        (stats) => stats?.weekCount == 2 && stats?.stats['open_male'] == 2);
    expect(container.read(yearlyStatsProvider).requireValue!.stats.containsKey('week_count'), isFalse);
  });
}
