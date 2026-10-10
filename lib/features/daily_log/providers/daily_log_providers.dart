import 'package:attendly/features/daily_log/data/daily_repository.dart';
import 'package:attendly/features/daily_log/models/category_record.dart';
import 'package:attendly/features/daily_log/models/person_with_categories.dart';
import 'package:attendly/core/utils/date_utils.dart';
import 'package:attendly/data/database/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


final dailyRepositoryProvider = Provider<DailyRepository>((ref) {
  return DailyRepository(ref.watch(appDatabaseProvider));
});


final dailyDateProvider = StateProvider<DateTime>((ref) {
  final dbYear = ref.watch(
    databaseProvider.select((s) => s.dbYear),
  );
  return getScopedDate(dbYear: dbYear);
});

final dailySearchProvider         = StateProvider.autoDispose<String>((ref) => '');
final dailyCategoryFilterProvider = StateProvider.autoDispose<String?>((ref) => null);
final dailyEditModeProvider       = StateProvider.autoDispose<bool>((ref) => false);
final dailySelectedPeopleProvider = StateProvider.autoDispose<Set<PersonWithCategories>>((ref) => {});


/// The entries of the selected day, grouped by person. Only this day is held:
/// a date change rebuilds the provider and cancels the old stream, and leaving
/// the daily tab releases it.
final dailyRawLogsProvider = StreamProvider.autoDispose<List<PersonWithCategories>>((ref) {
  final date = ref.watch(dailyDateProvider);
  final repo = ref.watch(dailyRepositoryProvider);

  return repo.watchDailyLogsFromCurrentDay(date).map((rawResults) {
    final Map<int, PersonWithCategories> personMap = {};

    for (final row in rawResults) {
      final personData = row.readTable(repo.db.directoryPeople);
      final dailyData = row.readTable(repo.db.dailyEntry);
      
      final personId = personData.id;

      if (!personMap.containsKey(personId)) {
        personMap[personId] = PersonWithCategories(
          personId: personId,
          name: personData.name,
          records: [],
        );
      }

      final record = CategoryRecord.fromDrift(personData, dailyData);
      personMap[personId]!.records.add(record);
    }

    return personMap.values.toList();
  });
});


final dailyFilteredLogsProvider = Provider.autoDispose<AsyncValue<List<PersonWithCategories>>>((ref) {
  final rawDataAsync = ref.watch(dailyRawLogsProvider);
  final searchQuery = ref.watch(dailySearchProvider).toLowerCase();
  final selectedCategory = ref.watch(dailyCategoryFilterProvider);

  return rawDataAsync.whenData((people) {
    var filtered = people;

    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((p) => p.name.toLowerCase().contains(searchQuery)).toList();
    }

    if (selectedCategory != null && selectedCategory.isNotEmpty) {
      filtered = filtered.map((person) {
        final matchingRecords = person.records.where((rec) => rec.category == selectedCategory).toList();
        if (matchingRecords.isEmpty) return null;
        return PersonWithCategories(
          personId: person.personId,
          name: person.name,
          records: matchingRecords,
        );
      }).whereType<PersonWithCategories>().toList();
    }

    return filtered;
  });
});