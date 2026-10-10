import 'package:attendly/data/database/app_database.dart';
import 'package:attendly/data/database/exceptions.dart' as custom_db_exceptions;
import 'package:attendly/features/directory/data/directory_repository.dart';
import 'package:attendly/features/directory/widgets/alphabet_index_bar.dart';
import 'package:attendly/features/directory/pages/add_person_page.dart';
import 'package:attendly/shared/dialogs/app_dialogs.dart';
import 'package:attendly/core/responsive/responsive.dart';
import 'package:attendly/data/database/database_provider.dart';
import 'package:attendly/features/directory/providers/directory_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:attendly/core/logging/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:attendly/features/directory/pages/edit_person_page.dart';
import 'package:attendly/features/directory/widgets/person_tile.dart';
import 'package:attendly/shared/widgets/refreshable_app_bar.dart';
import 'package:attendly/app/shell/app_navigation_drawer.dart';
import 'package:attendly/l10n/app_localizations.dart';
import 'package:anchored_list/anchored_list.dart';

class DirectoryTab extends ConsumerStatefulWidget {
  final Function(List<DirectoryPeopleData>)? onPersonsSelected;
  final bool isSelectionMode;
  final List<int>? initiallySelectedIds;
  final int? selectedTab;
  final void Function(int)? onTabChange;

  const DirectoryTab({
    super.key,
    this.onPersonsSelected,
    this.isSelectionMode = false,
    this.initiallySelectedIds,
    this.selectedTab,
    this.onTabChange,
  });

  @override
  ConsumerState<DirectoryTab> createState() => _DirectoryTabState();
}

class _DirectoryTabState extends ConsumerState<DirectoryTab> {
  final TextEditingController _searchController = TextEditingController();
  final AppDialogs _helper = AppDialogs();
  int _expandedIndex = -1;
  bool _isManualRefreshing = false;
  late final StateController<String> _searchQueryNotifier;
  final AnchoredListController _listController = AnchoredListController();

  // Store selected person IDs instead of indices
  final Set<int> _selectedPersonIds = {};

  @override
  void initState() {
    super.initState();

    _searchQueryNotifier = ref.read(directorySearchQueryProvider.notifier);

    if (widget.isSelectionMode && widget.initiallySelectedIds != null) {
      _selectedPersonIds.addAll(widget.initiallySelectedIds!);
    }

    if (widget.isSelectionMode) {
      _searchQueryNotifier.state = '';
    }

    _searchController.text = ref.read(directorySearchQueryProvider);
    _searchController.addListener(() {
      _searchQueryNotifier.state = _searchController.text;
    });
    if (_expandedIndex != -1) setState(() => _expandedIndex = -1);
  }

