import 'package:attendly/core/responsive/responsive.dart';
import 'package:attendly/data/database/database_provider.dart';
import 'package:attendly/data/database/exceptions.dart' as custom_db_exceptions;
import 'package:attendly/features/daily_log/models/category_record.dart';
import 'package:attendly/features/daily_log/models/person_with_categories.dart';
import 'package:attendly/features/daily_log/pages/add_daily_entry_page.dart';
import 'package:attendly/features/daily_log/pages/edit_daily_entry_page.dart';
import 'package:attendly/features/daily_log/providers/daily_log_providers.dart';
import 'package:attendly/l10n/app_localizations.dart';
import 'package:attendly/shared/dialogs/app_dialogs.dart';
import 'package:attendly/shared/navigation/app_routes.dart';
import 'package:attendly/shared/options/category_label.dart';
import 'package:attendly/shared/options/category_option.dart';
import 'package:attendly/shared/shell/shell_tab.dart';
import 'package:attendly/shared/widgets/tab_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Daily attendance: entries of one day, grouped by person, with an edit
/// mode for bulk actions.
class DailyLogTab extends ShellTab {
  const DailyLogTab();

  static void _toggleEditMode(WidgetRef ref) {
    final isEditing = ref.read(dailyEditModeProvider);
    ref.read(dailyEditModeProvider.notifier).state = !isEditing;
    if (isEditing) {
      ref.read(dailySelectedPeopleProvider.notifier).state = {};
    }
  }

  static void _selectAll(WidgetRef ref, List<PersonWithCategories> visiblePeople) {
    final currentSet = ref.read(dailySelectedPeopleProvider);
    if (currentSet.length == visiblePeople.length) {
      ref.read(dailySelectedPeopleProvider.notifier).state = {};
    } else {
      ref.read(dailySelectedPeopleProvider.notifier).state = Set.from(visiblePeople);
    }
  }

  @override
  PreferredSizeWidget buildAppBar(BuildContext context, WidgetRef ref) {
    final asyncFilteredData = ref.watch(dailyFilteredLogsProvider);
    final isEditMode = ref.watch(dailyEditModeProvider);
    final responsive = Responsive.of(context);

    // Grab the list if available to check lengths
    final visiblePeople = asyncFilteredData.valueOrNull ?? [];

    return TabAppBar(
      title: AppLocalizations.of(context).dailyLogs,
      leading:
          isEditMode
              ? IconButton(
                icon: Icon(Icons.close, size: responsive.iconSize()),
                onPressed: () => _toggleEditMode(ref),
              )
              : DrawerMenuButton.forShell(context),
      actions: [
        if (!isEditMode)
          IconButton(
            icon: Icon(Icons.edit, size: responsive.iconSize(baseSize: 30)),
            onPressed: visiblePeople.isEmpty ? null : () => _toggleEditMode(ref),
          ),
        if (isEditMode)
          IconButton(
            icon: Icon(
              Icons.select_all,
              size: responsive.iconSize(baseSize: 28),
            ),
            onPressed: visiblePeople.isEmpty ? null : () => _selectAll(ref, visiblePeople),
          ),
      ],
    );
  }

  @override
  Widget buildBody(BuildContext context, WidgetRef ref) => const _DailyLogBody();

