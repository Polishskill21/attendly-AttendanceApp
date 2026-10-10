import 'dart:math';

import 'package:attendly/data/database/app_database.dart';
import 'package:attendly/features/directory/widgets/alphabet_index_bar.dart';
import 'package:attendly/features/settings/data/test_people_seeder.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late TestPeopleSeeder seeder;

  setUp(() {
    db = createTestDatabase();
    seeder = TestPeopleSeeder(db, random: Random(42));
  });

  tearDown(() => db.close());

  test('seeds people with unique names spread over the alphabet', () async {
    await seeder.seed(1000);

    final people = await db.readDao.watchAllPerson(true).first;
    expect(people, hasLength(1000));
    expect(people.map((p) => p.name).toSet(), hasLength(1000));
    expect(people.map((p) => firstLetterBucket(p.name)).toSet().length, greaterThan(20));
  });

  test('seeding twice keeps the names unique', () async {
    await seeder.seed(10);
    await seeder.seed(10);

    expect(await seeder.countSeeded(), 20);
  });

  test('deleting removes only seeded people, with their entries', () async {
    final anna = await addTestPerson(db, 'Anna');
    await seeder.seed(5);
    final seeded = (await db.readDao.watchAllPerson(true).first)
        .firstWhere((p) => p.name.contains(TestPeopleSeeder.marker));
    await addTestEntry(db, personId: seeded.id, date: DateTime(2026, 3, 2));

    expect(await seeder.deleteSeeded(), 5);

    final people = await db.readDao.watchAllPerson(true).first;
    expect(people.map((p) => p.id), [anna]);
    expect(await db.readDao.getDailyEntriesByPersonId(seeded.id), isEmpty);
  });
}
