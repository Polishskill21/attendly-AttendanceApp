import 'package:attendly/core/logging/app_logger.dart';
import 'package:attendly/core/responsive/responsive.dart';
import 'package:attendly/data/database/app_database.dart';
import 'package:attendly/data/database/exceptions.dart' as custom_db_exceptions;
import 'package:attendly/features/directory/pages/add_person_page.dart';
import 'package:attendly/features/directory/pages/edit_person_page.dart';
import 'package:attendly/features/directory/providers/directory_providers.dart';
import 'package:attendly/features/directory/widgets/person_directory_list.dart';
import 'package:attendly/l10n/app_localizations.dart';
import 'package:attendly/shared/dialogs/app_dialogs.dart';
import 'package:attendly/shared/shell/shell_tab.dart';
import 'package:attendly/shared/widgets/refreshable_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// The people directory: search, sort, add, edit and delete people.
class DirectoryTab extends ShellTab {
  const DirectoryTab();

  @override
  PreferredSizeWidget buildAppBar(BuildContext context, WidgetRef ref) {
    final isAscending = ref.watch(directorySortAscendingProvider);
    final asyncPeople = ref.watch(filteredDirectoryProvider);

    return RefreshableAppBar(
      title: AppLocalizations.of(context).directory,
      showRefresh: true,
      isLoading: asyncPeople.isLoading ||
                 asyncPeople.isRefreshing ||
                 asyncPeople.isReloading,
      onRefresh: () {
        AppLogger.d("Directory", "Invalidating dir stream");
        ref.invalidate(directoryStreamProvider);
      },
      leading: DrawerMenuButton.forShell(context),
      actions: [
        IconButton(
          icon: FaIcon(
            isAscending
              ? FontAwesomeIcons.arrowDownZA
              : FontAwesomeIcons.arrowDownAZ),
          onPressed: () => ref.read(directorySortAscendingProvider.notifier).update((s) => !s),
        ),
      ],
    );
  }

  @override
  Widget buildBody(BuildContext context, WidgetRef ref) => const _DirectoryBody();

  @override
  Widget buildFab(BuildContext context, WidgetRef ref) {
    final responsive = Responsive.of(context);
    return SizedBox(
      width: responsive.buttonHeight + 25,
      height: responsive.buttonHeight + 25,
      child: FloatingActionButton(
        onPressed: () => _addPerson(context),
        child: Icon(Icons.add, size: responsive.iconSize(baseSize: 35)),
      ),
    );
  }

  Future<void> _addPerson(BuildContext context) async {
    try {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => AddPersonPage(),
      ));
    } catch (e, stackTrace) {
      if (!context.mounted) return;
      AppDialogs.showError(context,
          'An error occurred while adding a person.\n${e.toString()}',
          stackTrace: stackTrace);
    }
  }
}

class _DirectoryBody extends ConsumerStatefulWidget {
  const _DirectoryBody();

  @override
  ConsumerState<_DirectoryBody> createState() => _DirectoryBodyState();
}

class _DirectoryBodyState extends ConsumerState<_DirectoryBody> {

  Future<void> _deletePerson(DirectoryPeopleData person) async {
    if (!mounted) return;
    final localizations = AppLocalizations.of(context);
    final id = person.id;
    final name = person.name;

    final repo = ref.read(directoryRepositoryProvider);
    final count = await repo.getEntryCountForPerson(id);
    if (!mounted) return;

    final shouldDelete = await AppDialogs.confirm(
      context,
      title: localizations.deletePersonTitle(name),
      message: '${localizations.areYouSureYouWantToDelete}\n\n${localizations.personHasNRecords(count)}',
    );

    if (!shouldDelete || !mounted) return;

    try {
      AppDialogs.showLoading(context, localizations.delete);
      await repo.deletePerson(id);

      if (mounted) {
        AppDialogs.hideLoading(context);
        await AppDialogs.showSuccess(
            context, localizations.personDeletedFromDb(name, id));
      }
    } on custom_db_exceptions.DatabaseException catch (e) {
      if (!mounted) return;
      AppDialogs.hideLoading(context);
      String msg = e.toString();
      if (e is custom_db_exceptions.DatabaseOperationException) {
        msg = localizations.unexpectedErrorContactCreator;
        AppLogger.e("Directory", "Database operation failed", e, e.stackTrace);
      }
      AppDialogs.showError(context, msg);
    } catch (e, stackTrace) {
      if (!mounted) return;
      AppDialogs.hideLoading(context);
      AppDialogs.showError(context, e.toString(), stackTrace: stackTrace);
    }
  }

  Future<void> _editPerson(DirectoryPeopleData person) async {
    try {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => EditPersonPage(personToUpdate: person),
      ));
      // Stream auto-updates after the repo write inside EditPersonPage.
    } catch (e, stackTrace) {
      if (!mounted) return;
      AppDialogs.showError(
          context, 'Failed to update person: ${e.toString()}',
          stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PersonDirectoryList(
      onEditPress: _editPerson,
      onDeletePress: _deletePerson,
    );
  }
}
