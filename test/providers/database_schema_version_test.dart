import 'package:attendly/data/database/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

void main() {
  test('reports the schema version saved in the open database', () async {
    final db = createTestDatabase();
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
    ]);
    addTearDown(() async {
      container.dispose();
      await db.close();
    });

    expect(await container.read(databaseSchemaVersionProvider.future), db.schemaVersion);
  });
}
