import 'package:attendly/data/database/app_database.dart';
import 'package:attendly/features/directory/pages/person_picker_page.dart';
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

  testWidgets('selecting people and confirming pops the selection', (tester) async {
    late int annaId;
    await tester.runAsync(() async {
      annaId = await addTestPerson(db, 'Anna');
      await addTestPerson(db, 'Ben');
      await addTestPerson(db, 'Carla');
    });

    List<DirectoryPeopleData>? picked;
    await pumpWithDatabase(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            picked = await Navigator.of(context).push<List<DirectoryPeopleData>>(
              MaterialPageRoute(
                builder: (_) => PersonPickerPage(initiallySelectedIds: [annaId]),
              ),
            );
          },
          child: const Text('open'),
        ),
      ),
      db: db,
    );

    await tester.tap(find.text('open'));
    await settleStreams(tester);
    expect(find.text(l10n.selectAPerson), findsOneWidget);
    expect(find.text(l10n.confirmSelection(1)), findsOneWidget);

    await tester.tap(find.text('Carla'));
    await tester.pump();
    await tester.tap(find.text(l10n.confirmSelection(2)));
    await settleStreams(tester);

    expect(picked?.map((p) => p.name), ['Anna', 'Carla']);
    await unmount(tester);
  });
}
