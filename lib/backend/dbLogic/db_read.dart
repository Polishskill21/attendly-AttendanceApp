import 'package:attendly/backend/enums/category.dart';
import 'package:attendly/backend/global/global_func.dart';
import 'package:attendly/backend/dbLogic/db_base.dart';

class DbSelection extends DbBaseHandler {
  DateTime nowTime = getScopedDate();

  DbSelection(super.db);

  Future<List<Map<String, dynamic>>> returnExistsingNames(String name) async{
    await ensureConnection();
    
    String sql = "SELECT * FROM all_people WHERE name = ?";
    return db!.rawQuery(sql, [name]);
  }

  Future<List<Map<String, dynamic>>> getLatestDateFromDaily() async{
    await ensureConnection();
    
    String getLatestDataSet = "SELECT MAX(dates) as latest_date FROM daily_entry";
    final res = db!.rawQuery(getLatestDataSet);
    return res;
  }

  Future<List<Map<String, dynamic>>> getLatestWeekDate(String weekDate) async{
    await ensureConnection();
    
    String sql = "SELECT dates FROM weekly_entry WHERE dates = ?";
    final res = db!.rawQuery(sql,[weekDate]);
    return res;
  }

  Future<List<Map<String, dynamic>>> existEntryForDateinDaily(String date) async{
    await ensureConnection();
    
    String sql = "SELECT dates FROM daily_entry WHERE dates = ?";
    final res = db!.rawQuery(sql, [date]);
    return res;
  }

  Future<String?> getCategoryFromDaily(int recordID, int id, String date) async{
    await ensureConnection();
    
    String selectQuery = """
                      SELECT category
                      FROM daily_entry
                      WHERE record_id = ? AND dates = ? AND id = ?
                      """;
    final res = await db!.rawQuery(selectQuery, [recordID, date, id]);
    return res.first['category'].toString();
  }

  Future<List<Map<String, dynamic>>> getCategoryAndDescriptionDaily(int recordID, String date, int id) async{
    await ensureConnection();
    
    String sql = "SELECT category, description FROM daily_entry WHERE record_id = ? AND dates = ? AND id = ?";
    final res = db!.rawQuery(sql, [recordID, date, id]);
    return res;
  }

  Future<List<Map<String, dynamic>>> getAllEntriesfromDaily(int id) async{
    await ensureConnection();
    
    String sql = "SELECT dates, category FROM daily_entry WHERE id = ?";
    final res = db!.rawQuery(sql, [id]);
    return res;
  }

  Future<int> countDailyEntriesForPerson(int id) async {
    await ensureConnection();
    
    String sql = "SELECT COUNT(*) as entry_count FROM daily_entry WHERE id = ?";
    final result = await db!.rawQuery(sql, [id]);
    if (result.isNotEmpty) {
      return (result.first['entry_count'] as int?) ?? 0;
    }
    return 0;
  }

  Future<List<Map<String, dynamic>>> returnCategoryIfExists(String date, int idOfPerson, Category category) async{
    await ensureConnection();
    
    String sqlExist = "SELECT category FROM daily_entry WHERE dates = ? AND id = ? AND category = ?";
    final res = db!.rawQuery(sqlExist, [date, idOfPerson, category.name]);
    return res;
  }

  Future<List<Map<String, dynamic>>> getAgeAndGenderAndMigration(int id, String customDate) async{
    await ensureConnection();
    
    String sql = """SELECT (strftime('%Y', '$customDate') - strftime('%Y', birthday)) - 
       (strftime('%m-%d', '$customDate') < strftime('%m-%d', birthday)) as age, gender, migration
       FROM all_people WHERE id = ?""";
    final res = db!.rawQuery(sql, [id]);
    return res;
  }

  Future<List<Map<String, dynamic>>> getGenderAndMigration(int id) async{
    await ensureConnection();
    
    String sql = "SELECT gender, migration FROM all_people WHERE id = ?";
    final res = db!.rawQuery(sql, [id]);
    return res;
  }

  Future<List<Map<String, dynamic>>> getPersonFromAllPeople(int id) async{
    await ensureConnection();
    
    String sql = "SELECT * FROM all_people WHERE id = ?";
    final res = db!.rawQuery(sql, [id]);
    return res;
  }

