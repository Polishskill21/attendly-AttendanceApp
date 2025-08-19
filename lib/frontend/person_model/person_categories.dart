import 'package:attendly/frontend/person_model/category_record.dart';

class PersonWithCategories {
  final int personId;
  final String name;
  final List<CategoryRecord> records;

  PersonWithCategories({
    required this.personId,
    required this.name,
    required this.records,
  });
}