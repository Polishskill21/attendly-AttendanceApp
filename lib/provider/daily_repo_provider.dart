import 'package:attendly/backend/global/global_func.dart';
import 'package:attendly/data/repo/daily_repository.dart';
import 'package:attendly/frontend/person_model/category_record.dart';
import 'package:attendly/frontend/person_model/person_categories.dart';
import 'package:attendly/provider/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dailyRepositoryProvider = Provider<DailyRepository>((ref) {
  return DailyRepository(ref.watch(appDatabaseProvider));
});


final dailyDateProvider = StateProvider<DateTime>((ref) {
  final dbYear = ref.watch(databaseManagerProvider).dbYear;
  return getScopedDate(dbYear: dbYear);
});

final dailySearchProvider = StateProvider<String>((ref) => '');
final dailyCategoryFilterProvider = StateProvider<String?>((ref) => null);
final dailyEditModeProvider = StateProvider<bool>((ref) => false);
final dailySelectedPeopleProvider = StateProvider<Set<PersonWithCategories>>((ref) => {});


final dailyRawLogsProvider = FutureProvider<List<PersonWithCategories>>((ref) async {
  final date = ref.watch(dailyDateProvider);
  final repo = ref.watch(dailyRepositoryProvider);

  final rawResults = await repo.getDailyLogsFromCurrentDay(date);

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


final dailyFilteredLogsProvider = Provider<AsyncValue<List<PersonWithCategories>>>((ref) {
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