import 'package:attendly/backend/enums/category.dart';
import 'package:attendly/backend/enums/genders.dart';
import 'package:attendly/localization/app_localizations.dart';
import 'package:flutter/material.dart';

Genders stringToGender(String gender){
  switch(gender){
    case "m":
      return Genders.m;

    case "f":
      return Genders.f;

    case "d":
      return Genders.d;

    default:
      throw ArgumentError("Invalid gender string: $gender");
  }
}

String stringToStringGender(String gender, AppLocalizations localizations){
  switch(gender){
    case "m":
      return localizations.male;

    case "f":
      return localizations.female;

    case "d":
      return localizations.diverse; 

    default:
      throw ArgumentError("Invalid gender string: $gender");
  }
}

bool intToBool(int migrationStatus){
  switch(migrationStatus){
    case 1:
      return true;
    case 0: 
      return false;
    default: 
      throw ArgumentError("Invalid migraton status int: $migrationStatus");
  }
}

String intToBoolString(int migrationStatus, AppLocalizations localizations){
  switch(migrationStatus){
    case 1:
      return localizations.trueValue;
    case 0: 
      return localizations.falseValue;
    default: 
      throw ArgumentError("Invalid migraton status int: $migrationStatus");
  }
}

String localizedCategoryLabel(BuildContext context, String rawCategory) {
  final l = AppLocalizations.of(context);
  try {
    final cat = Category.values.byName(rawCategory);
    switch (cat) {
      case Category.open:
        return l.open;
      case Category.offer:
        return l.offers;
      case Category.parent:
        return l.parent;
      case Category.other:
        return l.other;
    }
  } catch (_) {
    return rawCategory;
  }
}

