import 'package:attendly/backend/db_exceptions.dart';
import 'package:attendly/data/local/config/database.dart';


class YearlyStatsRepository {
  final AppDatabase db;

  YearlyStatsRepository(this.db);

  /// Fetches the aggregated statistics for the yearly report.
  Future<List<Map<String, dynamic>>> getYearlyStats() async {
    try {
      return await db.readDao.getYearStats();
    } catch (e, stack) {
      throw DatabaseOperationException(
        "Failed to fetch yearly statistics",
        originalException: e is Exception ? e : Exception(e.toString()),
        stackTrace: stack,
      );
    }
  }

  /// Gets the total count of weeks recorded where countable is not 0.
  Future<int> getRecordedWeekCount() async {
    try {
      return await db.readDao.getWeekCount();
    } catch (e, stack) {
      throw DatabaseOperationException(
        "Failed to count recorded weeks",
        originalException: e is Exception ? e : null,
        stackTrace: stack,
      );
    }
  }
}