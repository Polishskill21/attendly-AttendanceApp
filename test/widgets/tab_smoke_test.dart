import 'package:attendly/app/shell/app_shell.dart';
import 'package:attendly/app/shell/app_tab.dart';
import 'package:attendly/data/database/app_database.dart';
import 'package:attendly/l10n/app_en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';
import '../helpers/test_database.dart';

void main() {
  final l10n = AppLocalizationsEn();
  late AppDatabase db;

  setUp(() => db = createTestDatabase());
  tearDown(() => db.close());

  /// Pumps the shell on [tab], as a phone unless [tablet].
  Future<void> pumpShell(WidgetTester tester, AppTab tab, {bool tablet = false}) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = tablet ? const Size(1280, 800) : const Size(580, 1000);
    addTearDown(tester.view.reset);

    await pumpWithDatabase(
      tester,
      const AppShell(),
      db: db,
      overrides: [selectedTabProvider.overrideWith((ref) => tab)],
    );
  }

  group('Tab smoke tests (empty database)', () {
    final emptyStates = {
      AppTab.directory: (l10n.directory, l10n.noPersonFound),
      AppTab.dailyLog: (l10n.dailyLogs, l10n.noEntriesForThisDay),
      AppTab.weeklyReport: (l10n.weeklyReport, l10n.noDataForThisWeek),
      AppTab.yearlyReport: (l10n.yearlyStats, l10n.noDataForThisYear),
    };

    for (final MapEntry(key: tab, value: (title, emptyText)) in emptyStates.entries) {
      testWidgets('${tab.name} tab shows title and empty state', (tester) async {
        await pumpShell(tester, tab);

        expect(find.text(title), findsOneWidget);
        expect(find.text(emptyText), findsOneWidget);
        await unmount(tester);
      });

      testWidgets('${tab.name} tab has exactly one Scaffold and one drawer on a phone',
          (tester) async {
        await pumpShell(tester, tab);

        expect(find.byType(Scaffold), findsOneWidget);
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
        expect(find.byType(Drawer), findsOneWidget);
        await unmount(tester);
      });
    }
  });

  group('Shell', () {
    testWidgets('choosing a tab in the drawer switches the tab', (tester) async {
      await pumpShell(tester, AppTab.directory);

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(Drawer), matching: find.text(l10n.weeklyReport)));
      await tester.pumpAndSettle();

      expect(find.text(l10n.noDataForThisWeek), findsOneWidget);
      expect(find.text(l10n.noPersonFound), findsNothing);
      await unmount(tester);
    });

    testWidgets('a tablet shows the rail next to the tab', (tester) async {
      await pumpShell(tester, AppTab.directory, tablet: true);

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      // The only menu button is the rail's, which opens the drawer.
      expect(find.byIcon(Icons.menu), findsOneWidget);

      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pumpAndSettle();
      expect(find.text(l10n.noEntriesForThisDay), findsOneWidget);
      await unmount(tester);
    });
  });

  group('Tab smoke tests (with data)', () {
    testWidgets('directory tab lists people', (tester) async {
      await tester.runAsync(() async {
        await addTestPerson(db, 'Anna');
        await addTestPerson(db, 'Ben');
      });

      await pumpShell(tester, AppTab.directory);

      expect(find.text('Anna'), findsOneWidget);
      expect(find.text('Ben'), findsOneWidget);
      await unmount(tester);
    });
  });
}
