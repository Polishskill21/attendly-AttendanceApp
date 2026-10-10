import 'package:flutter/material.dart';
import 'package:attendly/l10n/app_localizations.dart';

class MigrationOption{
  final int id;
  final String label;
  final bool value;
  final IconData? icon;

  MigrationOption(this.id, this.label, this.value, this.icon);
}

List<MigrationOption> getMigrationOptions(BuildContext context) {
  final localizations = AppLocalizations.of(context);
  return [
    MigrationOption(1, localizations.yes, true, Icons.location_on_outlined),
    MigrationOption(2, localizations.no, false, Icons.location_off_outlined)
  ];
}
