import 'package:attendly/data/local/config/database.dart';
import 'package:intl/intl.dart';

class CategoryRecord {
  final int recordId;
  final int personId;
  final String? personName; // Added for convenience
  final String date;
  final String category;
  final String? comment;

  CategoryRecord({
    required this.recordId,
    required this.personId,
    this.personName,
    required this.date,
    required this.category,
    this.comment,
  });

  // Factory constructor to create a CategoryRecord from a map
  factory CategoryRecord.fromDrift(DirectoryPeopleData person, DailyEntryData entry) {
    return CategoryRecord(
      recordId: entry.recordId,
      personId: person.id,
      personName: person.name,
      // Format DateTime to String for your UI
      date: DateFormat('yyyy-MM-dd').format(entry.date), 
      category: entry.category.name, // Enum to String
      comment: entry.description,
    );
  }
}

