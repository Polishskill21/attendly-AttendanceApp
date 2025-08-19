import 'package:attendly/backend/dbLogic/db_base.dart';
import 'package:attendly/backend/enums/category.dart';
import 'package:attendly/backend/enums/genders.dart';
import 'package:attendly/backend/global/global_func.dart';
import 'package:flutter/material.dart';
import 'package:attendly/backend/db_exceptions.dart' as custom_db_exceptions;
import 'package:sqflite/sqflite.dart';
import '../helpers/daily_person.dart';
import 'package:attendly/backend/dbLogic/db_read.dart';
import 'db_update.dart';
import '../helpers/child.dart';

class DbInsertion extends DbBaseHandler {
  final DbSelection reader;
  final DbUpdater updater;

  DbInsertion(super.db, this.reader, this.updater);

  ///inserting a person into the table of all available people
  Future<void> allPeopleTable(Child child) async {
    await ensureConnection();

    try {
      String sql = """
                      INSERT INTO all_people(name, birthday, gender, migration, migration_background) 
                      Values (?,?,?,?,?);
                      """;
      await db!.execute(sql, child.toList());
    } on DatabaseException catch (e, stackTrace) {

      if (e.isUniqueConstraintError()) {
        throw custom_db_exceptions.DuplicatePersonException(child.name);
      }
      throw custom_db_exceptions.DatabaseOperationException(
          "Failed to insert person",
          originalException: e,
          stackTrace: stackTrace);
    } catch (e, stackTrace) {
      debugPrint("Insertion class: Generic Exception");
      debugPrint(e.toString());
      debugPrintStack(stackTrace: stackTrace);
      if (e is custom_db_exceptions.DatabaseException) {
        rethrow;
      }
      throw custom_db_exceptions.DatabaseOperationException(
          "Failed to insert person",
          originalException: e as Exception,
          stackTrace: stackTrace);
    }
  }
   
   
  ///Inserting into the daily table, giva a list with (id,date,category,description), it is a transaction
    Future<void> dailyTable(DailyPerson person) async{
    await ensureConnection();
    
    try{
      await db!.execute("BEGIN TRANSACTION"); 
                    
      List<Map<String, dynamic>> exists = await reader.getPersonFromAllPeople(person.id);
      if(exists.isEmpty) {
        throw custom_db_exceptions.PersonNotFoundException(person.id);
      }

      List<Map<String, dynamic>> existsDaily = await reader.returnCategoryIfExists(person.date, person.id, person.category);
      
      if(existsDaily.isNotEmpty && existsDaily.first['category'] == "open"){
        debugPrint("skipped inserting the open cat twice");
        throw custom_db_exceptions.DuplicateDailyEntryException();
      }

      String sql = """
                    INSERT INTO daily_entry(record_id ,dates, id, category, description) VALUES (?,?,?,?,?)
                    """;
      //prepare the data 
      List<Object?> personList = [
      await _getLatestRecordID(person.date), 
      person.date, 
      person.id, 
      person.category.name, 
      person.description
      ];
        
      await db!.execute(sql,personList);

      await _weeklyTable(person.id, person.category, person.date);

      await db!.execute("COMMIT");
    }
    catch (e, stackTrace){
      debugPrint("daily");
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
      await db!.execute("ROLLBACK;");
      if (e is custom_db_exceptions.DatabaseException) {
        rethrow;
      }
      throw custom_db_exceptions.DatabaseOperationException("Failed to insert daily entry", originalException: e as Exception, stackTrace: stackTrace);
    }
  }

  Future<int> _getLatestRecordID(String date) async{
    await ensureConnection();
    
    String query = "SELECT MAX(record_id) AS record_id FROM daily_entry WHERE dates = ?";
    List<Map<String, dynamic>> fatch = await db!.rawQuery(query, [date]);
    int recordID = (fatch.first['record_id'] as int?) ?? 0;
    return recordID + 1;
  }

