import 'package:attendly/data/database/exceptions.dart' as custom_db_exceptions;
import 'package:attendly/features/daily_log/data/daily_repository.dart';
import 'package:attendly/features/daily_log/models/category_record.dart';
import 'package:attendly/shared/options/category_label.dart';
import 'package:attendly/shared/options/category_option.dart';
import 'package:attendly/core/responsive/responsive.dart';
import 'package:attendly/l10n/app_localizations.dart';
import 'package:attendly/features/daily_log/providers/daily_log_providers.dart';
import 'package:attendly/core/logging/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SearchType { name, description, nameAndDescription }

class DailyLogSearchPage extends ConsumerStatefulWidget {

  const DailyLogSearchPage({
    super.key,
  });

  @override
  ConsumerState<DailyLogSearchPage> createState() => _DailyLogSearchPageState();
}

class _DailyLogSearchPageState extends ConsumerState<DailyLogSearchPage> {
  final _nameSearchController = TextEditingController();
  final _descriptionSearchController = TextEditingController();
  final _categoryController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = false;
  Map<String, List<CategoryRecord>> _groupedResults = {};
  Set<SearchType> _selectedSearchType = {SearchType.name};

  late DailyRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = ref.read(dailyRepositoryProvider);
    _nameSearchController.addListener(() => setState(() {}));
    _descriptionSearchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameSearchController.dispose();
    _descriptionSearchController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _groupedResults = {};
    });

    try {
      final searchType = _selectedSearchType.first;
      final results = await _repo.searchLogs(
        name: searchType == SearchType.name || searchType == SearchType.nameAndDescription
            ? _nameSearchController.text
            : null,
        description: searchType == SearchType.description || searchType == SearchType.nameAndDescription
            ? _descriptionSearchController.text
            : null,
        category: _selectedCategory,
      );

      final Map<String, List<CategoryRecord>> grouped = {};
      
      for (final row in results) {
        final person = row.readTable(_repo.db.directoryPeople);
        final entry = row.readTable(_repo.db.dailyEntry);

        final record = CategoryRecord.fromDrift(person, entry);
        
        if (grouped.containsKey(record.date)) {
          grouped[record.date]!.add(record);
        } else {
          grouped[record.date] = [record];
        }
      }

      setState(() {
        _groupedResults = grouped;
      });
    } on custom_db_exceptions.DatabaseNotReadyException {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    catch (e, stackTrace) {
      AppLogger.e('Search', 'Search failed', e, stackTrace);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onEntryTap(String date) {
    Navigator.of(context).pop(DateTime.parse(date));
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final iconSize = Responsive.of(context).iconSize();
    final bodySize = Responsive.of(context).bodyFontSize;
    final isTablet = Responsive.of(context).isTablet;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.searchDailyLog,
          style: TextStyle(
            fontSize: Responsive.of(context).titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: iconSize),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              Responsive.of(context).contentPadding.left + 12,
              Responsive.of(context).contentPadding.top + 8,
              Responsive.of(context).contentPadding.right + 12,
              0,
            ),
            child: Column(
              children: [
                if (_selectedSearchType.first == SearchType.name ||
                    _selectedSearchType.first == SearchType.nameAndDescription)
                  TextField(
                    controller: _nameSearchController,
                    style: TextStyle(fontSize: bodySize),
                    decoration: InputDecoration(
                      labelText: localizations.searchByName,
                      labelStyle: TextStyle(fontSize: bodySize),
                      prefixIcon: Icon(Icons.person_search, size: iconSize),
                      suffixIcon: _nameSearchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, size: iconSize),
                              onPressed: () => _nameSearchController.clear(),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: Responsive.of(context).cardBorderRadius,
                      ),
                      contentPadding: Responsive.of(context).contentPadding,
                    ),
                  ),
                if (_selectedSearchType.first == SearchType.nameAndDescription)
                  SizedBox(height: Responsive.of(context).listPadding.vertical * 2),
                if (_selectedSearchType.first == SearchType.description ||
                    _selectedSearchType.first == SearchType.nameAndDescription)
                  TextField(
                    controller: _descriptionSearchController,
                    style: TextStyle(fontSize: bodySize),
                    decoration: InputDecoration(
                      labelText: localizations.searchByDescription,
                      labelStyle: TextStyle(fontSize: bodySize),
                      prefixIcon: Icon(Icons.description, size: iconSize),
                      suffixIcon: _descriptionSearchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, size: iconSize),
                              onPressed: () => _descriptionSearchController.clear(),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: Responsive.of(context).cardBorderRadius,
                      ),
                      contentPadding: Responsive.of(context).contentPadding,
                    ),
                  ),
                SizedBox(height: Responsive.of(context).listPadding.vertical * 2),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                      child: Text(
                        localizations.searchIn,
                        style: TextStyle(fontSize: bodySize - 2, color: Theme.of(context).hintColor),
                      ),
                    ),
                    SegmentedButton<SearchType>(
                      segments: <ButtonSegment<SearchType>>[
                        ButtonSegment<SearchType>(
                          value: SearchType.name,
                          label: Text(localizations.name, style: TextStyle(fontSize: bodySize - 2)),
                          icon: const Icon(Icons.person_search),
                        ),
                        ButtonSegment<SearchType>(
                          value: SearchType.description,
                          label: Text(localizations.searchByDescription, style: TextStyle(fontSize: bodySize - 2)),
                          icon: const Icon(Icons.description),
                        ),
                        ButtonSegment<SearchType>(
                          value: SearchType.nameAndDescription,
                          label: Text(localizations.searchByNameAndDescription, style: TextStyle(fontSize: bodySize - 2)),
                          icon: const Icon(Icons.find_in_page),
                        ),
                      ],
                      selected: _selectedSearchType,
                      onSelectionChanged: (Set<SearchType> newSelection) {
                        setState(() {
                          _selectedSearchType = newSelection;
                        });
                      },
                      multiSelectionEnabled: false,
                      showSelectedIcon: false,
                    ),
                  ],
                ),
                SizedBox(height: Responsive.of(context).listPadding.vertical * 2),
                DropdownMenu<CategoryOption?>(
                  controller: _categoryController,
                  // width: MediaQuery.of(context).size.width - (Responsive.of(context).contentPadding.horizontal * 2),
                  expandedInsets: EdgeInsets.zero,
                  menuHeight: isTablet ? 300 : 250,
                  enableFilter: true,
                  requestFocusOnTap: false,
                  textStyle: TextStyle(fontSize: bodySize),
                  label: Text(
                    localizations.filterByCategory,
                    style: TextStyle(fontSize: bodySize, fontWeight: FontWeight.w500),
                  ),
                  onSelected: (item) => setState(() => _selectedCategory = item?.category.name),
                  dropdownMenuEntries: getCategoryOptions(context)
                      .map<DropdownMenuEntry<CategoryOption?>>((CategoryOption item) {
                    return DropdownMenuEntry<CategoryOption?>(
                      value: item,
                      label: item.label,
                      leadingIcon: item.icon != null ? Icon(item.icon, size: iconSize) : null,
                      style: MenuItemButton.styleFrom(
                        textStyle: TextStyle(fontSize: bodySize),
                      ),
                    );
                  }).toList(),
                  inputDecorationTheme: InputDecorationTheme(
                    border: OutlineInputBorder(
                      borderRadius: Responsive.of(context).cardBorderRadius,
                    ),
                    contentPadding: Responsive.of(context).contentPadding,
                  ),
                  trailingIcon: _selectedCategory != null
                      ? IconButton(
                          icon: Icon(Icons.clear, size: iconSize),
                          onPressed: () => setState(() {
                            _selectedCategory = null;
                            _categoryController.clear();
                          }),
                        )
                      : null,
                ),
                SizedBox(height: Responsive.of(context).listPadding.vertical * 2.5),
                ElevatedButton.icon(
                  onPressed: _performSearch,
                  icon: Icon(Icons.search, size: iconSize, color: Colors.white),
                  label: Text(localizations.search, style: TextStyle(fontSize: bodySize)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, Responsive.of(context).buttonHeight),
                    padding: EdgeInsets.symmetric(vertical: Responsive.of(context).contentPadding.vertical / 2),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _groupedResults.isEmpty
                    ? SizedBox(
                        width: double.infinity,
                        child: Center(
                          child: Text(
                            localizations.noResultsFound,
                            textAlign: TextAlign.center, 
                            style: TextStyle(fontSize: bodySize),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.of(context).contentPadding.left + 12,
                          vertical: Responsive.of(context).listPadding.vertical,
                        ),
                        itemCount: _groupedResults.keys.length,
                        itemBuilder: (context, index) {
                          final date = _groupedResults.keys.elementAt(index);
                          final records = _groupedResults[date]!;

                          DateTime parsedDate = DateTime.parse(date);
                          String formattedDisplayDate = DateFormat('dd.MM.yyyy').format(parsedDate);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: Responsive.of(context).listPadding.vertical,
                                  horizontal: 8.0,
                                ),
                                child: Text(
                                  formattedDisplayDate,
                                  style: TextStyle(
                                    fontSize: Responsive.of(context).titleFontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ...records.map((record) {
                                return Card(
                                  margin: EdgeInsets.only(bottom: Responsive.of(context).listPadding.vertical / 2),
                                  elevation: Responsive.of(context).cardElevation,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: Responsive.of(context).cardBorderRadius,
                                  ),
                                  child: ListTile(
                                    contentPadding: Responsive.of(context).contentPadding,
                                    title: Text(
                                      record.personName ?? localizations.unknown,
                                      style: TextStyle(fontSize: bodySize, fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Text(
                                      '${localizedCategoryLabel(context, record.category)}${record.comment != null && record.comment!.isNotEmpty ? ': ${record.comment}' : ''}',
                                      style: TextStyle(fontSize: bodySize - 2),
                                    ),
                                    onTap: () => _onEntryTap(record.date),
                                  ),
                                );
                              }),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}