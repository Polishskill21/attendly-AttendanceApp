import 'package:attendly/data/local/database.dart';
import 'package:attendly/data/local/db_exceptions.dart';
import 'package:attendly/data/local/tables/enums/gender.dart';
import 'package:attendly/data/local/tables/enums/category.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.testInstance();
  });

  tearDown(() async {
    await db.close();
  });

  group('UpdateDao Integration Tests', () {
    
    Future<int> setupPerson({
      String name = 'Test User',
      DateTime? birthday,
      Gender gender = Gender.m,
      bool migration = false,
    }) async {
      return await db.into(db.directoryPeople).insert(
        DirectoryPeopleCompanion.insert(
          name: name,
          birthday: birthday ?? DateTime(2010, 01, 01),
          gender: gender,
          migration: migration,
        ),
      );
    }

    test('recalibrateWeeklyData rebuilds stats from scratch', () async {
      final bday = DateTime(2015, 01, 01); // 11 years old in 2026
      final pId = await setupPerson(birthday: bday, gender: Gender.f, migration: true);
      final entryDate = DateTime(2026, 05, 20);

      // Create a daily entry manually for recalibration to process
      await db.insertDao.insertDailyEntry(personId: pId, date: entryDate, category: Category.open);

      // 1. Clear weekly table to start fresh
      await db.delete(db.weeklyEntry).go();

      // 2. Run Recalibration logic (mirrors old DbUpdater logic)
      await db.updateDao.recalibrateWeeklyData();

      // 3. Verify the stats
      final weekDate = DateTime(2026, 05, 18); // Monday of that week
      final weekly = await db.readDao.getWeeklyEntryByDate(weekDate);

      expect(weekly, isNotNull);
      expect(weekly!.age_10_13, 1); 
      expect(weekly.allF, 1);
      expect(weekly.openFemale, 1);
      expect(weekly.migrationFemale, 1);
    });

    test('updatePerson correctly adjusts weekly counters when stats change', () async {
      final oldBday = DateTime(2020, 01, 01); // age 6 in 2026
      final pId = await setupPerson(birthday: oldBday, gender: Gender.m, migration: false);
      final entryDate = DateTime(2026, 01, 10);
      final weekDate = DateTime(2026, 01, 05); // Monday

      // 1. MUST INSERT DailyEntry: updatePerson needs this to find the week
      await db.insertDao.insertDailyEntry(personId: pId, date: entryDate, category: Category.open);

      // 2. Update Person stats (triggers the revert/re-add logic)
      await db.updateDao.updatePerson(
        pId,
        DirectoryPeopleCompanion(
          gender: const Value(Gender.f),
          birthday: Value(DateTime(2010, 01, 01)), // new age 16
        ),
      );

      final weekly = await db.readDao.getWeeklyEntryByDate(weekDate);

      expect(weekly!.under_10, 0);   
      expect(weekly.age_14_17, 1);   
      expect(weekly.allM, 0);        
      expect(weekly.allF, 1);        
      expect(weekly.openFemale, 1);  
      expect(weekly.openMale, 0);
    });

    test('updateDailyEntry handles category changes and counter migration', () async {
      final pId = await setupPerson(birthday: DateTime(2000, 01, 01), gender: Gender.d);
      final entryDate = DateTime(2026, 02, 10);
      final weekDate = DateTime(2026, 02, 09); // Monday

      await db.insertDao.insertDailyEntry(personId: pId, date: entryDate, category: Category.offer);
      
      await db.updateDao.updateDailyEntry(
        recordID: 1,
        date: entryDate,
        personId: pId,
        newCategory: Category.open,
      );

      final weekly = await db.readDao.getWeeklyEntryByDate(weekDate);

      expect(weekly!.offersDiverse, 0); 
      expect(weekly.openDiverse, 1);
      expect(weekly.over_24, 1); 
      expect(weekly.migrationDiverse, 0);
    });

    test('updateDailyEntry throws DuplicateDailyEntryException when changing to "open" if one already exists', () async {
      final pId = await setupPerson(birthday: DateTime(2000, 01, 01), gender: Gender.d);
      final date = DateTime(2024, 1, 1);

      // Setup: Person has one 'open' entry and one 'other' entry
      await db.insertDao.insertDailyEntry(personId: pId, date: date, category: Category.open);
      await db.insertDao.insertDailyEntry(personId: pId, date: date, category: Category.other);
      
      // Get the recordID of the 'other' entry
      final entries = await db.select(db.dailyEntry).get();
      final otherEntryId = entries.firstWhere((e) => e.category == Category.other).recordID;

      // Try to update the 'other' entry to be 'open'
      expect(
        () => db.updateDao.updateDailyEntry(
          recordID: otherEntryId,
          date: date,
          personId: pId,
          newCategory: Category.open,
        ),
        throwsA(isA<DuplicateDailyEntryException>()),
      );
    });

    test('updatePerson rolls back stats if name update fails (Unique Constraint)', () async {
      final date = DateTime(2026, 01, 01);
      final p1 = await setupPerson(name: 'Alice');
      await setupPerson(name: 'Bob');
      await db.insertDao.insertDailyEntry(personId: p1, date: date, category: Category.open);

      // Attempt to rename Alice to Bob (will fail unique constraint)
      // while simultaneously changing Alice's gender
      expect(
        () => db.updateDao.updatePerson(p1, const DirectoryPeopleCompanion(
          name: Value('Bob'),
          gender: Value(Gender.f), 
        )),
        throwsA(isA<DuplicatePersonException>()),
      );

      // Verify Alice is still Male in stats because transaction rolled back
      final weekly = await db.readDao.getWeeklyEntryByDate(DateTime(2025, 12, 29)); // Monday
      expect(weekly!.openMale, 1);
      expect(weekly.openFemale, 0);
    });

    test('updateWeeklyTableCounters handles atomic addition and subtraction', () async {
      final weekDate = DateTime(2026, 03, 01);
      
      await db.updateDao.updateWeeklyTableCounters(
        weekDate: weekDate, age: 5, gender: Gender.m, category: Category.open, migration: true, isAddition: true,
      );

      var weekly = await db.readDao.getWeeklyEntryByDate(weekDate);
      expect(weekly!.under_10, 1);
      expect(weekly.allM, 1);
      expect(weekly.migrationMale, 1);

      await db.updateDao.updateWeeklyTableCounters(
        weekDate: weekDate, age: 5, gender: Gender.m, category: Category.open, migration: true, isAddition: false,
      );

      weekly = await db.readDao.getWeeklyEntryByDate(weekDate);
      expect(weekly!.under_10, 0);
      expect(weekly.allM, 0);
      expect(weekly.migrationMale, 0);
    });

    test('updatePerson with no changes should not trigger weekly counter logic', () async {
      final pId = await setupPerson(name: 'Static User');
      final entryDate = DateTime(2026, 02, 01);

      await db.into(db.dailyEntry).insert(DailyEntryCompanion.insert(
        recordID: 50, dates: entryDate, id: pId, category: Category.open,
      ));

      await db.updateDao.updatePerson(
        pId, 
        const DirectoryPeopleCompanion(name: Value('Updated Name'))
      );

      final weekDate = DateTime(2026, 01, 26);
      final weekly = await db.readDao.getWeeklyEntryByDate(weekDate);
      expect(weekly, isNull); 
    });

    test('recalibrateWeeklyData handles Parent category (No migration count)', () async {
      final pId = await setupPerson(name: 'Parent Test', migration: true);
      final entryDate = DateTime(2026, 03, 04);

      await db.insertDao.insertDailyEntry(personId: pId, date: entryDate, category: Category.parent);

      await db.updateDao.recalibrateWeeklyData();

      final weekDate = DateTime(2026, 03, 02);
      final weekly = await db.readDao.getWeeklyEntryByDate(weekDate);

      expect(weekly!.allM, 1);
      expect(weekly.migrationMale, 0); 
    });
  });

  test('_ensureWeeklyRowExists does not overwrite existing data', () async {
    final date = DateTime(2026, 04, 01);
    
    await db.into(db.weeklyEntry).insert(WeeklyEntryCompanion.insert(
      dates: date, under_10: 10, age_10_13: 0, age_14_17: 0, age_18_24: 0, over_24: 0,
      allM: 0, allF: 0, allD: 0, openMale: 0, openFemale: 0, openDiverse: 0,
      offersMale: 0, offersFemale: 0, offersDiverse: 0, migrationMale: 0,
      migrationFemale: 0, migrationDiverse: 0, countable: true,
    ));

    await db.updateDao.updateWeeklyTableCounters(
      weekDate: date, age: 30, gender: Gender.d, category: Category.offer, migration: false, isAddition: true,
    );

    final weekly = await db.readDao.getWeeklyEntryByDate(date);
    expect(weekly!.under_10, 10); 
    expect(weekly.over_24, 1); 
  });
  
  test('updateCountableColZeroWeek marks week as non-countable if empty', () async {
    final weekDate = DateTime(2026, 12, 01);
    
    // Create a row with all zeros
    await db.updateDao.updateWeeklyTableCounters(
      weekDate: weekDate, age: 20, gender: Gender.m, category: Category.open, migration: false, isAddition: true,
    );

    await db.updateDao.updateCountableStatus(weekDate, true);
    final weeklyTest = await db.readDao.getWeeklyEntryByDate(weekDate);
    expect(weeklyTest!.countable, true);

    // Now subtract it to make it zero
    await db.updateDao.updateWeeklyTableCounters(
      weekDate: weekDate, age: 20, gender: Gender.m, category: Category.open, migration: false, isAddition: false,
    );

    await db.updateDao.updateCountableColZeroWeek(weekDate);

    final weekly = await db.readDao.getWeeklyEntryByDate(weekDate);
    expect(weekly!.countable, false);
  });
}