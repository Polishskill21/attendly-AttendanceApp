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
  AppDatabase(super.executor);

  AppDatabase.testInstance() : super(
    NativeDatabase.memory(setup: (db) {
      db.execute('PRAGMA foreign_keys = ON');
    }),
  );

  @override
  int get schemaVersion => 2;

  final dateOnlyConverter = const DateOnlyConverter();

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (m, from, to) async {
        await transaction(() async {
          if (from < 2) {
            debugPrint("Migrating table");
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

  Future<void> copyPersonDirFromOldDatabase(String oldDbPath) async {
    try {
      String sqlAttachDB = "ATTACH DATABASE ? AS old_db;";
      await customStatement(sqlAttachDB, [oldDbPath]);

      try {
        debugPrint("Performing a copy");
        await transaction(() async {
          String sqlCopyData = "INSERT INTO main.all_people SELECT * FROM old_db.all_people;";
          await customStatement(sqlCopyData);
          
        });
        
        debugPrint("Successfully rolled over 'all_people' table to new year database.");
        
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