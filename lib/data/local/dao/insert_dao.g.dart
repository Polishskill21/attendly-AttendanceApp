// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'insert_dao.dart';

// ignore_for_file: type=lint
mixin _$InsertDaoMixin on DatabaseAccessor<AppDatabase> {
  $DirectoryPeopleTable get directoryPeople => attachedDatabase.directoryPeople;
  $DailyEntryTable get dailyEntry => attachedDatabase.dailyEntry;
  InsertDaoManager get managers => InsertDaoManager(this);
}

class InsertDaoManager {
  final _$InsertDaoMixin _db;
  InsertDaoManager(this._db);
  $$DirectoryPeopleTableTableManager get directoryPeople =>
      $$DirectoryPeopleTableTableManager(
        _db.attachedDatabase,
        _db.directoryPeople,
      );
  $$DailyEntryTableTableManager get dailyEntry =>
      $$DailyEntryTableTableManager(_db.attachedDatabase, _db.dailyEntry);
}