  Future<void> _weeklyTable(int id, Category category, String customDate) async{
    await ensureConnection();
    
    try{
      List<Map<String, dynamic>> person = await reader.getAgeAndGenderAndMigration(id, customDate);
      if(person.isEmpty){
        throw custom_db_exceptions.PersonNotFoundException(id);
      }

      DateTime today =  DateTime.parse(customDate);

      //create a function for that
      int ageYears = person.first['age'];

      Genders gender = Genders.values.byName(person.first['gender']);
      int migration = person.first['migration'];
      final migrationBool = migration == 1 ? true : false;

      final weekDate = dateToString(getFirstDateOfWeek(today));

      List<Map<String, dynamic>> result = await reader.getLatestWeekDate(weekDate); 

      if(result.isNotEmpty){
        await updater.updateWeeklyTableData(weekDate, ageYears, gender, category, migrationBool,'+');
      }
      else{
        //insert into table if date not found
        await setDefaultValueWeek(weekDate);
        await updater.updateWeeklyTableData(weekDate, ageYears, gender, category, migrationBool,'+');
      }
    }
    catch (e, stackTrace){
      debugPrint(e.toString());
      debugPrintStack(stackTrace: stackTrace);
      if (e is custom_db_exceptions.DatabaseException) {
        rethrow;
      }
      throw custom_db_exceptions.DatabaseOperationException("Failed to update weekly table", originalException: e as Exception, stackTrace: stackTrace);
    }
  }

