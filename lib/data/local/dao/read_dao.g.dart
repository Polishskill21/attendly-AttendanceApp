// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'read_dao.dart';

// ignore_for_file: type=lint
mixin _$ReadDaoMixin on DatabaseAccessor<AppDatabase> {
  $DirectoryPeopleTable get directoryPeople => attachedDatabase.directoryPeople;
  $DailyEntryTable get dailyEntry => attachedDatabase.dailyEntry;
  $WeeklyEntryTable get weeklyEntry => attachedDatabase.weeklyEntry;
  ReadDaoManager get managers => ReadDaoManager(this);
}

class ReadDaoManager {
  final _$ReadDaoMixin _db;
  ReadDaoManager(this._db);
  $$DirectoryPeopleTableTableManager get directoryPeople =>
      $$DirectoryPeopleTableTableManager(
        _db.attachedDatabase,
        _db.directoryPeople,
      );
  $$DailyEntryTableTableManager get dailyEntry =>
      $$DailyEntryTableTableManager(_db.attachedDatabase, _db.dailyEntry);
  $$WeeklyEntryTableTableManager get weeklyEntry =>
      $$WeeklyEntryTableTableManager(_db.attachedDatabase, _db.weeklyEntry);
}
