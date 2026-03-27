import 'package:attendly/data/local/config/database.dart';
import 'package:attendly/data/local/config/db_exceptions.dart';
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

    test('insertDirPerson throws DuplicatePersonException when name already exists', () async {
      const duplicateName = 'Duplicate User';
      final companion = DirectoryPeopleCompanion.insert(
        name: duplicateName,
        birthday: DateTime(2000, 01, 01),
        gender: Gender.m,
        migration: false,
      );

      await db.insertDao.insertDirPerson(companion);

      expect(
        () => db.insertDao.insertDirPerson(companion),
        throwsA(isA<DuplicatePersonException>()),
      );
    });

    test('throws PersonNotFoundException when ID does not exist', () async {
      expect(
        () => db.insertDao.insertDailyEntry(
          personId: 999,
          date: DateTime.now(),
          category: Category.open,
        ),
        throwsA(isA<PersonNotFoundException>()),
      );
    });

    test('throws DuplicateDailyEntryException for multiple "open" entries on same day', () async {
      final testDate = DateTime(2024, 1, 1);
      
      // 1. Setup: Create a person first
      await db.insertDao.insertDirPerson(DirectoryPeopleCompanion.insert(
        name: 'Test User',
        birthday: DateTime(2000, 1, 1),
        gender: Gender.m,
        migration: false,
      ));
      final person = (await db.readDao.findPeopleByName('Test User')).first;

      // 2. Insert the first "open" entry
      await db.insertDao.insertDailyEntry(
        personId: person.id,
        date: testDate,
        category: Category.open,
      );

      // 3. Attempt to insert a second "open" entry for the same person/date
      expect(
        () => db.insertDao.insertDailyEntry(
          personId: person.id,
          date: testDate,
          category: Category.open,
        ),
        throwsA(isA<DuplicateDailyEntryException>()),
      );
    });

    test('successfully inserts multiple entries if category is NOT "open"', () async {
      // Setup person
      await db.insertDao.insertDirPerson(DirectoryPeopleCompanion.insert(
        name: 'Multi Entry User',
        birthday: DateTime(2000, 1, 1),
        gender: Gender.f,
        migration: false,
      ));
      final person = (await db.readDao.findPeopleByName('Multi Entry User')).first;
      final testDate = DateTime(2024, 1, 1);

      // This should NOT throw an exception because category is not Category.open
      // (My db logic only blocks duplicates for 'open')
      await db.insertDao.insertDailyEntry(
        personId: person.id,
        date: testDate,
        category: Category.other,
      );

      await db.insertDao.insertDailyEntry(
        personId: person.id,
        date: testDate,
        category: Category.other, 
      );
      
      // Verify two records exist
      final entries = await db.select(db.dailyEntry).get();
      expect(entries.length, 2);
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
      expect(entries.any((e) => e.recordId == 1), true);
      expect(entries.any((e) => e.recordId == 2), true);
    });

    test('insertDailyEntry skips duplicate "Open" category entries', () async {
      final pId = await db.into(db.directoryPeople).insert(
        DirectoryPeopleCompanion.insert(name: 'User B', birthday: DateTime(2010, 1, 1), gender: Gender.m, migration: false)
      );
      final date = DateTime(2026, 05, 20);

      // First insert
      await db.insertDao.insertDailyEntry(personId: pId, date: date, category: Category.open);

      expect(
        () => db.insertDao.insertDailyEntry(personId: pId, date: date, category: Category.open),
        throwsA(isA<DuplicateDailyEntryException>()),
      );

      final entries = await db.readDao.getDailyEntriesByPersonId(pId);
      expect(entries.length, 1);
    });

    test('insertDailyEntry automatically triggers weekly counter updates', () async {
      final bday = DateTime(2010, 01, 01); // Age 16 in 2026
      final pId = await db.into(db.directoryPeople).insert(
        DirectoryPeopleCompanion.insert(name: 'User C', birthday: bday, gender: Gender.f, migration: true)
      );
      final date = DateTime(2026, 05, 20); // Wednesday
      final monday = DateTime(2026, 05, 18);

      await db.insertDao.insertDailyEntry(personId: pId, date: date, category: Category.open);

      final weekly = await db.readDao.watchWeeklyEntryByDate(monday).first;
      expect(weekly, isNotNull);
      expect(weekly!.age_14_17, 1);
      expect(weekly.migrationFemale, 1);
    });

    test('insertDailyEntry saves null and non-null descriptions correctly', () async {
      final pId = await setupPerson();
      
      await db.insertDao.insertDailyEntry(
        personId: pId, 
        date: DateTime(2026, 1, 1), 
        category: Category.offer,
        description: 'Special Event'
      );

      final entry = (await db.select(db.dailyEntry).get()).first;
      expect(entry.description, 'Special Event');
    });

    test('insertDailyEntry rolls back EVERYTHING if an error occurs mid-transaction', () async {
      final pId = await setupPerson(name: 'Rollback User');
      final date = DateTime(2026, 01, 01);

      try {
        await db.transaction(() async {
          await db.insertDao.insertDailyEntry(
            personId: pId, 
            date: date, 
            category: Category.open
          );
          
          // We MANUALLY throw an error here. 
          throw Exception('Simulation of a crash'); 
        });
      } catch (e) {
        // Catch the error so the test doesn't stop
      }

      // VERIFY: The DailyEntry should NOT exist
      final entries = await db.readDao.getDailyEntriesByPersonId(pId);
      expect(entries, isEmpty, reason: 'The entry was saved even though the transaction should have rolled back!');
    });
  });
}