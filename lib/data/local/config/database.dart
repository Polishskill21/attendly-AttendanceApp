import 'dart:io';
import 'package:attendly/data/local/dao/insert_dao.dart';
import 'package:attendly/data/local/dao/delete_dao.dart';
import 'package:attendly/data/local/dao/read_dao.dart';
import 'package:attendly/data/local/dao/update_dao.dart';
import 'package:attendly/data/local/tables/date_only_converter.dart';
import 'package:attendly/data/local/tables/daily_entry_table.dart';
import 'package:attendly/data/local/tables/directory_people_table.dart';
import 'package:attendly/data/local/tables/enums/category.dart';
import 'package:attendly/data/local/tables/enums/gender.dart';
import 'package:attendly/data/local/tables/weekly_entry_table.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart' show debugPrint, debugPrintStack;

part 'database.g.dart';

@DriftDatabase(
  tables: [DirectoryPeople, DailyEntry, WeeklyEntry],
  daos: [ReadDao, UpdateDao, InsertDao, DeleteDao]
)
class AppDatabase extends _$AppDatabase{
  final Future<void> Function()? onMigrationStarted;

  AppDatabase(super.executor, {this.onMigrationStarted});

  AppDatabase.testInstance() : onMigrationStarted = null, super(
    NativeDatabase.memory(setup: (db) {
      db.execute('PRAGMA foreign_keys = ON');
    }),
  );

  @override
  int get schemaVersion => 2;

  //PRAGMA user_version; to check which db schema version currently is, need to added it to the settings page to display

  final dateOnlyConverter = const DateOnlyConverter();

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (m, from, to) async {
        if (onMigrationStarted != null) {
          await onMigrationStarted!();
        }

        await transaction(() async {
          if (from < 2) {
            debugPrint("Migrating table to v2: Renaming tables and columns");
            
            await m.renameTable(directoryPeople, 'all_people');

            await m.renameColumn(dailyEntry, 'dates', dailyEntry.date);
            await m.renameColumn(dailyEntry, 'id', dailyEntry.personId);

            await m.renameColumn(weeklyEntry, 'dates', weeklyEntry.weekDate);


            debugPrint("Migrating table to v2: Adjusting date formatting");
            
            await customStatement("UPDATE directory_people SET birthday = birthday || 'T00:00:00.000' WHERE birthday NOT LIKE '%T%'");
            await customStatement("UPDATE daily_entry SET date = date || 'T00:00:00.000' WHERE date NOT LIKE '%T%'");
            await customStatement("UPDATE weekly_entry SET week_date = week_date || 'T00:00:00.000' WHERE week_date NOT LIKE '%T%'");

            debugPrint("Migrating table to v2: Rebuilding for new name constraints");
            
            await m.alterTable(TableMigration(directoryPeople));
          }
        });
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> forceOpen() async {
    await customSelect('SELECT 1').getSingle();
  }

  Future<void> copyPersonDirFromOldDatabase(String oldDbPath) async {
    try {
      String sqlAttachDB = "ATTACH DATABASE ? AS old_db;";
      await customStatement(sqlAttachDB, [oldDbPath]);

      try {
        debugPrint("Performing a copy");
        await transaction(() async {
          String sqlCopyData = "INSERT INTO main.directory_people SELECT * FROM old_db.directory_people;";
          await customStatement(sqlCopyData);
          
        });
        
        debugPrint("Successfully rolled over 'directory_people' table to new year database.");
        
      } finally {
        String sqlDetachDB = "DETACH DATABASE old_db;";
        await customStatement(sqlDetachDB);
      }

    } catch (e, stackTrace) {
      debugPrint("Error performing year rollover inside DB: $e");
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  /// First call the 
  static QueryExecutor openConnection(File dbPath) {
    return LazyDatabase(() async {
      return NativeDatabase.createInBackground(dbPath);
    });
  }
}