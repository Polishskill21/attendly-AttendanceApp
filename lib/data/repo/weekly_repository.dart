import 'package:attendly/data/local/config/database.dart';
import 'package:attendly/data/local/config/db_exceptions.dart';


class WeeklyRepository {
  final AppDatabase db;

  WeeklyRepository(this.db);

  // --- READ OPERATIONS ---

  /// Fetches the full statistics for a specific week by its starting date.
  Stream<WeeklyEntryData?> watchWeeklyEntryByDate(DateTime date) {
    try {
      return db.readDao.watchWeeklyEntryByDate(date);
    } catch (e, stack) {
      throw DatabaseOperationException(
        "Failed to fetch weekly data for ${date.toIso8601String()}",
        originalException: e is Exception ? e : Exception(e.toString()),
        stackTrace: stack,
      );
    }
  }

  /// Fetches all recorded weeks.
  Stream<List<WeeklyEntryData>> watchAllWeeks() {
    try {
      return db.readDao.watchAllWeeklyEntries();
    } catch (e, stack) {
      throw DatabaseOperationException(
        "Failed to fetch the list of weekly entries",
        originalException: e is Exception ? e : Exception(e.toString()),
        stackTrace: stack,
      );
    }
  }

  // --- UPDATE OPERATIONS ---

  /// Updates the 'countable' status of a week to include or exclude it from the yearly report.
  Future<void> updateCountableStatus(DateTime date, bool isCountable) async {
    try {
      await db.updateDao.updateCountableStatus(date, isCountable);
    } catch (e, stack) {
      throw DatabaseOperationException(
        "Failed to update the status of the week",
        originalException: e is Exception ? e : Exception(e.toString()),
        stackTrace: stack,
      );
    }
  }
}