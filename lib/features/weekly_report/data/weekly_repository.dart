import 'package:attendly/data/database/app_database.dart';
import 'package:attendly/data/database/exceptions.dart';
import 'package:attendly/core/logging/app_logger.dart';


class WeeklyRepository {
  static const String _tag = 'WeeklyRepository';

  final AppDatabase db;

  WeeklyRepository(this.db);

  // --- READ OPERATIONS ---

  /// Fetches the full statistics for a specific week by its starting date.
  Stream<WeeklyEntryData?> watchWeeklyEntryByDate(DateTime date) {
    try {
      return db.readDao.watchWeeklyEntryByDate(date);
    } catch (e, stack) {
      AppLogger.e(_tag, "Failed to fetch weekly data for ${date.toIso8601String()}", e, stack);
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
      AppLogger.e(_tag, "Failed to fetch the list of weekly entries", e, stack);
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
      AppLogger.e(_tag, "Failed to update the status of the week", e, stack);
      throw DatabaseOperationException(
        "Failed to update the status of the week",
        originalException: e is Exception ? e : Exception(e.toString()),
        stackTrace: stack,
      );
    }
  }
}