import 'package:attendly/backend/global/global_func.dart';
import 'package:attendly/frontend/person_model/person_categories.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:attendly/backend/dbLogic/db_read.dart';
import 'package:attendly/frontend/person_model/category_record.dart';
import 'package:attendly/backend/db_exceptions.dart' as custom_db_exceptions;


class DailyPersonController extends ChangeNotifier {
  final Database database;
  late DbSelection reader;
  bool _isRefreshing = false;
  DateTime _selectedDate = getScopedDate();
  List<PersonWithCategories> _people = [];
  bool _isEditMode = false;
  final Set<PersonWithCategories> _selectedPeople = {};
  bool _isTablet = false;
  
  // Filtering properties
  String _searchQuery = '';
  String? _selectedCategory;

  DailyPersonController(this.database) {
    reader = DbSelection(database);
  }

  // Getters
  bool get isRefreshing => _isRefreshing;
  DateTime get selectedDate => _selectedDate;
  List<PersonWithCategories> get people => _people;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  bool get isEditMode => _isEditMode;
  Set<PersonWithCategories> get selectedPeople => _selectedPeople;
  bool get isTablet => _isTablet;

  // Set tablet mode
  void setTabletMode(bool isTablet) {
    _isTablet = isTablet;
  }

  // Filtered people getter
  List<PersonWithCategories> get filteredPeople {
    var filtered = _people.where((person) {
      // Search by name filter
      final nameMatch = person.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return nameMatch;
    }).toList();

    // Category filter
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filtered = filtered.map((person) {
        final matchingRecords = person.records.where((rec) => rec.category == _selectedCategory).toList();
        if (matchingRecords.isEmpty) return null;
        return PersonWithCategories(
          personId: person.personId,
          name: person.name,
          records: matchingRecords,
        );
      }).whereType<PersonWithCategories>().toList();
    }

    return filtered;
  }

  // Setters
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    if (_isEditMode) {
      toggleEditMode(); 
    }
    notifyListeners();
    refresh();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void toggleEditMode() {
    _isEditMode = !_isEditMode;
    if (!_isEditMode) {
      _selectedPeople.clear();
    }
    notifyListeners();
  }

  void togglePersonSelection(PersonWithCategories person) {
    if (_selectedPeople.contains(person)) {
      _selectedPeople.remove(person);
    } else {
      _selectedPeople.add(person);
    }
    notifyListeners();
  }

  void selectAll() {
    if (_selectedPeople.length == filteredPeople.length) {
      _selectedPeople.clear();
    } else {
      _selectedPeople.addAll(filteredPeople);
    }
    notifyListeners();
  }

  bool isPersonSelected(PersonWithCategories person) {
    return _selectedPeople.contains(person);
  }

  // Clear filters
  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    _selectedPeople.clear();
    notifyListeners();

    try {
      final dailyPeople = await reader.getPeopleFromCurrentDay(dateToString(_selectedDate));

      final Map<int, PersonWithCategories> personMap = {};
      for (var recordData in dailyPeople) {
        final personId = recordData['id'];

        if (!personMap.containsKey(personId)) {
          personMap[personId] = PersonWithCategories(
            personId: personId,
            name: recordData['name'],
            records: [],
          );
        }
        personMap[personId]!.records.add(CategoryRecord.fromMap(recordData));
      }
      _people = personMap.values.toList();
    } on custom_db_exceptions.DbConnectionException {
      _people = [];
      rethrow;
    } catch (e) {
      debugPrint("Error refreshing daily people: $e");
      _people = [];
      rethrow;
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
