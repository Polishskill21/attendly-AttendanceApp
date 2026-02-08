import 'package:attendly/data/local/dao/shared_dao_logic.dart';
import 'package:attendly/data/local/database.dart';
import 'package:attendly/data/local/db_exceptions.dart';
import 'package:attendly/data/local/tables/dialy_entry_table.dart';
import 'package:attendly/data/local/tables/directory_people_table.dart';
import 'package:attendly/data/local/tables/enums/category.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'insert_dao.g.dart';

@DriftAccessor(tables: [DirectoryPeople, DailyEntry])
class InsertDao extends DatabaseAccessor<AppDatabase> with _$InsertDaoMixin, SharedDaoLogic {
  InsertDao(super.db);

  // --- 1. All People Table Insertion ---
  /// Replaces allPeopleTable. Inserts a person into the directory.
  Future<void> insertDirPerson(DirectoryPeopleCompanion person) async {
    try {
      await into(directoryPeople).insert(person);
    } on SqliteException catch (e) {
      if (e.extendedResultCode == 2067) {
        throw DuplicatePersonException(person.name.value);
      }
      throw DatabaseOperationException("Database constraint failed", originalException: e);
    } catch (e) {
      rethrow;
    }
  }

  // --- 2. Daily Table Insertion ---
  /// Replaces dailyTable.
  Future<void> insertDailyEntry({
    required int personId,
    required DateTime date,
    required Category category,
    String? description,
  }) async {
    await transaction(() async {
      // Check if person exists
      final person = await db.readDao.getPersonById(personId);
      if (person == null) {
        throw PersonNotFoundException(personId);
      }

      if (category == Category.open) {        
        if (await db.readDao.hasOpenCategoryForDate(personId, date)) {
          throw DuplicateDailyEntryException();
        }
      }

      final latestId = await _getLatestRecordID(date);

      await into(dailyEntry).insert(DailyEntryCompanion.insert(
        recordID: latestId,
        dates: date,
        id: personId,
        category: category,
        description: Value(description),
      ));

      await _updateWeeklyStats(person, category, date);
    });
  }

  // --- Helper Methods ---

  Future<int> _getLatestRecordID(DateTime date) async {
    final query = selectOnly(dailyEntry)
      ..addColumns([dailyEntry.recordID.max()])
      ..where(dailyEntry.dates.equals(db.dateOnlyConverter.toSql(date)));
    
    final result = await query.map((row) => row.read(dailyEntry.recordID.max())).getSingle();
    return (result ?? 0) + 1;
  }

  Future<void> _updateWeeklyStats(DirectoryPeopleData person, Category category, DateTime date) async {
    final weekDate = getFirstDateOfWeek(date);
    final age = calcAge(date, person.birthday);

    await db.updateDao.updateWeeklyTableCounters(
      weekDate: weekDate,
      age: age,
      gender: person.gender,
      category: category,
      migration: person.migration,
      isAddition: true,
    );
  }
}