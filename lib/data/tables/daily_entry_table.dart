import 'package:attendly/data/tables/date_only_converter.dart';
import 'package:attendly/data/tables/directory_people_table.dart';
import 'package:attendly/data/tables/enums/category.dart';
import 'package:drift/drift.dart';

/// Per-day queries filter by date (the primary key starts with record_id, so it
/// cannot serve them); per-person counts, lookups and deletes filter by person.
@TableIndex(name: 'daily_entry_date_person', columns: {#date, #personId})
@TableIndex(name: 'daily_entry_person', columns: {#personId})
class DailyEntry extends Table{
  IntColumn get recordId => integer()();
  TextColumn get date => text().map(const DateOnlyConverter())();
  IntColumn get personId => integer().references(DirectoryPeople, #id)();
  TextColumn get category => textEnum<Category>()();
  TextColumn get description => text().nullable()();

  @override
  Set<Column> get primaryKey => {recordId, date, personId};
}