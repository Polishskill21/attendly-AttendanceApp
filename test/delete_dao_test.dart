import 'package:attendly/data/local/config/database.dart';
import 'package:attendly/data/local/config/exceptions/db_exceptions.dart';
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

  group('DeleteDao Integration Tests', () {
    
    // Helper to create a person with specific stats
    Future<int> setupPerson({
      required String name,
      required DateTime birthday,
      Gender gender = Gender.m,
      bool migration = false,
    }) async {
      return await db.into(db.directoryPeople).insert(
        DirectoryPeopleCompanion.insert(
          name: name,
          birthday: birthday,
          gender: gender,
          migration: migration,
        ),
      );
    }

    test('deleteDailyEntry removes record and reverts weekly counters', () async {
      final bday = DateTime(2010, 01, 01); // 16 years old in 2026
      final pId = await setupPerson(name: 'Delete Target', birthday: bday, gender: Gender.m);
      final entryDate = DateTime(2026, 05, 20);
      final weekDate = DateTime(2026, 05, 18); // Monday
      const recordId = 101;

      final actualAge = db.deleteDao.calcAge(entryDate, bday);

      // 1. Setup initial state: Entry + Weekly Counters
      await db.into(db.dailyEntry).insert(DailyEntryCompanion.insert(
        recordId: recordId, date: entryDate, personId: pId, category: Category.open,
      ));
      
      await db.updateDao.updateWeeklyTableCounters(
        weekDate: weekDate, age: actualAge, gender: Gender.m, category: Category.open, migration: false, isAddition: true,
      );

      // 2. Perform deletion
      await db.deleteDao.deleteDailyEntry(recordId, pId, entryDate);

      // 3. Assertions
      final entries = await db.readDao.getDailyEntriesByPersonId(pId);
      final weekly = await db.readDao.watchWeeklyEntryByDate(weekDate).first;

      expect(entries.isEmpty, true);
      expect(weekly!.age_14_17, 0); // Reverted
      expect(weekly.allM, 0);       // Reverted
      expect(weekly.countable, false); // Marked non-countable because stats are zero
    });

    test('deletePerson wipes history and reverts all associated weekly stats', () async {
      final bday = DateTime(2020, 01, 01); // 6 years old in 2026
      final pId = await setupPerson(name: 'Total Wipeout', birthday: bday, gender: Gender.f, migration: true);
      
      // Person attended two different weeks
      final dateW1 = DateTime(2026, 01, 06); // Week of Jan 05
      final dateW2 = DateTime(2026, 01, 13); // Week of Jan 12

      for (var date in [dateW1, dateW2]) {
        await db.into(db.dailyEntry).insert(DailyEntryCompanion.insert(
          recordId: date.day, date: date, personId: pId, category: Category.open,
        ));
        await db.updateDao.updateWeeklyTableCounters(
          weekDate: date.subtract(Duration(days: date.weekday - 1)), 
          age: 6, gender: Gender.f, category: Category.open, migration: true, isAddition: true,
        );
      }

      // Verify stats exist before deletion
      var week1 = await db.readDao.watchWeeklyEntryByDate(DateTime(2026, 01, 05)).first;
      expect(week1!.under_10, 1);
      expect(week1.allF, 1);
      expect(week1.migrationFemale, 1);

      // 2. Delete Person
      await db.deleteDao.deleteDirPerson(pId);

      // 3. Verify cascading cleanup
      final person = await db.readDao.getPersonById(pId);
      final entries = await db.readDao.getDailyEntriesByPersonId(pId);
      week1 = await db.readDao.watchWeeklyEntryByDate(DateTime(2026, 01, 05)).first;
      final week2 = await db.readDao.watchWeeklyEntryByDate(DateTime(2026, 01, 12)).first;

      expect(person, isNull);
      expect(entries.isEmpty, true);
      expect(week1!.under_10, 0);
      expect(week1.migrationFemale, 0);
      expect(week1.allF, 0);
      expect(week2!.under_10, 0);
      expect(week2.allF, 0);
      expect(week2.migrationFemale, 0);
    });

    test('deletePerson throws PersonNotFoundException when ID does not exist', () async {
      const nonExistentId = 9999;

      expect(
        () => db.deleteDao.deleteDirPerson(nonExistentId),
        throwsA(isA<PersonNotFoundException>()),
      );
    });

    test('deleteDailyEntry throws EntryNotFoundException when record does not exist', () async {
      final pId = await setupPerson(name: 'Valid User', birthday: DateTime(2000, 1, 1));
      final date = DateTime(2026, 1, 1);

      // Attempt to delete a recordID (999) that was never inserted
      expect(
        () => db.deleteDao.deleteDailyEntry(999, pId, date),
        throwsA(isA<EntryNotFoundException>()),
      );
    });

    test('deleteMultipleDailyEntries removes multiple records for a specific date', () async {
      final date = DateTime(2026, 06, 10);
      final p1 = await setupPerson(name: 'User A', birthday: DateTime(2000, 1, 1));
      final p2 = await setupPerson(name: 'User B', birthday: DateTime(2000, 1, 1));

      await db.into(db.dailyEntry).insert(DailyEntryCompanion.insert(
        recordId: 1, date: date, personId: p1, category: Category.offer,
      ));
      await db.into(db.dailyEntry).insert(DailyEntryCompanion.insert(
        recordId: 2, date: date, personId: p2, category: Category.offer,
      ));
      // Batch delete for that date
      await db.deleteDao.deleteMultipleDailyEntries([p1, p2], date);

      final entriesDate = await db.readDao.existsEntryForDate(date);
      expect(entriesDate, false);
    });
  });
}