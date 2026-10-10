import 'package:drift/drift.dart';

class DateOnlyConverter extends TypeConverter<DateTime, String> {
  const DateOnlyConverter();

  @override
  DateTime fromSql(String fromDb) {
    final DateTime parsed = DateTime.parse(fromDb);
    
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  @override
  String toSql(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');

    return "$year-$month-${day}T00:00:00.000";
  }
}