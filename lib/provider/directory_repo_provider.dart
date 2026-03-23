import 'package:attendly/data/local/config/database.dart';
import 'package:attendly/data/repo/directory_repository.dart';
import 'package:attendly/provider/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final directoryRepositoryProvider = Provider<DirectoryRepository>((ref) {
  return DirectoryRepository(ref.watch(appDatabaseProvider));
});

final directorySortAscendingProvider = StateProvider<bool>((ref) => true);
 
final directorySearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');
 
 
final directoryStreamProvider =
    StreamProvider<List<DirectoryPeopleData>>((ref) {
  final repo = ref.watch(directoryRepositoryProvider);
  final ascending = ref.watch(directorySortAscendingProvider);
  return repo.watchAllPerson(ascending: ascending);
});
 
 
final filteredDirectoryProvider = Provider<AsyncValue<List<DirectoryPeopleData>>>((ref) {
  final stream = ref.watch(directoryStreamProvider);
  final query = ref.watch(directorySearchQueryProvider).toLowerCase();

  return stream.whenData((people) {
    if (query.isEmpty) return people;
    
    return people
        .where((person) => person.name.toLowerCase().contains(query))
        .toList();
  });
});