import 'package:attendly/backend/db_exceptions.dart' as custom_db_exceptions;
import 'package:attendly/backend/db_connection_validator.dart';
import 'package:attendly/frontend/pages/directory_pages/dir_add_page.dart';
import 'package:attendly/frontend/pages/directory_pages/message_helper.dart';
import 'package:attendly/frontend/utils/responsive_utils.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import 'package:attendly/backend/dbLogic/db_read.dart';
import 'package:attendly/backend/dbLogic/db_delete.dart';
import 'package:attendly/backend/dbLogic/db_insert.dart';
import 'package:attendly/backend/dbLogic/db_update.dart';
import 'package:attendly/frontend/pages/directory_pages/dir_edit_page.dart';
import 'package:attendly/frontend/pages/directory_pages/state_manager_dir_page.dart';
import 'package:attendly/frontend/widgets/custom_expansion_widget.dart';
import 'package:attendly/frontend/widgets/refreshable_app_bar.dart';
import 'package:attendly/frontend/widgets/custom_drawer.dart';
import 'package:attendly/localization/app_localizations.dart';

class DirectoryPage extends StatefulWidget {
  final Database dbCon;
  final Function(List<Map<String, dynamic>>)? onPersonsSelected;
  final bool isSelectionMode;
  final List<Map<String, dynamic>>? initiallySelectedPersons;
  final int? selectedTab;
  final void Function(int)? onTabChange;
  final bool isTablet;

  const DirectoryPage({
    super.key,
    required this.dbCon,
    this.onPersonsSelected,
    this.isSelectionMode = false,
    this.initiallySelectedPersons,
    this.selectedTab,
    this.onTabChange,
    this.isTablet = false,
  });

  @override
  State<StatefulWidget> createState() => _DirectoryPageState();
}

class _DirectoryPageState extends State<DirectoryPage> {
  final TextEditingController _searchController = TextEditingController();
  late DbSelection reader;
  late DbDeletion deleter;
  late DbInsertion inserter;
  late DbUpdater updater;
  late HelperAllPerson helper;
  int _expandedIndex = -1;
  bool _isLoading = false;
  // Store selected person IDs instead of indices
  final Set<int> _selectedPersonIds = {};

