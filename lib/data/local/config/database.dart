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
import 'package:attendly/global/app_logger.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [DirectoryPeople, DailyEntry, WeeklyEntry],
  daos: [ReadDao, UpdateDao, InsertDao, DeleteDao]
)
class AppDatabase extends _$AppDatabase{
  static const String _tag = "Database";

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
        AppLogger.i(_tag, "Schema migration started: v$from -> v$to");
        if (onMigrationStarted != null) {
          await onMigrationStarted!();
        }

        final stopwatch = Stopwatch()..start();
        try {
          await _runMigration(m, from);
        } catch (e, stackTrace) {
          AppLogger.e(_tag, "Schema migration v$from -> v$to failed, transaction rolled back", e, stackTrace);
          rethrow;
        }
        AppLogger.i(_tag, "Schema migration v$from -> v$to finished in ${stopwatch.elapsedMilliseconds} ms");
      },
      beforeOpen: (details) async {
        AppLogger.i(_tag, "Database opened: schema v${details.versionNow}"
            "${details.wasCreated ? ' (newly created)' : details.hadUpgrade ? ' (upgraded from v${details.versionBefore})' : ''}");
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _runMigration(Migrator m, int from) async {
    await transaction(() async {
      if (from < 2) {
        AppLogger.i(_tag, "Migrating table to v2: Renaming tables and columns");

        await m.renameTable(directoryPeople, 'all_people');

        await m.renameColumn(dailyEntry, 'dates', dailyEntry.date);
        await m.renameColumn(dailyEntry, 'id', dailyEntry.personId);

        await m.renameColumn(weeklyEntry, 'dates', weeklyEntry.weekDate);


        AppLogger.i(_tag, "Migrating table to v2: Adjusting date formatting");

        await customStatement("UPDATE directory_people SET birthday = birthday || 'T00:00:00.000' WHERE birthday NOT LIKE '%T%'");
        await customStatement("UPDATE daily_entry SET date = date || 'T00:00:00.000' WHERE date NOT LIKE '%T%'");
        await customStatement("UPDATE weekly_entry SET week_date = week_date || 'T00:00:00.000' WHERE week_date NOT LIKE '%T%'");

        AppLogger.i(_tag, "Migrating table to v2: Rebuilding for new name constraints");

        await m.alterTable(TableMigration(directoryPeople));
      }
    });
  }

  Future<void> forceOpen() async {
    await customSelect('SELECT 1').getSingle();
  }

  Future<void> copyPersonDirFromOldDatabase(String oldDbPath) async {
    try {
      String sqlAttachDB = "ATTACH DATABASE ? AS old_db;";
      await customStatement(sqlAttachDB, [oldDbPath]);

      try {
        AppLogger.i(_tag, "Copying 'directory_people' from $oldDbPath");
        await transaction(() async {
          String sqlCopyData = "INSERT INTO main.directory_people SELECT * FROM old_db.directory_people;";
          await customStatement(sqlCopyData);

        });

        final copied = await customSelect("SELECT COUNT(*) AS c FROM main.directory_people").getSingle();
        AppLogger.i(_tag, "Rolled over ${copied.read<int>('c')} people into the new year database");

      } finally {
        String sqlDetachDB = "DETACH DATABASE old_db;";
        await customStatement(sqlDetachDB);
      }

    } catch (e, stackTrace) {
      AppLogger.e(_tag, "Copying people from $oldDbPath failed", e, stackTrace);
      rethrow;
    }
  }

  /// First call the
  static QueryExecutor openConnection(File dbPath) {
    return LazyDatabase(() async {
      return NativeDatabase.createInBackground(dbPath, logStatements: AppLogger.logSqlStatements);
    });
  }
}