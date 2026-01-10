import 'package:attendly/frontend/pages/search_pages/search_daily_logs_page.dart';
import 'package:attendly/frontend/person_model/person_categories.dart';
import 'package:attendly/frontend/person_model/person_logic_conversion.dart';
import 'package:attendly/frontend/utils/responsive_utils.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:attendly/backend/db_exceptions.dart' as custom_db_exceptions;
import 'package:attendly/backend/dbLogic/db_read.dart';
import 'package:attendly/backend/dbLogic/db_delete.dart';
import 'package:attendly/backend/dbLogic/db_insert.dart';
import 'package:attendly/backend/dbLogic/db_update.dart';
import 'package:attendly/frontend/pages/directory_pages/message_helper.dart';
import 'package:attendly/frontend/pages/daily_logs_pages/add_page_daily.dart';
import 'package:attendly/frontend/pages/daily_logs_pages/daily_person_controller.dart';
import 'package:attendly/frontend/pages/daily_logs_pages/edit_category_page.dart';
import 'package:attendly/frontend/person_model/category_record.dart';
import 'package:attendly/frontend/widgets/refreshable_app_bar.dart';
import 'package:attendly/frontend/widgets/custom_drawer.dart';
import 'package:attendly/frontend/selection_options/category_item.dart';
import 'package:attendly/localization/app_localizations.dart';
import 'package:attendly/backend/db_connection_validator.dart';

class DailyPerson extends StatefulWidget{
  final Database dbCon;
  final int selectedTab;
  final void Function(int) onTabChange;
  final bool isTablet;

  const DailyPerson({
    super.key, 
    required this.dbCon, 
    required this.selectedTab, 
    required this.onTabChange,
    this.isTablet = false,
  });

  @override
  State<StatefulWidget> createState() => DailyPersonState();
}

class DailyPersonState extends State<DailyPerson>{
  late DbSelection reader;
  late DbDeletion deleter;
  late DbInsertion inserter;
  late DbUpdater updater;
  late HelperAllPerson _helper;
  late DailyPersonController _controller;

  bool get isLoading => _controller.isRefreshing;
  DateTime get selectedDate => _controller.selectedDate;

  @override
  void initState() {
    super.initState();
    reader = DbSelection(widget.dbCon);
    updater = DbUpdater(widget.dbCon, reader);
    inserter = DbInsertion(widget.dbCon, reader, updater);
    deleter = DbDeletion(widget.dbCon, reader, inserter, updater);
    _helper = HelperAllPerson();
    _controller = DailyPersonController(widget.dbCon);

    // Properly handle async refresh after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    try {
      await _controller.refresh();
    } on custom_db_exceptions.DbConnectionException catch (e) {
      debugPrint('Database connection error during initialization: $e');
      if (mounted) {
        await DbConnectionValidator.handleConnectionError(context);
      }
    } catch (e, stackTrace) {
      debugPrint('Error during initialization: $e');
      if (mounted) {
        _helper.showErrorMessage(context, 'Failed to load initial data: ${e.toString()}', stackTrace: stackTrace);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async{
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _controller.selectedDate,
      firstDate: DateTime(2000), 
      lastDate: DateTime(2100),
      keyboardType: TextInputType.numberWithOptions(),
      builder: (context, child) {
        if (!widget.isTablet || child == null) return child ?? const SizedBox.shrink();

       final mq = MediaQuery.of(context);
       final currentScale = mq.textScaler.scale(1.0);
       final newScale = (currentScale * 1.2).clamp(1.0, 1.6);
       
       return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(newScale),
          ),
          child: Transform.scale(
            scale: 1.1,
            child: child,
          ),
        );
      },
    );

