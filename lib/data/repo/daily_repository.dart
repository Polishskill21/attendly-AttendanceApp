import 'package:attendly/data/local/config/database.dart';
import 'package:attendly/data/local/config/db_exceptions.dart';
import 'package:attendly/data/local/models/batch_result.dart';
import 'package:attendly/data/local/tables/enums/category.dart';
import 'package:drift/drift.dart';

class DailyRepository {
  final AppDatabase db;

  DailyRepository(this.db);

  // --- READ OPERATIONS ---

  /// Fetches all daily entries joined with person data for a specific date.
  Stream<List<TypedResult>> watchDailyLogsFromCurrentDay(DateTime date) {
    try {
      return db.readDao.watchPeopleFromCurrentDay(date);
    } catch (e, stack) {
      throw DatabaseOperationException(
        "Failed to watch daily logs",
        originalException: e is Exception ? e : Exception(e.toString()),
        stackTrace: stack,
      );
    }
  }

  /// Searches daily logs with optional filters.
  Future<List<TypedResult>> searchLogs({String? name, String? description, String? category}) async {
    return await db.readDao.searchDailyLogs(
      name: name,
      description: description,
      category: category,
    );
  }

  // --- INSERT OPERATIONS ---

  /// Adds a new entry to the daily table and updates weekly counters.
  Future<void> addDailyEntry({
    required int personId,
    required DateTime date,
    required Category category,
    String? description,
    int multiplier = 1
  }) async {
    try {
      await db.insertDao.insertDailyEntry(
        personId: personId,
        date: date,
        category: category,
        description: description,
        multiplier: multiplier
      );
    } on DuplicateDailyEntryException {
      rethrow;
    } on PersonNotFoundException {
      rethrow;
    } catch (e, stack) {
      throw DatabaseOperationException(
        "Could not add daily entry",
        originalException: e is Exception ? e : Exception(e.toString()),
        stackTrace: stack,
      );
    }
  }

  /// Handles batch adding multiple people on the dialy add page if there are more then one person
  Future<BatchAddResult> batchAddDailyEntries({
    required List<Map<String, dynamic>> persons,
    required DateTime date,
    required Category category,
    String? description,
  }) async {
    int successCount = 0;
    int failCount = 0;
    List<String> duplicateNames = [];
    List<String> errorMessages = [];

    for (var person in persons) {
      try {
        await db.insertDao.insertDailyEntry(
          personId: person['id'],
          date: date,
          category: category,
          description: description,
        );
        successCount++;
      } on DuplicateDailyEntryException {
        duplicateNames.add(person['name'] ?? 'Unknown');
      } catch (e) {
        failCount++;
        errorMessages.add("${person['name']}: ${e.toString()}");
      }
    }

    return BatchAddResult(
      successCount: successCount,
      failCount: failCount,
      duplicateNames: duplicateNames,
      errorMessages: errorMessages,
    );
  }

  // --- UPDATE OPERATIONS ---

  /// Updates an existing daily record (category or description).
  Future<void> updateDailyEntry({
    required int recordId,
    required DateTime date,
    required int personId,
    required Category newCategory,
    String? newDescription,
  }) async {
    try {
      await db.updateDao.updateDailyEntry(
        recordID: recordId,
        date: date,
        personId: personId,
        newCategory: newCategory,
        newDescription: newDescription,
      );
    } on DuplicateDailyEntryException {
      rethrow;
    } catch (e, stack) {
      throw DatabaseOperationException(
        "Failed to update entry",
        originalException: e is Exception ? e : null,
        stackTrace: stack,
      );
    }
  }

  // --- DELETE OPERATIONS ---

  /// Deletes a specific record and adjusts weekly stats.
  Future<void> deleteDailyEntry(int recordId, int personId, DateTime date) async {
    try {
      await db.deleteDao.deleteDailyEntry(recordId, personId, date);
    } catch (e, stack) {
      throw DatabaseOperationException(
        "Deletion failed daily entry",
        originalException: e is Exception ? e : null,
        stackTrace: stack,
      );
    }
  }

  /// Deletes all entries for a list of people on a specific date (Bulk Delete).
  Future<void> bulkDeleteEntries(List<int> personIds, DateTime date) async {
    try {
      await db.deleteDao.deleteMultipleDailyEntries(personIds, date);
    } catch (e, stack) {
      throw DatabaseOperationException(
        "Bulk deletion failed",
        originalException: e is Exception ? e : null,
        stackTrace: stack,
      );
    }
  }
}