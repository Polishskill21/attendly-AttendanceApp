import 'package:attendly/data/local/dao/shared_dao_logic.dart';
import 'package:attendly/data/local/database.dart';
import 'package:attendly/data/local/db_exceptions.dart';
import 'package:drift/drift.dart';
import 'package:attendly/data/local/tables/directory_people_table.dart';
import 'package:attendly/data/local/tables/dialy_entry_table.dart';
import 'package:attendly/data/local/tables/weekly_entry_table.dart';
import 'package:attendly/data/local/tables/enums/category.dart';
import 'package:attendly/data/local/tables/enums/gender.dart';

part 'update_dao.g.dart';

@DriftAccessor(tables: [DirectoryPeople, DailyEntry, WeeklyEntry])
class UpdateDao extends DatabaseAccessor<AppDatabase> with _$UpdateDaoMixin, SharedDaoLogic {
  UpdateDao(super.db);

  // --- 1. The Recalibration Logic ---
  Future<void> recalibrateWeeklyData() async {
    await transaction(() async {
      final existingWeeks = await db.readDao.getAllWeeklyEntries();
      final countableStates = {for (var w in existingWeeks) w.dates: w.countable};

      await delete(weeklyEntry).go();

      final rows = await db.readDao.getAllDailyEntriesWithPeople();

      for (final row in rows) {
        final daily = row.readTable(dailyEntry);
        final person = row.readTable(directoryPeople);
        final weekDate = getFirstDateOfWeek(daily.dates);

        await _ensureWeeklyRowExists(weekDate);

        final age = calcAge(daily.dates, person.birthday);

        await updateWeeklyTableCounters(
          weekDate: weekDate,
          age: age,
          gender: person.gender,
          category: daily.category,
          migration: person.migration,
          isAddition: true,
        );
      }

      for (final entry in countableStates.entries) {
        await (update(weeklyEntry)..where((t) => t.dates.equals(db.dateOnlyConverter.toSql(entry.key))))
            .write(WeeklyEntryCompanion(countable: Value(entry.value)));
      }
    });
  }

  // --- 2. Update Person (Directory) ---
  /// only do partial updates to a person, so create the companion only with new values that really changed after the ui has submitted
  Future<void> updatePerson(int id, DirectoryPeopleCompanion companion) async {
    await transaction(() async {
      final oldData = await db.readDao.getPersonById(id);
      if (oldData == null ) throw PersonNotFoundException(id);

      if (companion.name.present && companion.name.value != oldData.name) {
        final isNameTaken = await (select(directoryPeople)
              ..where((t) => t.name.equals(companion.name.value) & t.id.equals(id).not()))
            .getSingleOrNull();

        if (isNameTaken != null) {
          throw DuplicatePersonException(companion.name.value);
        }
      }

      final statsChanged = companion.birthday.present || 
                          companion.gender.present || 
                          companion.migration.present;

      if (statsChanged) {
        final entries = await db.readDao.getDailyEntriesByPersonId(id);
        
        for (final entry in entries) {
          await updateWeeklyTableCounters(
            weekDate: getFirstDateOfWeek(entry.dates),
            age: calcAge(entry.dates, oldData.birthday),
            gender: oldData.gender,
            category: entry.category,
            migration: oldData.migration,
            isAddition: false,
          );

          // ADD the new stats
          // If a field isn't in the companion, we use the existing oldData
          final newBirthday = companion.birthday.present ? companion.birthday.value : oldData.birthday;
          final newGender = companion.gender.present ? companion.gender.value : oldData.gender;
          final newMigration = companion.migration.present ? companion.migration.value : oldData.migration;

          await updateWeeklyTableCounters(
            weekDate: getFirstDateOfWeek(entry.dates),
            age: calcAge(entry.dates, newBirthday),
            gender: newGender,
            category: entry.category,
            migration: newMigration,
            isAddition: true,
          );
        }
      }

      // 3. Update the directory table
      await (update(directoryPeople)..where((t) => t.id.equals(id))).write(companion);
    });
  }

