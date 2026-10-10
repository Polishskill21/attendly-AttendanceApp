import 'package:attendly/features/yearly_report/data/yearly_report_repository.dart';
import 'package:attendly/features/yearly_report/models/year_stats.dart';
import 'package:attendly/data/database/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final yearlyRepositoryProvider = Provider<YearlyReportRepository>((ref) {
  return YearlyReportRepository(ref.watch(appDatabaseProvider));
});

/// One aggregate query, watched directly: Drift re-runs it when weekly_entry
/// changes.
final yearlyStatsProvider = StreamProvider.autoDispose<YearStats?>((ref) {
  return ref.watch(yearlyRepositoryProvider).watchYearlyStats();
});
