/// Named routes for navigation between features.
///
/// A feature never imports another feature's pages; it pushes one of these
/// names and the route table in `app/app_router.dart` builds the page.
abstract final class AppRoutes {
  /// Pops with `List<DirectoryPeopleData>`. Argument: `List<int>` of the
  /// initially selected person ids (optional).
  static const String personPicker = '/person-picker';

  /// Pops with the `DateTime` of the chosen log entry.
  static const String dailyLogSearch = '/daily-log-search';
}
