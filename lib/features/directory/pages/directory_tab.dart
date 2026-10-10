import 'package:attendly/data/database/app_database.dart';
import 'package:attendly/data/database/exceptions.dart' as custom_db_exceptions;
import 'package:attendly/features/directory/pages/add_person_page.dart';
import 'package:attendly/features/directory/widgets/person_directory_list.dart';
import 'package:attendly/shared/dialogs/app_dialogs.dart';
import 'package:attendly/core/responsive/responsive.dart';
import 'package:attendly/features/directory/providers/directory_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:attendly/core/logging/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:attendly/features/directory/pages/edit_person_page.dart';
import 'package:attendly/shared/widgets/refreshable_app_bar.dart';
import 'package:attendly/app/shell/app_navigation_drawer.dart';
import 'package:attendly/l10n/app_localizations.dart';

class DirectoryTab extends ConsumerStatefulWidget {
  final int selectedTab;
  final void Function(int) onTabChange;

  const DirectoryTab({
    super.key,
    required this.selectedTab,
    required this.onTabChange,
  });

  @override
  ConsumerState<DirectoryTab> createState() => _DirectoryTabState();
}

class _DirectoryTabState extends ConsumerState<DirectoryTab> {
  final AppDialogs _helper = AppDialogs();
  bool _isManualRefreshing = false;

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
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    final isAscending = ref.watch(directorySortAscendingProvider);
    final asyncPeople = ref.watch(filteredDirectoryProvider);

    return Scaffold(
      drawer: Responsive.of(context).isTablet 
          ? null
          : AppNavigationDrawer(
              selectedTab: widget.selectedTab,
              onTabChange: widget.onTabChange,
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
      body: PersonDirectoryList(
        onEditPress: _editPerson,
        onDeletePress: _deletePerson,
      ),
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
}
