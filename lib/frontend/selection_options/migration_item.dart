import 'package:flutter/material.dart';
import 'package:attendly/localization/app_localizations.dart';

class MigraionItem{
  final int id;
  final String label;
  final bool value;
  final IconData? icon;

  MigraionItem(this.id, this.label, this.value, this.icon);
}

List<MigraionItem> getMigrationItems(BuildContext context) {
  final localizations = AppLocalizations.of(context);
  return [
    MigraionItem(1, localizations.yes, true, Icons.location_on_outlined),
    MigraionItem(2, localizations.no, false, Icons.location_off_outlined)
  ];
}

// Keep the old list for backward compatibility but deprecate it
@deprecated
List<MigraionItem> migrationItems = [
  MigraionItem(1, "True", true, Icons.location_on_outlined),
  MigraionItem(2, "False", false, Icons.location_off_outlined)
];
