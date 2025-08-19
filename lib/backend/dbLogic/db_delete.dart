import 'package:attendly/backend/db_exceptions.dart' as custom_db_exceptions;
import 'package:attendly/backend/dbLogic/db_base.dart';
import 'package:attendly/backend/enums/category.dart';
import 'package:attendly/backend/enums/genders.dart';
import 'package:attendly/backend/global/global_func.dart';
import 'package:attendly/backend/dbLogic/db_read.dart';
import 'package:attendly/backend/dbLogic/db_insert.dart';
import 'package:attendly/backend/dbLogic/db_update.dart';

class DbDeletion extends DbBaseHandler {
  final DbSelection reader;
  final DbInsertion inserter;
  final DbUpdater updater;

  DbDeletion(super.db, this.reader, this.inserter, this.updater);

  Future<void> deleteFromAllPeople(int id) async{
    await ensureConnection();
    
    try{
      //transaction
        await db!.execute("BEGIN TRANSACTION");
        var exists = await reader.getPersonFromAllPeople(id);
        var dailyResult = await reader.getAllEntriesfromDaily(id);
        
        if(exists.isNotEmpty){
          if(dailyResult.isNotEmpty){
            //weekly
            for(var result in dailyResult){            
              //each daily day and category
              String eachDayinDailyStr = result['dates'];
              DateTime eachDayinDaily = DateTime.parse(eachDayinDailyStr);
              String weekDate = dateToString(getFirstDateOfWeek(eachDayinDaily));
              String categoryStr = result['category'];
              Category category = Category.values.byName(categoryStr);
              
              // Get age, gender, and migration for the specific record date
              final personDetails = await reader.getAgeAndGenderAndMigration(id, eachDayinDailyStr);
              if (personDetails.isNotEmpty) {
                final age = personDetails.first['age'] as int;
                final genderStr = personDetails.first['gender'] as String;
                final gender = Genders.values.byName(genderStr);
                final migration = (personDetails.first['migration'] as int) == 1;

                // Decrement the weekly table stats
                await updater.updateWeeklyTableData(weekDate, age, gender, category, migration, '-');
              }
            }
          }
        }
        else{
          throw custom_db_exceptions.PersonNotFoundException(id);
        }        
        String deleteDaily = "DELETE FROM daily_entry WHERE id = ?";
        await db!.execute(deleteDaily, [id]);

        //for(var result in dailyResult){
          //String eachDayinDailyStr = result['dates'];
          //var existsDate = await reader.existEntryForDateinDaily(eachDayinDailyStr);
          //if(existsDate.isEmpty || existsDate.first['dates'] == null){
            //await inserter.insertDummy(db, DateTime.now(), date: eachDayinDailyStr);
          //}
        //}

        String deleteAllPeople = "DELETE FROM all_people WHERE id = ?";
        await db!.execute(deleteAllPeople, [id]);

        await db!.execute("COMMIT");
      }
    catch (e, stackTrace){
      await db!.execute("ROLLBACK");
      if (e is custom_db_exceptions.DatabaseException) {
        rethrow;
      }
      throw custom_db_exceptions.DatabaseOperationException("Failed to delete person with ID $id.", originalException: e as Exception, stackTrace: stackTrace);
    }
  }

  Future<void> deleteDailyEntry(int recordID, int id, {String? date}) async{
    await ensureConnection();
    
    try{
        final rightDate = date ?? dateToString(getCurrentDate());

        await db!.execute("BEGIN TRANSACTION");

        String? category = await reader.getCategoryFromDaily(recordID, id, rightDate);
        Category cat = Category.values.byName(category!);
        
        final resAgeandGender = await reader.getAgeAndGenderAndMigration(id, rightDate);
        final gender = resAgeandGender.first['gender'];
        final age = resAgeandGender.first['age'];
        int migration = resAgeandGender.first['migration'];
        final migrationBool = migration == 1 ? true : false;

        await _weeklyTable(id, cat, gender, age, rightDate, migrationBool);

        String deleteQuery = "DELETE FROM daily_entry WHERE record_id = ? AND id = ? AND dates = ?";
        await db!.execute(deleteQuery, [recordID, id, rightDate]);

        await db!.execute("COMMIT");
        //var existsDate = await reader.existEntryForDateinDaily(rightDate);
        //if(existsDate.isEmpty || existsDate.first['dates'] == null){
          //await inserter.insertDummy(db, DateTime.now(), date: rightDate);
        //}
      }
    catch (e, stackTrace){
      await db!.execute("ROLLBACK");
      if (e is custom_db_exceptions.DatabaseException) {
        rethrow;
      }
      throw custom_db_exceptions.DatabaseOperationException("Failed to delete daily entry.", originalException: e as Exception, stackTrace: stackTrace);
    }
  }
  
  Future<void> _weeklyTable(int id, Category category, String genderStr, int ageYears, String date, bool migration) async{
    await ensureConnection();
    try{
      DateTime today =  DateTime.parse(date);      
      Genders gender = Genders.values.byName(genderStr);

      final weekDate = dateToString(getFirstDateOfWeek(today));
      
      final result = await reader.getLatestWeekDate(weekDate); 

      if(result.isNotEmpty){
        await updater.updateWeeklyTableData(weekDate, ageYears, gender, category, migration, '-');
        await updater.updateCountableColZeroWeek(weekDate);
      }
    }
    catch(e){
      rethrow;
    }
  }

    Future<void> deleteMultipleDailyEntriesForPeople(List<int> personIds, DateTime date) async {
    await ensureConnection();
    if (personIds.isEmpty) return;

    final dateStr = dateToString(date);

    try {
      // First, get all record_ids for the people on that date
      final placeholders = List.filled(personIds.length, '?').join(',');
      final entriesToDelete = await db!.rawQuery(
        'SELECT record_id, id FROM daily_entry WHERE dates = ? AND id IN ($placeholders)',
        [dateStr, ...personIds],
      );

      if (entriesToDelete.isEmpty) return;

      // Now, loop through them and delete one by one using the existing method.
      // Each call to deleteDailyEntry will handle its own transaction and weekly table update.
      for (final entry in entriesToDelete) {
        final recordId = entry['record_id'] as int;
        final personId = entry['id'] as int;
        await deleteDailyEntry(recordId, personId, date: dateStr);
      }
    } catch (e, stackTrace) {
      throw custom_db_exceptions.DatabaseOperationException(
        'Failed to delete entries for people.',
        originalException: e is Exception ? e : Exception(e.toString()),
        stackTrace: stackTrace,
      );
    }
  }

  // Future<void> delteAllFromDaily() async{
  //     String sql = "DELETE FROM daily_entry";
  //     await db.execute(sql);
  // }

  // Future<void> delteAllFromWeekly() async{
  //   String sql = "DELETE FROM weekly_entry";
  //   await db.execute(sql);
  // }
}