import 'package:attendly/data/local/config/db_exceptions.dart' as custom_db_exceptions;
import 'package:attendly/data/repo/daily_repository.dart';
import 'package:attendly/frontend/pages/search_pages/search_daily_logs_page.dart';
import 'package:attendly/frontend/person_model/person_categories.dart';
import 'package:attendly/frontend/person_model/person_logic_conversion.dart';
import 'package:attendly/frontend/utils/responsive_utils.dart';
import 'package:attendly/provider/daily_repo_provider.dart';
import 'package:attendly/provider/database_provider.dart';
import 'package:flutter/material.dart';
import 'package:attendly/frontend/pages/directory_pages/message_helper.dart';
import 'package:attendly/frontend/pages/daily_logs_pages/add_page_daily.dart';
import 'package:attendly/frontend/pages/daily_logs_pages/edit_category_page.dart';
import 'package:attendly/frontend/person_model/category_record.dart';
import 'package:attendly/frontend/widgets/refreshable_app_bar.dart';
import 'package:attendly/frontend/widgets/custom_drawer.dart';
import 'package:attendly/frontend/selection_options/category_item.dart';
import 'package:attendly/localization/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DailyPerson extends ConsumerStatefulWidget {
  final int selectedTab;
  final void Function(int) onTabChange;
  final bool isTablet;

  const DailyPerson({
    super.key,
    required this.selectedTab,
    required this.onTabChange,
    this.isTablet = false,
  });

  @override
  ConsumerState<DailyPerson> createState() => DailyPersonState();
}

class DailyPersonState extends ConsumerState<DailyPerson> {
  late DailyRepository _repo;
  final HelperAllPerson _helper = HelperAllPerson();

  void refreshDailyEntries() {
    ref.invalidate(dailyRawLogsProvider);
  }

  void _toggleEditMode() {
    final isEditing = ref.read(dailyEditModeProvider);
    ref.read(dailyEditModeProvider.notifier).state = !isEditing;
    if (isEditing) {
      ref.read(dailySelectedPeopleProvider.notifier).state = {};
    }
  }

  void _toggleSelection(PersonWithCategories person) {
    final currentSet = ref.read(dailySelectedPeopleProvider);
    final newSet = Set<PersonWithCategories>.from(currentSet);
    if (newSet.contains(person)) {
      newSet.remove(person);
    } else {
      newSet.add(person);
    }
    ref.read(dailySelectedPeopleProvider.notifier).state = newSet;
  }

  void _selectAll(List<PersonWithCategories> visiblePeople) {
    final currentSet = ref.read(dailySelectedPeopleProvider);
    if (currentSet.length == visiblePeople.length) {
      ref.read(dailySelectedPeopleProvider.notifier).state = {};
    } else {
      ref.read(dailySelectedPeopleProvider.notifier).state = Set.from(visiblePeople);
    }
  }

  Future<void> _selectDate() async {
    final currentDate = ref.read(dailyDateProvider);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      keyboardType: const TextInputType.numberWithOptions(),
    );

