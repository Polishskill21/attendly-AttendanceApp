import 'package:attendly/data/repo/yearly_repository.dart';
import 'package:attendly/frontend/pages/yearly_report/year_stats_model.dart';
import 'package:attendly/provider/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final yearlyRepositoryProvider = Provider<YearlyStatsRepository>((ref) {
  return YearlyStatsRepository(ref.watch(appDatabaseProvider));
});

final yearlyStatsProvider = StreamProvider.autoDispose<YearStatsModel?>((ref) async* {
  final db = ref.watch(appDatabaseProvider);
  final yearlyRepo = ref.watch(yearlyRepositoryProvider);

  // A lightweight trigger stream that fires every time the weekly_entry table changes
  final tableChanges = db.customSelect(
    'SELECT COUNT(*) FROM weekly_entry', 
    readsFrom: {db.weeklyEntry}
  ).watch();

  await for (final _ in tableChanges) {
    final results = await Future.wait([
      yearlyRepo.getYearlyStats(),
      yearlyRepo.getRecordedWeekCount(),
    ]);

    final statsData = results[0] as List<Map<String, dynamic>>;
    final weekCount = results[1] as int;

    if (statsData.isNotEmpty && statsData.first.values.any((v) => v != null)) {
      yield YearStatsModel(stats: statsData.first, weekCount: weekCount);
    } else {
      yield null;
    }
  }
});