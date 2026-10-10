import 'package:attendly/data/database/app_database.dart';
import 'package:attendly/features/directory/pages/person_form_page.dart';
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

  Future<DirectoryPeopleData> loadPerson(WidgetTester tester, String name) async {
    late DirectoryPeopleData person;
    await tester.runAsync(() async {
      final id = await addTestPerson(db, name);
      person = (await db.readDao.getPersonById(id))!;
    });
    return person;
  }

  /// Pumps a button that opens [page], taps it, and returns the popped result.
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

  group('add mode', () {
    testWidgets('shows the add title, reset and submit', (tester) async {
      await openPage(tester, const PersonFormPage(mode: PersonFormMode.add));

      expect(find.text(l10n.addPersonToTable), findsOneWidget);
      expect(find.text(l10n.reset), findsOneWidget);
      expect(find.text(l10n.submit), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('submitting an empty form asks to fill all fields', (tester) async {
      await openPage(tester, const PersonFormPage(mode: PersonFormMode.add));

      await tester.tap(find.text(l10n.submit));
      await tester.pumpAndSettle();

      expect(find.text(l10n.allFieldsMustBeFilled), findsOneWidget);
      await unmount(tester);
    });
  });

  group('edit mode', () {
    testWidgets('is prefilled and has no reset button', (tester) async {
      final anna = await loadPerson(tester, 'Anna');

      await openPage(tester, PersonFormPage(mode: PersonFormMode.edit, person: anna));

      expect(find.text(l10n.editPerson), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Anna'), findsOneWidget);
      expect(find.widgetWithText(TextField, '01.01.2010'), findsOneWidget);
      expect(find.text(l10n.reset), findsNothing);
      expect(find.text(l10n.update), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('without changes it closes with false and writes nothing', (tester) async {
      final anna = await loadPerson(tester, 'Anna');

      final results = await openPage(tester, PersonFormPage(mode: PersonFormMode.edit, person: anna));
      await tester.tap(find.text(l10n.update));
      await settleStreams(tester);

      expect(results, [false]);
      expect(find.text(l10n.updatedSuccessfully), findsNothing);
      await unmount(tester);
    });

    testWidgets('renaming saves the new name and closes with true', (tester) async {
      final anna = await loadPerson(tester, 'Anna');

      final results = await openPage(tester, PersonFormPage(mode: PersonFormMode.edit, person: anna));
      await tester.enterText(find.widgetWithText(TextField, 'Anna'), 'Annika');
      await tester.tap(find.text(l10n.update));
      await settleStreams(tester);
      await tester.pumpAndSettle();

      expect(find.text(l10n.updatedSuccessfully), findsOneWidget);
      await tester.tap(find.text(l10n.ok));
      await tester.pumpAndSettle();

      expect(results, [true]);
      final renamed = await tester.runAsync(() => db.readDao.getPersonById(anna.id));
      expect(renamed?.name, 'Annika');
      await unmount(tester);
    });

    testWidgets('a duplicate name shows the duplicate message', (tester) async {
      final anna = await loadPerson(tester, 'Anna');
      await loadPerson(tester, 'Ben');

      await openPage(tester, PersonFormPage(mode: PersonFormMode.edit, person: anna));
      await tester.enterText(find.widgetWithText(TextField, 'Anna'), 'Ben');
      await tester.tap(find.text(l10n.update));
      await settleStreams(tester);
      await tester.pumpAndSettle();

      expect(find.text(l10n.personNamedAlreadyExists('Ben')), findsOneWidget);
      await unmount(tester);
    });
  });
}
