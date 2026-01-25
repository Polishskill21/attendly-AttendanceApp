import 'dart:io';
import 'package:attendly/data/local/tables/dialy_entry_table.dart';
import 'package:attendly/data/local/tables/directory_people_table.dart';
import 'package:attendly/data/local/tables/enums/category.dart';
import 'package:attendly/data/local/tables/enums/gender.dart';
import 'package:attendly/data/local/tables/weekly_entry_table.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'database.g.dart';

@DriftDatabase(tables: [DirectoryPeople, DailyEntry, WeeklyEntry])
class AppDatabase extends _$AppDatabase{
  AppDatabase(super.executor);

  AppDatabase.testInstance() : super(
    NativeDatabase.memory(setup: (db) {
      db.execute('PRAGMA foreign_keys = ON');
    }),
  );

  @override
  int get schemaVersion => 1;

  Future<void> forceOpen() async {
    await customSelect('SELECT 1').getSingle();
  }

  /// First call the 
  static QueryExecutor createExecutor(File filename){
    return NativeDatabase(
      filename,
      setup: (db) {
        db.execute('PRAGMA foreign_keys = ON;');
      },
    );
  }
}