    if(picked != null && picked != _controller.selectedDate){
      _controller.setSelectedDate(picked);
    }
  }

  Future<void> refreshDailyEntries() async {
    try {
      await _controller.refresh();
    } on custom_db_exceptions.DbConnectionException catch (e) {
      debugPrint('Database connection error: $e');
      if (mounted) {
        await DbConnectionValidator.handleConnectionError(context);
      }
    } catch (e, stackTrace) {
      _helper.showErrorMessage(context, 'Failed to refresh data: ${e.toString()}', stackTrace: stackTrace);
    }
  }

  Future<void> _onFabPressed(BuildContext context) async {
    try {
      DateTime? currentDate = selectedDate;
      bool? res = await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => AddDaily(
          database: widget.dbCon,
          initialDate: currentDate,
          isTablet: widget.isTablet,
        ))
      );
      
      if (res == true) {
        await refreshDailyEntries();
      }
    } on custom_db_exceptions.DbConnectionException catch (e) {
      debugPrint('Database connection error: $e');
      if (mounted) {
        await DbConnectionValidator.handleConnectionError(context);
      }
    }
  }

  Future<void> _onSearchFabPressed() async {
    final selectedDate = await Navigator.of(context).push<DateTime>(
      MaterialPageRoute(
        builder: (context) => SearchDailyLogsPage(
          dbCon: widget.dbCon,
          isTablet: widget.isTablet,
        ),
      ),
    );

    if (selectedDate != null) {
      _controller.setSelectedDate(selectedDate);
    }
  }

  Future<void> _onBulkAddCategory() async {
    final selected = _controller.selectedPeople.map((p) {
      return {'id': p.personId, 'name': p.name};
    }).toList();

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddDaily(
          database: widget.dbCon,
          initialDate: _controller.selectedDate,
          preselectedPersons: selected,
          isTablet: widget.isTablet,
        ),
      ),
    );
    if (result == true) {
      _controller.toggleEditMode();
      await _controller.refresh();
    }
  }

  Future<void> _onBulkDelete() async {
    final localizations = AppLocalizations.of(context);
    final count = _controller.selectedPeople.length;
    final confirm = await _helper.displayDialog(
      context,
      localizations.delete,
      localizations.confirmBulkDelete(count),
      localizations,
    );

    if (confirm != true) return;

    try {
      _helper.showLoadingDialog(context, localizations.delete);
      final personIds = _controller.selectedPeople.map((p) => p.personId).toList();
      await deleter.deleteMultipleDailyEntriesForPeople(personIds, _controller.selectedDate);
      if (mounted) _helper.hideLoadingDialog(context);
      await _helper.showSubmitMessage(context, localizations.peopleEntriesDeleted(count));
      _controller.toggleEditMode();
      await _controller.refresh();
    } catch (e, stackTrace) {
      if (mounted) _helper.hideLoadingDialog(context);
      _helper.showErrorMessage(context, 'Failed to delete entries: $e', stackTrace: stackTrace);
    }
  }

  Future<void> _addCategoryForPerson(PersonWithCategories person) async {
    try {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => AddDaily(
            database: widget.dbCon,
            initialDate: _controller.selectedDate,
            preselectedPersons: [{'id': person.personId, 'name': person.name}],
            isTablet: widget.isTablet,
          ),
        ),
      );
      if (result == true) {
        await _controller.refresh();
      }
    } on custom_db_exceptions.DbConnectionException catch (e) {
      debugPrint('Database connection error: $e');
      if (mounted) {
        await DbConnectionValidator.handleConnectionError(context);
      }
    }
  }

  Future<void> _editCategory(CategoryRecord record) async {
    try {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => EditCategoryPage(
            database: widget.dbCon,
            record: record,
          ),
        ),
      );
      if (result == true) {
        await _controller.refresh();
      }
    } on custom_db_exceptions.DbConnectionException catch (e) {
      debugPrint('Database connection error: $e');
      if (mounted) {
        await DbConnectionValidator.handleConnectionError(context);
      }
    }
  }

  Future<void> _deleteCategory(CategoryRecord record) async {
    final localizations = AppLocalizations.of(context);
    final confirm = await _helper.displayDialog(
      context,
      localizations.deleteRecord,
      // use localized category here
      localizations.confirmDeleteCategory(
        localizedCategoryLabel(context, record.category),
        record.personName ?? localizations.unknown,
        record.date,
      ),
      localizations,
    );

    if (confirm == true) {
      try{
        _helper.showLoadingDialog(context, localizations.delete);
        await deleter.deleteDailyEntry(record.recordId, record.personId, date: record.date);
        if (mounted) {
          _helper.hideLoadingDialog(context);
          await _helper.showSubmitMessage(context, localizations.recordDeleted);
        }
        if (mounted) {
          await _controller.refresh();
        }
      } on custom_db_exceptions.DbConnectionException catch (e) {
        if (mounted) _helper.hideLoadingDialog(context);
        debugPrint('Database connection error: $e');
        if (mounted) {
          await DbConnectionValidator.handleConnectionError(context);
        }
      } catch (e, stackTrace) {
        if (mounted) _helper.hideLoadingDialog(context);
        _helper.showErrorMessage(context, e.toString(), stackTrace: stackTrace);
      }
    }
  }

   @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<DailyPersonController>(
        builder: (context, controller, child) {
          final theme = Theme.of(context);
          final now = DateTime.now();
          final todayDateOnly = DateTime(now.year, now.month, now.day);
          final selectedDateOnly = DateTime(controller.selectedDate.year, controller.selectedDate.month, controller.selectedDate.day);
          final isTodayOrFuture = !selectedDateOnly.isBefore(todayDateOnly);
          final isTablet = widget.isTablet;
          final arrowIconSize = ResponsiveUtils.getIconSize(context, baseSize: 30);
          final appBarIconSize = ResponsiveUtils.getIconSize(context);

          return Scaffold(
            drawer: isTablet
                ? null
                : CustomDrawer(
                    selectedTab: widget.selectedTab,
                    onTabChange: widget.onTabChange,
                  ),
            appBar: RefreshableAppBar(
                title: localizations.dailyLogs,
                onRefresh: refreshDailyEntries,
                isLoading: isLoading,
                showRefresh: !controller.isEditMode,
                isTablet: isTablet,
                leading: controller.isEditMode
                    ? IconButton(
                        icon: Icon(Icons.close, size: appBarIconSize),
                        onPressed: controller.toggleEditMode,
                      )
                    : isTablet
                        ? null
                        : Builder(
                            builder: (context) => IconButton(
                              onPressed: () => Scaffold.of(context).openDrawer(),
                              // Bigger drawer icon
                              icon: Icon(Icons.menu, size: ResponsiveUtils.getIconSize(context, baseSize: 35)),
                            ),
                          ),
                actions: [
                  if (!controller.isEditMode)
                    IconButton(
                      icon: Icon(Icons.edit, size: ResponsiveUtils.getIconSize(context, baseSize: 30)),
                      onPressed: controller.people.isEmpty ? null : controller.toggleEditMode,
                    ),
                  if (controller.isEditMode)
                    IconButton(
                      icon: Icon(Icons.select_all, size: ResponsiveUtils.getIconSize(context, baseSize: 28)),
                      onPressed: controller.filteredPeople.isEmpty ? null : controller.selectAll,
                    ),
                ],
              ),
              body: SafeArea(
                child: Center(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.getListPadding(context).horizontal,
                          vertical: ResponsiveUtils.getListPadding(context).vertical
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              onPressed: () => controller.setSelectedDate(controller.selectedDate.subtract(const Duration(days: 1))),
                              icon: Icon(Icons.arrow_back_ios_sharp, color: theme.iconTheme.color),
                              iconSize: arrowIconSize,
                            ),
                            GestureDetector(
                              onTap: _selectDate,
                              child: Text(
                                 "${controller.selectedDate.day}.${controller.selectedDate.month}.${controller.selectedDate.year}",
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: ResponsiveUtils.getTitleFontSize(context),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: isTodayOrFuture ? null : () => controller.setSelectedDate(controller.selectedDate.add(const Duration(days: 1))),
                              icon: Icon(
                                Icons.arrow_forward_ios_sharp, 
                                color: isTodayOrFuture ? theme.disabledColor : theme.iconTheme.color
                              ),
                              iconSize: arrowIconSize,
                            )
                          ],
                        ),
                      ),
                      _FilterSection(controller: controller),
                      //_buildFilterSection(),
                      Expanded(
                        child: _PersonList(
                          onAddCategory: _addCategoryForPerson,
                          onEditCategory: _editCategory,
                          onDeleteCategory: _deleteCategory,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              floatingActionButton: controller.isEditMode
                ? null
                : Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: ResponsiveUtils.getButtonHeight(context) + 10,
                        height: ResponsiveUtils.getButtonHeight(context) + 10,
                        child: FloatingActionButton(
                          heroTag: 'search_fab',
                          onPressed: _onSearchFabPressed,
                          child: Icon(Icons.search, size: ResponsiveUtils.getIconSize(context, baseSize: 30)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: ResponsiveUtils.getButtonHeight(context) + 25,
                        height: ResponsiveUtils.getButtonHeight(context) + 25,
                        child: FloatingActionButton(
                          heroTag: 'add_fab',
                          onPressed: () => _onFabPressed(context),
                          child: Icon(Icons.add, size: ResponsiveUtils.getIconSize(context, baseSize: 35)),
                        ),
                      ),
                    ],
                  ),
            bottomNavigationBar: controller.isEditMode ? _buildEditModeActions() : null,
          );
        },
      ),
    );
  }

  Widget _buildEditModeActions() {
    final localizations = AppLocalizations.of(context);
    final selectedCount = _controller.selectedPeople.length;
    final hasSelection = selectedCount > 0;

    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          TextButton.icon(
            icon: Icon(Icons.add_task, size: ResponsiveUtils.getIconSize(context)),
            label: Text(localizations.addCategory, style: TextStyle(fontSize: ResponsiveUtils.getSmallFontSize(context))),
            onPressed: hasSelection ? _onBulkAddCategory : null,
          ),
          TextButton.icon(
            icon: Icon(Icons.delete_sweep, size: ResponsiveUtils.getIconSize(context)),
            label: Text('${localizations.delete} ($selectedCount)', style: TextStyle(fontSize: ResponsiveUtils.getSmallFontSize(context))),
            onPressed: hasSelection ? _onBulkDelete : null,
            style: TextButton.styleFrom(
              foregroundColor: hasSelection ? Colors.red : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}


class _FilterSection extends StatefulWidget {
  final DailyPersonController controller;

  const _FilterSection({required this.controller});

  @override
  State<_FilterSection> createState() => _FilterSectionState();
}

class _FilterSectionState extends State<_FilterSection> {
  final _searchController = TextEditingController();
  final _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Add a listener to the controller to update the text fields if data is externally refreshed
    widget.controller.addListener(_onControllerUpdate);
    // Listen to text changes to apply the filter
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
  
  void _onControllerUpdate() {
    // If the controller's filters are ever cleared externally, update the UI here.
    if(widget.controller.searchQuery.isEmpty) _searchController.clear();
    if(widget.controller.selectedCategory == null) _categoryController.clear();
  }

  void _applyFilters() {
    widget.controller.setSearchQuery(_searchController.text);
  }

  void _selectCategory(CategoryItem? item) {
    widget.controller.setSelectedCategory(item?.category.name);
    // No need to call setState, the controller will notify listeners.
  }

  void _clearCategoryFilter() {
    _categoryController.clear();
    widget.controller.setSelectedCategory(null);
  }
  
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final body = ResponsiveUtils.getBodyFontSize(context);
    final title = ResponsiveUtils.getTitleFontSize(context);
    return Consumer<DailyPersonController>(
      builder: (context, controller, child) {
        return Padding(
          padding: ResponsiveUtils.getListPadding(context),
          child: ExpansionTile(
            leading: const Icon(Icons.filter_list),
            title: Text(
              localizations.filterOptions,
              style: TextStyle(fontSize: title, fontWeight: FontWeight.w600),
            ),
            tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
            childrenPadding: ResponsiveUtils.getListPadding(context),
            children: [
              TextField(
                controller: _searchController,
                style: TextStyle(fontSize: body + 2),
                decoration: InputDecoration(
                  labelText: localizations.searchByName,
                  labelStyle: TextStyle(fontSize: body + 2),
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: ResponsiveUtils.getCardBorderRadius(context),
                  ),
                  suffixIcon: controller.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  contentPadding: ResponsiveUtils.getContentPadding(context),
                ),
              ),
              const SizedBox(height: 12),
              DropdownMenu<CategoryItem?>(
                controller: _categoryController,
                enableFilter: true,
                requestFocusOnTap: false,
                label: Text(
                  localizations.filterByCategory,
                  style: TextStyle(fontSize: body + 2, fontWeight: FontWeight.w500),
                ),
                initialSelection: null,
                onSelected: _selectCategory,
                dropdownMenuEntries: getCategoryItems(context)
                    .map<DropdownMenuEntry<CategoryItem?>>((CategoryItem item) {
                  return DropdownMenuEntry<CategoryItem?>(
                    value: item,
                    label: item.label,
                    leadingIcon: item.icon != null ? Icon(item.icon) : null,
                    style: MenuItemButton.styleFrom(
                      textStyle: TextStyle(fontSize: body + 2),
                    ),
                  );
                }).toList(),
                inputDecorationTheme: InputDecorationTheme(
                  border: OutlineInputBorder(
                    borderRadius: ResponsiveUtils.getCardBorderRadius(context),
                  ),
                  contentPadding: ResponsiveUtils.getContentPadding(context),
                ),
                trailingIcon: controller.selectedCategory != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearCategoryFilter,
                      )
                    : null,
                expandedInsets: EdgeInsets.zero,
              ),
            ],
          ),
        );
      }
    );
  }
}


