import 'package:drift/drift.dart';

class DirectoryPeople extends Table {
  @override
  String get tableName => 'all_people';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  DateTimeColumn get birthday => dateTime()();
  TextColumn get gender => text().check(gender.isIn(['m', 'f', 'd']))();
  BoolColumn get migration => boolean()();
  TextColumn get migrationBackground => text().named('migration_background')();
}