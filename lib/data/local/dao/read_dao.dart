import 'package:attendly/data/local/config/database.dart';
import 'package:attendly/data/local/tables/daily_entry_table.dart';
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

  Future<List<Map<String, dynamic>>> getYearStats() async {
    const sql = '''
      SELECT 
        SUM(under_10) AS under_10, 
        SUM(age_10_13) AS age_10_13, 
        SUM(age_14_17) AS age_14_17, 
        SUM(age_18_24) AS age_18_24,
        SUM(over_24) AS over_24, 
        SUM(all_m) AS all_m, 
        SUM(all_f) AS all_f,
        SUM(all_d) AS all_d, 
        SUM(open_male) AS open_male, 
        SUM(open_female) AS open_female,
        SUM(open_diverse) AS open_diverse, 
        SUM(offers_male) AS offers_male, 
        SUM(offers_female) AS offers_female, 
        SUM(offers_diverse) AS offers_diverse,    
        SUM(migration_male) as migration_male,
        SUM(migration_female) as migration_female,
        SUM(migration_diverse) as migration_diverse
      FROM weekly_entry
      WHERE countable != 0;
    ''';

    final result = await customSelect(sql).get();
    return result.map((row) => row.data).toList();
  }

  /// Counts recorded weeks where countable is not 0
  Future<int> getWeekCount() async {
    final countExp = weeklyEntry.dates.count();
    final query = selectOnly(weeklyEntry)
      ..addColumns([countExp])
      ..where(weeklyEntry.countable.equals(true));

    final result = await query.map((row) => row.read(countExp)).getSingle();
    return result ?? 0;
  }
}