    if (picked != null && picked != currentDate) {
      ref.read(dailyDateProvider.notifier).state = picked;
      if (ref.read(dailyEditModeProvider)) _toggleEditMode();
    }
  }

  Future<void> _onFabPressed(BuildContext context) async {
    final currentDate = ref.read(dailyDateProvider);
    bool? res = await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => AddDaily(
          initialDate: currentDate,
          isTablet: widget.isTablet,
        ))
    );
    if (res == true) refreshDailyEntries();
  }

  Future<void> _onSearchFabPressed() async {
    final selectedDate = await Navigator.of(context).push<DateTime>(
      MaterialPageRoute(builder: (context) => SearchDailyLogsPage(isTablet: widget.isTablet)),
    );
    if (selectedDate != null) {
      ref.read(dailyDateProvider.notifier).state = selectedDate;
    }
  }

  Future<void> _onBulkAddCategory() async {
    final selectedSet = ref.read(dailySelectedPeopleProvider);
    final date = ref.read(dailyDateProvider);
    final selectedList = selectedSet.map((p) => {'id': p.personId, 'name': p.name}).toList();

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddDaily(
          initialDate: date,
          preselectedPersons: selectedList,
          isTablet: widget.isTablet,
        ),
      ),
    );
    if (result == true) {
      _toggleEditMode();
      refreshDailyEntries();
    }
  }

  Future<void> _onBulkDelete() async {
    final localizations = AppLocalizations.of(context);
    final selectedSet = ref.read(dailySelectedPeopleProvider);
    final count = selectedSet.length;
    final date = ref.read(dailyDateProvider);
    _repo = ref.read(dailyRepositoryProvider);

    final confirm = await _helper.displayDialog(
      context, localizations.delete, localizations.confirmBulkDelete(count), localizations,
    );
    if (confirm != true) return;

    try {
      _helper.showLoadingDialog(context, localizations.delete);
      final personIds = selectedSet.map((p) => p.personId).toList();
      await _repo.bulkDeleteEntries(personIds, date);
      if (mounted) _helper.hideLoadingDialog(context);
      await _helper.showSubmitMessage(context, localizations.peopleEntriesDeleted(count));
      _toggleEditMode();
      refreshDailyEntries();
    } catch (e, stackTrace) {
      if (mounted) _helper.hideLoadingDialog(context);
      _helper.showErrorMessage(context, 'Failed to delete entries: $e', stackTrace: stackTrace);
    }
  }

  Future<void> _deleteCategory(CategoryRecord record) async {
    final localizations = AppLocalizations.of(context);
    _repo = ref.read(dailyRepositoryProvider);
    
    final confirm = await _helper.displayDialog(
      context, localizations.deleteRecord,
      localizations.confirmDeleteCategory(
        localizedCategoryLabel(context, record.category),
        record.personName ?? localizations.unknown,
        record.date,
      ), localizations,
    );

    if (confirm == true) {
      try {
        _helper.showLoadingDialog(context, localizations.delete);
        await _repo.deleteDailyEntry(record.recordId, record.personId, DateTime.parse(record.date));
        if (mounted) {
          _helper.hideLoadingDialog(context);
          await _helper.showSubmitMessage(context, localizations.recordDeleted);
        }
        refreshDailyEntries();
      } catch (e) {
        if (mounted) _helper.hideLoadingDialog(context);
        _helper.showErrorMessage(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    
    // Watch state
    final asyncFilteredData = ref.watch(dailyFilteredLogsProvider);
    final selectedDate = ref.watch(dailyDateProvider);
    final isEditMode = ref.watch(dailyEditModeProvider);
    final selectedPeople = ref.watch(dailySelectedPeopleProvider);

    // Error listening side-effect
    // ref.listen<AsyncValue<List<PersonWithCategories>>>(dailyRawLogsProvider, (prev, next) {
    //   if (next is AsyncError) {
    //     if (next.error is custom_db_exceptions.DbConnectionException) {
    //       DbConnectionValidator.handleConnectionError(context);
    //     } else {
    //       _helper.showErrorMessage(context, 'Failed to load: ${next.error}');
    //     }
    //   }
    // });

    ref.listen<AsyncValue<List<PersonWithCategories>?>>(dailyRawLogsProvider, (prev, next) {
      if (next is AsyncError) {
        final error = next.error;
        if (error != null && error is! custom_db_exceptions.DatabaseNotReadyException) {
          ref.read(databaseManagerProvider.notifier).reportDatabaseError(error);
        }
      }
    });

    final now = DateTime.now();
    final todayDateOnly = DateTime(now.year, now.month, now.day);
    final selectedDateOnly = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final isTodayOrFuture = !selectedDateOnly.isBefore(todayDateOnly);
    final arrowIconSize = ResponsiveUtils.getIconSize(context, baseSize: 30);
    final appBarIconSize = ResponsiveUtils.getIconSize(context);

    // Grab the list if available to check lengths
    final visiblePeople = asyncFilteredData.valueOrNull ?? [];

    return Scaffold(
      drawer: widget.isTablet ? null : CustomDrawer(selectedTab: widget.selectedTab, onTabChange: widget.onTabChange),
      appBar: RefreshableAppBar(
        title: localizations.dailyLogs,
        onRefresh: null,
        isLoading: asyncFilteredData.isLoading || asyncFilteredData.isReloading,
        showRefresh: false,
        isTablet: widget.isTablet,
        leading: isEditMode
            ? IconButton(icon: Icon(Icons.close, size: appBarIconSize), onPressed: _toggleEditMode)
            : widget.isTablet
                ? null
                : Builder(
                    builder: (context) => IconButton(
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: Icon(Icons.menu, size: ResponsiveUtils.getIconSize(context, baseSize: 35)),
                    ),
                  ),
        actions: [
          if (!isEditMode)
            IconButton(
              icon: Icon(Icons.edit, size: ResponsiveUtils.getIconSize(context, baseSize: 30)),
              onPressed: visiblePeople.isEmpty ? null : _toggleEditMode,
            ),
          if (isEditMode)
            IconButton(
              icon: Icon(Icons.select_all, size: ResponsiveUtils.getIconSize(context, baseSize: 28)),
              onPressed: visiblePeople.isEmpty ? null : () => _selectAll(visiblePeople),
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
                    vertical: ResponsiveUtils.getListPadding(context).vertical),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: () => ref.read(dailyDateProvider.notifier).state = selectedDate.subtract(const Duration(days: 1)),
                      icon: Icon(Icons.arrow_back_ios_sharp, color: theme.iconTheme.color),
                      iconSize: arrowIconSize,
                    ),
                    GestureDetector(
                      onTap: _selectDate,
                      child: Text(
                        "${selectedDate.day}.${selectedDate.month}.${selectedDate.year}",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: ResponsiveUtils.getTitleFontSize(context),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: isTodayOrFuture ? null : () => ref.read(dailyDateProvider.notifier).state = selectedDate.add(const Duration(days: 1)),
                      icon: Icon(Icons.arrow_forward_ios_sharp, color: isTodayOrFuture ? theme.disabledColor : theme.iconTheme.color),
                      iconSize: arrowIconSize,
                    )
                  ],
                ),
              ),
              const _FilterSection(),
              Expanded(
                child: asyncFilteredData.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  // error: (_, __) => Center(
                  //   child: ElevatedButton(onPressed: refreshDailyEntries, child: const Text("Retry"))
                  // ),
                  error: (error, __) {
                    if (error is custom_db_exceptions.DatabaseNotReadyException) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return const Center(child: CircularProgressIndicator()); // MyApp handles redirect
                  },
                  data: (people) => _PersonList(
                    people: people,
                    isEditMode: isEditMode,
                    selectedPeople: selectedPeople,
                    onToggleSelection: _toggleSelection,
                    onAddCategory: (person) async {
                      final res = await Navigator.push<bool>(context, MaterialPageRoute(builder: (ctx) => AddDaily(initialDate: selectedDate, preselectedPersons: [{'id': person.personId, 'name': person.name}], isTablet: widget.isTablet)));
                      if (res == true) refreshDailyEntries();
                    },
                    onEditCategory: (record) async {
                      final res = await Navigator.push<bool>(context, MaterialPageRoute(builder: (ctx) => EditCategoryPage(record: record, isTablet: widget.isTablet)));
                      if (res == true) refreshDailyEntries();
                    },
                    onDeleteCategory: _deleteCategory,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
      floatingActionButton: isEditMode
          ? null
          : Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: ResponsiveUtils.getButtonHeight(context) + 10,
                  height: ResponsiveUtils.getButtonHeight(context) + 10,
                  child: FloatingActionButton(heroTag: 'search_fab', onPressed: _onSearchFabPressed, child: Icon(Icons.search, size: ResponsiveUtils.getIconSize(context, baseSize: 30))),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: ResponsiveUtils.getButtonHeight(context) + 25,
                  height: ResponsiveUtils.getButtonHeight(context) + 25,
                  child: FloatingActionButton(heroTag: 'add_fab', onPressed: () => _onFabPressed(context), child: Icon(Icons.add, size: ResponsiveUtils.getIconSize(context, baseSize: 35))),
                ),
              ],
            ),
      bottomNavigationBar: isEditMode ? _buildEditModeActions(selectedPeople.length) : null,
    );
  }

  Widget _buildEditModeActions(int selectedCount) {
    final localizations = AppLocalizations.of(context);
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
            style: TextButton.styleFrom(foregroundColor: hasSelection ? Colors.red : Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _FilterSection extends ConsumerStatefulWidget {
  const _FilterSection();
  @override
  ConsumerState<_FilterSection> createState() => _FilterSectionState();
}

class _FilterSectionState extends ConsumerState<_FilterSection> {
  final _searchController = TextEditingController();
  final _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref.read(dailySearchProvider.notifier).state = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final body = ResponsiveUtils.getBodyFontSize(context);
    final selectedCat = ref.watch(dailyCategoryFilterProvider);

    // Clear external UI if providers get cleared
    if (ref.watch(dailySearchProvider).isEmpty && _searchController.text.isNotEmpty) _searchController.clear();
    if (selectedCat == null && _categoryController.text.isNotEmpty) _categoryController.clear();

    return Padding(
      padding: ResponsiveUtils.getListPadding(context),
      child: ExpansionTile(
        leading: const Icon(Icons.filter_list),
        title: Text(localizations.filterOptions, style: TextStyle(fontSize: ResponsiveUtils.getTitleFontSize(context), fontWeight: FontWeight.w600)),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
        childrenPadding: ResponsiveUtils.getListPadding(context),
        children: [
          TextField(
            controller: _searchController,
            style: TextStyle(fontSize: body + 2),
            decoration: InputDecoration(
              labelText: localizations.searchByName,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: ResponsiveUtils.getCardBorderRadius(context)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchController.clear())
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          DropdownMenu<CategoryItem?>(
            controller: _categoryController,
            expandedInsets: EdgeInsets.zero, 
            textStyle: TextStyle(fontSize: body + 2), 
            enableFilter: true,
            label: Text(
              localizations.filterByCategory, 
              style: TextStyle(fontSize: body),
            ),
            onSelected: (item) => ref.read(dailyCategoryFilterProvider.notifier).state = item?.category.name,
            dropdownMenuEntries: getCategoryItems(context).map((item) => DropdownMenuEntry(
              value: item, 
              label: item.label, 
              leadingIcon: item.icon != null ? Icon(item.icon) : null,
              style: MenuItemButton.styleFrom(
                textStyle: TextStyle(fontSize: body + 2),
              ),
            )).toList(),
            trailingIcon: selectedCat != null
                ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                    _categoryController.clear();
                    ref.read(dailyCategoryFilterProvider.notifier).state = null;
                  })
                : null,
          ),
        ],
      ),
    );
  }
}

class _PersonList extends StatelessWidget {
  final List<PersonWithCategories> people;
  final bool isEditMode;
  final Set<PersonWithCategories> selectedPeople;
  final Function(PersonWithCategories) onToggleSelection;
  final Function(PersonWithCategories) onAddCategory;
  final Function(CategoryRecord) onEditCategory;
  final Function(CategoryRecord) onDeleteCategory;

  const _PersonList({
    required this.people,
    required this.isEditMode,
    required this.selectedPeople,
    required this.onToggleSelection,
    required this.onAddCategory,
    required this.onEditCategory,
    required this.onDeleteCategory,
  });

  @override
  Widget build(BuildContext context) {
    if (people.isEmpty) return Center(child: Text(AppLocalizations.of(context).noEntriesForThisDay, style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context))));

    return ListView.builder(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.getButtonHeight(context) + 60),
      itemCount: people.length,
      itemBuilder: (context, index) {
        final person = people[index];
        final isSelected = selectedPeople.contains(person);

        return Card(
          color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : null,
          shape: RoundedRectangleBorder(
            side: isSelected ? BorderSide(color: Theme.of(context).primaryColor, width: 2) : BorderSide.none,
            borderRadius: ResponsiveUtils.getCardBorderRadius(context),
          ),
          child: InkWell(
            onTap: isEditMode ? () => onToggleSelection(person) : null,
            child: Padding(
              padding: ResponsiveUtils.getContentPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(person.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: ResponsiveUtils.getTitleFontSize(context)))),
                      if (isEditMode) Checkbox(value: isSelected, onChanged: (_) => onToggleSelection(person)),
                    ],
                  ),
                  const Divider(),
                  ...person.records.map((record) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(localizedCategoryLabel(context, record.category)),
                    subtitle: record.comment != null ? Text(record.comment!) : null,
                    trailing: isEditMode ? null : PopupMenuButton<String>(
                      onSelected: (val) {
                        if (val == 'edit') onEditCategory(record);
                        if (val == 'delete') onDeleteCategory(record);
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(value: 'edit', child: Text(AppLocalizations.of(context).edit)),
                        PopupMenuItem(value: 'delete', child: Text(AppLocalizations.of(context).delete)),
                      ],
                    ),
                  )),
                  if (!isEditMode)
                    Center(child: IconButton(icon: const Icon(Icons.add_circle_outline), color: Theme.of(context).primaryColor, onPressed: () => onAddCategory(person))),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}