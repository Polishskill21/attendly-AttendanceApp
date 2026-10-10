import 'package:attendly/data/database/app_database.dart';
import 'package:attendly/data/database/exceptions.dart';
import 'package:attendly/core/logging/app_logger.dart';


class DirectoryRepository {
  static const String _tag = 'DirectoryRepository';

  final AppDatabase db;

  DirectoryRepository(this.db);

  // --- READ OPERATIONS ---

  /// Fetches all people for the main directory list
  Stream<List<DirectoryPeopleData>> watchAllPerson({bool ascending = true}) {
    try {
      return db.readDao.watchAllPerson(ascending);
    } catch (e, stack) {
      AppLogger.e(_tag, "Failed to fetch directory", e, stack);
      throw DatabaseOperationException("Failed to fetch directory", originalException: e is Exception ? e : null);
    }
  }

  /// Searches for people by name
  Future<List<DirectoryPeopleData>> searchPeople(String query) async {
    return await db.readDao.findPeopleByName(query);
  }

  /// Counts how many logs a person has before deletion
  Future<int> getEntryCountForPerson(int personId) async {
    return await db.readDao.countEntriesForPerson(personId);
  }

  // --- INSERT OPERATIONS ---

  /// Adds a new person to the directory (Used in AddPersonPage)
  Future<void> addPerson(DirectoryPeopleCompanion person) async {
    try {
      await db.insertDao.insertDirPerson(person);
    } on DuplicatePersonException {
      rethrow;
    }on DatabaseException {
      rethrow; 
    } catch (e, stack) {
      AppLogger.e(_tag, "Could not add person", e, stack);
      throw DatabaseOperationException(
        "Could not add person", 
        originalException: e is Exception ? e : Exception(e.toString()),
        stackTrace: stack,
      );
    }
  }

  // --- UPDATE OPERATIONS ---

  /// Updates an existing person's details, but create the companion only with new data (Used in EditPersonPage)
  Future<void> updatePerson(int id, DirectoryPeopleCompanion companion) async {
    try {
      await db.updateDao.updateDirPerson(id, companion);
    } on PersonNotFoundException {
      rethrow;
    } on DuplicatePersonException {
      rethrow;
    } catch (e, stack) {
      AppLogger.e(_tag, "Update failed for person $id", e, stack);
      throw DatabaseOperationException(
        "Update failed", 
        originalException: e is Exception ? e : null, 
        stackTrace: stack
      );
    }
  }

  // --- DELETE OPERATIONS ---

  /// Deletes a person and reverts all their weekly stats (Used in DirectoryTab)
  Future<void> deletePerson(int id) async {
    try {
      await db.deleteDao.deleteDirPerson(id);
    } on PersonNotFoundException {
      rethrow;
    } catch (e, stack) {
      AppLogger.e(_tag, "Deletion failed for person $id", e, stack);
      throw DatabaseOperationException(
        "Deletion failed dir person", 
        originalException: e is Exception ? e : null, 
        stackTrace: stack
      );
    }
  }
}