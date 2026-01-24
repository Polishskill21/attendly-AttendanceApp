import 'package:drift/drift.dart';

class WeeklyEntry extends Table{
  //rename it to weekDates
  DateTimeColumn get dates => dateTime()();
  IntColumn get under_10 => integer()();
  IntColumn get age_10_13 => integer()();
  IntColumn get age_14_17 => integer()();
  IntColumn get age_18_24 => integer()();
  IntColumn get over_24 => integer()();
  IntColumn get allM => integer()();
  IntColumn get allF => integer()();
  IntColumn get allD => integer()();
  IntColumn get openMale => integer()();
  IntColumn get openFemale => integer()();
  IntColumn get openDiverse => integer()();
  IntColumn get offersMale => integer()();
  IntColumn get offersFemale => integer()();
  IntColumn get offersDiverse => integer()();
  IntColumn get migrationMale => integer()();
  IntColumn get migrationFemale => integer()();
  IntColumn get migrationDiverse => integer()();
  BoolColumn get countable => boolean()();

  @override
  Set<Column> get primaryKey => {dates}; 
}