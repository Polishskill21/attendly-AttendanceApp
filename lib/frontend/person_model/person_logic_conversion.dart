import 'package:attendly/backend/enums/genders.dart';
import 'package:attendly/frontend/l10n/app_localizations.dart';

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