  Future<List<Map<String, dynamic>>> getAllPeople({bool ascending = true}) async{
    await ensureConnection();
    String order = ascending ? 'ASC' : 'DESC';

    String sql = "SELECT * FROM all_people ORDER BY name COLLATE NOCASE $order";
    return db!.rawQuery(sql);
  }

// toDo
  Future<List<Map<String, dynamic>>> getPeopleFromCurrentDay(String date) async{
    await ensureConnection();
    
    String sql = """SELECT d_e.record_id as record_id, d_e.dates as dates, d_e.id as id, a_p.name as name, d_e.category as category, d_e.description as description 
                    FROM daily_entry as d_e 
                    INNER JOIN all_people as a_p on d_e.id = a_p.id 
                    WHERE d_e.dates = ?""";
    final res = db!.rawQuery(sql, [date]);
    return res;
  }

  Future<List<Map<String, dynamic>>> searchDailyLogs({String? name, String? description, String? category}) async {
    await ensureConnection();

    String filter = '';
    List<Object?> params = [];

    if (name != null && name.isNotEmpty) {
      filter += " AND LOWER(a_p.name) LIKE ?";
      params.add('%${name.toLowerCase()}%');
    }

    if (description != null && description.isNotEmpty) {
      filter += " AND LOWER(d_e.description) LIKE ?";
      params.add('%${description.toLowerCase()}%');
    }

    if (category != null && category.isNotEmpty) {
      filter += " AND d_e.category = ?";
      params.add(category);
    }

    String sql = """
      SELECT 
        d_e.record_id, 
        d_e.dates, 
        d_e.id, 
        a_p.name, 
        d_e.category, 
        d_e.description
      FROM daily_entry as d_e
      JOIN all_people as a_p ON d_e.id = a_p.id
      WHERE 1=1 $filter
      ORDER BY d_e.dates DESC, a_p.name ASC
    """;

    return db!.rawQuery(sql, params);
  }

  Future<List<Map<String, dynamic>>> getDataFromCurrentWeek(String weekDate) async{
    await ensureConnection();
    
    String sql = "SELECT * FROM weekly_entry WHERE dates = ?";
    final res = db!.rawQuery(sql,[weekDate]);
    return res;
  }

  Future<List<Map<String, dynamic>>> getDataFromWeekTable() async{
    await ensureConnection();
    
    String sql = "SELECT * FROM weekly_entry";
    final res = db!.rawQuery(sql);
    return res;
  }

  Future<bool> areAllColumnsZero(String weekDate) async {
  const sql = """
      SELECT
        (under_10 = 0 AND
        age_10_13 = 0 AND
        age_14_17 = 0 AND
        age_18_24 = 0 AND
        over_24 = 0 AND
        all_m = 0 AND
        all_f = 0 AND
        all_d = 0 AND
        open_male = 0 AND
        open_female = 0 AND
        open_diverse = 0 AND
        offers_male = 0 AND
        offers_female = 0 AND
        offers_diverse = 0 AND
        migration_male = 0 AND
        migration_female = 0 AND
        migration_diverse = 0) AS all_zero
      FROM weekly_entry
      WHERE dates = ?;
    """;

  final result = await db!.rawQuery(sql, [weekDate]);

  if (result.isEmpty) return false; // No entry for the date

  // SQLite returns 1 for true, 0 for false
  return result.first['all_zero'] == 1;
}

  Future<List<Map<String, dynamic>>> getYearStats() async{
    await ensureConnection();
    
    String sql = """SELECT 
    SUM(under_10) AS under_10, 
    SUM(age_10_13) AS age_10_13, 
    SUM(age_14_17) AS age_14_17, 
    SUM(age_18_24) AS age_18_24,
    SUM(over_24) AS over_24, 
    SUM(all_m) AS all_m, 
    SUM(all_f) AS all_f,
    SUM(all_d) AS all_d, 
    SUM(open_male) AS open_male, 
    SUM(open_female) AS open_female,
    SUM(open_diverse) AS open_diverse, 
    SUM(offers_male) AS offers_male, 
    SUM(offers_female) AS offers_female, 
    SUM(offers_diverse) AS offers_diverse,    
    SUM(migration_male) as migration_male,
    SUM(migration_female) as migration_female,
    SUM(migration_diverse) as migration_diverse
    FROM weekly_entry
    WHERE countable != 0;
    """;

    return await db!.rawQuery(sql);
  }

