import 'package:attendly/data/local/config/database.dart';
import 'package:attendly/provider/database_provider.dart';
import 'package:attendly/provider/directory_repo_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = createTestDatabase();
    container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
    ]);
    await addTestPerson(db, 'Anna');
    await addTestPerson(db, 'Benjamin');
    await addTestPerson(db, 'Hannah');
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<List<String>> filteredNames() async {
    container.listen(filteredDirectoryProvider, (_, _) {});
    await container.read(directoryStreamProvider.future);
    return container
        .read(filteredDirectoryProvider)
        .requireValue
        .map((p) => p.name)
        .toList();
  }

  test('without a query all people are listed, sorted by name', () async {
    expect(await filteredNames(), ['Anna', 'Benjamin', 'Hannah']);
  });

  test('search is case-insensitive and matches anywhere in the name', () async {
    container.read(directorySearchQueryProvider.notifier).state = 'ANN';
    expect(await filteredNames(), ['Anna', 'Hannah']);
  });

  test('search without a match returns an empty list', () async {
    container.read(directorySearchQueryProvider.notifier).state = 'zzz';
    expect(await filteredNames(), isEmpty);
  });

  test('descending sort reverses the order', () async {
    container.read(directorySortAscendingProvider.notifier).state = false;
    expect(await filteredNames(), ['Hannah', 'Benjamin', 'Anna']);
  });
}
