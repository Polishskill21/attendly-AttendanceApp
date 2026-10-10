import 'package:attendly/data/database/app_database.dart';
import 'package:attendly/data/tables/enums/category.dart';
import 'package:attendly/data/tables/enums/gender.dart';
import 'package:drift/drift.dart';

/// In-memory database with the same setup as the DAO tests.
AppDatabase createTestDatabase() => AppDatabase.testInstance();

/// Inserts a person and returns its id.
Future<int> addTestPerson(
  AppDatabase db,
  String name, {
  DateTime? birthday,
  Gender gender = Gender.m,
  bool migration = false,
}) async {
  await db.insertDao.insertDirPerson(DirectoryPeopleCompanion.insert(
    name: name,
    birthday: birthday ?? DateTime(2010, 1, 1),
    gender: gender,
    migration: migration,
    migrationBackground: const Value(''),
  ));
  final people = await db.readDao.findPeopleByName(name);
  return people.single.id;
}

Future<void> addTestEntry(
  AppDatabase db, {
  required int personId,
  required DateTime date,
  Category category = Category.open,
  String? description,
}) {
  return db.insertDao.insertDailyEntry(
    personId: personId,
    date: date,
    category: category,
    description: description,
  );
}
