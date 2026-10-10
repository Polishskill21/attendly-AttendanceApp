import 'package:attendly/core/responsive/responsive.dart';
import 'package:attendly/data/database/app_database.dart';
import 'package:attendly/features/directory/providers/directory_providers.dart';
import 'package:attendly/features/directory/widgets/person_directory_list.dart';
import 'package:attendly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pick one or more people from the directory. Pops with the selected
/// [DirectoryPeopleData] list, or null when the user goes back.
class PersonPickerPage extends ConsumerStatefulWidget {
  final List<int> initiallySelectedIds;

  const PersonPickerPage({super.key, this.initiallySelectedIds = const []});

  @override
  ConsumerState<PersonPickerPage> createState() => _PersonPickerPageState();
}

class _PersonPickerPageState extends ConsumerState<PersonPickerPage> {
  late final Set<int> _selectedPersonIds = {...widget.initiallySelectedIds};

  void _toggle(DirectoryPeopleData person) {
    setState(() {
      if (!_selectedPersonIds.remove(person.id)) _selectedPersonIds.add(person.id);
    });
  }

  void _confirm() {
    // Use the full unfiltered list, not the search-filtered one
    final allPeople = ref.read(directoryStreamProvider).valueOrNull ?? [];
    final selected = allPeople.where((p) => _selectedPersonIds.contains(p.id)).toList();
    Navigator.of(context).pop(selected);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final responsive = Responsive.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.selectAPerson,
            style: TextStyle(
                fontSize: responsive.titleFontSize,
                fontWeight: FontWeight.bold)),
        leading: IconButton(
            icon: Icon(Icons.arrow_back, size: responsive.iconSize()),
            onPressed: () => Navigator.pop(context)),
      ),
      body: PersonDirectoryList(
        isSelectionMode: true,
        selectedPersonIds: _selectedPersonIds,
        onPersonTap: _toggle,
      ),
      floatingActionButton: _selectedPersonIds.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _confirm,
              label: Text(localizations.confirmSelection(_selectedPersonIds.length),
                  style: TextStyle(fontSize: responsive.isTablet ? 18 : 14)),
              icon: Icon(Icons.check, size: responsive.isTablet ? 28 : 24),
            ),
    );
  }
}
