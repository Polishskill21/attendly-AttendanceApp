import 'package:attendly/backend/dbLogic/db_base.dart';
import 'package:attendly/backend/dbLogic/db_insert.dart';
import 'package:attendly/backend/db_exceptions.dart' as custom_db_exceptions;
import 'package:attendly/backend/enums/category.dart';
import 'package:attendly/backend/enums/genders.dart';
import 'package:attendly/backend/global/global_func.dart';
import '../helpers/child.dart';
import 'db_read.dart';
import 'package:flutter/material.dart';

class DbUpdater extends DbBaseHandler {  
  final DbSelection reader;

  DbUpdater(super.db, this.reader);


/// Recalculates the entire weekly_entry table based on data from daily_entry.
  /// This acts as an "absolute counter" to ensure data integrity.
  Future<void> recalibrateWeeklyData(DbInsertion inserter) async {
    await ensureConnection();
    try {
      await db!.execute("BEGIN TRANSACTION");

      // 1. Preserve the current 'countable' state for each week.
      final countableStates = <String, int>{};
      final existingWeeklyEntries = await reader.getDataFromWeekTable();
      for (final entry in existingWeeklyEntries) {
        final date = entry['dates'] as String;
        final countable = entry['countable'] as int;
        countableStates[date] = countable;
      }
      debugPrint("Preserved 'countable' state for ${countableStates.length} weeks.");

      // 2. Clear the weekly_entry table to start fresh.
      await db!.execute("DELETE FROM weekly_entry");
      debugPrint("Cleared weekly_entry table for recalibration.");

      // 3. Get all daily entries joined with person details for efficient processing.
      String sql = """
        SELECT de.dates, de.id, de.category, ap.birthday, ap.gender, ap.migration
        FROM daily_entry as de
        JOIN all_people as ap ON de.id = ap.id
        ORDER BY de.dates;
      """;
      final dailyEntries = await db!.rawQuery(sql);
      debugPrint("Fetched ${dailyEntries.length} daily entries to process.");

      if (dailyEntries.isEmpty) {
        await db!.execute("COMMIT");
        debugPrint("No daily entries to process. Recalibration finished.");
        return;
      }

      // 4. Process each daily entry to rebuild the weekly stats.
      for (final entry in dailyEntries) {
        final dateStr = entry['dates'] as String;
        final date = DateTime.parse(dateStr);
        final weekDate = getFirstDateOfWeek(date);
        final weekDateStr = dateToString(weekDate);

        // Check if a weekly row for this week has been created in this transaction.
        final weeklyEntryExists = await reader.getLatestWeekDate(weekDateStr);
        if (weeklyEntryExists.isEmpty) {
          // If not, create a default (zeroed) one.
          await inserter.setDefaultValueWeek(weekDateStr);
        }

        // Extract person details from the pre-fetched query result.
        final birthdayStr = entry['birthday'] as String?;
        if (birthdayStr == null || birthdayStr.isEmpty) {
            debugPrint("Skipping entry for person ID ${entry['id']} on $dateStr due to missing birthday.");
            continue; // Age cannot be calculated without a birthday.
        }
        final birthday = DateTime.parse(birthdayStr);
        final age = calcAge(date, birthday);

        final genderStr = entry['gender'] as String;
        final gender = Genders.values.byName(genderStr);

        final categoryStr = entry['category'] as String;
        final category = Category.values.byName(categoryStr);

        final migrationInt = entry['migration'] as int;
        final migration = migrationInt == 1;

        // Use the existing update logic to increment the counters for the week.
        await updateWeeklyTableData(weekDateStr, age, gender, category, migration, '+');
      }

      // 5. Restore the preserved 'countable' states.
      for (final entry in countableStates.entries) {
        await updateCountableCol(entry.key, entry.value);
      }
      debugPrint("Restored 'countable' state for ${countableStates.length} weeks.");

      await db!.execute("COMMIT");
      debugPrint("Successfully recalibrated weekly data.");

    } catch (e, stackTrace) {
      await db!.execute("ROLLBACK");
      debugPrint("Error during weekly data recalibration: $e");
      debugPrintStack(stackTrace: stackTrace);
      throw custom_db_exceptions.DatabaseOperationException(
        "Failed to recalibrate weekly data.",
        originalException: e is Exception ? e : Exception(e.toString()),
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> updateAllPeopleTable(int id, Child child) async {
    await ensureConnection();

    try {
      var res = await reader.getPersonFromAllPeople(id);
      if (res.isEmpty) {
        throw custom_db_exceptions.PersonNotFoundException(id);
      }

      final oldName = res.first['name'] as String;
      final oldBirthdayStr = res.first['birthday'];
      final oldGenderStr = res.first['gender'];
      final oldGender = Genders.values.byName(oldGenderStr);
      final oldMigrationInt = res.first['migration'];
      final oldMigrationBool = oldMigrationInt == 1;

      // PRE-CHECK: If the name is being changed, verify it's unique before the transaction.
      if (oldName != child.name) {
        final existing = await db!
            .rawQuery('SELECT id FROM all_people WHERE name = ? AND id != ?', [child.name, id]);
        if (existing.isNotEmpty) {
          throw custom_db_exceptions.DuplicatePersonException(child.name);
        }
      }

      // Start transaction only after pre-checks have passed.
      await db!.execute("BEGIN TRANSACTION");
      try {
        // Check if any data that affects weekly stats has changed.
        if (oldBirthdayStr != child.birthday ||
            oldGender != child.gender ||
            oldMigrationBool != child.migration) {
          final allEntriesDaily = await reader.getAllEntriesfromDaily(id);

          for (Map<String, dynamic> dailyEntry in allEntriesDaily) {
            if (oldGender != child.gender) {
              await _updateRecordForGender(dailyEntry, oldGender, child.gender);
            }

            if (oldBirthdayStr != child.birthday) {
              await _updateRecordForBirthday(
                  dailyEntry, oldBirthdayStr, child.birthday);
            }

            if (oldMigrationBool != child.migration ||
                oldGender != child.gender) {
              await _updateRecordForMigration(
                  dailyEntry, oldMigrationBool, child.migration, oldGender, child.gender);
            }
          }
        }

        // Unconditionally update the person's details in the all_people table.
        // This ensures all fields (name, birthday, etc.) are updated regardless of what changed.
        await _updatePersonInAllPeopleTable(id, child);

        await db!.execute("COMMIT");
      } catch (e) {
        // If anything fails inside the transaction, roll back and rethrow.
        await db!.execute("ROLLBACK");
        rethrow;
      }
    } on custom_db_exceptions.DatabaseException {
      // Rethrow custom exceptions to be handled by the UI.
      rethrow;
    } catch (e, stackTrace) {
      // Wrap any other unexpected errors.
      debugPrint("Failed to update person with id $id. Error: $e");
      debugPrintStack(stackTrace: stackTrace);
      throw custom_db_exceptions.DatabaseOperationException(
          "Failed to update person with id $id",
          originalException: e is Exception ? e : Exception(e.toString()),
          stackTrace: stackTrace);
    }
  }

  ///updating only category and/or description, pass new values to this function
  Future<void> updateDailyTable(int recordID, String date, int id, Category newCategory, String? newDescription) async{
    await ensureConnection();
    
    try{
      var result = await reader.getCategoryAndDescriptionDaily(recordID, date, id);
      String oldCategoryStr = result.first['category'];
      String? oldDescription = result.first['description'];

      if (oldCategoryStr == newCategory.name && oldDescription == newDescription) {
        // No update needed
        debugPrint("no update, since data same");
        return;
      }

      await db!.execute("BEGIN TRANSACTION");

      if(oldCategoryStr != newCategory.name){
        //update both
        Category oldCategory = Category.values.byName(oldCategoryStr);
        var res = await reader.getGenderAndMigration(id);
        int migrationInt = res.first['migration'];
        bool migrationBool = migrationInt == 1 ? true: false;
        Genders gender = Genders.values.byName(res.first['gender']);
        
        DateTime weekDate = getFirstDateOfWeek(DateTime.parse(date));
        String weekDateStr = dateToString(weekDate);

        await _updateWeeklyTableGenderCategory(weekDateStr, gender, newCategory, oldCategory, migrationBool);
        String sql = "UPDATE daily_entry SET category = ? WHERE record_id = ? AND dates = ? AND id = ?";
        await db!.execute(sql, [newCategory.name, recordID, date, id]);
      }

      if(newDescription != oldDescription){
        //update descritption
        String sql = "UPDATE daily_entry SET description = ? WHERE record_id = ? AND dates = ? AND id = ?";
        await db!.execute(sql, [newDescription, recordID, date, id]);
      }

      await db!.execute("COMMIT");
    }
    catch (e, stackTrace){
      debugPrint("Error updating daily table: $e");
      debugPrintStack(stackTrace: stackTrace);
      await db!.execute("ROLLBACK");
      if (e is custom_db_exceptions.DatabaseException) {
        rethrow;
      }
      if(e is custom_db_exceptions.DuplicatePersonException){
        rethrow;
      }
      throw custom_db_exceptions.DatabaseOperationException("Failed to update daily entry", originalException: e as Exception, stackTrace: stackTrace);
    }
  }


   ///calculating with current data, nothing to do with past entries only with current ones
  Future<void> updateWeeklyTableData(String weekDate, int age, Genders gender, Category category, bool migration, String operator ) async{
    await ensureConnection();
    
    try{
      final ageCol = _determineAgeGroup(age);
      final genderCol = _determineGenderColumn(gender);
      final genderCat = _determineGenderCategory(gender, category);
      final migrationCol = _determineMigrationCol(gender, migration);
  
      String sql = """
                    UPDATE weekly_entry
                    SET $ageCol = $ageCol $operator 1,
                    $genderCol = $genderCol $operator 1
                    WHERE dates = ?;""";

      await db!.execute(sql, [weekDate]);

      if(genderCat.isNotEmpty){
        String sql = """
                      UPDATE weekly_entry
                      SET $genderCat = $genderCat $operator 1
                      WHERE dates = ?;""";

        await db!.execute(sql, [weekDate]);
      }

      if(migrationCol.isNotEmpty && category == Category.open){
        String sql = """
                      UPDATE weekly_entry
                      SET $migrationCol = $migrationCol $operator 1
                      WHERE dates = ?;""";
        await db!.execute(sql, [weekDate]);
      }
    }
    catch (e, stackTrace){
      debugPrint(e.toString());
      debugPrintStack(stackTrace: stackTrace);
      if (e is custom_db_exceptions.DatabaseException) {
        rethrow;
      }
      throw custom_db_exceptions.DatabaseOperationException("Failed to update weekly table data", originalException: e as Exception, stackTrace: stackTrace);
    }
  }

  Future<void> updateCountableColZeroWeek(String weekDate) async {
    try {
      String sql;
      int newValue = 0;

      bool onlyIfAllZero = await reader.areAllColumnsZero(weekDate);

      if (!onlyIfAllZero) {
        debugPrint("no column to update, no zero values");
        return;
      } 

      sql = """
        UPDATE weekly_entry
        SET countable = ?
        WHERE dates = ?
      """;
      await db!.execute(sql, [newValue, weekDate]);
    } catch (e, stackTrace) {
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
    }
  }

  Future<void> updateCountableCol(String weekDate, int newValue) async{
    try {
      String sql;

      sql = "UPDATE weekly_entry SET countable = ? WHERE dates = ?";

      await db!.execute(sql, [newValue, weekDate]);
    } catch (e, stackTrace) {
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
    }
  }

  Future<void> _updateWeeklyTableGenderCategory(String weekDate, Genders gender, Category newCategory, Category oldCategory, bool migrationBool) async{
  
    String genderCol = _determineGenderColumn(gender);
    String oldGenderCategory = _determineGenderCategory(gender, oldCategory);
    String newGenderCategory = _determineGenderCategory(gender, newCategory);
    String migrationCol = _determineMigrationCol(gender, migrationBool);

    String sql = """
      UPDATE weekly_entry
      SET 
        $genderCol = $genderCol - 1 + 1
        ${oldGenderCategory.isNotEmpty ? ', $oldGenderCategory = $oldGenderCategory - 1' : ''}
        ${newGenderCategory.isNotEmpty ? ', $newGenderCategory = $newGenderCategory + 1' : ''}
      WHERE dates = ?;
      """;

    await db!.execute(sql, [weekDate]);

    if (oldCategory == Category.open || newCategory == Category.open) {
      int migrationChange = (newCategory == Category.open ? 1 : 0) - (oldCategory == Category.open ? 1 : 0);
      if (migrationChange != 0) {
        String sql = "UPDATE weekly_entry SET $migrationCol = $migrationCol + ? WHERE dates = ?";
        await db!.execute(sql, [migrationChange, weekDate]);
      }
    }
  }

  Future<void> _updatePersonInAllPeopleTable(int id, Child child) async {
    try {
      String sql = """
                  UPDATE all_people
                  SET name = ?,
                      birthday = ?,
                      gender = ?,
                      migration = ?,
                      migration_background = ?
                  WHERE id = ?;""";
      await db!.execute(sql, [
        child.name,
        child.birthday,
        child.gender.name,
        child.migration ? 1 : 0,
        child.migrationBackground,
        id
      ]);
    } catch (e, stackTrace) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> _updateRecordForGender(Map<String, dynamic> record, Genders oldGender, Genders newGender) async{
    try{
      await _updateWeeklyTableGenderFromDailyEntry(record, oldGender, '-');
      await _updateWeeklyTableGenderFromDailyEntry(record, newGender, '+');
    }
    catch(e, stackTrace){
      debugPrint(e.toString());
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> _updateRecordForBirthday(Map<String, dynamic> record, String oldBirthdayStr, String newBirthday) async{
    try{
      await _updateWeeklyTableBirthdayFromDailyEntry(record, oldBirthdayStr, "-");
      await _updateWeeklyTableBirthdayFromDailyEntry(record, newBirthday, "+");
    }
    catch(e, stackTrace){
      debugPrint(e.toString());
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> _updateRecordForMigration(Map<String, dynamic> record, bool oldMigrationBool, bool newMigration, Genders oldGender, Genders newGender) async{
    try{
      await _updateWeeklyTableMigrationFromDailyEntry(record, oldMigrationBool, oldGender, "-");
      await _updateWeeklyTableMigrationFromDailyEntry(record, newMigration, newGender, "+");
    }
    catch(e, stackTrace){
      debugPrint(e.toString());
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> _updateWeeklyTableGenderFromDailyEntry(Map<String, dynamic> record, Genders gender, String operator ) async{
    try{
      String categoryStr = record['category'];
      final category = Category.values.byName(categoryStr);
      String dateStr = record['dates'];
      DateTime dateOfRecord = DateTime.parse(dateStr);
      final weekDateOfRecord = dateToString(getFirstDateOfWeek(dateOfRecord));

      final genderCol = _determineGenderColumn(gender);
      final genderCat = _determineGenderCategory(gender, category);
  
      String sql = """
                    UPDATE weekly_entry
                    SET $genderCol = $genderCol $operator 1
                    WHERE dates = ?;""";

      await db!.execute(sql, [weekDateOfRecord]);

      if(genderCat.isNotEmpty){
        String sql = """
                      UPDATE weekly_entry
                      SET $genderCat = $genderCat $operator 1
                      WHERE dates = ?;""";

        await db!.execute(sql, [weekDateOfRecord]);
      }
    }
    catch (e, stackTrace){
      debugPrint(e.toString());
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

//Birthday
Future<void> _updateWeeklyTableBirthdayFromDailyEntry(Map<String, dynamic> record, String birthday, String operator ) async{
    try{
      //calculate birthday
      final date = record['dates'];
      DateTime birthdayDateObj = DateTime.parse(birthday);
      DateTime dateOfRecord = DateTime.parse(date);

      final age = calcAge(dateOfRecord, birthdayDateObj);
      final ageCol = _determineAgeGroup(age);
      final weekDateOfRecord = dateToString(getFirstDateOfWeek(dateOfRecord));
  
      String sql = """
                    UPDATE weekly_entry
                    SET $ageCol = $ageCol $operator 1
                    WHERE dates = ?;""";

      await db!.execute(sql, [weekDateOfRecord]);

    }
    catch (e, stackTrace){
      debugPrint(e.toString());
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }


  Future<void> _updateWeeklyTableMigrationFromDailyEntry(Map<String, dynamic> record, bool migration, Genders gender, String operator) async{
    try{
      String categoryStr = record['category'];
      final category = Category.values.byName(categoryStr);
      String dateStr = record['dates'];
      DateTime dateOfRecord = DateTime.parse(dateStr);

      final migrationCol = _determineMigrationCol(gender, migration);
      final weekDateOfRecord = dateToString(getFirstDateOfWeek(dateOfRecord));

      if(migrationCol.isNotEmpty && category == Category.open && migration){
        String sql = """
                      UPDATE weekly_entry
                      SET $migrationCol = $migrationCol $operator 1
                      WHERE dates = ?;""";
        await db!.execute(sql, [weekDateOfRecord]);
      }
    }
    catch (e, stackTrace){
      debugPrint(e.toString());
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  String _determineAgeGroup(int age){
    if(age < 10){
      return "under_10";
    }
    else if(age <= 13){
      return "age_10_13";
    }
    else if(age <= 17){
      return "age_14_17";
    }
    else if( age <= 24){
      return "age_18_24";
    }
    else{
      return "over_24";
    }
  }

  String _determineGenderColumn(Genders gender){
    switch(gender){
      case Genders.m:
        return "all_m";

      case Genders.f:
        return "all_f";
      
      case Genders.d:
        return "all_d";
    }
  }
  
  String _determineGenderCategory(Genders gender, Category category){

    switch(category){
      case Category.open:

        switch(gender){
          case Genders.m:
          return "open_male";
          case Genders.f:
          return "open_female";
          case Genders.d:
          return "open_diverse";
        }
      case Category.offer:

        switch(gender){
          case Genders.m:
          return "offers_male";
          case Genders.f:
          return "offers_female";
          case Genders.d:
          return "offers_diverse";
        }

      default:
        return "";
    }
  }
  
  String _determineMigrationCol(Genders gender, bool migration) {
    if(migration){
      switch(gender){
        case Genders.m:
        return "migration_male";
        case Genders.f:
        return "migration_female";
        case Genders.d:
        return "migration_diverse";
      }
    }
    else{
      return "";
    }
  }
}

  // Future<void> setWeekToZero(String weekDate) async{
  //   await ensureConnection();
    
  //   String sql = """
  //       UPDATE weekly_entry
  //       SET 
  //           under_10 = 0, 
  //           age_10_13 = 0, 
  //           age_14_17 = 0, 
  //           age_18_24 = 0, 
  //           over_24 = 0, 
  //           all_m = 0, 
  //           all_f = 0, 
  //           all_d = 0, 
  //           open_male = 0, 
  //           open_female = 0, 
  //           open_diverse = 0, 
  //           offers_male = 0, 
  //           offers_female = 0, 
  //           offers_diverse = 0,
  //           migration_male = 0,
  //           migration_female = 0,
  //           migration_diverse = 0
  //       WHERE dates = ?;
  //   """;

  //   await db!.execute(sql, [weekDate]);
  // }