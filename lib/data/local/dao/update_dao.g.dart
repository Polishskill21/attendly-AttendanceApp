// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_dao.dart';

// ignore_for_file: type=lint
mixin _$UpdateDaoMixin on DatabaseAccessor<AppDatabase> {
  $DirectoryPeopleTable get directoryPeople => attachedDatabase.directoryPeople;
  $DailyEntryTable get dailyEntry => attachedDatabase.dailyEntry;
  $WeeklyEntryTable get weeklyEntry => attachedDatabase.weeklyEntry;
  UpdateDaoManager get managers => UpdateDaoManager(this);
}

class UpdateDaoManager {
  final _$UpdateDaoMixin _db;
  UpdateDaoManager(this._db);
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
