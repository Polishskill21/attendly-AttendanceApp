import 'package:attendly/data/local/config/database.dart';
import 'package:attendly/data/repo/weekly_repository.dart';
import 'package:attendly/provider/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final weeklyRepositoryProvider = Provider<WeeklyRepository>((ref) {
  return WeeklyRepository(ref.watch(appDatabaseProvider));
});

final weeklyReportProvider = FutureProvider.family<WeeklyEntryData?, DateTime>((ref, date) async {
  final repo = ref.watch(weeklyRepositoryProvider);
  return await repo.getWeeklyEntryByDate(date);
});


final allWeeksProvider = FutureProvider<List<WeeklyEntryData>>((ref) async {
  final repo = ref.watch(weeklyRepositoryProvider);
  return await repo.getAllWeeks();
});