import 'dart:math';

import 'package:attendly/core/logging/app_logger.dart';
import 'package:attendly/data/database/app_database.dart';
import 'package:attendly/data/tables/enums/gender.dart';
import 'package:drift/drift.dart';

/// Fills the directory with fake people to check how the app copes with
/// large directories (debug menu only).
///
/// Seeded names start with a random letter, so the alphabet index has
/// something to jump to, and end with [marker], so they can be found and
/// deleted again.
class TestPeopleSeeder {
  static const String _tag = 'Debug';

  /// Suffix that marks a seeded person.
  static const String marker = ' #seed';

  final AppDatabase db;
  final Random _random;

  TestPeopleSeeder(this.db, {Random? random}) : _random = random ?? Random();

  Expression<bool> _isSeeded($DirectoryPeopleTable t) => t.name.like('%$marker%');

  Future<int> countSeeded() async {
    final count = db.directoryPeople.id.count(filter: _isSeeded(db.directoryPeople));
    final query = db.selectOnly(db.directoryPeople)..addColumns([count]);
    return await query.map((row) => row.read(count)).getSingle() ?? 0;
  }

  /// Inserts [count] people in one batch. Returns the number inserted.
  Future<int> seed(int count) async {
    final stopwatch = Stopwatch()..start();
    final offset = await countSeeded();

    final people = [
      for (var i = 0; i < count; i++) _fakePerson(offset + i + 1),
    ];
    await db.batch((batch) => batch.insertAll(db.directoryPeople, people));

    AppLogger.i(_tag, 'Seeded $count test people in ${stopwatch.elapsedMilliseconds} ms');
    return count;
  }

  /// Deletes every seeded person, including their daily entries and weekly
  /// counts. Returns the number deleted.
  Future<int> deleteSeeded() async {
    final stopwatch = Stopwatch()..start();
    final ids = await (db.selectOnly(db.directoryPeople)
          ..addColumns([db.directoryPeople.id])
          ..where(_isSeeded(db.directoryPeople)))
        .map((row) => row.read(db.directoryPeople.id)!)
        .get();

    await db.transaction(() async {
      for (final id in ids) {
        await db.deleteDao.deleteDirPerson(id);
      }
    });

    AppLogger.i(_tag, 'Deleted ${ids.length} test people in ${stopwatch.elapsedMilliseconds} ms');
    return ids.length;
  }

  DirectoryPeopleCompanion _fakePerson(int number) {
    const letters = 'abcdefghijklmnopqrstuvwxyz';
    final first = letters[_random.nextInt(26)].toUpperCase();
    final rest = List.generate(5, (_) => letters[_random.nextInt(26)]).join();
    final migration = _random.nextBool();

    return DirectoryPeopleCompanion.insert(
      name: '$first$rest$marker${number.toString().padLeft(4, '0')}',
      birthday: DateTime(2005 + _random.nextInt(14), 1 + _random.nextInt(12), 1 + _random.nextInt(28)),
      gender: Gender.values[_random.nextInt(Gender.values.length)],
      migration: migration,
      migrationBackground: Value(migration ? 'Test' : ''),
    );
  }
}
