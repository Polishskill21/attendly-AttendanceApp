import 'package:attendly/data/database/app_database.dart';
import 'package:attendly/features/directory/pages/person_picker_page.dart';
import 'package:attendly/features/search/pages/daily_log_search_page.dart';
import 'package:attendly/shared/navigation/app_routes.dart';
import 'package:flutter/material.dart';

/// Builds the pages behind [AppRoutes] for `MaterialApp.onGenerateRoute`.
Route<dynamic>? onGenerateAppRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.personPicker:
      return MaterialPageRoute<List<DirectoryPeopleData>>(
        settings: settings,
        builder: (_) => PersonPickerPage(
          initiallySelectedIds: settings.arguments as List<int>? ?? const [],
        ),
      );
    case AppRoutes.dailyLogSearch:
      return MaterialPageRoute<DateTime>(
        settings: settings,
        builder: (_) => const DailyLogSearchPage(),
      );
  }
  return null;
}
