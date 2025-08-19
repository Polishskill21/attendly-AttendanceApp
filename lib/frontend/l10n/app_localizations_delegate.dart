import 'dart:async';
import 'package:flutter/material.dart';
import 'package:attendly/frontend/l10n/app_de.dart';
import 'package:attendly/frontend/l10n/app_en.dart';
import 'package:attendly/frontend/l10n/app_localizations.dart';

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'de'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return _load(locale);
  }

  static Future<AppLocalizations> _load(Locale locale) async {
    switch (locale.languageCode) {
      case 'en':
        return AppLocalizationsEn();
      case 'de':
        return AppLocalizationsDe();
      default:
        return AppLocalizationsEn();
    }
  }

  static AppLocalizations getLocalization(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return AppLocalizationsEn();
      case 'de':
        return AppLocalizationsDe();
      default:
        return AppLocalizationsEn();
    }
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) => false;
}