  Future<void> setDefaultValueWeek(String weekDate) async{
    await ensureConnection();
    
    String sql = """
                INSERT OR IGNORE INTO weekly_entry (
                dates, 
                under_10, 
                age_10_13, 
                age_14_17, 
                age_18_24, 
                over_24, 
                all_m, 
                all_f, 
                all_d, 
                open_male, 
                open_female, 
                open_diverse, 
                offers_male, 
                offers_female, 
                offers_diverse, 
                migration_male,
                migration_female,
                migration_diverse,
                countable)
                VALUES (?, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1);
              """;
      await db!.execute(sql, [weekDate]);
  }
}

  ///for auto inserting null values for the last days
  //Future<bool> autoFillDefaultValues({List<DailyPerson>? persons}) async{
    //try{
      //DateTime latestDate;
      //List<Map<String, dynamic>> latestDateString = await reader.getLatestDateFromDaily();

      //if(latestDateString.isEmpty || latestDateString.first['latest_date'] == null){
        //latestDate = DateTime(getCurrentYearAsInt(),1,1);
      //}
      //else{
        //latestDate = DateTime.parse(latestDateString.first['latest_date']);
        //latestDate = latestDate.add(const Duration(days: 1));
      //}
      ////print("print $latestDate");
      ////DateTime previousDate = getPreviousDate();
      //DateTime firstDateInList;
      //if(persons != null){
        //firstDateInList = dateToDateTime(persons.first.date);
      //}
      //else{
        //firstDateInList = _nowDay;
      //}
      
      //await _insertMissingDays(firstDateInList, latestDate: latestDate, persons: persons);
      //return true;
    //}
    //catch (e, stackTrace){
      //print("Insertion class");
      //print(e);
      //print(stackTrace);
      //return false;
    //}
  //}

  //Future<bool> proccessDailyEntries(List<DailyPerson> persons) async{
    //try{
      //if(persons.isEmpty) return false;
      //persons.sort((a,b) => a.date.compareTo(b.date));

      //await autoFillDefaultValues(persons: persons);

      //List<DailyPerson> groupedPersons = [];
      //DateTime? lastDateInGroup;

      //for(int i = 0; i < persons.length; i++){
        //DateTime currentDate = DateTime.parse(persons[i].date);
        //print("Processing date: $currentDate, Last date in group: $lastDateInGroup");

        //if(groupedPersons.isEmpty || currentDate.isAtSameMomentAs(lastDateInGroup!)) {
          //groupedPersons.add(persons[i]);
        //}
        //else{
          //await dailyTable(groupedPersons);
          
          //await _insertMissingDays(currentDate, lastDateStr:  groupedPersons.last.date, persons: persons);

          //groupedPersons = [persons[i]];
        //}
        //lastDateInGroup = currentDate;
      //}
      //if(groupedPersons.isNotEmpty){
        //await dailyTable(groupedPersons);  
      //}
      //await autoFillDefaultValues();
      //return true;
    //}
    //catch (e, stackTrace){
      //print(e);
      //print(stackTrace);
      //return false;
    //}
  //}

  //Future<void> insertDummy(Database db, DateTime latestDate, {String? date}) async{
    //String sql = """INSERT INTO daily_entry (record_id,dates,id,category,description) VALUES (?,?,?,?,?)""";
    //await db.execute(sql, [1, date ?? dateToString(latestDate),1,Category.other.name, null]);
  //}

  //Future<void> _insertMissingDays( DateTime currentDate, {DateTime? latestDate, String? lastDateStr, List<DailyPerson>? persons }) async{
    //DateTime lastDate = latestDate ?? DateTime.parse(lastDateStr!).add(const Duration(days: 1));

    //while(!lastDate.isAfter(currentDate)){
      ////skip weekends (sturday = 6 and sunday = 7)
      //if(_isWeekday(lastDate) && !_isDateInPersonsList(lastDate, persons)){

        //await insertDummy(db,lastDate);
        //List<Map<String, dynamic>> res = await reader.getLatestWeekDate(dateToString(getFirstDateOfWeek(lastDate)));
        
        //if(res.isEmpty){
          //await setDefaultValueWeek(dateToString(getFirstDateOfWeek(lastDate)));
        //}
      //}
      //lastDate = lastDate.add(const Duration(days: 1));
    //}
  //}
  
  // bool _isDateInPersonsList(DateTime date, List<DailyPerson>? persons) {
  //   if(persons == null){
  //     return false;
  //   }
  //   return persons.any((person) => DateTime.parse(person.date).isAtSameMomentAs(date));
  // }

  // // Function to check if a date is a weekday (Monday-Friday)
  // bool _isWeekday(DateTime date) {
  //   return date.weekday != DateTime.saturday && date.weekday != DateTime.sunday;
  // }

    ///sets all days starting from the latest day in the old db to null values 
  //:Future<void> setNullValuesDailyByYearChange(String previousYear, String oldPath) async{
    //:try{
      //:List<Map<String, dynamic>> latestDateString = await reader.getLatestDateFromDaily();

      //:DateTime latestDate = DateTime.parse(latestDateString.first['latest_date']);
      //:DateTime lastDay = DateTime(int.parse(previousYear), 12, 31);
      //:latestDate = latestDate.add(const Duration(days: 1));
        
      //:while(!latestDate.isAfter(lastDay)){
        //://skip weekends (sturday = 6 and sunday = 7)
        //:if(lastDay.weekday != DateTime.saturday && latestDate.weekday != DateTime.sunday){
          //:insertDummy(db, latestDate);
          //:// String sql = """INSERT INTO daily_entry (record_id,dates,id,category,description) VALUES (?,?,?,?)""";
          //:// await db.execute(sql, [1,dateToString(latestDate),1,Category.other.name, null]);
        //:}
        //:latestDate = latestDate.add(const Duration(days: 1));
      //:}
      //:await _setNullValuesWeeklyByYearChange(previousYear);
    //:}
    //:catch (e, stackTrace){
      //:print("Insertion class");
      //:print(e);
      //:print(stackTrace);
    //:}
  //:}

  //:Future<void> _setNullValuesWeeklyByYearChange(String previousYear) async{
    //:try{
      //:String sql = "SELECT MAX(dates) as latest_week FROM weekly_entry";
      //:List<Map<String, dynamic>> latestWeekString = await db.rawQuery(sql);

      //:DateTime latestWeek = DateTime.parse(latestWeekString.first['latest_week']);
      //:DateTime lastWeekOfYear = getFirstDateOfWeek(DateTime(int.parse(previousYear), 12, 31));
      
      //:latestWeek = latestWeek.add(const Duration(days: 7));

      //:while(!latestWeek.isAfter(lastWeekOfYear)){

        //:await setDefaultValueWeek(dateToString(latestWeek));

        //:latestWeek = latestWeek.add(const Duration(days: 7));
      //:}
    //:}
    //:catch (e, stackTrace){
      //:print("Insertion class");
      //:print(e);
      //:print(stackTrace);
    //:}
  //:}