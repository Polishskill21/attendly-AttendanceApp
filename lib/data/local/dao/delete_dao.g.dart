// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_dao.dart';

// ignore_for_file: type=lint
mixin _$DeleteDaoMixin on DatabaseAccessor<AppDatabase> {
  $DirectoryPeopleTable get directoryPeople => attachedDatabase.directoryPeople;
  $DailyEntryTable get dailyEntry => attachedDatabase.dailyEntry;
  $WeeklyEntryTable get weeklyEntry => attachedDatabase.weeklyEntry;
  DeleteDaoManager get managers => DeleteDaoManager(this);
}

class DeleteDaoManager {
  final _$DeleteDaoMixin _db;
  DeleteDaoManager(this._db);
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