  @override
  void dispose() {
    _searchQueryNotifier.state = '';
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onFabPressed() async {
    try {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => AddPersonPage(),
      ));
    } catch (e, stackTrace) {
      _helper.showErrorMessage(context,
          'An error occurred while adding a person.\n${e.toString()}',
          stackTrace: stackTrace);
    }
  }


  Future<void> _deletePerson(DirectoryPeopleData person) async {
    if (!mounted) return;
    final localizations = AppLocalizations.of(context);
    final id = person.id;
    final name = person.name;

    final repo = ref.read(directoryRepositoryProvider);
    final count = await repo.getEntryCountForPerson(id);

    final shouldDelete = await _helper.displayDialog(
      context,
      localizations.deletePersonTitle(name),
      '${localizations.areYouSureYouWantToDelete}\n\n${localizations.personHasNRecords(count)}',
      localizations,
    );

    if (shouldDelete != true) return;

    try {
      _helper.showLoadingDialog(context, localizations.delete);
      await repo.deletePerson(id);

      if (mounted) {
        _helper.hideLoadingDialog(context);
        await _helper.showSubmitMessage(
            context, localizations.personDeletedFromDb(name, id));
      }
    } on custom_db_exceptions.DatabaseException catch (e) {
      if (mounted) _helper.hideLoadingDialog(context);
      String msg = e.toString();
      if (e is custom_db_exceptions.DatabaseOperationException) {
        msg = localizations.unexpectedErrorContactCreator;
        AppLogger.e("Directory", "Database operation failed", e, e.stackTrace);
      }
      _helper.showErrorMessage(context, msg);
    } catch (e, stackTrace) {
      if (mounted) _helper.hideLoadingDialog(context);
      _helper.showErrorMessage(context, e.toString(), stackTrace: stackTrace);
    }
  }

  Future<void> _editPerson(DirectoryPeopleData person) async {
    try {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => EditPersonPage(
            personToUpdate: person),
      ));
      // Stream auto-updates after the repo write inside EditPersonPage.
    } catch (e, stackTrace) {
      _helper.showErrorMessage(
          context, 'Failed to update person: ${e.toString()}',
          stackTrace: stackTrace);
    }
  }

  void _toggleSort() {
    ref.read(directorySortAscendingProvider.notifier).update((s) => !s);
    setState(() => _expandedIndex = -1);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isTablet = Responsive.of(context).isTablet;
    final iconSize = Responsive.of(context).iconSize();

    final isAscending = ref.watch(directorySortAscendingProvider);
    final asyncPeople = ref.watch(filteredDirectoryProvider);

    if (widget.isSelectionMode) {
      return Scaffold(
        appBar: AppBar(
          title: Text(localizations.selectAPerson,
              style: TextStyle(
                  fontSize: Responsive.of(context).titleFontSize,
                  fontWeight: FontWeight.bold)),
          leading: IconButton(
              icon: Icon(Icons.arrow_back, size: iconSize),
              onPressed: () => Navigator.pop(context)),
        ),
        body: _buildBody(context, localizations, isTablet, asyncPeople),
        floatingActionButton:
            _selectedPersonIds.isNotEmpty && widget.onPersonsSelected != null
                ? FloatingActionButton.extended(
                      onPressed: () {
                      // Use the full unfiltered list, not the search-filtered one
                      final allPeople = ref.read(directoryStreamProvider).valueOrNull ?? [];
                      final selected = allPeople
                          .where((p) => _selectedPersonIds.contains(p.id))
                          .toList();
                      widget.onPersonsSelected!(selected);
                    },
                    label: Text(
                        localizations
                            .confirmSelection(_selectedPersonIds.length),
                        style: TextStyle(fontSize: isTablet ? 18 : 14)),
                    icon: Icon(Icons.check, size: isTablet ? 28 : 24),
                  )
                : null,
      );
    }

    return Scaffold(
      drawer: Responsive.of(context).isTablet 
          ? null
          : AppNavigationDrawer(
              selectedTab: widget.selectedTab!,
              onTabChange: widget.onTabChange!,
            ),
      appBar: RefreshableAppBar(
        title: localizations.directory,
        showRefresh: true,
        isLoading: asyncPeople.isLoading || 
                   asyncPeople.isRefreshing || 
                   asyncPeople.isReloading || 
                   _isManualRefreshing,
        onRefresh: () async {
          setState(() => _isManualRefreshing = true);
          
          AppLogger.d("Directory", "Invalidating dir stream");
          ref.invalidate(directoryStreamProvider);
          
          await Future.delayed(const Duration(milliseconds: 400));
          if (mounted) setState(() => _isManualRefreshing = false);
        },
        leading: Responsive.of(context).isTablet
            ? null
            : Builder(
                builder: (context) => IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  // Bigger drawer icon
                  icon: Icon(Icons.menu, size: Responsive.of(context).iconSize(baseSize: 35)),
                ),
              ),
        actions: [
           IconButton(
            icon: FaIcon(
              isAscending
                ? FontAwesomeIcons.arrowDownZA
                : FontAwesomeIcons.arrowDownAZ),
            onPressed: _toggleSort,
          ),
        ],
      ),
      body: _buildBody(context, localizations, isTablet, asyncPeople),
      floatingActionButton: SizedBox(
          width: Responsive.of(context).buttonHeight + 25,
          height: Responsive.of(context).buttonHeight + 25,
          child: FloatingActionButton(
              onPressed: () => _onFabPressed(),
              child: Icon(Icons.add, size: Responsive.of(context).iconSize(baseSize: 35))
          )
        ),
    );
  }

  Widget _buildBody(BuildContext context,
    AppLocalizations localizations,
    bool isTablet,
    AsyncValue<List<DirectoryPeopleData>> asyncPeople,
  ) {
    return Column (
      children: [
        _SearchField(
          controller: _searchController,
          onClear: () {
            _searchController.clear();
            ref.read(directorySearchQueryProvider.notifier).state = '';
          },
        ),
        Expanded (
          child: asyncPeople.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) {
              if (e is custom_db_exceptions.DatabaseNotReadyException) {
                return const Center(child: CircularProgressIndicator());
              }
              
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) ref.read(databaseProvider.notifier).reportDatabaseError(e);
              });
              return const Center(child: CircularProgressIndicator());
            },
            data: (people) {
              if (people.isEmpty) {
                return Center(
                  child: Text(localizations.noPersonFound,
                      style: TextStyle(
                          fontSize: Responsive.of(context).bodyFontSize,
                          fontWeight: FontWeight.bold)),
                );
              }
              // First-letter -> index map, built from the list in its current
              // (ascending or descending) order, so the jump target is always
              // correct regardless of sort direction.
              final letterIndexMap = buildLetterIndexMap<DirectoryPeopleData>(
                people,
                (p) => p.name,
              );

              return Stack(
              children: [
                Positioned.fill(
                  child: _PersonListView(
                    people: people,
                    isSelectionMode: widget.isSelectionMode,
                    selectedPersonIds: _selectedPersonIds,
                    expandedIndex: _expandedIndex,
                    listController: _listController,
                    onPersonTap: (person) {
                      if (widget.isSelectionMode) {
                        setState(() {
                          final id = person.id;
                          if (_selectedPersonIds.contains(id)) {
                            _selectedPersonIds.remove(id);
                          } else {
                            _selectedPersonIds.add(id);
                          }
                        });
                      }
                    },
                    onExpansionChanged: (index, expanded) {
                      setState(() => _expandedIndex = expanded ? index : -1);
                    },
                    onDeletePress: (person) => _deletePerson(person),
                    onEditPress: (person) => _editPerson(person),
                    buildPersonDetails: (person) => _helper.buildPersonDetails(
                        people, people.indexOf(person), localizations, context),
                    repo: ref.read(directoryRepositoryProvider),
                    helper: _helper,
                  ),
                ),
                if (people.length > 1)
                  Positioned(
                    // Kept slightly away from the screen edge so Android's
                    // back gesture does not steal touches on the bar.
                    right: 10,
                    top: 8,
                    bottom: Responsive.of(context).buttonHeight + 48 + MediaQuery.of(context).padding.bottom,
                    child: AlphabetIndexBar(
                        availableLetters: letterIndexMap.keys.toSet(),
                        onLetterSelected: (letter, {required bool isDragging}) {
                          final index = letterIndexMap[letter];
                          if (index == null) return;
                          if (_expandedIndex == -1) {
                            _listController.jumpToIndex(index, alignment: 0.0);
                            return;
                          }

                          // Collapse the open card first, then jump once the
                          // list has been rebuilt without it.
                          setState(() => _expandedIndex = -1);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            _listController.jumpToIndex(index, alignment: 0.0);
                          });
                        }
                    ),
                  ),
              ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Padding(
      padding: Responsive.of(context).listPadding,
      child: TextField(
        controller: controller,
        style: TextStyle(fontSize: Responsive.of(context).bodyFontSize),
        decoration: InputDecoration(
          labelText: localizations.searchForName,
          labelStyle:
              TextStyle(fontSize: Responsive.of(context).bodyFontSize),
          contentPadding: Responsive.of(context).contentPadding,
          border: OutlineInputBorder(
              borderRadius: Responsive.of(context).cardBorderRadius),
          suffixIcon: IconButton(
            icon: Icon(Icons.cancel,
                size: Responsive.of(context).iconSize()),
            onPressed: onClear,
          ),
        ),
      ),
    );
  }
}

