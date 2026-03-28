import 'package:attendly/data/local/dao/shared_dao_logic.dart';
import 'package:attendly/data/local/config/database.dart';
import 'package:attendly/data/local/config/exceptions/db_exceptions.dart';
import 'package:attendly/data/local/tables/daily_entry_table.dart';
import 'package:attendly/data/local/tables/directory_people_table.dart';
import 'package:attendly/data/local/tables/weekly_entry_table.dart';
import 'package:drift/drift.dart';

part 'delete_dao.g.dart';

@DriftAccessor(tables: [DirectoryPeople, DailyEntry, WeeklyEntry])
class DeleteDao extends DatabaseAccessor<AppDatabase> with _$DeleteDaoMixin, SharedDaoLogic {
  DeleteDao(super.db);

  // --- 1. Delete Person (and all their history) ---
  /// Replaces deleteFromAllPeople from the old implementation.
  Future<void> deleteDirPerson(int id) async {
    await transaction(() async {
      final dailyEntries = await (select(dailyEntry)..where((t) => t.personId.equals(id))).get();
      final person = await (select(directoryPeople)..where((t) => t.id.equals(id))).getSingleOrNull();

      if (person == null) throw PersonNotFoundException(id);

      for (final entry in dailyEntries) {
        final weekDate = getFirstDateOfWeek(entry.date);
        final age = calcAge(entry.date, person.birthday);

        await db.updateDao.updateWeeklyTableCounters(
          weekDate: weekDate,
          age: age,
          gender: person.gender,
          category: entry.category,
          migration: person.migration,
          isAddition: false,
        );

        await db.updateDao.updateCountableColZeroWeek(weekDate);
      }

      await (delete(dailyEntry)..where((t) => t.personId.equals(id))).go();
      await (delete(directoryPeople)..where((t) => t.id.equals(id))).go();
    });
  }

  // --- 2. Delete Single Daily Entry ---
  Future<void> deleteDailyEntry(int recordID, int personId, DateTime date) async {
    await transaction(() async {
      final row = await db.readDao.getEntryWithPerson(recordID, personId, date);
      if (row == null) throw EntryNotFoundException(recordID, personId, date);

      final entry = row.readTable(dailyEntry);
      final person = row.readTable(directoryPeople);
      final weekDate = getFirstDateOfWeek(date);

      await db.updateDao.updateWeeklyTableCounters(
        weekDate: weekDate,
        age: calcAge(date, person.birthday),
        gender: person.gender,
        category: entry.category,
        migration: person.migration,
        isAddition: false,
      );

      await (delete(dailyEntry)..where((t) => 
        t.recordId.equals(recordID) & 
        t.date.equals(db.dateOnlyConverter.toSql(date)) & 
        t.personId.equals(personId)
      )).go();

      await db.updateDao.updateCountableColZeroWeek(weekDate);
    });
  }

  // --- 3. Deletion of multiple entries for a date ---
  /// Replaces deleteMultipleDailyEntriesForPeople.
  Future<void> deleteMultipleDailyEntries(List<int> personIds, DateTime date) async {
    await transaction(() async {
      for (final id in personIds) {
        // Find all records for that person on that specific date
        final entries = await (select(dailyEntry)
              ..where((t) => t.personId.equals(id) & t.date.equals(db.dateOnlyConverter.toSql(date))))
            .get();

        for (final entry in entries) {
          await deleteDailyEntry(entry.recordId, entry.personId, entry.date);
        }
      }
    });
  }
}