class _PersonList extends StatelessWidget {
  final Future<void> Function(PersonWithCategories) onAddCategory;
  final Future<void> Function(CategoryRecord) onEditCategory;
  final Future<void> Function(CategoryRecord) onDeleteCategory;

  const _PersonList({
    required this.onAddCategory,
    required this.onEditCategory,
    required this.onDeleteCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<DailyPersonController>(
      builder: (context, controller, child) {
        final localizations = AppLocalizations.of(context);
        final theme = Theme.of(context);
        final titleSize = ResponsiveUtils.getTitleFontSize(context);
        final bodySize = ResponsiveUtils.getBodyFontSize(context);
        final listPad = ResponsiveUtils.getListPadding(context);

        if (controller.isRefreshing && controller.filteredPeople.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        } else if (controller.filteredPeople.isEmpty) {
          return Center(
            child: Text(
              localizations.noEntriesForThisDay,
              style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context))
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.only(
            left: listPad.left,
            right: listPad.right,
            top: 0,
            
            bottom: ResponsiveUtils.getButtonHeight(context) + 60 + MediaQuery.of(context).padding.bottom,
          ),
          itemCount: controller.filteredPeople.length,
          itemBuilder: (context, index) {
            final person = controller.filteredPeople[index];
            final isSelected = controller.isPersonSelected(person);
            return Card(
              margin: EdgeInsets.only(bottom: listPad.vertical * 1.5),
              elevation: ResponsiveUtils.getCardElevation(context),
              shape: RoundedRectangleBorder(
                side: isSelected
                    ? BorderSide(color: theme.primaryColor, width: 2)
                    : BorderSide.none,
                borderRadius: ResponsiveUtils.getCardBorderRadius(context),
              ),
              color: isSelected ? theme.primaryColor.withValues(alpha: 0.1) : theme.cardTheme.color,
              child: InkWell(
                onTap: controller.isEditMode ? () => controller.togglePersonSelection(person) : null,
                borderRadius: ResponsiveUtils.getCardBorderRadius(context),
                child: Padding(
                 
                  padding: ResponsiveUtils.getContentPadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  person.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: titleSize,
                                    color: theme.textTheme.titleLarge?.color,
                                  ),
                                ),
                                // Text(
                                //   '${localizations.id}: ${person.personId}',
                                //   style: TextStyle(
                                //     fontSize: bodySize,
                                //     color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                                //   ),
                                // ),
                              ],
                            ),
                          ),
                          if (controller.isEditMode)
                            Checkbox(
                              value: isSelected,
                              onChanged: (bool? value) {
                                controller.togglePersonSelection(person);
                              },
                            ),
                        ],
                      ),
                      Divider(height: 24, color: theme.dividerColor),
                      ...person.records.map((record) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            // localize category label
                            localizedCategoryLabel(context, record.category),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: bodySize,
                            ),
                          ),
                          subtitle: record.comment != null && record.comment!.isNotEmpty
                              ? Text(
                                  record.comment!,
                                  style: TextStyle(fontSize: bodySize - 2),
                                )
                              : null,
                          trailing: controller.isEditMode
                              ? null
                              : PopupMenuButton<String>(
                                  icon: Icon(
                                    Icons.more_vert,
                                    size: ResponsiveUtils.getIconSize(context, baseSize: 28),
                                  ),
                                  onSelected: (value) {
                                    if (value == 'edit') onEditCategory(record);
                                    if (value == 'delete') onDeleteCategory(record);
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text(
                                        localizations.edit,
                                        style: TextStyle(fontSize: bodySize),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text(
                                        localizations.delete,
                                        style: TextStyle(fontSize: bodySize),
                                      ),
                                    ),
                                  ],
                                ),
                        );
                      }),
                      if (!controller.isEditMode) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: IconButton(
                            onPressed: () => onAddCategory(person),
                            icon: Icon(Icons.add_circle_outline, color: theme.primaryColor),
                            iconSize: ResponsiveUtils.getIconSize(context, baseSize: 28),
                            tooltip: localizations.addCategory,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              )
              );
            },
          );
        },
    );
  }
}