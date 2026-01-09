import 'package:attendly/backend/dbLogic/db_read.dart';
import 'package:attendly/frontend/person_model/category_record.dart';
import 'package:attendly/frontend/person_model/person_logic_conversion.dart';
import 'package:attendly/frontend/selection_options/category_item.dart';
import 'package:attendly/frontend/utils/responsive_utils.dart';
import 'package:attendly/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

enum SearchType { name, description, nameAndDescription }

class SearchDailyLogsPage extends StatefulWidget {
  final Database dbCon;
  final bool isTablet;

  const SearchDailyLogsPage({
    super.key,
    required this.dbCon,
    this.isTablet = false,
  });

  @override
  State<SearchDailyLogsPage> createState() => _SearchDailyLogsPageState();
}

class _SearchDailyLogsPageState extends State<SearchDailyLogsPage> {
  late final DbSelection _reader;
  final _nameSearchController = TextEditingController();
  final _descriptionSearchController = TextEditingController();
  final _categoryController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = false;
  Map<String, List<CategoryRecord>> _groupedResults = {};
  Set<SearchType> _selectedSearchType = {SearchType.name};

  @override
  void initState() {
    super.initState();
    _reader = DbSelection(widget.dbCon);
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
      final results = await _reader.searchDailyLogs(
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
        final record = CategoryRecord.fromMap(row);
        if (grouped.containsKey(record.date)) {
          grouped[record.date]!.add(record);
        } else {
          grouped[record.date] = [record];
        }
      }

      setState(() {
        _groupedResults = grouped;
      });
    } catch (e) {
      // Handle error
      debugPrint('Search failed: $e');
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
    final iconSize = ResponsiveUtils.getIconSize(context);
    final bodySize = ResponsiveUtils.getBodyFontSize(context);
    final isTablet = widget.isTablet || ResponsiveUtils.isTablet(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.searchDailyLog,
          style: TextStyle(
            fontSize: ResponsiveUtils.getTitleFontSize(context),
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
              ResponsiveUtils.getContentPadding(context).left + 12,
              ResponsiveUtils.getContentPadding(context).top + 8,
              ResponsiveUtils.getContentPadding(context).right + 12,
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
                        borderRadius: ResponsiveUtils.getCardBorderRadius(context),
                      ),
                      contentPadding: ResponsiveUtils.getContentPadding(context),
                    ),
                  ),
                if (_selectedSearchType.first == SearchType.nameAndDescription)
                  SizedBox(height: ResponsiveUtils.getListPadding(context).vertical * 2),
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
                        borderRadius: ResponsiveUtils.getCardBorderRadius(context),
                      ),
                      contentPadding: ResponsiveUtils.getContentPadding(context),
                    ),
                  ),
                SizedBox(height: ResponsiveUtils.getListPadding(context).vertical * 2),
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
                SizedBox(height: ResponsiveUtils.getListPadding(context).vertical * 2),
                DropdownMenu<CategoryItem?>(
                  controller: _categoryController,
                  width: MediaQuery.of(context).size.width - (ResponsiveUtils.getContentPadding(context).horizontal * 2),
                  menuHeight: isTablet ? 300 : 250,
                  enableFilter: true,
                  requestFocusOnTap: false,
                  textStyle: TextStyle(fontSize: bodySize),
                  label: Text(
                    localizations.filterByCategory,
                    style: TextStyle(fontSize: bodySize, fontWeight: FontWeight.w500),
                  ),
                  onSelected: (item) => setState(() => _selectedCategory = item?.category.name),
                  dropdownMenuEntries: getCategoryItems(context)
                      .map<DropdownMenuEntry<CategoryItem?>>((CategoryItem item) {
                    return DropdownMenuEntry<CategoryItem?>(
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
                      borderRadius: ResponsiveUtils.getCardBorderRadius(context),
                    ),
                    contentPadding: ResponsiveUtils.getContentPadding(context),
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
                  expandedInsets: EdgeInsets.zero,
                ),
                SizedBox(height: ResponsiveUtils.getListPadding(context).vertical * 2.5),
                ElevatedButton.icon(
                  onPressed: _performSearch,
                  icon: Icon(Icons.search, size: iconSize, color: Colors.white),
                  label: Text(localizations.search, style: TextStyle(fontSize: bodySize)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, ResponsiveUtils.getButtonHeight(context)),
                    padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.getContentPadding(context).vertical / 2),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _groupedResults.isEmpty
                    ? Center(child: Text(localizations.noResultsFound, style: TextStyle(fontSize: bodySize)))
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.getContentPadding(context).left + 12,
                          vertical: ResponsiveUtils.getListPadding(context).vertical,
                        ),
                        itemCount: _groupedResults.keys.length,
                        itemBuilder: (context, index) {
                          final date = _groupedResults.keys.elementAt(index);
                          final records = _groupedResults[date]!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: ResponsiveUtils.getListPadding(context).vertical,
                                  horizontal: 8.0,
                                ),
                                child: Text(
                                  date,
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.getTitleFontSize(context),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ...records.map((record) {
                                return Card(
                                  margin: EdgeInsets.only(bottom: ResponsiveUtils.getListPadding(context).vertical / 2),
                                  elevation: ResponsiveUtils.getCardElevation(context),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: ResponsiveUtils.getCardBorderRadius(context),
                                  ),
                                  child: ListTile(
                                    contentPadding: ResponsiveUtils.getContentPadding(context),
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
