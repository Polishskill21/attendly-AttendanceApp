import 'package:attendly/data/tables/enums/gender.dart';
import 'package:flutter/material.dart';
import 'package:attendly/l10n/app_localizations.dart';

class GenderOption{
  final int id;
  final String label;
  final Gender value;
  final IconData icon;

  GenderOption(this.id, this.label, this.value, this.icon);
}

List<GenderOption> getGenderOptions(BuildContext context) {
  final localizations = AppLocalizations.of(context);
  return [
    GenderOption(1, localizations.male, Gender.m, Icons.male),
    GenderOption(2, localizations.female, Gender.f, Icons.female),
    GenderOption(3, localizations.diverse, Gender.d, Icons.transgender)
  ];
}