  @override
  Widget? buildFab(BuildContext context, WidgetRef ref) {
    if (ref.watch(dailyEditModeProvider)) return null;
    final responsive = Responsive.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: responsive.buttonHeight + 10,
          height: responsive.buttonHeight + 10,
          child: FloatingActionButton(
            heroTag: 'search_fab',
            onPressed: () => _openSearch(context, ref),
            child: Icon(
              Icons.search,
              size: responsive.iconSize(baseSize: 30),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: responsive.buttonHeight + 25,
          height: responsive.buttonHeight + 25,
          child: FloatingActionButton(
            heroTag: 'add_fab',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AddDailyEntryPage(initialDate: ref.read(dailyDateProvider)),
              ),
            ),
            child: Icon(
              Icons.add,
              size: responsive.iconSize(baseSize: 35),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget? buildBottomBar(BuildContext context, WidgetRef ref) {
    return ref.watch(dailyEditModeProvider) ? const _EditModeActions() : null;
  }

  Future<void> _openSearch(BuildContext context, WidgetRef ref) async {
    final selectedDate = await Navigator.of(context).pushNamed<DateTime>(AppRoutes.dailyLogSearch);
    if (selectedDate != null && context.mounted) {
      ref.read(dailyDateProvider.notifier).state = selectedDate;
    }
  }
}

class _DailyLogBody extends ConsumerStatefulWidget {
  const _DailyLogBody();

  @override
  ConsumerState<_DailyLogBody> createState() => _DailyLogBodyState();
}

class _DailyLogBodyState extends ConsumerState<_DailyLogBody> {

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

  Future<void> _selectDate() async {
    final currentDate = ref.read(dailyDateProvider);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      keyboardType: const TextInputType.numberWithOptions(),
    );

    if (picked != null && picked != currentDate && mounted) {
      ref.read(dailyDateProvider.notifier).state = picked;
      if (ref.read(dailyEditModeProvider)) DailyLogTab._toggleEditMode(ref);
    }
  }

  Future<void> _deleteCategory(CategoryRecord record) async {
    final localizations = AppLocalizations.of(context);
    final repo = ref.read(dailyRepositoryProvider);

    final confirm = await AppDialogs.confirm(
      context,
      title: localizations.deleteRecord,
      message: localizations.confirmDeleteCategory(
        localizedCategoryLabel(context, record.category),
        record.personName ?? localizations.unknown,
        record.date,
      ),
    );

    if (confirm && mounted) {
      try {
        AppDialogs.showLoading(context, localizations.delete);
        await repo.deleteDailyEntry(record.recordId, record.personId, DateTime.parse(record.date));
        if (mounted) {
          AppDialogs.hideLoading(context);
          await AppDialogs.showSuccess(context, localizations.recordDeleted);
        }
      } catch (e) {
        if (!mounted) return;
        AppDialogs.hideLoading(context);
        AppDialogs.showError(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = Responsive.of(context);

    // Watch state
    final asyncFilteredData = ref.watch(dailyFilteredLogsProvider);
    final selectedDate = ref.watch(dailyDateProvider);
    final isEditMode = ref.watch(dailyEditModeProvider);
    final selectedPeople = ref.watch(dailySelectedPeopleProvider);

    ref.listen<AsyncValue<List<PersonWithCategories>?>>(dailyRawLogsProvider, (prev, next) {
      if (next is AsyncError) {
        final error = next.error;
        if (error != null && error is! custom_db_exceptions.DatabaseNotReadyException) {
          ref.read(databaseProvider.notifier).reportDatabaseError(error);
        }
      }
    });

    final now = DateTime.now();
    final todayDateOnly = DateTime(now.year, now.month, now.day);
    final selectedDateOnly = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final isTodayOrFuture = !selectedDateOnly.isBefore(todayDateOnly);
    final arrowIconSize = responsive.iconSize(baseSize: 30);

    return Center(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.listPadding.horizontal,
              vertical: responsive.listPadding.vertical,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed:
                      () =>
                          ref.read(dailyDateProvider.notifier).state = selectedDate.subtract(
                            const Duration(days: 1),
                          ),
                  icon: Icon(Icons.arrow_back_ios_sharp, color: theme.iconTheme.color),
                  iconSize: arrowIconSize,
                ),
                GestureDetector(
                  onTap: _selectDate,
                  child: Text(
                    "${selectedDate.day}.${selectedDate.month}.${selectedDate.year}",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: responsive.titleFontSize,
                    ),
                  ),
                ),
                IconButton(
                  onPressed:
                      isTodayOrFuture
                          ? null
                          : () =>
                              ref.read(dailyDateProvider.notifier).state = selectedDate.add(
                                const Duration(days: 1),
                              ),
                  icon: Icon(
                    Icons.arrow_forward_ios_sharp,
                    color: isTodayOrFuture ? theme.disabledColor : theme.iconTheme.color,
                  ),
                  iconSize: arrowIconSize,
                ),
              ],
            ),
          ),
          const _FilterSection(),
          Expanded(
            child: asyncFilteredData.when(
              skipLoadingOnReload: true,
              loading: () => const Center(child: CircularProgressIndicator()),
              // Errors are reported to the startup gate by the listener above.
              error: (error, stacktrace) => const Center(child: CircularProgressIndicator()),
              data:
                  (people) => _PersonList(
                    people: people,
                    isEditMode: isEditMode,
                    selectedPeople: selectedPeople,
                    onToggleSelection: _toggleSelection,
                    onAddCategory: (person) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (ctx) => AddDailyEntryPage(
                                initialDate: selectedDate,
                                preselectedPersons: [
                                  {'id': person.personId, 'name': person.name},
                                ],
                              ),
                        ),
                      );
                    },
                    onEditCategory: (record) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => EditDailyEntryPage(record: record),
                        ),
                      );
                    },
                    onDeleteCategory: _deleteCategory,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom bar in edit mode: add a category to, or delete the entries of, the
