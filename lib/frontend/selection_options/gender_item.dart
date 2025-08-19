import 'package:attendly/backend/enums/genders.dart';
import 'package:flutter/material.dart';
import 'package:attendly/frontend/l10n/app_localizations.dart';

class GenderItem{
  final int id;
  final String label;
  final Genders value;
  final IconData icon;

  GenderItem(this.id, this.label, this.value, this.icon);
}

List<GenderItem> getGenderItems(BuildContext context) {
  final localizations = AppLocalizations.of(context);
  return [
    GenderItem(1, localizations.male, Genders.m, Icons.male),
    GenderItem(2, localizations.female, Genders.f, Icons.female),
    GenderItem(3, localizations.diverse, Genders.d, Icons.transgender)
  ];
}

// Keep the old list for backward compatibility but deprecate it
@deprecated
List<GenderItem> genderItems = [
  GenderItem(1, "Male", Genders.m, Icons.male),
  GenderItem(2, "Female", Genders.f, Icons.female),
  GenderItem(3, "Diverse", Genders.d, Icons.transgender)
];