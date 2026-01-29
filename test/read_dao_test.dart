import 'package:attendly/data/local/database.dart';
import 'package:attendly/data/local/tables/enums/gender.dart';
import 'package:attendly/data/local/tables/enums/category.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.testInstance();
  });

  tearDown(() async {
    await db.close();
  });

  group('ReadDao Comprehensive Method Tests', () {
    
    // --- Directory Table Tests ---
    
    test('getAllPeople & getPersonById', () async {
      await db.into(db.directoryPeople).insert(DirectoryPeopleCompanion.insert(
        name: 'Rafa',
        birthday: DateTime(2000, 02, 21),
        gender: Gender.m,
        migration: true,
        migrationBackground: const Value('Polnisch'),
      ));

      final all = await db.readDao.getAllPeople();
      expect(all.length, 1);
      
      final person = await db.readDao.getPersonById(all.first.id);
      expect(person?.name, 'Rafa');
      expect(person?.birthday, DateTime(2000, 02, 21));

      // final rawResult = await db.customSelect("SELECT birthday FROM all_people WHERE name = 'Rafa'").getSingle();
      // print("RAW SQL VALUE: ${rawResult.read<String>('birthday')}");
    });

    test('findPeopleByName returns exact matches', () async {
      await db.into(db.directoryPeople).insert(DirectoryPeopleCompanion.insert(
        name: 'Michelle',
        birthday: DateTime(2005, 09, 14),
        gender: Gender.f,
        migration: false,
        migrationBackground: const Value('German'),
      ));

      final found = await db.readDao.findPeopleByName('Michelle');
      final notFound = await db.readDao.findPeopleByName('Unknown');
      
      expect(found.length, 1);
      expect(notFound.isEmpty, true);
    });

    // --- Daily Entry Table Tests ---

    test('getLatestDailyDate & existsEntryForDate', () async {
      final date1 = DateTime(2026, 01, 20);
      final date2 = DateTime(2026, 01, 25);
      
      final pId = await db.into(db.directoryPeople).insert(
        DirectoryPeopleCompanion.insert(name: 'Test', birthday: DateTime.now(), gender: Gender.m, migration: false)
      );

      await db.into(db.dailyEntry).insert(DailyEntryCompanion.insert(
        recordID: 1, dates: date1, id: pId, category: Category.open, description: const Value('Old')
      ));
      await db.into(db.dailyEntry).insert(DailyEntryCompanion.insert(
        recordID: 2, dates: date2, id: pId, category: Category.offer, description: const Value('New')
      ));

      expect(await db.readDao.getLatestDailyDate(), date2);
      expect(await db.readDao.existsEntryForDate(date1), true);
      expect(await db.readDao.existsEntryForDate(DateTime(2020, 01, 01)), false);
    });

    test('getCategory & countEntriesForPerson', () async {
      final pId = await db.into(db.directoryPeople).insert(
        DirectoryPeopleCompanion.insert(name: 'Counter', birthday: DateTime.now(), gender: Gender.m, migration: false)
      );
      final date = DateTime(2026, 01, 25);

      await db.into(db.dailyEntry).insert(DailyEntryCompanion.insert(
        recordID: 10, dates: date, id: pId, category: Category.parent, description: const Value('Desc')
      ));

      final cat = await db.readDao.getCategory(10, date, pId);
      final count = await db.readDao.countEntriesForPerson(pId);

      expect(cat, Category.parent);
      expect(count, 1);
    });

    // --- Join & Search Tests ---

    test('getPeopleFromCurrentDay returns joined data', () async {
      final date = DateTime(2026, 01, 25);
      final pId = await db.into(db.directoryPeople).insert(
        DirectoryPeopleCompanion.insert(name: 'Viktor B.', birthday: DateTime.now(), gender: Gender.m, migration: true, migrationBackground: const Value('Russian'))
      );
      await db.into(db.dailyEntry).insert(DailyEntryCompanion.insert(
        recordID: 1, dates: date, id: pId, category: Category.open, description: const Value('Present')
      ));

      final results = await db.readDao.getPeopleFromCurrentDay(date);
      expect(results.length, 1);
      expect(results.first.readTable(db.directoryPeople).name, 'Viktor B.');
    });

    test('searchDailyLogs filters by partial name and description', () async {
      final pId = await db.into(db.directoryPeople).insert(
        DirectoryPeopleCompanion.insert(name: 'Gregor', birthday: DateTime.now(), gender: Gender.m, migration: true, migrationBackground: const Value('Kazakhstan'))
      );
      await db.into(db.dailyEntry).insert(DailyEntryCompanion.insert(
        recordID: 1, dates: DateTime.now(), id: pId, category: Category.open, description: const Value('Searching for something')
      ));

      final byName = await db.readDao.searchDailyLogs(name: 'Greg');
      final byDesc = await db.readDao.searchDailyLogs(description: 'thing');
      
      expect(byName.length, 1);
      expect(byDesc.length, 1);
    });

    // --- Weekly Entry Table Tests ---

    test('Weekly Entry queries', () async {
      final date = DateTime(2026, 01, 01);
      await db.into(db.weeklyEntry).insert(WeeklyEntryCompanion.insert(
        dates: date, under_10: 5, age_10_13: 2, age_14_17: 0, age_18_24: 0, over_24: 1,
        allM: 4, allF: 4, allD: 0, openMale: 2, openFemale: 2, openDiverse: 0,
        offersMale: 1, offersFemale: 1, offersDiverse: 0, migrationMale: 1, 
        migrationFemale: 1, migrationDiverse: 0, countable: true
      ));

      final entry = await db.readDao.getWeeklyEntryByDate(date);
      final all = await db.readDao.getAllWeeklyEntries();

      expect(entry?.under_10, 5);
      expect(all.length, 1);
    });
  });
}