class _PersonListView extends StatelessWidget {
  final List<DirectoryPeopleData> people;
  final bool isSelectionMode;
  final Set<int> selectedPersonIds;
  final int expandedIndex;
  final Function(DirectoryPeopleData) onPersonTap;
  final Function(int, bool) onExpansionChanged;
  final Function(DirectoryPeopleData) onDeletePress;
  final Function(DirectoryPeopleData) onEditPress;
  final List<Widget> Function(DirectoryPeopleData) buildPersonDetails;
  final DirectoryRepository? repo;
  final AppDialogs helper;
  final AnchoredListController listController;

  const _PersonListView({
    required this.people,
    required this.isSelectionMode,
    required this.selectedPersonIds,
    required this.expandedIndex,
    required this.onPersonTap,
    required this.onExpansionChanged,
    required this.onDeletePress,
    required this.onEditPress,
    required this.buildPersonDetails,
    required this.repo,
    required this.helper,
    required this.listController,
  });

  @override
  Widget build(BuildContext context) {
    return AnchoredList.builder(
      controller: listController,
      itemCount: people.length,
      addRepaintBoundaries: true,
      addAutomaticKeepAlives: false,
      padding: EdgeInsets.only(
        left: Responsive.of(context).listPadding.left,
        // A bit of extra right padding so rows don't sit under the
        // alphabet index bar overlaid on top of the list.
        right: Responsive.of(context).listPadding.right + 24 + 10,
        top: 0,
        bottom: Responsive.of(context).buttonHeight +
            40 +
            MediaQuery.of(context).padding.bottom,
      ),
      itemBuilder: (context, index) {
        final person = people[index];
        final isSelected =
            isSelectionMode && selectedPersonIds.contains(person.id);
        return PersonTile(
          allPeopleList: people,
          index: index,
          isExpanded: expandedIndex == index,
          isSelected: isSelected,
          isSelectionMode: isSelectionMode,
          onExpansionChanged: (expanded) => onExpansionChanged(index, expanded),
          onTap: () => onPersonTap(person),
          onDeletePress: () => onDeletePress(person),
          onEditPress: () => onEditPress(person),
          buildChildren: buildPersonDetails(person),
        );
      },
    );
  }
}