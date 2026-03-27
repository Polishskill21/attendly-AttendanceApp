import 'package:attendly/data/local/config/database.dart';
import 'package:attendly/data/repo/weekly_repository.dart';
import 'package:attendly/provider/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final weeklyRepositoryProvider = Provider<WeeklyRepository>((ref) {
  return WeeklyRepository(ref.watch(appDatabaseProvider));
});

final weeklyReportProvider = StreamProvider.autoDispose.family<WeeklyEntryData?, DateTime>((ref, date) {
  final repo = ref.watch(weeklyRepositoryProvider);
  return repo.watchWeeklyEntryByDate(date);
});


final allWeeksProvider = StreamProvider.autoDispose<List<WeeklyEntryData>>((ref) {
  final repo = ref.watch(weeklyRepositoryProvider);
  return repo.watchAllWeeks();
});