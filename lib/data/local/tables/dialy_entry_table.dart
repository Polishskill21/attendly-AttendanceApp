import 'package:attendly/data/local/tables/date_only_converter.dart';
import 'package:attendly/data/local/tables/directory_people_table.dart';
import 'package:attendly/data/local/tables/enums/category.dart';
import 'package:drift/drift.dart';

class DailyEntry extends Table{
  IntColumn get recordID => integer().named('record_id')();
  TextColumn get dates => text().map(const DateOnlyConverter())();
  IntColumn get id => integer().references(DirectoryPeople, #id)();
  TextColumn get category => textEnum<Category>()();
  TextColumn get description => text().nullable()();

  @override
  Set<Column> get primaryKey => {recordID, dates, id};
}