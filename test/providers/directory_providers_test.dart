import 'package:attendly/data/database/app_database.dart';
import 'package:attendly/data/database/database_provider.dart';
import 'package:attendly/features/directory/providers/directory_providers.dart';
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

  test('the letter index points at the first person of each letter', () async {
    container.listen(directoryLetterIndexProvider, (_, _) {});
    await container.read(directoryStreamProvider.future);
    expect(container.read(directoryLetterIndexProvider), {'A': 0, 'B': 1, 'H': 2});

    container.read(directorySortAscendingProvider.notifier).state = false;
    await container.read(directoryStreamProvider.future);
    expect(container.read(directoryLetterIndexProvider), {'H': 0, 'B': 1, 'A': 2});
  });
}
