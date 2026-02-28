import 'package:attendly/data/local/config/database.dart';
import 'package:attendly/data/local/tables/enums/category.dart';
import 'package:attendly/data/local/tables/enums/gender.dart';
import 'package:drift/drift.dart';

mixin SharedDaoLogic on DatabaseAccessor<AppDatabase> {
  /// Logic to find the Monday of the week for a given date.
  DateTime getFirstDateOfWeek(DateTime date) =>
      date.subtract(Duration(days: date.weekday - 1));

  /// Logic to calculate age based on the record date and birthday.
  int calcAge(DateTime recordDate, DateTime birthday) {
    int age = recordDate.year - birthday.year;
    if (recordDate.month < birthday.month ||
        (recordDate.month == birthday.month && recordDate.day < birthday.day)) {
      age--;
    }
    return age;
  }

  /// Maps an age to its corresponding SQLite column name.
  String determineAgeGroup(int age) {
    if (age < 10) return "under_10";
    if (age <= 13) return "age_10_13";
    if (age <= 17) return "age_14_17";
    if (age <= 24) return "age_18_24";
    return "over_24";
  }

  /// Maps gender to general total columns.
  String determineGenderColumn(Gender gender) => switch (gender) {
        Gender.m => "all_m",
        Gender.f => "all_f",
        Gender.d => "all_d"
      };

  /// Maps gender and category to specific total columns (Open/Offer).
  String determineGenderCategory(Gender gender, Category category) {
    if (category == Category.open) {
      return switch (gender) {
        Gender.m => "open_male",
        Gender.f => "open_female",
        Gender.d => "open_diverse"
      };
    }
    if (category == Category.offer) {
      return switch (gender) {
        Gender.m => "offers_male",
        Gender.f => "offers_female",
        Gender.d => "offers_diverse"
      };
    }
    return "";
  }

  /// Maps gender to migration-specific columns.
  String determineMigrationCol(Gender gender) => switch (gender) {
        Gender.m => "migration_male",
        Gender.f => "migration_female",
        Gender.d => "migration_diverse"
      };
}