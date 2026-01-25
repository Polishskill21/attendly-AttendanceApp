import 'dart:io';
import 'package:attendly/data/local/dao/read_dao.dart';
import 'package:attendly/data/local/tables/date_only_converter.dart';
import 'package:attendly/data/local/tables/dialy_entry_table.dart';
import 'package:attendly/data/local/tables/directory_people_table.dart';
import 'package:attendly/data/local/tables/enums/category.dart';
import 'package:attendly/data/local/tables/enums/gender.dart';
import 'package:attendly/data/local/tables/weekly_entry_table.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [DirectoryPeople, DailyEntry, WeeklyEntry],
  daos: [ReadDao]
)
class AppDatabase extends _$AppDatabase{
  AppDatabase(super.executor);

  AppDatabase.testInstance() : super(
    NativeDatabase.memory(setup: (db) {
      db.execute('PRAGMA foreign_keys = ON');
    }),
  );

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (m, from, to) async {
        await transaction(() async {
          if (from < 2) {
            // Appends 'T00:00:00.000' to any string that doesn't have a 'T' yet 
            await customStatement("UPDATE all_people SET birthday = birthday || 'T00:00:00.000' WHERE birthday NOT LIKE '%T%'");
            await customStatement("UPDATE daily_entry SET dates = dates || 'T00:00:00.000' WHERE dates NOT LIKE '%T%'");
            await customStatement("UPDATE weekly_entry SET dates = dates || 'T00:00:00.000' WHERE dates NOT LIKE '%T%'");
          }
        });
      },
      beforeOpen: (details) async {
        // This runs every time the database is opened 
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

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