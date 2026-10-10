import 'package:attendly/data/database/app_database.dart';
import 'package:attendly/features/daily_log/pages/daily_log_tab.dart';
import 'package:attendly/features/directory/pages/directory_tab.dart';
import 'package:attendly/features/weekly_report/pages/weekly_report_tab.dart';
import 'package:attendly/features/yearly_report/pages/yearly_report_tab.dart';
import 'package:attendly/l10n/app_en.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';
import '../helpers/test_database.dart';

void main() {
  final l10n = AppLocalizationsEn();
  late AppDatabase db;

  setUp(() => db = createTestDatabase());
  tearDown(() => db.close());

  group('Tab smoke tests (empty database)', () {
    testWidgets('directory tab shows title and empty state', (tester) async {
      await pumpWithDatabase(
        tester,
        DirectoryTab(selectedTab: 0, onTabChange: (_) {}),
        db: db,
      );

      expect(find.text(l10n.directory), findsOneWidget);
      expect(find.text(l10n.noPersonFound), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('daily log tab shows title and empty state', (tester) async {
      await pumpWithDatabase(
        tester,
        DailyLogTab(selectedTab: 1, onTabChange: (_) {}),
        db: db,
      );

      expect(find.text(l10n.dailyLogs), findsOneWidget);
      expect(find.text(l10n.noEntriesForThisDay), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('weekly report tab shows title and empty state', (tester) async {
      await pumpWithDatabase(
        tester,
        WeeklyReportPage(selectedTab: 2, onTabChange: (_) {}),
        db: db,
      );

      expect(find.text(l10n.weeklyReport), findsOneWidget);
      expect(find.text(l10n.noDataForThisWeek), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('yearly report tab shows title and empty state', (tester) async {
      await pumpWithDatabase(
        tester,
        YearStatsPage(selectedTab: 3, onTabChange: (_) {}, isTablet: false),
        db: db,
      );

      expect(find.text(l10n.yearlyStats), findsOneWidget);
      expect(find.text(l10n.noDataForThisYear), findsOneWidget);
      await unmount(tester);
    });
  });

  group('Tab smoke tests (with data)', () {
    testWidgets('directory tab lists people', (tester) async {
      await tester.runAsync(() async {
        await addTestPerson(db, 'Anna');
        await addTestPerson(db, 'Ben');
      });

      await pumpWithDatabase(
        tester,
        DirectoryTab(selectedTab: 0, onTabChange: (_) {}),
        db: db,
      );

      expect(find.text('Anna'), findsOneWidget);
      expect(find.text('Ben'), findsOneWidget);
      await unmount(tester);
    });
  });
}
