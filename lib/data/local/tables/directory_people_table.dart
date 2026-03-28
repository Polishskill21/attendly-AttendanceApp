import 'package:attendly/data/local/tables/date_only_converter.dart';
import 'package:attendly/data/local/tables/enums/gender.dart';
import 'package:drift/drift.dart';

class DirectoryPeople extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().customConstraint('NOT NULL UNIQUE ON CONFLICT FAIL COLLATE NOCASE')();
  TextColumn get birthday => text().map(const DateOnlyConverter())();

  //https://drift.simonbinder.eu/type_converters/#implicit-enum-converters:~:text=textEnum%3CStatus%3E%28%29%28%29%3B%20%7D-,Caution%20with%20enums
  TextColumn get gender => textEnum<Gender>()();
  BoolColumn get migration => boolean()();
  TextColumn get migrationBackground => text().nullable()(); 
}