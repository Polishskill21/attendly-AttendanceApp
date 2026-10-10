import 'package:attendly/data/database/app_database.dart';
import 'package:attendly/data/tables/enums/category.dart';
import 'package:attendly/features/daily_log/models/category_record.dart';
import 'package:attendly/features/daily_log/pages/daily_entry_form_page.dart';
import 'package:attendly/l10n/app_en.dart';
import 'package:attendly/shared/options/category_option.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';
import '../helpers/test_database.dart';

void main() {
  final l10n = AppLocalizationsEn();
  final monday = DateTime(2026, 3, 2);
  late AppDatabase db;

  setUp(() => db = createTestDatabase());
  tearDown(() => db.close());

  /// Pumps a button that opens [page], taps it, and returns the popped results.
  Future<List<Object?>> openPage(WidgetTester tester, Widget page) async {
    // Tall enough to show the whole form without scrolling.
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 1600);
    addTearDown(tester.view.reset);

    final results = <Object?>[];
    await pumpWithDatabase(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            results.add(await Navigator.of(context).push<Object?>(
              MaterialPageRoute(builder: (_) => page),
            ));
          },
          child: const Text('open'),
        ),
      ),
      db: db,
    );
    await tester.tap(find.text('open'));
    await settleStreams(tester);
    return results;
  }

  Future<void> chooseCategory(WidgetTester tester, String label) async {
    await tester.tap(find.byType(DropdownMenu<CategoryOption>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<List<DailyEntryData>> entriesOf(WidgetTester tester, int personId) async =>
      (await tester.runAsync(() => db.readDao.getDailyEntriesByPersonId(personId)))!;

  group('add mode', () {
    testWidgets('submitting without a category asks for person, category and date',
        (tester) async {
      await openPage(tester, const DailyEntryFormPage(mode: DailyEntryFormMode.add));

      expect(find.text(l10n.addPersonToDailyTable), findsOneWidget);
      expect(find.text(l10n.tapToSelectPersons), findsOneWidget);

      await tester.tap(find.text(l10n.submit));
      await tester.pumpAndSettle();

      expect(find.text(l10n.personCategoryDateRequired), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('the multiplier is only offered for countable categories', (tester) async {
      await openPage(tester, const DailyEntryFormPage(
        mode: DailyEntryFormMode.add,
        preselectedPersons: [(id: 1, name: 'Anna')],
      ));

      await chooseCategory(tester, l10n.open);
      expect(find.text(l10n.numberOfEntries), findsNothing);

      await chooseCategory(tester, l10n.offers);
      expect(find.text(l10n.numberOfEntries), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('a preselected person gets the entry on the given day', (tester) async {
      final anna = (await tester.runAsync(() => addTestPerson(db, 'Anna')))!;

      final results = await openPage(tester, DailyEntryFormPage(
        mode: DailyEntryFormMode.add,
        initialDate: monday,
        preselectedPersons: [(id: anna, name: 'Anna')],
      ));
      expect(find.text('Anna'), findsOneWidget);
      expect(find.widgetWithText(TextField, '02.03.2026'), findsOneWidget);

      await chooseCategory(tester, l10n.open);
      await tester.tap(find.text(l10n.submit));
      await settleStreams(tester);
      await tester.pumpAndSettle();

      expect(find.text(l10n.personsAddedSuccessfully(1)), findsOneWidget);
      await tester.tap(find.text(l10n.ok));
      await tester.pumpAndSettle();

      expect(results, [true]);
      final entries = await entriesOf(tester, anna);
      expect(entries.map((e) => (e.date, e.category)), [(monday, Category.open)]);
      await unmount(tester);
    });
  });

  group('edit mode', () {
    Future<(int, CategoryRecord)> recordFor(WidgetTester tester, Category category) async {
      return (await tester.runAsync(() async {
        final anna = await addTestPerson(db, 'Anna');
        await addTestEntry(db, personId: anna, date: monday, category: Category.open);
        if (category != Category.open) {
          await addTestEntry(db, personId: anna, date: monday, category: category, description: 'old');
        }
        final person = (await db.readDao.getPersonById(anna))!;
        final entry = (await db.readDao.getDailyEntriesByPersonId(anna))
            .firstWhere((e) => e.category == category);
        return (anna, CategoryRecord.fromDrift(person, entry));
      }))!;
    }

    testWidgets('is prefilled and saves the new comment', (tester) async {
      final (anna, record) = await recordFor(tester, Category.offer);

      final results = await openPage(tester, DailyEntryFormPage(mode: DailyEntryFormMode.edit, record: record));
      expect(find.text(l10n.editCategory), findsOneWidget);
      expect(find.text('${l10n.date}: 02.03.2026'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'old'), findsOneWidget);
      expect(find.text(l10n.reset), findsNothing);

      await tester.enterText(find.widgetWithText(TextField, 'old'), 'new');
      await tester.tap(find.text(l10n.saveChanges));
      await settleStreams(tester);
      await tester.pumpAndSettle();
      expect(find.text(l10n.recordUpdatedSuccessfully), findsOneWidget);
      await tester.tap(find.text(l10n.ok));
      await tester.pumpAndSettle();

      expect(results, [true]);
      final entries = await entriesOf(tester, anna);
      expect(entries.firstWhere((e) => e.category == Category.offer).description, 'new');
      await unmount(tester);
    });

    testWidgets('changing to a second "open" shows the duplicate message', (tester) async {
      final (_, record) = await recordFor(tester, Category.offer);

      await openPage(tester, DailyEntryFormPage(mode: DailyEntryFormMode.edit, record: record));
      await chooseCategory(tester, l10n.open);
      await tester.tap(find.text(l10n.saveChanges));
      await settleStreams(tester);
      await tester.pumpAndSettle();

      expect(find.text(l10n.personAlreadyInCategoryOpen('Anna')), findsOneWidget);
      await unmount(tester);
    });
  });
}
