import 'package:attendly/data/local/database.dart';
import 'package:attendly/data/local/tables/dialy_entry_table.dart';
import 'package:attendly/data/local/tables/directory_people_table.dart';
import 'package:attendly/data/local/tables/enums/category.dart';
import 'package:attendly/data/local/tables/weekly_entry_table.dart';
import 'package:drift/drift.dart';

part 'read_dao.g.dart';

@DriftAccessor(tables: [DirectoryPeople, DailyEntry, WeeklyEntry])
class ReadDao extends DatabaseAccessor<AppDatabase> with _$ReadDaoMixin {
  ReadDao(super.db);

  // --- Directory --- 

  Future<DirectoryPeopleData?> getPersonById(int id) {
    return (select(directoryPeople)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<DirectoryPeopleData>> getAllPerson(bool ascending) {
    return (select(directoryPeople)
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.name, 
                mode: ascending ? OrderingMode.asc : OrderingMode.desc)
          ]))
        .get();
  }

  Future<List<DirectoryPeopleData>> findPeopleByName(String name) {
    return (select(directoryPeople)..where((t) => t.name.equals(name))).get();
  }

  // --- Daily ---

  Future<List<DailyEntryData>> getDailyEntriesByPersonId(int id) {
    return (select(dailyEntry)..where((t) => t.id.equals(id))).get();
  }

  Future<DateTime?> getLatestDailyDate() async {
    final query = selectOnly(dailyEntry)..addColumns([dailyEntry.dates.max()]);
    final result = await query.map((row) => row.read(dailyEntry.dates.max())).getSingle();
    return result != null ? db.dateOnlyConverter.fromSql(result) : null;
  }

  Future<bool> existsEntryForDate(DateTime date) async {
    final query = select(dailyEntry)..where((t) => t.dates.equals(db.dateOnlyConverter.toSql(date)));
    final result = await query.get();
    return result.isNotEmpty;
  }

  Future<Category?> getCategory(int recordId, DateTime date, int personId) async {
    final query = select(dailyEntry)
      ..where((t) => t.recordID.equals(recordId) & t.dates.equals(db.dateOnlyConverter.toSql(date)) & t.id.equals(personId));
    final entry = await query.getSingleOrNull();
    return entry?.category;
  }

  Future<bool> hasOpenCategoryForDate(int personId, DateTime date) async {
    final query = select(dailyEntry)
      ..where((t) => 
        t.id.equals(personId) & 
        t.dates.equals(db.dateOnlyConverter.toSql(date)) &
        t.category.equals(Category.open.name)
      );
    final result = await query.getSingleOrNull();
    return result != null;
  }

  Future<int> countEntriesForPerson(int personId) async {
    final countExp = dailyEntry.id.count();
    final query = selectOnly(dailyEntry)
      ..addColumns([countExp])
      ..where(dailyEntry.id.equals(personId));
    final result = await query.map((row) => row.read(countExp)).getSingle();
    return result ?? 0;
  }

  Future<List<TypedResult>> getPeopleFromCurrentDay(DateTime date) {
    final query = select(dailyEntry).join([
      innerJoin(directoryPeople, directoryPeople.id.equalsExp(dailyEntry.id)),
    ])
      ..where(dailyEntry.dates.equals(db.dateOnlyConverter.toSql(date)));

    return query.get();
  }

  Future<List<TypedResult>> searchDailyLogs({String? name, String? description, String? category}) {
    final query = select(dailyEntry).join([
      innerJoin(directoryPeople, directoryPeople.id.equalsExp(dailyEntry.id)),
    ]);

    if (name != null && name.isNotEmpty) {
      query.where(directoryPeople.name.lower().like('%${name.toLowerCase()}%'));
    }
    if (description != null && description.isNotEmpty) {
      query.where(dailyEntry.description.lower().like('%${description.toLowerCase()}%'));
    }
    if (category != null && category.isNotEmpty) {
      query.where(dailyEntry.category.equals(category));
    }

    query.orderBy([OrderingTerm.desc(dailyEntry.dates), OrderingTerm.asc(directoryPeople.name)]);

    return query.get();
  }

  Future<TypedResult?> getEntryWithPerson(int recordID, int personId, DateTime date) {
    return (select(dailyEntry).join([
      innerJoin(directoryPeople, directoryPeople.id.equalsExp(dailyEntry.id)),
    ])..where(
        dailyEntry.recordID.equals(recordID) & 
        dailyEntry.dates.equals(db.dateOnlyConverter.toSql(date)) & 
        dailyEntry.id.equals(personId)
      )).getSingleOrNull();
  }

  // --- Weekly & Stats Queries ---

  Future<WeeklyEntryData?> getWeeklyEntryByDate(DateTime date) {
    return (select(weeklyEntry)..where((t) => t.dates.equals(db.dateOnlyConverter.toSql(date)))).getSingleOrNull();
  }

  Future<List<WeeklyEntryData>> getAllWeeklyEntries() {
    return (select(weeklyEntry)
      ..orderBy([(t) => OrderingTerm.desc(t.dates)]))
      .get();
  }

  Future<List<TypedResult>> getAllDailyEntriesWithPeople() {
    return (select(dailyEntry).join([
      innerJoin(directoryPeople, directoryPeople.id.equalsExp(dailyEntry.id)),
    ])).get();
  }

  Future<bool> areAllColumnsZero(DateTime weekDate) async {
    final dateStr = db.dateOnlyConverter.toSql(weekDate);

    final query = customSelect(
      'SELECT (under_10 + age_10_13 + age_14_17 + age_18_24 + over_24 + '
      'all_m + all_f + all_d + open_male + open_female + open_diverse + '
      'offers_male + offers_female + offers_diverse + '
      'migration_male + migration_female + migration_diverse) AS total '
      'FROM weekly_entry WHERE dates = ?',
      variables: [Variable<String>(dateStr)],
    );

    final row = await query.getSingleOrNull();
    if (row == null) return false;

    final total = row.read<int>('total');
    return total == 0;
  }
}