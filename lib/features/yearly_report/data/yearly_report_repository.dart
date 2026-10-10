import 'package:attendly/data/database/app_database.dart';
import 'package:attendly/data/database/exceptions.dart';
import 'package:attendly/core/logging/app_logger.dart';
import 'package:attendly/features/yearly_report/models/year_stats.dart';


class YearlyReportRepository {
  static const String _tag = 'YearlyReportRepository';

  final AppDatabase db;

  YearlyReportRepository(this.db);

  /// The yearly report over all countable weeks, or null while no week has
  /// data. Updates whenever a week changes.
  Stream<YearStats?> watchYearlyStats() {
    try {
      return db.readDao.watchYearStats().map((row) {
        final stats = Map<String, dynamic>.of(row);
        final weekCount = (stats.remove('week_count') as int?) ?? 0;
        if (stats.values.every((value) => value == null)) return null;
        return YearStats(stats: stats, weekCount: weekCount);
      });
    } catch (e, stack) {
      AppLogger.e(_tag, "Failed to watch yearly statistics", e, stack);
      throw DatabaseOperationException(
        "Failed to watch yearly statistics",
        originalException: e is Exception ? e : Exception(e.toString()),
        stackTrace: stack,
      );
    }
  }
}
