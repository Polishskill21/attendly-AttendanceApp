import 'package:attendly/data/local/tables/enums/gender.dart';
import 'package:flutter/material.dart';
import 'package:attendly/localization/app_localizations.dart';

class GenderItem{
  final int id;
  final String label;
  final Gender value;
  final IconData icon;

  GenderItem(this.id, this.label, this.value, this.icon);
}

List<GenderItem> getGenderItems(BuildContext context) {
  final localizations = AppLocalizations.of(context);
  return [
    GenderItem(1, localizations.male, Gender.m, Icons.male),
    GenderItem(2, localizations.female, Gender.f, Icons.female),
    GenderItem(3, localizations.diverse, Gender.d, Icons.transgender)
  ];
}

// Keep the old list for backward compatibility but deprecate it
@Deprecated("Keep the old list for backward compatibility but deprecate it")
List<GenderItem> genderItems = [
  GenderItem(1, "Male", Gender.m, Icons.male),
  GenderItem(2, "Female", Gender.f, Icons.female),
  GenderItem(3, "Diverse", Gender.d, Icons.transgender)
];