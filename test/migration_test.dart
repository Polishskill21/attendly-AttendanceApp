import 'package:attendly/data/database/app_database.dart';
import 'package:attendly/data/tables/enums/category.dart';
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated_migrations/schema.dart';
import 'generated_migrations/schema_v2.dart' as v2;

/// Schema migrations, checked against the dumps in drift_schemas/.
/// After changing the schema: bump schemaVersion, then run
///   dart run drift_dev schema dump lib/data/database/app_database.dart drift_schemas/
///   dart run drift_dev schema generate drift_schemas/ test/generated_migrations/
void main() {
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('v2 -> v3 matches the v3 schema', () async {
    final connection = await verifier.startAt(2);
    final db = AppDatabase(connection);

    await verifier.migrateAndValidate(db, 3);
    await db.close();
  });

  test('v2 -> v3 keeps people and entries', () async {
    final schema = await verifier.schemaAt(2);

    final oldDb = v2.DatabaseAtV2(schema.newConnection());
    await oldDb.customStatement(
      "INSERT INTO directory_people (id, name, birthday, gender, migration, migration_background) "
      "VALUES (1, 'Anna', '2010-01-01T00:00:00.000', 'f', 0, '')",
    );
    await oldDb.customStatement(
      "INSERT INTO daily_entry (record_id, date, person_id, category, description) "
      "VALUES (1, '2026-03-02T00:00:00.000', 1, 'open', NULL)",
    );
    await oldDb.close();

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 3);

    final people = await db.readDao.watchAllPerson(true).first;
    expect(people.map((p) => p.name), ['Anna']);
    final entries = await db.readDao.getDailyEntriesByPersonId(1);
    expect(entries.map((e) => (e.date, e.category)), [(DateTime(2026, 3, 2), Category.open)]);
    await db.close();
  });

  test('v2 -> v3 also works when an interrupted run left the indexes', () async {
    final schema = await verifier.schemaAt(2);

    final oldDb = v2.DatabaseAtV2(schema.newConnection());
    await oldDb.customStatement(
      'CREATE INDEX daily_entry_date_person ON daily_entry (date, person_id)',
    );
    await oldDb.customStatement('CREATE INDEX daily_entry_person ON daily_entry (person_id)');
    await oldDb.close();

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 3);
    await db.close();
  });

  test('the per-day query uses the new index', () async {
    final db = AppDatabase.testInstance();
    final day = db.dateOnlyConverter.toSql(DateTime(2026, 3, 2));

    final plan = await db.customSelect(
      'EXPLAIN QUERY PLAN SELECT * FROM daily_entry '
      'INNER JOIN directory_people ON directory_people.id = daily_entry.person_id '
      'WHERE daily_entry.date = ?',
      variables: [Variable<String>(day)],
    ).get();

    expect(plan.map((row) => row.read<String>('detail')).join('\n'),
        contains('USING INDEX daily_entry_date_person'));
    await db.close();
  });
}
