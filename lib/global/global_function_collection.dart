import 'package:intl/intl.dart';

// DateTime getScopedDate(BuildContext context){
//   DateTime now = DateTime.now();
//   final dbYear = context.read<AppState>().dbYear;

//   if (dbYear != null && dbYear < now.year) {
//     // If DB is from a past year, return Jan 1st of that year.
//     return DateTime(dbYear, 1, 1);
//   }
  
//   // Otherwise, return today's date.
//   DateTime date = DateTime(now.year, now.month, now.day);
//   return date;
// }

// DateTime getPreviousDate(BuildContext context){
//   DateTime current = getScopedDate(context);
//   DateTime previous = current.subtract(const Duration(days: 1));
//   return previous;
// }

DateTime getScopedDate({int? dbYear}) {
  DateTime now = DateTime.now();

  if (dbYear != null && dbYear < now.year) {
    // If DB is from a past year, return Jan 1st of that year.
    return DateTime(dbYear, 1, 1);
  }
  
  return DateTime(now.year, now.month, now.day);
}

DateTime getPreviousDate({int? dbYear}) {
  DateTime current = getScopedDate(dbYear: dbYear);
  return current.subtract(const Duration(days: 1));
}

DateTime getCurrentYear(){
  DateTime thisYear = DateTime.now();
  DateTime year = DateTime(thisYear.year);
  return year;
}

int getCurrentYearAsInt(){
  DateTime yearDate = getCurrentYear();
  return yearDate.year.toInt();
}

DateTime getFirstDateOfWeek(DateTime date) {
  int daysToSubtract = date.weekday - DateTime.monday;
  return date.subtract(Duration(days: daysToSubtract));
}

DateTime dateToDateTime(String stringDate){
  DateTime date = DateTime.parse(stringDate);
  DateTime rightDate = DateTime(date.year, date.month, date.day);
  return rightDate;
}

String dateToString(DateTime date){
  return DateFormat('yyyy-MM-dd').format(date);
}

String yearToString(DateTime year){
  return DateFormat('yyyy').format(year);
}

int calcAge(DateTime today, DateTime born){
  int ageYears = today.year - born.year;

        if (today.month < born.month || (today.month == born.month && today.day < born.day)) {
          ageYears--;
        }
  return ageYears;
}