/// selected people.
class _EditModeActions extends ConsumerStatefulWidget {
  const _EditModeActions();

  @override
  ConsumerState<_EditModeActions> createState() => _EditModeActionsState();
}

class _EditModeActionsState extends ConsumerState<_EditModeActions> {

  Future<void> _onBulkAddCategory() async {
    final selectedSet = ref.read(dailySelectedPeopleProvider);
    final date = ref.read(dailyDateProvider);
    final selectedList = selectedSet.map((p) => {'id': p.personId, 'name': p.name}).toList();

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder:
            (context) => AddDailyEntryPage(
              initialDate: date,
              preselectedPersons: selectedList,
            ),
      ),
    );

    if (result == true && mounted) {
      DailyLogTab._toggleEditMode(ref);
    }
  }

  Future<void> _onBulkDelete() async {
    final localizations = AppLocalizations.of(context);
    final selectedSet = ref.read(dailySelectedPeopleProvider);
    final count = selectedSet.length;
    final date = ref.read(dailyDateProvider);
    final repo = ref.read(dailyRepositoryProvider);

    final confirm = await AppDialogs.confirm(
      context,
      title: localizations.delete,
      message: localizations.confirmBulkDelete(count),
    );
    if (!confirm || !mounted) return;

    try {
      AppDialogs.showLoading(context, localizations.delete);
      final personIds = selectedSet.map((p) => p.personId).toList();
      await repo.bulkDeleteEntries(personIds, date);
      if (!mounted) return;
      AppDialogs.hideLoading(context);
      await AppDialogs.showSuccess(context, localizations.peopleEntriesDeleted(count));
      if (mounted) DailyLogTab._toggleEditMode(ref);
    } catch (e, stackTrace) {
      if (!mounted) return;
      AppDialogs.hideLoading(context);
      AppDialogs.showError(context, 'Failed to delete entries: $e', stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final responsive = Responsive.of(context);
    final selectedCount = ref.watch(dailySelectedPeopleProvider).length;
    final hasSelection = selectedCount > 0;

    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          TextButton.icon(
            icon: Icon(Icons.add_task, size: responsive.iconSize()),
            label: Text(
              localizations.addCategory,
              style: TextStyle(fontSize: responsive.smallFontSize),
            ),
            onPressed: hasSelection ? _onBulkAddCategory : null,
          ),
          TextButton.icon(
            icon: Icon(Icons.delete_sweep, size: responsive.iconSize()),
            label: Text(
              '${localizations.delete} ($selectedCount)',
              style: TextStyle(fontSize: responsive.smallFontSize),
            ),
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
    final body = Responsive.of(context).bodyFontSize;
    final selectedCat = ref.watch(dailyCategoryFilterProvider);

    // Sync controllers when providers are externally reset (e.g. on date change).
    // ref.listen callbacks fire after build — safe to mutate controller state here.
    ref.listen<String>(dailySearchProvider, (_, next) {
      if (next.isEmpty && _searchController.text.isNotEmpty) _searchController.clear();
    });
    ref.listen<String?>(dailyCategoryFilterProvider, (_, next) {
      if (next == null && _categoryController.text.isNotEmpty) _categoryController.clear();
    });

    return Padding(
      padding: Responsive.of(context).listPadding,
      child: ExpansionTile(
        leading: const Icon(Icons.filter_list),
        title: Text(
          localizations.filterOptions,
          style: TextStyle(
            fontSize: Responsive.of(context).titleFontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
        childrenPadding: Responsive.of(context).listPadding,
        children: [
          TextField(
            controller: _searchController,
            style: TextStyle(fontSize: body + 2),
            decoration: InputDecoration(
              labelText: localizations.searchByName,
              labelStyle: TextStyle(fontSize: body + 2, color: Theme.of(context).primaryColor),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: Responsive.of(context).cardBorderRadius,
              ),
              suffixIcon:
                  _searchController.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                      : null,
            ),
          ),
          const SizedBox(height: 12),
          DropdownMenu<CategoryOption?>(
            controller: _categoryController,
            expandedInsets: EdgeInsets.zero,
            textStyle: TextStyle(fontSize: body + 2),
            enableFilter: true,
            label: Text(localizations.filterByCategory, style: TextStyle(fontSize: body)),
            onSelected:
                (item) =>
                    ref.read(dailyCategoryFilterProvider.notifier).state = item?.category.name,
            dropdownMenuEntries:
                getCategoryOptions(context)
                    .map(
                      (item) => DropdownMenuEntry(
                        value: item,
                        label: item.label,
                        leadingIcon: item.icon != null ? Icon(item.icon) : null,
                        style: MenuItemButton.styleFrom(textStyle: TextStyle(fontSize: body + 2)),
                      ),
                    )
                    .toList(),
            trailingIcon:
                selectedCat != null
                    ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _categoryController.clear();
                        ref.read(dailyCategoryFilterProvider.notifier).state = null;
                      },
                    )
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
    if (people.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).noEntriesForThisDay,
          style: TextStyle(fontSize: Responsive.of(context).bodyFontSize),
        ),
      );
    }

    final bodyFontSize = Responsive.of(context).bodyFontSize;
    final iconSize = Responsive.of(context).iconSize();

    return ListView.builder(
      padding: EdgeInsets.only(bottom: Responsive.of(context).buttonHeight + 60),
      itemCount: people.length,
      itemBuilder: (context, index) {
        final person = people[index];
        final isSelected = selectedPeople.contains(person);

        return Card(
          color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : null,
          shape: RoundedRectangleBorder(
            side:
                isSelected
                    ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
                    : BorderSide.none,
            borderRadius: Responsive.of(context).cardBorderRadius,
          ),
          child: InkWell(
            onTap: isEditMode ? () => onToggleSelection(person) : null,
            child: Padding(
              padding: Responsive.of(context).contentPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          person.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: Responsive.of(context).titleFontSize,
                          ),
                        ),
                      ),
                      if (isEditMode)
                        Checkbox(value: isSelected, onChanged: (_) => onToggleSelection(person)),
                    ],
                  ),
                  const Divider(),
                  ...person.records.map(
                    (record) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        localizedCategoryLabel(context, record.category),
                        style: TextStyle(fontSize: bodyFontSize),
                      ),
                      subtitle:
                          record.comment != null
                              ? Text(record.comment!, style: TextStyle(fontSize: bodyFontSize - 2))
                              : null,
                      trailing:
                          isEditMode
                              ? null
                              : PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert, size: iconSize),
                                onSelected: (val) {
                                  if (val == 'edit') onEditCategory(record);
                                  if (val == 'delete') onDeleteCategory(record);
                                },
                                itemBuilder:
                                    (ctx) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text(
                                          AppLocalizations.of(context).edit,
                                          style: TextStyle(fontSize: bodyFontSize),
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text(
                                          AppLocalizations.of(context).delete,
                                          style: TextStyle(fontSize: bodyFontSize),
                                        ),
                                      ),
                                    ],
                              ),
                    ),
                  ),
                  if (!isEditMode)
                    Center(
                      child: IconButton(
                        icon: Icon(
                          Icons.add_circle_outline,
                          size: Responsive.of(context).iconSize(baseSize: 32),
                        ),
                        color: Theme.of(context).primaryColor,
                        onPressed: () => onAddCategory(person),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