  // --- 3. Update Daily Entry ---
  /// pass all the information, also old description otherwise it will set it to null
  Future<void> updateDailyEntry({
    required int recordID,
    required DateTime date,
    required int personId,
    required Category newCategory,
    String? newDescription,
  }) async {
    await transaction(() async {
      final row = await db.readDao.getEntryWithPerson(recordID, personId, date);
      if (row == null) return;

      final oldEntry = row.readTable(dailyEntry);
      final person = row.readTable(directoryPeople);

      // do not allow to update a category to open if the person has already one for the day
      if (newCategory == Category.open && oldEntry.category != Category.open) {
        final hasDuplicate = await db.readDao.hasOpenCategoryForDate(personId, date);
        if (hasDuplicate) {
          throw DuplicateDailyEntryException();
        }
      }

      // Only perform logic if the category actually changed
      if (oldEntry.category != newCategory) {
        final weekDate = getFirstDateOfWeek(date);
        final age = calcAge(date, person.birthday);

        // Subtract old category totals, Add new category totals
        await updateWeeklyTableCounters(weekDate: weekDate, age: age, gender: person.gender, category: oldEntry.category, migration: person.migration, isAddition: false);
        await updateWeeklyTableCounters(weekDate: weekDate, age: age, gender: person.gender, category: newCategory, migration: person.migration, isAddition: true);
      }

      await (update(dailyEntry)
            ..where((t) => t.recordID.equals(recordID) & t.dates.equals(db.dateOnlyConverter.toSql(date)) & t.id.equals(personId)))
          .write(DailyEntryCompanion(category: Value(newCategory), description: Value(newDescription)));
    });
  }

  // --- 4. Atomic Weekly Counters ---
  // Shared logic to increment or decrement specific weekly columns.
  Future<void> updateWeeklyTableCounters({
    required DateTime weekDate,
    required int age,
    required Gender gender,
    required Category category,
    required bool migration,
    required bool isAddition,
  }) async {
    final op = isAddition ? '+' : '-';
    final ageCol = determineAgeGroup(age);
    final genderCol = determineGenderColumn(gender);
    final genCatCol = determineGenderCategory(gender, category);
    final migrCol = migration ? determineMigrationCol(gender) : null;
    final dateStr = db.dateOnlyConverter.toSql(weekDate);

    await _ensureWeeklyRowExists(weekDate);

    await customUpdate('UPDATE weekly_entry SET $ageCol = $ageCol $op 1, $genderCol = $genderCol $op 1 WHERE dates = ?', variables: [Variable<String>(dateStr)]);

    if (genCatCol.isNotEmpty) {
      await customUpdate('UPDATE weekly_entry SET $genCatCol = $genCatCol $op 1 WHERE dates = ?', variables: [Variable<String>(dateStr)]);
    }

    if (migrCol != null && category == Category.open) {
      await customUpdate('UPDATE weekly_entry SET $migrCol = $migrCol $op 1 WHERE dates = ?', variables: [Variable<String>(dateStr)]);
    }
  }

  Future<void> updateCountableColZeroWeek(DateTime weekDate) async {
    if (await db.readDao.areAllColumnsZero(weekDate)) {
      await (update(weeklyEntry)..where((t) => t.dates.equals(db.dateOnlyConverter.toSql(weekDate)))).write(const WeeklyEntryCompanion(countable: Value(false)));
    }
  }

  Future<void> updateCountableStatus(DateTime weekDate, bool newValue) async {
    final dateStr = db.dateOnlyConverter.toSql(weekDate);
    await (update(weeklyEntry)..where((t) => t.dates.equals(dateStr))).write(WeeklyEntryCompanion(countable: Value(newValue)));
  }

  // --- Helper Method ---

  Future<void> _ensureWeeklyRowExists(DateTime date) async {
    await customStatement(
      'INSERT OR IGNORE INTO weekly_entry (dates, under_10, age_10_13, age_14_17, age_18_24, over_24, all_m, all_f, all_d, open_male, open_female, open_diverse, offers_male, offers_female, offers_diverse, migration_male, migration_female, migration_diverse, countable) '
      'VALUES (?, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1)',
      [db.dateOnlyConverter.toSql(date)],
    );
  }
}