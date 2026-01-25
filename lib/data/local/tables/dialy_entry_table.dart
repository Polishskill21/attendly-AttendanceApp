import 'package:attendly/data/local/tables/directory_people_table.dart';
import 'package:attendly/data/local/tables/enums/category.dart';
import 'package:drift/drift.dart';

class DailyEntry extends Table{
  IntColumn get recordID => integer().named('record_id')();
  DateTimeColumn get dates => dateTime()();
  IntColumn get id => integer().references(DirectoryPeople, #id)();
  TextColumn get categroy => textEnum<Category>()();
  //TextColumn get category => text().check(category.isIn(['open', 'offer', 'parent', 'other']))();
  TextColumn get description => text()();

  @override
  Set<Column> get primaryKey => {recordID, dates, id};
}