  // This list holds the filtered results and is the only part that changes during search
  List<Map<String, dynamic>> _searchResult = [];
  bool get isLoading => _isLoading;
  bool _isAscending = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    reader = DbSelection(widget.dbCon);
    updater = DbUpdater(widget.dbCon, reader);
    inserter = DbInsertion(widget.dbCon, reader, updater);
    deleter = DbDeletion(widget.dbCon, reader, inserter, updater);
    helper = HelperAllPerson();
    _populateList().then((_) {
      // After list is populated, initialize selection if needed
      if (widget.isSelectionMode && widget.initiallySelectedPersons != null) {
        for (var person in widget.initiallySelectedPersons!) {
          // Add the ID to the set of selected IDs
          _selectedPersonIds.add(person['id']);
        }
        setState(() {});
      }
    });
  }

  Future<void> _onFabPressed(BuildContext context) async {
    try {
      bool? res = await Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => AddPage(
            database: widget.dbCon,
            isTablet: widget.isTablet,
          )));

      if (res == true) {
        await updateChildrenList();
      }
    } on custom_db_exceptions.DbConnectionException catch (e) {
      debugPrint('Database connection error: $e');
      if (mounted) {
        await DbConnectionValidator.handleConnectionError(context);
      }
    } catch (e, stackTrace) {
      debugPrint('Error in add page navigation: $e');
      helper.showErrorMessage(
          context, 'An error occurred while adding a person. \n ${e.toString()}',
          stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isTablet = widget.isTablet || ResponsiveUtils.isTablet(context);
    final iconSize = ResponsiveUtils.getIconSize(context);

    if (widget.isSelectionMode) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            localizations.selectAPerson,
            style: TextStyle(
              fontSize: ResponsiveUtils.getTitleFontSize(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, size: iconSize),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: pageBody(context, localizations, isTablet),
        floatingActionButton: widget.isSelectionMode &&
                _selectedPersonIds.isNotEmpty &&
                widget.onPersonsSelected != null
            ? FloatingActionButton.extended(
                onPressed: () {
                  final allChildren = StateManager.getChildrenList();
                  final selectedPersonsData = allChildren
                      .where((person) => _selectedPersonIds.contains(person['id']))
                      .toList();
                  widget.onPersonsSelected!(selectedPersonsData);
                },
                label: Text(
                  localizations.confirmSelection(_selectedPersonIds.length),
                  style: TextStyle(fontSize: isTablet ? 18 : 14),
                ),
                icon: Icon(Icons.check, size: isTablet ? 28 : 24),
              )
            : null,
      );
    }

    return Scaffold(
      drawer: widget.isTablet 
          ? null
          : CustomDrawer(
              selectedTab: widget.selectedTab!,
              onTabChange: widget.onTabChange!,
            ),
      appBar: RefreshableAppBar(
        title: localizations.directory,
        onRefresh: updateChildrenList,
        isLoading: _isLoading,
        showRefresh: true,
        isTablet: isTablet,
        leading: widget.isTablet
            ? null
            : Builder(
                builder: (context) => IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  // Bigger drawer icon
                  icon: Icon(Icons.menu, size: ResponsiveUtils.getIconSize(context, baseSize: 35)),
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(_isAscending ? FontAwesomeIcons.arrowDownZA : FontAwesomeIcons.arrowDownAZ),
            onPressed: _toggleSort,
            //tooltip: "Sort Alphabetically",
          ),
        ],
      ),
      body: pageBody(context, localizations, isTablet),
      floatingActionButton: SizedBox(
          width: ResponsiveUtils.getButtonHeight(context) + 25,
          height: ResponsiveUtils.getButtonHeight(context) + 25,
          child: FloatingActionButton(
              onPressed: () => _onFabPressed(context),
              child: Icon(Icons.add, size: ResponsiveUtils.getIconSize(context, baseSize: 35))
          )
        ),
    );
  }

  Widget pageBody(BuildContext context, AppLocalizations localizations, bool isTablet){
    return Column(
      children: [
        // NEW: Self-contained search field widget
        _SearchField(
          controller: _searchController,
          onChanged: _runSearchFilter,
          onClear: () {
            _searchController.clear();
            _runSearchFilter('');
          },
          isTablet: isTablet,
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _searchResult.isEmpty
                  ? Center(
                      child: Text(
                        localizations.noPersonFound,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getBodyFontSize(context),
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    )
                  // NEW: Self-contained list view widget
                  : _PersonListView(
                      searchResult: _searchResult,
                      isSelectionMode: widget.isSelectionMode,
                      selectedPersonIds: _selectedPersonIds, // Pass the set of IDs
                      expandedIndex: _expandedIndex,
                      onPersonTap: (index) {
                        if (widget.isSelectionMode) {
                          setState(() {
                            final personId = _searchResult[index]['id'];
                            if (_selectedPersonIds.contains(personId)) {
                              _selectedPersonIds.remove(personId);
                            } else {
                              _selectedPersonIds.add(personId);
                            }
                          });
                        }
                      },
                      onExpansionChanged: (index, expanded) {
                        setState(() {
                          _expandedIndex = expanded ? index : -1;
                        });
                      },
                      onDeletePress: (index) async {
                        final person = _searchResult[index];
                        final personName = person['name'] as String;
                        final personId = person['id'] as int;

                        final dailyEntryCount = await reader.countDailyEntriesForPerson(personId);

                        final shouldDelete = await helper.displayDialog(
                            context,
                            localizations.deletePersonTitle(personName),
                            '${localizations.areYouSureYouWantToDelete}\n\n${localizations.personHasNRecords(dailyEntryCount)}',
                            localizations);

                        if (shouldDelete == true) {
                          await _deletePerson(index);
                        }
                      },
                      onEditPress: (index) async {
                        await _editPerson(index);
                      },
                      buildPersonDetails: (index) => helper.buildPersonDetails(
                          _searchResult, index, localizations, context),
                      isTablet: isTablet,
                    ),
        ),
      ],
    );
  }

  void _runSearchFilter(String enteredKeyWord) {
    List<Map<String, dynamic>> result = [];
    final allChildren = StateManager.getChildrenList();

    if (enteredKeyWord.isEmpty) {
      result = allChildren;
    } else {
      result = allChildren
          .where((person) =>
              person["name"].toLowerCase().contains(enteredKeyWord.toLowerCase()))
          .toList();
    }

    setState(() {
      _searchResult = result;
      _expandedIndex = -1;
    });
  }

  void _toggleSort() {
    setState(() {
      _isAscending = !_isAscending;
    });
    updateChildrenList();
  }

  Future<void> updateChildrenList() async {
    await _populateList(forceRefresh: true);
  }

  Future<void> _deletePerson(int index) async {
    if (!mounted) return;

    final localizations = AppLocalizations.of(context);
    int id = _searchResult[index]['id'];
    String personName = _searchResult[index]['name'];
    int originalIndex =
        StateManager.getChildrenList().indexWhere((person) => person['id'] == id);

    if (originalIndex == -1) return;

    try {
      helper.showLoadingDialog(context, localizations.delete);
      await deleter.deleteFromAllPeople(id);

      // If the deletion succeeds, update the UI
      StateManager.delteChildAtIndex(originalIndex);
      _runSearchFilter(_searchController.text);
      if (mounted) {
        helper.hideLoadingDialog(context);
        await helper.showSubmitMessage(
            context, localizations.personDeletedFromDb(personName, id));
      }
    } on custom_db_exceptions.DbConnectionException catch (e) {
      if (mounted) helper.hideLoadingDialog(context);
      debugPrint('Database connection error: $e');
      if (mounted) {
        await DbConnectionValidator.handleConnectionError(context);
      }
    } on custom_db_exceptions.DatabaseException catch (e) {
      if (mounted) helper.hideLoadingDialog(context);
      // Catch our custom database exceptions
      String errorMessage = e.toString();
      if (e is custom_db_exceptions.DatabaseOperationException) {
        // For unexpected errors, show a generic message and log the details.
        errorMessage = localizations.unexpectedErrorContactCreator;
        debugPrint(e.toString());
        if (e.stackTrace != null) {
          debugPrintStack(stackTrace: e.stackTrace);
        }
      }
      helper.showErrorMessage(context, errorMessage);
    } catch (e, stackTrace) {
      if (mounted) helper.hideLoadingDialog(context);
      // Catch any other unexpected errors
      helper.showErrorMessage(context, e.toString(), stackTrace: stackTrace);
      debugPrint(e.toString());
    }
  }

  Future<void> _editPerson(int index) async {
    //get the person and load the new page
    int id = _searchResult[index]['id'];
    int originalIndex =
        StateManager.getChildrenList().indexWhere((person) => person['id'] == id);

    if (originalIndex == -1) return;

    final child = _searchResult[index];

    try {
      bool? state = await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => EditPage(
          childToUpdate: child,
          database: widget.dbCon,
          isTablet: widget.isTablet,
        ),
      ));

      if (state == true) {
        final result = await reader.getPersonFromAllPeople(id);
        StateManager.updateChildAtIndex(originalIndex, result.first);
        _runSearchFilter(_searchController.text);
      }
    } on custom_db_exceptions.DbConnectionException catch (e) {
      debugPrint('Database connection error: $e');
      if (mounted) {
        await DbConnectionValidator.handleConnectionError(context);
      }
    } catch (e, stackTrace) {
      helper.showErrorMessage(context, 'Failed to update person: ${e.toString()}',
          stackTrace: stackTrace);
    }
  }

  Future<void> _populateList({bool forceRefresh = false}) async {
    if (StateManager.getChildrenList().isEmpty || forceRefresh) {
      setState(() {
        _isLoading = true;
      });

      try {
        Future<List<Map<String, dynamic>>> dataLoadFuture = reader.getAllPeople(ascending: _isAscending);

        Future<void> minWaitFuture = Future.delayed(const Duration(seconds: 1));

        final results = await Future.wait([dataLoadFuture, minWaitFuture]);

        StateManager.setChildrenList(results[0] as List<Map<String, dynamic>>);
      } on custom_db_exceptions.DbConnectionException catch (e) {
        debugPrint('Database connection error: $e');
        if (mounted) {
          await DbConnectionValidator.handleConnectionError(context);
        }
      } catch (e, stackTrace) {
        debugPrint('Error populating list: $e');
        if (mounted) {
          helper.showErrorMessage(
              context, 'Failed to load data: ${e.toString()}',
              stackTrace: stackTrace);
        }
      }
    }

    if (mounted) {
      setState(() {
        _searchResult = StateManager.getChildrenList();
        _isLoading = false;
        _expandedIndex = -1;
      });
    }
  }
}

