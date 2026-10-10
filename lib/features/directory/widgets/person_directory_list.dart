import 'package:anchored_list/anchored_list.dart';
import 'package:attendly/core/responsive/responsive.dart';
import 'package:attendly/data/database/app_database.dart';
import 'package:attendly/data/database/database_provider.dart';
import 'package:attendly/data/database/exceptions.dart' as custom_db_exceptions;
import 'package:attendly/features/directory/providers/directory_providers.dart';
import 'package:attendly/features/directory/widgets/alphabet_index_bar.dart';
import 'package:attendly/features/directory/widgets/directory_search_field.dart';
import 'package:attendly/features/directory/widgets/person_tile.dart';
import 'package:attendly/l10n/app_localizations.dart';
import 'package:attendly/shared/dialogs/app_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Search field, person list and alphabet index, shared by the directory tab
/// and the person picker.
class PersonDirectoryList extends ConsumerStatefulWidget {
  /// Selection mode shows check marks instead of edit/delete buttons.
  final bool isSelectionMode;
  final Set<int> selectedPersonIds;
  final ValueChanged<DirectoryPeopleData>? onPersonTap;
  final ValueChanged<DirectoryPeopleData>? onEditPress;
  final ValueChanged<DirectoryPeopleData>? onDeletePress;

  const PersonDirectoryList({
    super.key,
    this.isSelectionMode = false,
    this.selectedPersonIds = const {},
    this.onPersonTap,
    this.onEditPress,
    this.onDeletePress,
  });

  @override
  ConsumerState<PersonDirectoryList> createState() => _PersonDirectoryListState();
}

class _PersonDirectoryListState extends ConsumerState<PersonDirectoryList> {
  final TextEditingController _searchController = TextEditingController();
  final AnchoredListController _listController = AnchoredListController();
  final AppDialogs _helper = AppDialogs();
  late final StateController<String> _searchQueryNotifier;
  int _expandedIndex = -1;

  @override
  void initState() {
    super.initState();
    _searchQueryNotifier = ref.read(directorySearchQueryProvider.notifier);

    if (widget.isSelectionMode) {
      _searchQueryNotifier.state = '';
    }

    _searchController.text = ref.read(directorySearchQueryProvider);
    _searchController.addListener(() {
      _searchQueryNotifier.state = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchQueryNotifier.state = '';
    _searchController.dispose();
    super.dispose();
  }

  void _jumpToLetter(Map<String, int> letterIndexMap, String letter) {
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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final asyncPeople = ref.watch(filteredDirectoryProvider);

    // Changing the sort order moves every row, so an open card would jump.
    ref.listen(directorySortAscendingProvider, (_, _) {
      setState(() => _expandedIndex = -1);
    });

    return Column(
      children: [
        DirectorySearchField(
          controller: _searchController,
          onClear: () {
            _searchController.clear();
            ref.read(directorySearchQueryProvider.notifier).state = '';
          },
        ),
        Expanded(
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
                      selectedPersonIds: widget.selectedPersonIds,
                      expandedIndex: _expandedIndex,
                      listController: _listController,
                      onPersonTap: (person) => widget.onPersonTap?.call(person),
                      onExpansionChanged: (index, expanded) {
                        setState(() => _expandedIndex = expanded ? index : -1);
                      },
                      onDeletePress: (person) => widget.onDeletePress?.call(person),
                      onEditPress: (person) => widget.onEditPress?.call(person),
                      buildPersonDetails: (person) => _helper.buildPersonDetails(
                          people, people.indexOf(person), localizations, context),
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
                        onLetterSelected: (letter, {required bool isDragging}) =>
                            _jumpToLetter(letterIndexMap, letter),
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
