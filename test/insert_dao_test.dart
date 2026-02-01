import 'package:attendly/data/local/database.dart';
import 'package:attendly/data/local/tables/enums/gender.dart';
import 'package:attendly/data/local/tables/enums/category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.testInstance();
  });

  tearDown(() async {
    await db.close();
  });

  group('InsertDao Integration Tests', () {
    test('insertDirPerson adds a new person to the directory', () async {
      await db.insertDao.insertDirPerson(DirectoryPeopleCompanion.insert(
        name: 'New User',
        birthday: DateTime(2000, 01, 01),
        gender: Gender.m,
        migration: false,
      ));

      final person = await db.readDao.findPeopleByName('New User');
      expect(person.length, 1);
      expect(person.first.name, 'New User');
    });

    test('insertDailyEntry increments recordID for the same day', () async {
      final pId = await db.into(db.directoryPeople).insert(
        DirectoryPeopleCompanion.insert(name: 'User A', birthday: DateTime(2010, 1, 1), gender: Gender.m, migration: false)
      );
      final date = DateTime(2026, 05, 20);

      // First entry (recordID should be 1)
      await db.insertDao.insertDailyEntry(personId: pId, date: date, category: Category.offer);
      // Second entry (recordID should be 2)
      await db.insertDao.insertDailyEntry(personId: pId, date: date, category: Category.parent);

      final entries = await db.readDao.getDailyEntriesByPersonId(pId);
      expect(entries.length, 2);
      expect(entries.any((e) => e.recordID == 1), true);
      expect(entries.any((e) => e.recordID == 2), true);
    });

    test('insertDailyEntry skips duplicate "Open" category entries', () async {
      final pId = await db.into(db.directoryPeople).insert(
        DirectoryPeopleCompanion.insert(name: 'User B', birthday: DateTime(2010, 1, 1), gender: Gender.m, migration: false)
      );
      final date = DateTime(2026, 05, 20);

      // First insert
      await db.insertDao.insertDailyEntry(personId: pId, date: date, category: Category.open);
      // Second insert (Should be ignored by logic)
      await db.insertDao.insertDailyEntry(personId: pId, date: date, category: Category.open);

      final entries = await db.readDao.getDailyEntriesByPersonId(pId);
      expect(entries.length, 1); // Only the first one remains
    });

    test('insertDailyEntry automatically triggers weekly counter updates', () async {
      final bday = DateTime(2010, 01, 01); // Age 16 in 2026
      final pId = await db.into(db.directoryPeople).insert(
        DirectoryPeopleCompanion.insert(name: 'User C', birthday: bday, gender: Gender.f, migration: true)
      );
      final date = DateTime(2026, 05, 20); // Wednesday
      final monday = DateTime(2026, 05, 18);

      await db.insertDao.insertDailyEntry(personId: pId, date: date, category: Category.open);

      final weekly = await db.readDao.getWeeklyEntryByDate(monday);
      expect(weekly, isNotNull);
      expect(weekly!.age_14_17, 1);
      expect(weekly.migrationFemale, 1);
    });
  });
}