// NEW WIDGET 1: The search field
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool isTablet;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Padding(
      padding: ResponsiveUtils.getListPadding(context),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context)),
        decoration: InputDecoration(
          labelText: localizations.searchForName,
          labelStyle: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context)),
          contentPadding: ResponsiveUtils.getContentPadding(context),
          border: OutlineInputBorder(
            borderRadius: ResponsiveUtils.getCardBorderRadius(context),
          ),
          suffixIcon: IconButton(
            icon: Icon(Icons.cancel, size: ResponsiveUtils.getIconSize(context)),
            onPressed: onClear,
          ),
        ),
      ),
    );
  }
}

// NEW WIDGET 2: The list view
class _PersonListView extends StatelessWidget {
  final List<Map<String, dynamic>> searchResult;
  final bool isSelectionMode;
  final Set<int> selectedPersonIds; 
  final int expandedIndex;
  final Function(int) onPersonTap;
  final Function(int, bool) onExpansionChanged;
  final Function(int) onDeletePress;
  final Function(int) onEditPress;
  final List<Widget> Function(int) buildPersonDetails;
  final bool isTablet;

  const _PersonListView({
    required this.searchResult,
    required this.isSelectionMode,
    required this.selectedPersonIds, 
    required this.expandedIndex,
    required this.onPersonTap,
    required this.onExpansionChanged,
    required this.onDeletePress,
    required this.onEditPress,
    required this.buildPersonDetails,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: searchResult.length,
      padding: EdgeInsets.only(
        left: ResponsiveUtils.getListPadding(context).left,
        right: ResponsiveUtils.getListPadding(context).right,
        top: 0,
        bottom: ResponsiveUtils.getButtonHeight(context) + 40 + MediaQuery.of(context).padding.bottom,
      ),
      itemBuilder: (context, index) {
        final person = searchResult[index];
        final isSelected = isSelectionMode && selectedPersonIds.contains(person['id']); // Check based on ID
        return CustomExpansion(
          allPeopleList: searchResult,
          index: index,
          isExpanded: expandedIndex == index,
          isSelected: isSelected,
          isSelectionMode: isSelectionMode,
          onExpansionChanged: (expanded) => onExpansionChanged(index, expanded),
          onTap: () => onPersonTap(index),
          onDeletePress: () => onDeletePress(index),
          onEditPress: () => onEditPress(index),
          buildChildren: buildPersonDetails(index),
          isTablet: isTablet,
        );
      },
    );
  }
}