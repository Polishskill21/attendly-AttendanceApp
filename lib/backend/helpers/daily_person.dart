import 'package:attendly/backend/enums/category.dart';

class DailyPerson {
  final int id;
  final String date;
  final Category category;
  final String? description;

  DailyPerson({
    required this.id, 
    required String date, 
    required this.category, 
    this.description
  }): this.date = date.split('.').reversed.join('-');
}