import 'package:attendly/data/local/database.dart';
import 'package:attendly/data/local/db_exceptions.dart';

class DirectoryRepository {
  final AppDatabase db;

  DirectoryRepository(this.db);

  // --- READ OPERATIONS ---

  /// Fetches all people for the main directory list
  Future<List<DirectoryPeopleData>> getAllPerson({bool ascending = true}) async {
    try {
      return await db.readDao.getAllPerson(ascending);
    } catch (e) {
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

  /// Adds a new person to the directory (Used in AddPage)
  Future<void> addPerson(DirectoryPeopleCompanion person) async {
    try {
      await db.insertDao.insertDirPerson(person);
    } on DuplicatePersonException {
      rethrow;
    }on DatabaseException {
      rethrow; 
    } catch (e, stack) {
      throw DatabaseOperationException(
        "Could not add person", 
        originalException: e is Exception ? e : Exception(e.toString()),
        stackTrace: stack,
      );
    }
  }

  // --- UPDATE OPERATIONS ---

  /// Updates an existing person's details, but create the companion only with new data (Used in EditPage)
  Future<void> updatePerson(int id, DirectoryPeopleCompanion companion) async {
    try {
      await db.updateDao.updateDirPerson(id, companion);
    } on PersonNotFoundException {
      rethrow;
    } on DuplicatePersonException {
      rethrow;
    } catch (e, stack) {
      throw DatabaseOperationException(
        "Update failed", 
        originalException: e is Exception ? e : null, 
        stackTrace: stack
      );
    }
  }

  // --- DELETE OPERATIONS ---

  /// Deletes a person and reverts all their weekly stats (Used in DirectoryPage)
  Future<void> deletePerson(int id) async {
    try {
      await db.deleteDao.deleteDirPerson(id);
    } on PersonNotFoundException {
      rethrow;
    } catch (e, stack) {
      throw DatabaseOperationException(
        "Deletion failed", 
        originalException: e is Exception ? e : null, 
        stackTrace: stack
      );
    }
  }
}