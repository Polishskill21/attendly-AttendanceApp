import 'package:attendly/localization/app_localizations.dart';

enum Gender{
  m,
  f,
  d
}

extension GenderLocalization on Gender {
  String localizedName(AppLocalizations loc) {
    switch (this) {
      case Gender.m:
        return loc.male;  
      case Gender.f:
        return loc.female;
      case Gender.d:
        return loc.diverse;
    }
  }
}