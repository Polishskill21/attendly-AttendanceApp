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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonWithCategories &&
          runtimeType == other.runtimeType &&
          personId == other.personId;
 
  @override
  int get hashCode => personId.hashCode; 
}