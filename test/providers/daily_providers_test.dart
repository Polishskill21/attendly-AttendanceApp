import 'package:attendly/data/database/app_database.dart';
import 'package:attendly/data/tables/enums/category.dart';
import 'package:attendly/features/daily_log/providers/daily_log_providers.dart';
import 'package:attendly/data/database/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

void main() {
  final monday = DateTime(2026, 3, 2);
  final tuesday = DateTime(2026, 3, 3);

  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = createTestDatabase();
    container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
    ]);

    final anna = await addTestPerson(db, 'Anna');
    final ben = await addTestPerson(db, 'Ben');
    final hannah = await addTestPerson(db, 'Hannah');

    await addTestEntry(db, personId: anna, date: monday, category: Category.open);
    await addTestEntry(db, personId: anna, date: monday, category: Category.offer);
    await addTestEntry(db, personId: ben, date: monday, category: Category.offer);
    await addTestEntry(db, personId: hannah, date: tuesday, category: Category.open);

    container.read(dailyDateProvider.notifier).state = monday;
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<Map<String, List<String>>> filteredLogs() async {
    container.listen(dailyFilteredLogsProvider, (_, _) {});
    await container.read(dailyRawLogsProvider.future);
    return {
      for (final person in container.read(dailyFilteredLogsProvider).requireValue)
        person.name: person.records.map((r) => r.category).toList(),
    };
  }

  test('groups the entries of the selected day by person', () async {
    expect(await filteredLogs(), {
      'Anna': ['open', 'offer'],
      'Ben': ['offer'],
    });
  });

  test('search filters people by name, case-insensitive', () async {
    container.read(dailySearchProvider.notifier).state = 'BE';
    expect(await filteredLogs(), {'Ben': ['offer']});
  });

  test('category filter keeps only matching records and drops empty people', () async {
    container.read(dailyCategoryFilterProvider.notifier).state = Category.open.name;
    expect(await filteredLogs(), {'Anna': ['open']});
  });

  test('search and category filter combine', () async {
    container.read(dailySearchProvider.notifier).state = 'anna';
    container.read(dailyCategoryFilterProvider.notifier).state = Category.offer.name;
    expect(await filteredLogs(), {'Anna': ['offer']});
  });

  test('changing the date switches the raw logs to that day', () async {
    container.listen(dailyRawLogsProvider, (_, _) {});
    final mondayLogs = await container.read(dailyRawLogsProvider.future);
    expect(mondayLogs.map((p) => p.name), ['Anna', 'Ben']);

    container.read(dailyDateProvider.notifier).state = tuesday;
    final tuesdayLogs = await container.read(dailyRawLogsProvider.future);
    expect(tuesdayLogs.map((p) => p.name), ['Hannah']);
  });

  test('the day stream is released when nobody watches it', () async {
    final subscription = container.listen(dailyRawLogsProvider, (_, _) {});
    await container.read(dailyRawLogsProvider.future);
    expect(container.exists(dailyRawLogsProvider), isTrue);

    subscription.close();
    await Future<void>.delayed(Duration.zero);

    expect(container.exists(dailyRawLogsProvider), isFalse);
  });
}
