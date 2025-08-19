import 'package:attendly/backend/dbLogic/db_base.dart';
import 'package:flutter/material.dart';


class DbCreation extends DbBaseHandler { 
  DbCreation(super.db);

  Future<void> init() async{
    await ensureConnection();
    
    try{
      //AUTOINCREMENT key is going to create a table called sqlite_squence to keep track of the autoincrementation
      // Create the tables and insert initial data separately
      String createAllPeopleTable = """
        CREATE TABLE IF NOT EXISTS all_people(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT UNIQUE ON CONFLICT FAIL,
          birthday DATE,
          gender TEXT CHECK(gender IN ('m', 'f', 'd')),
          migration INTEGER,
          migration_background TEXT
        );
      """;

      String createDailyEntryTable = """
        CREATE TABLE IF NOT EXISTS daily_entry(
          record_id INTEGER, 
          dates DATE,
          id INTEGER,
          category TEXT CHECK(category IN('open', 'offer', 'parent', 'other')),
          description TEXT,
          FOREIGN KEY (id) REFERENCES all_people(id),
          PRIMARY KEY(record_id, dates, id)
        );
      """;

      String createWeeklyEntryTable = """
        CREATE TABLE IF NOT EXISTS weekly_entry(
          dates DATE PRIMARY KEY NOT NULL,
          under_10 INTEGER NOT NULL,
          age_10_13 INTEGER NOT NULL,
          age_14_17 INTEGER NOT NULL,
          age_18_24 INTEGER NOT NULL,
          over_24 INTEGER NOT NULL,
          all_m INTEGER NOT NULL,
          all_f INTEGER NOT NULL,
          all_d INTEGER NOT NULL,
          open_male INTEGER NOT NULL,
          open_female INTEGER NOT NULL,
          open_diverse INTEGER NOT NULL,
          offers_male INTEGER NOT NULL,
          offers_female INTEGER NOT NULL,
          offers_diverse INTEGER NOT NULL,
          migration_male INTEGER NOT NULL,
          migration_female INTEGER NOT NULL,
          migration_diverse INTEGER NOT NULL,
          countable INTEGER NOT NULL
        );
      """;



      //String insertDummyData = """
        //INSERT INTO all_people(name,birthday,gender,migration,migration_background) 
        //VALUES('dummy', NULL, NULL, NULL, NULL);
      //""";
        //ON CONFLICT(name) DO NOTHING
        
      // Execute the SQL statements
      await db!.execute(createAllPeopleTable);
      await db!.execute(createDailyEntryTable);
      await db!.execute(createWeeklyEntryTable); 
           
      //String sql = "SELECT name FROM all_people WHERE id = 1";
      //var res = await db.rawQuery(sql);

      //if (res.isNotEmpty && res[0]['name'] == "dummy") {
        //debugPrint("Executed once");
        //return;
      //}

      //await db.execute(insertDummyData);
      debugPrint("Executed once");
    }
    catch (e, stackTrace){
      debugPrint(e.toString());
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> moveTableContent(String oldDBPath, String newDBPath) async{
    await ensureConnection();
    
    try{
      // The currently connected DB is the NEW one. We attach the OLD one to it.
      String sqlAttachDB = """ATTACH DATABASE ? AS old_db""";
      String sqlCopyData = """INSERT INTO main.all_people SELECT * FROM old_db.all_people;""";
      String sqlDetachDB = """DETACH DATABASE old_db""";

      await db!.execute(sqlAttachDB, [oldDBPath]); 
      await db!.execute(sqlCopyData);
      await db!.execute(sqlDetachDB);
      debugPrint("Successfully moved 'all_people' table content.");
    }
    catch (e, stackTrace){
        debugPrint("Error moving table content: $e");
        debugPrintStack(stackTrace: stackTrace);
        rethrow;
    }
  }
}