  Future<int> getWeekCount() async {
    await ensureConnection();

    //use countable to count
    String sql = """
      SELECT COUNT(*) as week_count
      FROM weekly_entry 
      WHERE countable != 0;
        """;
    
    final result = await db!.rawQuery(sql);
    if (result.isNotEmpty) {
      return (result.first['week_count'] as int?) ?? 0;
    }
    return 0;
  }

  Future<List<Map<String, dynamic>>> getAllWeeklyEntries() async {
    await ensureConnection();

    String sql = """
      SELECT *
      FROM weekly_entry
      WHERE 
        under_10 > 0 OR
        age_10_13 > 0 OR
        age_14_17 > 0 OR         
        age_18_24 > 0 OR 
        over_24 > 0 OR
        all_m > 0 OR
        all_f > 0 OR
        all_d > 0 OR
        open_male > 0 OR
        open_female > 0 OR
        open_diverse > 0 OR
        offers_male > 0 OR
        offers_female > 0 OR
        offers_diverse > 0 OR
        migration_male > 0 OR
        migration_female > 0 OR
        migration_diverse > 0
      ORDER BY dates DESC""";

    final result = await db!.rawQuery(sql);
    // The result of rawQuery is already a List<Map<String, dynamic>>
    return result;
}

  bool checkDateMatch(DateTime date1, DateTime date2){
    if(date1.year == date2.year && date1.month == date2.month && date1.day == date2.day){
      return false;
    }
    else{
      return true; 
    }
  }
  // Future<int> getWeeksNotEqualToZero() async{
  //   await ensureConnection();
    
  //   String sql = """
  //     SELECT COUNT(*) as week_count
  //     FROM weekly_entry 
  //     WHERE 
  //         under_10 > 0 AND
  //         age_10_13 > 0 AND
  //         age_14_17 > 0 AND
  //         age_18_24 > 0 AND 
  //         over_24 > 0 AND
  //         all_m > 0 AND
  //         all_f > 0 AND
  //         all_d > 0 AND
  //         open_male > 0 AND
  //         open_female > 0 AND
  //         open_diverse > 0 AND
  //         offers_male > 0 AND
  //         offers_female > 0 AND
  //         offers_diverse > 0 AND
  //         migration_male > 0 AND
  //         migration_female > 0 AND
  //         migration_diverse > 0;
  //       """;

  //   List<Map<String, dynamic>> res = await db!.rawQuery(sql);

  //   if (res.isNotEmpty) {
  //     return res.first['week_count'];
  //   } else {
  //     return 0;
  //   }
  // }

///"SELECT MAX(dates) AS max_date FROM daily_entry"
  //Future<bool> missingDates() async{
    //try{
        //String sql = "SELECT MAX(dates) AS max_date FROM daily_entry";
        //List<Map<String, dynamic>> res = await db!.rawQuery(sql);
        //var latestDateDB = res.first["max_date"];

        //if(latestDateDB != null){
          //DateTime latestTime = DateTime.parse(latestDateDB);
          ////determine the subtraction
          //if(nowTime.weekday == DateTime.monday){
            //nowTime = nowTime.subtract(Duration(days: 3));
          //}
          //else if(nowTime.weekday == DateTime.saturday){
            //nowTime = nowTime.subtract(Duration(days: 1));
            
          //}
          //else if(nowTime.weekday == DateTime.sunday){
            //nowTime = nowTime.subtract(Duration(days: 2));
          //}
          //else{
            //nowTime = nowTime.subtract(Duration(days: 1));
          //}
          //return checkDateMatch(nowTime, latestTime);
        //}
        //else{
          //return true;
        //}
    //}
    //catch (e, stackTrace){
      //debugPrint(e.toString());
      //debugPrintStack(stackTrace: stackTrace);
    //}
    //return false;
  //}

}