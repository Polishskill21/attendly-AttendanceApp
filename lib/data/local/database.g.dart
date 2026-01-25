// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $DirectoryPeopleTable extends DirectoryPeople
    with TableInfo<$DirectoryPeopleTable, DirectoryPeopleData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DirectoryPeopleTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _birthdayMeta = const VerificationMeta(
    'birthday',
  );
  @override
  late final GeneratedColumn<DateTime> birthday = GeneratedColumn<DateTime>(
    'birthday',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Gender, String> gender =
      GeneratedColumn<String>(
        'gender',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Gender>($DirectoryPeopleTable.$convertergender);
  static const VerificationMeta _migrationMeta = const VerificationMeta(
    'migration',
  );
  @override
  late final GeneratedColumn<bool> migration = GeneratedColumn<bool>(
    'migration',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("migration" IN (0, 1))',
    ),
  );
  static const VerificationMeta _migrationBackgroundMeta =
      const VerificationMeta('migrationBackground');
  @override
  late final GeneratedColumn<String> migrationBackground =
      GeneratedColumn<String>(
        'migration_background',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    birthday,
    gender,
    migration,
    migrationBackground,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'all_people';
  @override
  VerificationContext validateIntegrity(
    Insertable<DirectoryPeopleData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('birthday')) {
      context.handle(
        _birthdayMeta,
        birthday.isAcceptableOrUnknown(data['birthday']!, _birthdayMeta),
      );
    } else if (isInserting) {
      context.missing(_birthdayMeta);
    }
    if (data.containsKey('migration')) {
      context.handle(
        _migrationMeta,
        migration.isAcceptableOrUnknown(data['migration']!, _migrationMeta),
      );
    } else if (isInserting) {
      context.missing(_migrationMeta);
    }
    if (data.containsKey('migration_background')) {
      context.handle(
        _migrationBackgroundMeta,
        migrationBackground.isAcceptableOrUnknown(
          data['migration_background']!,
          _migrationBackgroundMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_migrationBackgroundMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DirectoryPeopleData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DirectoryPeopleData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      birthday:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}birthday'],
          )!,
      gender: $DirectoryPeopleTable.$convertergender.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}gender'],
        )!,
      ),
      migration:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}migration'],
          )!,
      migrationBackground:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}migration_background'],
          )!,
    );
  }

  @override
  $DirectoryPeopleTable createAlias(String alias) {
    return $DirectoryPeopleTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Gender, String, String> $convertergender =
      const EnumNameConverter<Gender>(Gender.values);
}

class DirectoryPeopleData extends DataClass
    implements Insertable<DirectoryPeopleData> {
  final int id;
  final String name;
  final DateTime birthday;
  final Gender gender;
  final bool migration;
  final String migrationBackground;
  const DirectoryPeopleData({
    required this.id,
    required this.name,
    required this.birthday,
    required this.gender,
    required this.migration,
    required this.migrationBackground,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['birthday'] = Variable<DateTime>(birthday);
    {
      map['gender'] = Variable<String>(
        $DirectoryPeopleTable.$convertergender.toSql(gender),
      );
    }
    map['migration'] = Variable<bool>(migration);
    map['migration_background'] = Variable<String>(migrationBackground);
    return map;
  }

  DirectoryPeopleCompanion toCompanion(bool nullToAbsent) {
    return DirectoryPeopleCompanion(
      id: Value(id),
      name: Value(name),
      birthday: Value(birthday),
      gender: Value(gender),
      migration: Value(migration),
      migrationBackground: Value(migrationBackground),
    );
  }

  factory DirectoryPeopleData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DirectoryPeopleData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      birthday: serializer.fromJson<DateTime>(json['birthday']),
      gender: $DirectoryPeopleTable.$convertergender.fromJson(
        serializer.fromJson<String>(json['gender']),
      ),
      migration: serializer.fromJson<bool>(json['migration']),
      migrationBackground: serializer.fromJson<String>(
        json['migrationBackground'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'birthday': serializer.toJson<DateTime>(birthday),
      'gender': serializer.toJson<String>(
        $DirectoryPeopleTable.$convertergender.toJson(gender),
      ),
      'migration': serializer.toJson<bool>(migration),
      'migrationBackground': serializer.toJson<String>(migrationBackground),
    };
  }

  DirectoryPeopleData copyWith({
    int? id,
    String? name,
    DateTime? birthday,
    Gender? gender,
    bool? migration,
    String? migrationBackground,
  }) => DirectoryPeopleData(
    id: id ?? this.id,
    name: name ?? this.name,
    birthday: birthday ?? this.birthday,
    gender: gender ?? this.gender,
    migration: migration ?? this.migration,
    migrationBackground: migrationBackground ?? this.migrationBackground,
  );
  DirectoryPeopleData copyWithCompanion(DirectoryPeopleCompanion data) {
    return DirectoryPeopleData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      birthday: data.birthday.present ? data.birthday.value : this.birthday,
      gender: data.gender.present ? data.gender.value : this.gender,
      migration: data.migration.present ? data.migration.value : this.migration,
      migrationBackground:
          data.migrationBackground.present
              ? data.migrationBackground.value
              : this.migrationBackground,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DirectoryPeopleData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('birthday: $birthday, ')
          ..write('gender: $gender, ')
          ..write('migration: $migration, ')
          ..write('migrationBackground: $migrationBackground')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, birthday, gender, migration, migrationBackground);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DirectoryPeopleData &&
          other.id == this.id &&
          other.name == this.name &&
          other.birthday == this.birthday &&
          other.gender == this.gender &&
          other.migration == this.migration &&
          other.migrationBackground == this.migrationBackground);
}

class DirectoryPeopleCompanion extends UpdateCompanion<DirectoryPeopleData> {
  final Value<int> id;
  final Value<String> name;
  final Value<DateTime> birthday;
  final Value<Gender> gender;
  final Value<bool> migration;
  final Value<String> migrationBackground;
  const DirectoryPeopleCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.birthday = const Value.absent(),
    this.gender = const Value.absent(),
    this.migration = const Value.absent(),
    this.migrationBackground = const Value.absent(),
  });
  DirectoryPeopleCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required DateTime birthday,
    required Gender gender,
    required bool migration,
    required String migrationBackground,
  }) : name = Value(name),
       birthday = Value(birthday),
       gender = Value(gender),
       migration = Value(migration),
       migrationBackground = Value(migrationBackground);
  static Insertable<DirectoryPeopleData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<DateTime>? birthday,
    Expression<String>? gender,
    Expression<bool>? migration,
    Expression<String>? migrationBackground,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (birthday != null) 'birthday': birthday,
      if (gender != null) 'gender': gender,
      if (migration != null) 'migration': migration,
      if (migrationBackground != null)
        'migration_background': migrationBackground,
    });
  }

  DirectoryPeopleCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<DateTime>? birthday,
    Value<Gender>? gender,
    Value<bool>? migration,
    Value<String>? migrationBackground,
  }) {
    return DirectoryPeopleCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      birthday: birthday ?? this.birthday,
      gender: gender ?? this.gender,
      migration: migration ?? this.migration,
      migrationBackground: migrationBackground ?? this.migrationBackground,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (birthday.present) {
      map['birthday'] = Variable<DateTime>(birthday.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(
        $DirectoryPeopleTable.$convertergender.toSql(gender.value),
      );
    }
    if (migration.present) {
      map['migration'] = Variable<bool>(migration.value);
    }
    if (migrationBackground.present) {
      map['migration_background'] = Variable<String>(migrationBackground.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DirectoryPeopleCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('birthday: $birthday, ')
          ..write('gender: $gender, ')
          ..write('migration: $migration, ')
          ..write('migrationBackground: $migrationBackground')
          ..write(')'))
        .toString();
  }
}

class $DailyEntryTable extends DailyEntry
    with TableInfo<$DailyEntryTable, DailyEntryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyEntryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _recordIDMeta = const VerificationMeta(
    'recordID',
  );
  @override
  late final GeneratedColumn<int> recordID = GeneratedColumn<int>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _datesMeta = const VerificationMeta('dates');
  @override
  late final GeneratedColumn<DateTime> dates = GeneratedColumn<DateTime>(
    'dates',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES all_people (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Category, String> categroy =
      GeneratedColumn<String>(
        'categroy',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Category>($DailyEntryTable.$convertercategroy);
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    recordID,
    dates,
    id,
    categroy,
    description,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_entry';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyEntryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIDMeta,
        recordID.isAcceptableOrUnknown(data['record_id']!, _recordIDMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIDMeta);
    }
    if (data.containsKey('dates')) {
      context.handle(
        _datesMeta,
        dates.isAcceptableOrUnknown(data['dates']!, _datesMeta),
      );
    } else if (isInserting) {
      context.missing(_datesMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {recordID, dates, id};
  @override
  DailyEntryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyEntryData(
      recordID:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}record_id'],
          )!,
      dates:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}dates'],
          )!,
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      categroy: $DailyEntryTable.$convertercategroy.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}categroy'],
        )!,
      ),
      description:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}description'],
          )!,
    );
  }

  @override
  $DailyEntryTable createAlias(String alias) {
    return $DailyEntryTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Category, String, String> $convertercategroy =
      const EnumNameConverter<Category>(Category.values);
}

class DailyEntryData extends DataClass implements Insertable<DailyEntryData> {
  final int recordID;
  final DateTime dates;
  final int id;
  final Category categroy;
  final String description;
  const DailyEntryData({
    required this.recordID,
    required this.dates,
    required this.id,
    required this.categroy,
    required this.description,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['record_id'] = Variable<int>(recordID);
    map['dates'] = Variable<DateTime>(dates);
    map['id'] = Variable<int>(id);
    {
      map['categroy'] = Variable<String>(
        $DailyEntryTable.$convertercategroy.toSql(categroy),
      );
    }
    map['description'] = Variable<String>(description);
    return map;
  }

  DailyEntryCompanion toCompanion(bool nullToAbsent) {
    return DailyEntryCompanion(
      recordID: Value(recordID),
      dates: Value(dates),
      id: Value(id),
      categroy: Value(categroy),
      description: Value(description),
    );
  }

  factory DailyEntryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyEntryData(
      recordID: serializer.fromJson<int>(json['recordID']),
      dates: serializer.fromJson<DateTime>(json['dates']),
      id: serializer.fromJson<int>(json['id']),
      categroy: $DailyEntryTable.$convertercategroy.fromJson(
        serializer.fromJson<String>(json['categroy']),
      ),
      description: serializer.fromJson<String>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'recordID': serializer.toJson<int>(recordID),
      'dates': serializer.toJson<DateTime>(dates),
      'id': serializer.toJson<int>(id),
      'categroy': serializer.toJson<String>(
        $DailyEntryTable.$convertercategroy.toJson(categroy),
      ),
      'description': serializer.toJson<String>(description),
    };
  }

  DailyEntryData copyWith({
    int? recordID,
    DateTime? dates,
    int? id,
    Category? categroy,
    String? description,
  }) => DailyEntryData(
    recordID: recordID ?? this.recordID,
    dates: dates ?? this.dates,
    id: id ?? this.id,
    categroy: categroy ?? this.categroy,
    description: description ?? this.description,
  );
  DailyEntryData copyWithCompanion(DailyEntryCompanion data) {
    return DailyEntryData(
      recordID: data.recordID.present ? data.recordID.value : this.recordID,
      dates: data.dates.present ? data.dates.value : this.dates,
      id: data.id.present ? data.id.value : this.id,
      categroy: data.categroy.present ? data.categroy.value : this.categroy,
      description:
          data.description.present ? data.description.value : this.description,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyEntryData(')
          ..write('recordID: $recordID, ')
          ..write('dates: $dates, ')
          ..write('id: $id, ')
          ..write('categroy: $categroy, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(recordID, dates, id, categroy, description);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyEntryData &&
          other.recordID == this.recordID &&
          other.dates == this.dates &&
          other.id == this.id &&
          other.categroy == this.categroy &&
          other.description == this.description);
}

class DailyEntryCompanion extends UpdateCompanion<DailyEntryData> {
  final Value<int> recordID;
  final Value<DateTime> dates;
  final Value<int> id;
  final Value<Category> categroy;
  final Value<String> description;
  final Value<int> rowid;
  const DailyEntryCompanion({
    this.recordID = const Value.absent(),
    this.dates = const Value.absent(),
    this.id = const Value.absent(),
    this.categroy = const Value.absent(),
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyEntryCompanion.insert({
    required int recordID,
    required DateTime dates,
    required int id,
    required Category categroy,
    required String description,
    this.rowid = const Value.absent(),
  }) : recordID = Value(recordID),
       dates = Value(dates),
       id = Value(id),
       categroy = Value(categroy),
       description = Value(description);
  static Insertable<DailyEntryData> custom({
    Expression<int>? recordID,
    Expression<DateTime>? dates,
    Expression<int>? id,
    Expression<String>? categroy,
    Expression<String>? description,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (recordID != null) 'record_id': recordID,
      if (dates != null) 'dates': dates,
      if (id != null) 'id': id,
      if (categroy != null) 'categroy': categroy,
      if (description != null) 'description': description,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyEntryCompanion copyWith({
    Value<int>? recordID,
    Value<DateTime>? dates,
    Value<int>? id,
    Value<Category>? categroy,
    Value<String>? description,
    Value<int>? rowid,
  }) {
    return DailyEntryCompanion(
      recordID: recordID ?? this.recordID,
      dates: dates ?? this.dates,
      id: id ?? this.id,
      categroy: categroy ?? this.categroy,
      description: description ?? this.description,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (recordID.present) {
      map['record_id'] = Variable<int>(recordID.value);
    }
    if (dates.present) {
      map['dates'] = Variable<DateTime>(dates.value);
    }
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (categroy.present) {
      map['categroy'] = Variable<String>(
        $DailyEntryTable.$convertercategroy.toSql(categroy.value),
      );
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyEntryCompanion(')
          ..write('recordID: $recordID, ')
          ..write('dates: $dates, ')
          ..write('id: $id, ')
          ..write('categroy: $categroy, ')
          ..write('description: $description, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeeklyEntryTable extends WeeklyEntry
    with TableInfo<$WeeklyEntryTable, WeeklyEntryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeeklyEntryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _datesMeta = const VerificationMeta('dates');
  @override
  late final GeneratedColumn<DateTime> dates = GeneratedColumn<DateTime>(
    'dates',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _under_10Meta = const VerificationMeta(
    'under_10',
  );
  @override
  late final GeneratedColumn<int> under_10 = GeneratedColumn<int>(
    'under_10',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _age_10_13Meta = const VerificationMeta(
    'age_10_13',
  );
  @override
  late final GeneratedColumn<int> age_10_13 = GeneratedColumn<int>(
    'age_10_13',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _age_14_17Meta = const VerificationMeta(
    'age_14_17',
  );
  @override
  late final GeneratedColumn<int> age_14_17 = GeneratedColumn<int>(
    'age_14_17',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _age_18_24Meta = const VerificationMeta(
    'age_18_24',
  );
  @override
  late final GeneratedColumn<int> age_18_24 = GeneratedColumn<int>(
    'age_18_24',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _over_24Meta = const VerificationMeta(
    'over_24',
  );
  @override
  late final GeneratedColumn<int> over_24 = GeneratedColumn<int>(
    'over_24',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _allMMeta = const VerificationMeta('allM');
  @override
  late final GeneratedColumn<int> allM = GeneratedColumn<int>(
    'all_m',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _allFMeta = const VerificationMeta('allF');
  @override
  late final GeneratedColumn<int> allF = GeneratedColumn<int>(
    'all_f',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _allDMeta = const VerificationMeta('allD');
  @override
  late final GeneratedColumn<int> allD = GeneratedColumn<int>(
    'all_d',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openMaleMeta = const VerificationMeta(
    'openMale',
  );
  @override
  late final GeneratedColumn<int> openMale = GeneratedColumn<int>(
    'open_male',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openFemaleMeta = const VerificationMeta(
    'openFemale',
  );
  @override
  late final GeneratedColumn<int> openFemale = GeneratedColumn<int>(
    'open_female',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openDiverseMeta = const VerificationMeta(
    'openDiverse',
  );
  @override
  late final GeneratedColumn<int> openDiverse = GeneratedColumn<int>(
    'open_diverse',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _offersMaleMeta = const VerificationMeta(
    'offersMale',
  );
  @override
  late final GeneratedColumn<int> offersMale = GeneratedColumn<int>(
    'offers_male',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _offersFemaleMeta = const VerificationMeta(
    'offersFemale',
  );
  @override
  late final GeneratedColumn<int> offersFemale = GeneratedColumn<int>(
    'offers_female',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _offersDiverseMeta = const VerificationMeta(
    'offersDiverse',
  );
  @override
  late final GeneratedColumn<int> offersDiverse = GeneratedColumn<int>(
    'offers_diverse',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _migrationMaleMeta = const VerificationMeta(
    'migrationMale',
  );
  @override
  late final GeneratedColumn<int> migrationMale = GeneratedColumn<int>(
    'migration_male',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _migrationFemaleMeta = const VerificationMeta(
    'migrationFemale',
  );
  @override
  late final GeneratedColumn<int> migrationFemale = GeneratedColumn<int>(
    'migration_female',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _migrationDiverseMeta = const VerificationMeta(
    'migrationDiverse',
  );
  @override
  late final GeneratedColumn<int> migrationDiverse = GeneratedColumn<int>(
    'migration_diverse',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countableMeta = const VerificationMeta(
    'countable',
  );
  @override
  late final GeneratedColumn<bool> countable = GeneratedColumn<bool>(
    'countable',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("countable" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    dates,
    under_10,
    age_10_13,
    age_14_17,
    age_18_24,
    over_24,
    allM,
    allF,
    allD,
    openMale,
    openFemale,
    openDiverse,
    offersMale,
    offersFemale,
    offersDiverse,
    migrationMale,
    migrationFemale,
    migrationDiverse,
    countable,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weekly_entry';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeeklyEntryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('dates')) {
      context.handle(
        _datesMeta,
        dates.isAcceptableOrUnknown(data['dates']!, _datesMeta),
      );
    } else if (isInserting) {
      context.missing(_datesMeta);
    }
    if (data.containsKey('under_10')) {
      context.handle(
        _under_10Meta,
        under_10.isAcceptableOrUnknown(data['under_10']!, _under_10Meta),
      );
    } else if (isInserting) {
      context.missing(_under_10Meta);
    }
    if (data.containsKey('age_10_13')) {
      context.handle(
        _age_10_13Meta,
        age_10_13.isAcceptableOrUnknown(data['age_10_13']!, _age_10_13Meta),
      );
    } else if (isInserting) {
      context.missing(_age_10_13Meta);
    }
    if (data.containsKey('age_14_17')) {
      context.handle(
        _age_14_17Meta,
        age_14_17.isAcceptableOrUnknown(data['age_14_17']!, _age_14_17Meta),
      );
    } else if (isInserting) {
      context.missing(_age_14_17Meta);
    }
    if (data.containsKey('age_18_24')) {
      context.handle(
        _age_18_24Meta,
        age_18_24.isAcceptableOrUnknown(data['age_18_24']!, _age_18_24Meta),
      );
    } else if (isInserting) {
      context.missing(_age_18_24Meta);
    }
    if (data.containsKey('over_24')) {
      context.handle(
        _over_24Meta,
        over_24.isAcceptableOrUnknown(data['over_24']!, _over_24Meta),
      );
    } else if (isInserting) {
      context.missing(_over_24Meta);
    }
    if (data.containsKey('all_m')) {
      context.handle(
        _allMMeta,
        allM.isAcceptableOrUnknown(data['all_m']!, _allMMeta),
      );
    } else if (isInserting) {
      context.missing(_allMMeta);
    }
    if (data.containsKey('all_f')) {
      context.handle(
        _allFMeta,
        allF.isAcceptableOrUnknown(data['all_f']!, _allFMeta),
      );
    } else if (isInserting) {
      context.missing(_allFMeta);
    }
    if (data.containsKey('all_d')) {
      context.handle(
        _allDMeta,
        allD.isAcceptableOrUnknown(data['all_d']!, _allDMeta),
      );
    } else if (isInserting) {
      context.missing(_allDMeta);
    }
    if (data.containsKey('open_male')) {
      context.handle(
        _openMaleMeta,
        openMale.isAcceptableOrUnknown(data['open_male']!, _openMaleMeta),
      );
    } else if (isInserting) {
      context.missing(_openMaleMeta);
    }
    if (data.containsKey('open_female')) {
      context.handle(
        _openFemaleMeta,
        openFemale.isAcceptableOrUnknown(data['open_female']!, _openFemaleMeta),
      );
    } else if (isInserting) {
      context.missing(_openFemaleMeta);
    }
    if (data.containsKey('open_diverse')) {
      context.handle(
        _openDiverseMeta,
        openDiverse.isAcceptableOrUnknown(
          data['open_diverse']!,
          _openDiverseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_openDiverseMeta);
    }
    if (data.containsKey('offers_male')) {
      context.handle(
        _offersMaleMeta,
        offersMale.isAcceptableOrUnknown(data['offers_male']!, _offersMaleMeta),
      );
    } else if (isInserting) {
      context.missing(_offersMaleMeta);
    }
    if (data.containsKey('offers_female')) {
      context.handle(
        _offersFemaleMeta,
        offersFemale.isAcceptableOrUnknown(
          data['offers_female']!,
          _offersFemaleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_offersFemaleMeta);
    }
    if (data.containsKey('offers_diverse')) {
      context.handle(
        _offersDiverseMeta,
        offersDiverse.isAcceptableOrUnknown(
          data['offers_diverse']!,
          _offersDiverseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_offersDiverseMeta);
    }
    if (data.containsKey('migration_male')) {
      context.handle(
        _migrationMaleMeta,
        migrationMale.isAcceptableOrUnknown(
          data['migration_male']!,
          _migrationMaleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_migrationMaleMeta);
    }
    if (data.containsKey('migration_female')) {
      context.handle(
        _migrationFemaleMeta,
        migrationFemale.isAcceptableOrUnknown(
          data['migration_female']!,
          _migrationFemaleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_migrationFemaleMeta);
    }
    if (data.containsKey('migration_diverse')) {
      context.handle(
        _migrationDiverseMeta,
        migrationDiverse.isAcceptableOrUnknown(
          data['migration_diverse']!,
          _migrationDiverseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_migrationDiverseMeta);
    }
    if (data.containsKey('countable')) {
      context.handle(
        _countableMeta,
        countable.isAcceptableOrUnknown(data['countable']!, _countableMeta),
      );
    } else if (isInserting) {
      context.missing(_countableMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {dates};
  @override
  WeeklyEntryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeeklyEntryData(
      dates:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}dates'],
          )!,
      under_10:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}under_10'],
          )!,
      age_10_13:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}age_10_13'],
          )!,
      age_14_17:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}age_14_17'],
          )!,
      age_18_24:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}age_18_24'],
          )!,
      over_24:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}over_24'],
          )!,
      allM:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}all_m'],
          )!,
      allF:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}all_f'],
          )!,
      allD:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}all_d'],
          )!,
      openMale:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}open_male'],
          )!,
      openFemale:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}open_female'],
          )!,
      openDiverse:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}open_diverse'],
          )!,
      offersMale:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}offers_male'],
          )!,
      offersFemale:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}offers_female'],
          )!,
      offersDiverse:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}offers_diverse'],
          )!,
      migrationMale:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}migration_male'],
          )!,
      migrationFemale:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}migration_female'],
          )!,
      migrationDiverse:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}migration_diverse'],
          )!,
      countable:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}countable'],
          )!,
    );
  }

  @override
  $WeeklyEntryTable createAlias(String alias) {
    return $WeeklyEntryTable(attachedDatabase, alias);
  }
}

class WeeklyEntryData extends DataClass implements Insertable<WeeklyEntryData> {
  final DateTime dates;
  final int under_10;
  final int age_10_13;
  final int age_14_17;
  final int age_18_24;
  final int over_24;
  final int allM;
  final int allF;
  final int allD;
  final int openMale;
  final int openFemale;
  final int openDiverse;
  final int offersMale;
  final int offersFemale;
  final int offersDiverse;
  final int migrationMale;
  final int migrationFemale;
  final int migrationDiverse;
  final bool countable;
  const WeeklyEntryData({
    required this.dates,
    required this.under_10,
    required this.age_10_13,
    required this.age_14_17,
    required this.age_18_24,
    required this.over_24,
    required this.allM,
    required this.allF,
    required this.allD,
    required this.openMale,
    required this.openFemale,
    required this.openDiverse,
    required this.offersMale,
    required this.offersFemale,
    required this.offersDiverse,
    required this.migrationMale,
    required this.migrationFemale,
    required this.migrationDiverse,
    required this.countable,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['dates'] = Variable<DateTime>(dates);
    map['under_10'] = Variable<int>(under_10);
    map['age_10_13'] = Variable<int>(age_10_13);
    map['age_14_17'] = Variable<int>(age_14_17);
    map['age_18_24'] = Variable<int>(age_18_24);
    map['over_24'] = Variable<int>(over_24);
    map['all_m'] = Variable<int>(allM);
    map['all_f'] = Variable<int>(allF);
    map['all_d'] = Variable<int>(allD);
    map['open_male'] = Variable<int>(openMale);
    map['open_female'] = Variable<int>(openFemale);
    map['open_diverse'] = Variable<int>(openDiverse);
    map['offers_male'] = Variable<int>(offersMale);
    map['offers_female'] = Variable<int>(offersFemale);
    map['offers_diverse'] = Variable<int>(offersDiverse);
    map['migration_male'] = Variable<int>(migrationMale);
    map['migration_female'] = Variable<int>(migrationFemale);
    map['migration_diverse'] = Variable<int>(migrationDiverse);
    map['countable'] = Variable<bool>(countable);
    return map;
  }

  WeeklyEntryCompanion toCompanion(bool nullToAbsent) {
    return WeeklyEntryCompanion(
      dates: Value(dates),
      under_10: Value(under_10),
      age_10_13: Value(age_10_13),
      age_14_17: Value(age_14_17),
      age_18_24: Value(age_18_24),
      over_24: Value(over_24),
      allM: Value(allM),
      allF: Value(allF),
      allD: Value(allD),
      openMale: Value(openMale),
      openFemale: Value(openFemale),
      openDiverse: Value(openDiverse),
      offersMale: Value(offersMale),
      offersFemale: Value(offersFemale),
      offersDiverse: Value(offersDiverse),
      migrationMale: Value(migrationMale),
      migrationFemale: Value(migrationFemale),
      migrationDiverse: Value(migrationDiverse),
      countable: Value(countable),
    );
  }

  factory WeeklyEntryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeeklyEntryData(
      dates: serializer.fromJson<DateTime>(json['dates']),
      under_10: serializer.fromJson<int>(json['under_10']),
      age_10_13: serializer.fromJson<int>(json['age_10_13']),
      age_14_17: serializer.fromJson<int>(json['age_14_17']),
      age_18_24: serializer.fromJson<int>(json['age_18_24']),
      over_24: serializer.fromJson<int>(json['over_24']),
      allM: serializer.fromJson<int>(json['allM']),
      allF: serializer.fromJson<int>(json['allF']),
      allD: serializer.fromJson<int>(json['allD']),
      openMale: serializer.fromJson<int>(json['openMale']),
      openFemale: serializer.fromJson<int>(json['openFemale']),
      openDiverse: serializer.fromJson<int>(json['openDiverse']),
      offersMale: serializer.fromJson<int>(json['offersMale']),
      offersFemale: serializer.fromJson<int>(json['offersFemale']),
      offersDiverse: serializer.fromJson<int>(json['offersDiverse']),
      migrationMale: serializer.fromJson<int>(json['migrationMale']),
      migrationFemale: serializer.fromJson<int>(json['migrationFemale']),
      migrationDiverse: serializer.fromJson<int>(json['migrationDiverse']),
      countable: serializer.fromJson<bool>(json['countable']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dates': serializer.toJson<DateTime>(dates),
      'under_10': serializer.toJson<int>(under_10),
      'age_10_13': serializer.toJson<int>(age_10_13),
      'age_14_17': serializer.toJson<int>(age_14_17),
      'age_18_24': serializer.toJson<int>(age_18_24),
      'over_24': serializer.toJson<int>(over_24),
      'allM': serializer.toJson<int>(allM),
      'allF': serializer.toJson<int>(allF),
      'allD': serializer.toJson<int>(allD),
      'openMale': serializer.toJson<int>(openMale),
      'openFemale': serializer.toJson<int>(openFemale),
      'openDiverse': serializer.toJson<int>(openDiverse),
      'offersMale': serializer.toJson<int>(offersMale),
      'offersFemale': serializer.toJson<int>(offersFemale),
      'offersDiverse': serializer.toJson<int>(offersDiverse),
      'migrationMale': serializer.toJson<int>(migrationMale),
      'migrationFemale': serializer.toJson<int>(migrationFemale),
      'migrationDiverse': serializer.toJson<int>(migrationDiverse),
      'countable': serializer.toJson<bool>(countable),
    };
  }

  WeeklyEntryData copyWith({
    DateTime? dates,
    int? under_10,
    int? age_10_13,
    int? age_14_17,
    int? age_18_24,
    int? over_24,
    int? allM,
    int? allF,
    int? allD,
    int? openMale,
    int? openFemale,
    int? openDiverse,
    int? offersMale,
    int? offersFemale,
    int? offersDiverse,
    int? migrationMale,
    int? migrationFemale,
    int? migrationDiverse,
    bool? countable,
  }) => WeeklyEntryData(
    dates: dates ?? this.dates,
    under_10: under_10 ?? this.under_10,
    age_10_13: age_10_13 ?? this.age_10_13,
    age_14_17: age_14_17 ?? this.age_14_17,
    age_18_24: age_18_24 ?? this.age_18_24,
    over_24: over_24 ?? this.over_24,
    allM: allM ?? this.allM,
    allF: allF ?? this.allF,
    allD: allD ?? this.allD,
    openMale: openMale ?? this.openMale,
    openFemale: openFemale ?? this.openFemale,
    openDiverse: openDiverse ?? this.openDiverse,
    offersMale: offersMale ?? this.offersMale,
    offersFemale: offersFemale ?? this.offersFemale,
    offersDiverse: offersDiverse ?? this.offersDiverse,
    migrationMale: migrationMale ?? this.migrationMale,
    migrationFemale: migrationFemale ?? this.migrationFemale,
    migrationDiverse: migrationDiverse ?? this.migrationDiverse,
    countable: countable ?? this.countable,
  );
  WeeklyEntryData copyWithCompanion(WeeklyEntryCompanion data) {
    return WeeklyEntryData(
      dates: data.dates.present ? data.dates.value : this.dates,
      under_10: data.under_10.present ? data.under_10.value : this.under_10,
      age_10_13: data.age_10_13.present ? data.age_10_13.value : this.age_10_13,
      age_14_17: data.age_14_17.present ? data.age_14_17.value : this.age_14_17,
      age_18_24: data.age_18_24.present ? data.age_18_24.value : this.age_18_24,
      over_24: data.over_24.present ? data.over_24.value : this.over_24,
      allM: data.allM.present ? data.allM.value : this.allM,
      allF: data.allF.present ? data.allF.value : this.allF,
      allD: data.allD.present ? data.allD.value : this.allD,
      openMale: data.openMale.present ? data.openMale.value : this.openMale,
      openFemale:
          data.openFemale.present ? data.openFemale.value : this.openFemale,
      openDiverse:
          data.openDiverse.present ? data.openDiverse.value : this.openDiverse,
      offersMale:
          data.offersMale.present ? data.offersMale.value : this.offersMale,
      offersFemale:
          data.offersFemale.present
              ? data.offersFemale.value
              : this.offersFemale,
      offersDiverse:
          data.offersDiverse.present
              ? data.offersDiverse.value
              : this.offersDiverse,
      migrationMale:
          data.migrationMale.present
              ? data.migrationMale.value
              : this.migrationMale,
      migrationFemale:
          data.migrationFemale.present
              ? data.migrationFemale.value
              : this.migrationFemale,
      migrationDiverse:
          data.migrationDiverse.present
              ? data.migrationDiverse.value
              : this.migrationDiverse,
      countable: data.countable.present ? data.countable.value : this.countable,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeeklyEntryData(')
          ..write('dates: $dates, ')
          ..write('under_10: $under_10, ')
          ..write('age_10_13: $age_10_13, ')
          ..write('age_14_17: $age_14_17, ')
          ..write('age_18_24: $age_18_24, ')
          ..write('over_24: $over_24, ')
          ..write('allM: $allM, ')
          ..write('allF: $allF, ')
          ..write('allD: $allD, ')
          ..write('openMale: $openMale, ')
          ..write('openFemale: $openFemale, ')
          ..write('openDiverse: $openDiverse, ')
          ..write('offersMale: $offersMale, ')
          ..write('offersFemale: $offersFemale, ')
          ..write('offersDiverse: $offersDiverse, ')
          ..write('migrationMale: $migrationMale, ')
          ..write('migrationFemale: $migrationFemale, ')
          ..write('migrationDiverse: $migrationDiverse, ')
          ..write('countable: $countable')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    dates,
    under_10,
    age_10_13,
    age_14_17,
    age_18_24,
    over_24,
    allM,
    allF,
    allD,
    openMale,
    openFemale,
    openDiverse,
    offersMale,
    offersFemale,
    offersDiverse,
    migrationMale,
    migrationFemale,
    migrationDiverse,
    countable,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeeklyEntryData &&
          other.dates == this.dates &&
          other.under_10 == this.under_10 &&
          other.age_10_13 == this.age_10_13 &&
          other.age_14_17 == this.age_14_17 &&
          other.age_18_24 == this.age_18_24 &&
          other.over_24 == this.over_24 &&
          other.allM == this.allM &&
          other.allF == this.allF &&
          other.allD == this.allD &&
          other.openMale == this.openMale &&
          other.openFemale == this.openFemale &&
          other.openDiverse == this.openDiverse &&
          other.offersMale == this.offersMale &&
          other.offersFemale == this.offersFemale &&
          other.offersDiverse == this.offersDiverse &&
          other.migrationMale == this.migrationMale &&
          other.migrationFemale == this.migrationFemale &&
          other.migrationDiverse == this.migrationDiverse &&
          other.countable == this.countable);
}

class WeeklyEntryCompanion extends UpdateCompanion<WeeklyEntryData> {
  final Value<DateTime> dates;
  final Value<int> under_10;
  final Value<int> age_10_13;
  final Value<int> age_14_17;
  final Value<int> age_18_24;
  final Value<int> over_24;
  final Value<int> allM;
  final Value<int> allF;
  final Value<int> allD;
  final Value<int> openMale;
  final Value<int> openFemale;
  final Value<int> openDiverse;
  final Value<int> offersMale;
  final Value<int> offersFemale;
  final Value<int> offersDiverse;
  final Value<int> migrationMale;
  final Value<int> migrationFemale;
  final Value<int> migrationDiverse;
  final Value<bool> countable;
  final Value<int> rowid;
  const WeeklyEntryCompanion({
    this.dates = const Value.absent(),
    this.under_10 = const Value.absent(),
    this.age_10_13 = const Value.absent(),
    this.age_14_17 = const Value.absent(),
    this.age_18_24 = const Value.absent(),
    this.over_24 = const Value.absent(),
    this.allM = const Value.absent(),
    this.allF = const Value.absent(),
    this.allD = const Value.absent(),
    this.openMale = const Value.absent(),
    this.openFemale = const Value.absent(),
    this.openDiverse = const Value.absent(),
    this.offersMale = const Value.absent(),
    this.offersFemale = const Value.absent(),
    this.offersDiverse = const Value.absent(),
    this.migrationMale = const Value.absent(),
    this.migrationFemale = const Value.absent(),
    this.migrationDiverse = const Value.absent(),
    this.countable = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeeklyEntryCompanion.insert({
    required DateTime dates,
    required int under_10,
    required int age_10_13,
    required int age_14_17,
    required int age_18_24,
    required int over_24,
    required int allM,
    required int allF,
    required int allD,
    required int openMale,
    required int openFemale,
    required int openDiverse,
    required int offersMale,
    required int offersFemale,
    required int offersDiverse,
    required int migrationMale,
    required int migrationFemale,
    required int migrationDiverse,
    required bool countable,
    this.rowid = const Value.absent(),
  }) : dates = Value(dates),
       under_10 = Value(under_10),
       age_10_13 = Value(age_10_13),
       age_14_17 = Value(age_14_17),
       age_18_24 = Value(age_18_24),
       over_24 = Value(over_24),
       allM = Value(allM),
       allF = Value(allF),
       allD = Value(allD),
       openMale = Value(openMale),
       openFemale = Value(openFemale),
       openDiverse = Value(openDiverse),
       offersMale = Value(offersMale),
       offersFemale = Value(offersFemale),
       offersDiverse = Value(offersDiverse),
       migrationMale = Value(migrationMale),
       migrationFemale = Value(migrationFemale),
       migrationDiverse = Value(migrationDiverse),
       countable = Value(countable);
  static Insertable<WeeklyEntryData> custom({
    Expression<DateTime>? dates,
    Expression<int>? under_10,
    Expression<int>? age_10_13,
    Expression<int>? age_14_17,
    Expression<int>? age_18_24,
    Expression<int>? over_24,
    Expression<int>? allM,
    Expression<int>? allF,
    Expression<int>? allD,
    Expression<int>? openMale,
    Expression<int>? openFemale,
    Expression<int>? openDiverse,
    Expression<int>? offersMale,
    Expression<int>? offersFemale,
    Expression<int>? offersDiverse,
    Expression<int>? migrationMale,
    Expression<int>? migrationFemale,
    Expression<int>? migrationDiverse,
    Expression<bool>? countable,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (dates != null) 'dates': dates,
      if (under_10 != null) 'under_10': under_10,
      if (age_10_13 != null) 'age_10_13': age_10_13,
      if (age_14_17 != null) 'age_14_17': age_14_17,
      if (age_18_24 != null) 'age_18_24': age_18_24,
      if (over_24 != null) 'over_24': over_24,
      if (allM != null) 'all_m': allM,
      if (allF != null) 'all_f': allF,
      if (allD != null) 'all_d': allD,
      if (openMale != null) 'open_male': openMale,
      if (openFemale != null) 'open_female': openFemale,
      if (openDiverse != null) 'open_diverse': openDiverse,
      if (offersMale != null) 'offers_male': offersMale,
      if (offersFemale != null) 'offers_female': offersFemale,
      if (offersDiverse != null) 'offers_diverse': offersDiverse,
      if (migrationMale != null) 'migration_male': migrationMale,
      if (migrationFemale != null) 'migration_female': migrationFemale,
      if (migrationDiverse != null) 'migration_diverse': migrationDiverse,
      if (countable != null) 'countable': countable,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeeklyEntryCompanion copyWith({
    Value<DateTime>? dates,
    Value<int>? under_10,
    Value<int>? age_10_13,
    Value<int>? age_14_17,
    Value<int>? age_18_24,
    Value<int>? over_24,
    Value<int>? allM,
    Value<int>? allF,
    Value<int>? allD,
    Value<int>? openMale,
    Value<int>? openFemale,
    Value<int>? openDiverse,
    Value<int>? offersMale,
    Value<int>? offersFemale,
    Value<int>? offersDiverse,
    Value<int>? migrationMale,
    Value<int>? migrationFemale,
    Value<int>? migrationDiverse,
    Value<bool>? countable,
    Value<int>? rowid,
  }) {
    return WeeklyEntryCompanion(
      dates: dates ?? this.dates,
      under_10: under_10 ?? this.under_10,
      age_10_13: age_10_13 ?? this.age_10_13,
      age_14_17: age_14_17 ?? this.age_14_17,
      age_18_24: age_18_24 ?? this.age_18_24,
      over_24: over_24 ?? this.over_24,
      allM: allM ?? this.allM,
      allF: allF ?? this.allF,
      allD: allD ?? this.allD,
      openMale: openMale ?? this.openMale,
      openFemale: openFemale ?? this.openFemale,
      openDiverse: openDiverse ?? this.openDiverse,
      offersMale: offersMale ?? this.offersMale,
      offersFemale: offersFemale ?? this.offersFemale,
      offersDiverse: offersDiverse ?? this.offersDiverse,
      migrationMale: migrationMale ?? this.migrationMale,
      migrationFemale: migrationFemale ?? this.migrationFemale,
      migrationDiverse: migrationDiverse ?? this.migrationDiverse,
      countable: countable ?? this.countable,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dates.present) {
      map['dates'] = Variable<DateTime>(dates.value);
    }
    if (under_10.present) {
      map['under_10'] = Variable<int>(under_10.value);
    }
    if (age_10_13.present) {
      map['age_10_13'] = Variable<int>(age_10_13.value);
    }
    if (age_14_17.present) {
      map['age_14_17'] = Variable<int>(age_14_17.value);
    }
    if (age_18_24.present) {
      map['age_18_24'] = Variable<int>(age_18_24.value);
    }
    if (over_24.present) {
      map['over_24'] = Variable<int>(over_24.value);
    }
    if (allM.present) {
      map['all_m'] = Variable<int>(allM.value);
    }
    if (allF.present) {
      map['all_f'] = Variable<int>(allF.value);
    }
    if (allD.present) {
      map['all_d'] = Variable<int>(allD.value);
    }
    if (openMale.present) {
      map['open_male'] = Variable<int>(openMale.value);
    }
    if (openFemale.present) {
      map['open_female'] = Variable<int>(openFemale.value);
    }
    if (openDiverse.present) {
      map['open_diverse'] = Variable<int>(openDiverse.value);
    }
    if (offersMale.present) {
      map['offers_male'] = Variable<int>(offersMale.value);
    }
    if (offersFemale.present) {
      map['offers_female'] = Variable<int>(offersFemale.value);
    }
    if (offersDiverse.present) {
      map['offers_diverse'] = Variable<int>(offersDiverse.value);
    }
    if (migrationMale.present) {
      map['migration_male'] = Variable<int>(migrationMale.value);
    }
    if (migrationFemale.present) {
      map['migration_female'] = Variable<int>(migrationFemale.value);
    }
    if (migrationDiverse.present) {
      map['migration_diverse'] = Variable<int>(migrationDiverse.value);
    }
    if (countable.present) {
      map['countable'] = Variable<bool>(countable.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeeklyEntryCompanion(')
          ..write('dates: $dates, ')
          ..write('under_10: $under_10, ')
          ..write('age_10_13: $age_10_13, ')
          ..write('age_14_17: $age_14_17, ')
          ..write('age_18_24: $age_18_24, ')
          ..write('over_24: $over_24, ')
          ..write('allM: $allM, ')
          ..write('allF: $allF, ')
          ..write('allD: $allD, ')
          ..write('openMale: $openMale, ')
          ..write('openFemale: $openFemale, ')
          ..write('openDiverse: $openDiverse, ')
          ..write('offersMale: $offersMale, ')
          ..write('offersFemale: $offersFemale, ')
          ..write('offersDiverse: $offersDiverse, ')
          ..write('migrationMale: $migrationMale, ')
          ..write('migrationFemale: $migrationFemale, ')
          ..write('migrationDiverse: $migrationDiverse, ')
          ..write('countable: $countable, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DirectoryPeopleTable directoryPeople = $DirectoryPeopleTable(
    this,
  );
  late final $DailyEntryTable dailyEntry = $DailyEntryTable(this);
  late final $WeeklyEntryTable weeklyEntry = $WeeklyEntryTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    directoryPeople,
    dailyEntry,
    weeklyEntry,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$DirectoryPeopleTableCreateCompanionBuilder =
    DirectoryPeopleCompanion Function({
      Value<int> id,
      required String name,
      required DateTime birthday,
      required Gender gender,
      required bool migration,
      required String migrationBackground,
    });
typedef $$DirectoryPeopleTableUpdateCompanionBuilder =
    DirectoryPeopleCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<DateTime> birthday,
      Value<Gender> gender,
      Value<bool> migration,
      Value<String> migrationBackground,
    });

final class $$DirectoryPeopleTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $DirectoryPeopleTable,
          DirectoryPeopleData
        > {
  $$DirectoryPeopleTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$DailyEntryTable, List<DailyEntryData>>
  _dailyEntryRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.dailyEntry,
    aliasName: $_aliasNameGenerator(db.directoryPeople.id, db.dailyEntry.id),
  );

  $$DailyEntryTableProcessedTableManager get dailyEntryRefs {
    final manager = $$DailyEntryTableTableManager(
      $_db,
      $_db.dailyEntry,
    ).filter((f) => f.id.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_dailyEntryRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DirectoryPeopleTableFilterComposer
    extends Composer<_$AppDatabase, $DirectoryPeopleTable> {
  $$DirectoryPeopleTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get birthday => $composableBuilder(
    column: $table.birthday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Gender, Gender, String> get gender =>
      $composableBuilder(
        column: $table.gender,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get migration => $composableBuilder(
    column: $table.migration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get migrationBackground => $composableBuilder(
    column: $table.migrationBackground,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> dailyEntryRefs(
    Expression<bool> Function($$DailyEntryTableFilterComposer f) f,
  ) {
    final $$DailyEntryTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dailyEntry,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DailyEntryTableFilterComposer(
            $db: $db,
            $table: $db.dailyEntry,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DirectoryPeopleTableOrderingComposer
    extends Composer<_$AppDatabase, $DirectoryPeopleTable> {
  $$DirectoryPeopleTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get birthday => $composableBuilder(
    column: $table.birthday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get migration => $composableBuilder(
    column: $table.migration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get migrationBackground => $composableBuilder(
    column: $table.migrationBackground,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DirectoryPeopleTableAnnotationComposer
    extends Composer<_$AppDatabase, $DirectoryPeopleTable> {
  $$DirectoryPeopleTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get birthday =>
      $composableBuilder(column: $table.birthday, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Gender, String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<bool> get migration =>
      $composableBuilder(column: $table.migration, builder: (column) => column);

  GeneratedColumn<String> get migrationBackground => $composableBuilder(
    column: $table.migrationBackground,
    builder: (column) => column,
  );

  Expression<T> dailyEntryRefs<T extends Object>(
    Expression<T> Function($$DailyEntryTableAnnotationComposer a) f,
  ) {
    final $$DailyEntryTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dailyEntry,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DailyEntryTableAnnotationComposer(
            $db: $db,
            $table: $db.dailyEntry,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DirectoryPeopleTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DirectoryPeopleTable,
          DirectoryPeopleData,
          $$DirectoryPeopleTableFilterComposer,
          $$DirectoryPeopleTableOrderingComposer,
          $$DirectoryPeopleTableAnnotationComposer,
          $$DirectoryPeopleTableCreateCompanionBuilder,
          $$DirectoryPeopleTableUpdateCompanionBuilder,
          (DirectoryPeopleData, $$DirectoryPeopleTableReferences),
          DirectoryPeopleData,
          PrefetchHooks Function({bool dailyEntryRefs})
        > {
  $$DirectoryPeopleTableTableManager(
    _$AppDatabase db,
    $DirectoryPeopleTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () =>
                  $$DirectoryPeopleTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$DirectoryPeopleTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$DirectoryPeopleTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> birthday = const Value.absent(),
                Value<Gender> gender = const Value.absent(),
                Value<bool> migration = const Value.absent(),
                Value<String> migrationBackground = const Value.absent(),
              }) => DirectoryPeopleCompanion(
                id: id,
                name: name,
                birthday: birthday,
                gender: gender,
                migration: migration,
                migrationBackground: migrationBackground,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required DateTime birthday,
                required Gender gender,
                required bool migration,
                required String migrationBackground,
              }) => DirectoryPeopleCompanion.insert(
                id: id,
                name: name,
                birthday: birthday,
                gender: gender,
                migration: migration,
                migrationBackground: migrationBackground,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$DirectoryPeopleTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({dailyEntryRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (dailyEntryRefs) db.dailyEntry],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (dailyEntryRefs)
                    await $_getPrefetchedData<
                      DirectoryPeopleData,
                      $DirectoryPeopleTable,
                      DailyEntryData
                    >(
                      currentTable: table,
                      referencedTable: $$DirectoryPeopleTableReferences
                          ._dailyEntryRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$DirectoryPeopleTableReferences(
                                db,
                                table,
                                p0,
                              ).dailyEntryRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) =>
                              referencedItems.where((e) => e.id == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$DirectoryPeopleTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DirectoryPeopleTable,
      DirectoryPeopleData,
      $$DirectoryPeopleTableFilterComposer,
      $$DirectoryPeopleTableOrderingComposer,
      $$DirectoryPeopleTableAnnotationComposer,
      $$DirectoryPeopleTableCreateCompanionBuilder,
      $$DirectoryPeopleTableUpdateCompanionBuilder,
      (DirectoryPeopleData, $$DirectoryPeopleTableReferences),
      DirectoryPeopleData,
      PrefetchHooks Function({bool dailyEntryRefs})
    >;
typedef $$DailyEntryTableCreateCompanionBuilder =
    DailyEntryCompanion Function({
      required int recordID,
      required DateTime dates,
      required int id,
      required Category categroy,
      required String description,
      Value<int> rowid,
    });
typedef $$DailyEntryTableUpdateCompanionBuilder =
    DailyEntryCompanion Function({
      Value<int> recordID,
      Value<DateTime> dates,
      Value<int> id,
      Value<Category> categroy,
      Value<String> description,
      Value<int> rowid,
    });

final class $$DailyEntryTableReferences
    extends BaseReferences<_$AppDatabase, $DailyEntryTable, DailyEntryData> {
  $$DailyEntryTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DirectoryPeopleTable _idTable(_$AppDatabase db) =>
      db.directoryPeople.createAlias(
        $_aliasNameGenerator(db.dailyEntry.id, db.directoryPeople.id),
      );

  $$DirectoryPeopleTableProcessedTableManager get id {
    final $_column = $_itemColumn<int>('id')!;

    final manager = $$DirectoryPeopleTableTableManager(
      $_db,
      $_db.directoryPeople,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_idTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DailyEntryTableFilterComposer
    extends Composer<_$AppDatabase, $DailyEntryTable> {
  $$DailyEntryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get recordID => $composableBuilder(
    column: $table.recordID,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dates => $composableBuilder(
    column: $table.dates,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Category, Category, String> get categroy =>
      $composableBuilder(
        column: $table.categroy,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  $$DirectoryPeopleTableFilterComposer get id {
    final $$DirectoryPeopleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.directoryPeople,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DirectoryPeopleTableFilterComposer(
            $db: $db,
            $table: $db.directoryPeople,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DailyEntryTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyEntryTable> {
  $$DailyEntryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get recordID => $composableBuilder(
    column: $table.recordID,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dates => $composableBuilder(
    column: $table.dates,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categroy => $composableBuilder(
    column: $table.categroy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  $$DirectoryPeopleTableOrderingComposer get id {
    final $$DirectoryPeopleTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.directoryPeople,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DirectoryPeopleTableOrderingComposer(
            $db: $db,
            $table: $db.directoryPeople,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DailyEntryTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyEntryTable> {
  $$DailyEntryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get recordID =>
      $composableBuilder(column: $table.recordID, builder: (column) => column);

  GeneratedColumn<DateTime> get dates =>
      $composableBuilder(column: $table.dates, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Category, String> get categroy =>
      $composableBuilder(column: $table.categroy, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  $$DirectoryPeopleTableAnnotationComposer get id {
    final $$DirectoryPeopleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.directoryPeople,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DirectoryPeopleTableAnnotationComposer(
            $db: $db,
            $table: $db.directoryPeople,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DailyEntryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyEntryTable,
          DailyEntryData,
          $$DailyEntryTableFilterComposer,
          $$DailyEntryTableOrderingComposer,
          $$DailyEntryTableAnnotationComposer,
          $$DailyEntryTableCreateCompanionBuilder,
          $$DailyEntryTableUpdateCompanionBuilder,
          (DailyEntryData, $$DailyEntryTableReferences),
          DailyEntryData,
          PrefetchHooks Function({bool id})
        > {
  $$DailyEntryTableTableManager(_$AppDatabase db, $DailyEntryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$DailyEntryTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$DailyEntryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$DailyEntryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> recordID = const Value.absent(),
                Value<DateTime> dates = const Value.absent(),
                Value<int> id = const Value.absent(),
                Value<Category> categroy = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyEntryCompanion(
                recordID: recordID,
                dates: dates,
                id: id,
                categroy: categroy,
                description: description,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int recordID,
                required DateTime dates,
                required int id,
                required Category categroy,
                required String description,
                Value<int> rowid = const Value.absent(),
              }) => DailyEntryCompanion.insert(
                recordID: recordID,
                dates: dates,
                id: id,
                categroy: categroy,
                description: description,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$DailyEntryTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({id = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                T extends TableManagerState<
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic
                >
              >(state) {
                if (id) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.id,
                            referencedTable: $$DailyEntryTableReferences
                                ._idTable(db),
                            referencedColumn:
                                $$DailyEntryTableReferences._idTable(db).id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DailyEntryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyEntryTable,
      DailyEntryData,
      $$DailyEntryTableFilterComposer,
      $$DailyEntryTableOrderingComposer,
      $$DailyEntryTableAnnotationComposer,
      $$DailyEntryTableCreateCompanionBuilder,
      $$DailyEntryTableUpdateCompanionBuilder,
      (DailyEntryData, $$DailyEntryTableReferences),
      DailyEntryData,
      PrefetchHooks Function({bool id})
    >;
typedef $$WeeklyEntryTableCreateCompanionBuilder =
    WeeklyEntryCompanion Function({
      required DateTime dates,
      required int under_10,
      required int age_10_13,
      required int age_14_17,
      required int age_18_24,
      required int over_24,
      required int allM,
      required int allF,
      required int allD,
      required int openMale,
      required int openFemale,
      required int openDiverse,
      required int offersMale,
      required int offersFemale,
      required int offersDiverse,
      required int migrationMale,
      required int migrationFemale,
      required int migrationDiverse,
      required bool countable,
      Value<int> rowid,
    });
typedef $$WeeklyEntryTableUpdateCompanionBuilder =
    WeeklyEntryCompanion Function({
      Value<DateTime> dates,
      Value<int> under_10,
      Value<int> age_10_13,
      Value<int> age_14_17,
      Value<int> age_18_24,
      Value<int> over_24,
      Value<int> allM,
      Value<int> allF,
      Value<int> allD,
      Value<int> openMale,
      Value<int> openFemale,
      Value<int> openDiverse,
      Value<int> offersMale,
      Value<int> offersFemale,
      Value<int> offersDiverse,
      Value<int> migrationMale,
      Value<int> migrationFemale,
      Value<int> migrationDiverse,
      Value<bool> countable,
      Value<int> rowid,
    });

class $$WeeklyEntryTableFilterComposer
    extends Composer<_$AppDatabase, $WeeklyEntryTable> {
  $$WeeklyEntryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get dates => $composableBuilder(
    column: $table.dates,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get under_10 => $composableBuilder(
    column: $table.under_10,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get age_10_13 => $composableBuilder(
    column: $table.age_10_13,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get age_14_17 => $composableBuilder(
    column: $table.age_14_17,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get age_18_24 => $composableBuilder(
    column: $table.age_18_24,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get over_24 => $composableBuilder(
    column: $table.over_24,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get allM => $composableBuilder(
    column: $table.allM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get allF => $composableBuilder(
    column: $table.allF,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get allD => $composableBuilder(
    column: $table.allD,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get openMale => $composableBuilder(
    column: $table.openMale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get openFemale => $composableBuilder(
    column: $table.openFemale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get openDiverse => $composableBuilder(
    column: $table.openDiverse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get offersMale => $composableBuilder(
    column: $table.offersMale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get offersFemale => $composableBuilder(
    column: $table.offersFemale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get offersDiverse => $composableBuilder(
    column: $table.offersDiverse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get migrationMale => $composableBuilder(
    column: $table.migrationMale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get migrationFemale => $composableBuilder(
    column: $table.migrationFemale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get migrationDiverse => $composableBuilder(
    column: $table.migrationDiverse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get countable => $composableBuilder(
    column: $table.countable,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeeklyEntryTableOrderingComposer
    extends Composer<_$AppDatabase, $WeeklyEntryTable> {
  $$WeeklyEntryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get dates => $composableBuilder(
    column: $table.dates,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get under_10 => $composableBuilder(
    column: $table.under_10,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get age_10_13 => $composableBuilder(
    column: $table.age_10_13,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get age_14_17 => $composableBuilder(
    column: $table.age_14_17,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get age_18_24 => $composableBuilder(
    column: $table.age_18_24,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get over_24 => $composableBuilder(
    column: $table.over_24,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get allM => $composableBuilder(
    column: $table.allM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get allF => $composableBuilder(
    column: $table.allF,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get allD => $composableBuilder(
    column: $table.allD,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get openMale => $composableBuilder(
    column: $table.openMale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get openFemale => $composableBuilder(
    column: $table.openFemale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get openDiverse => $composableBuilder(
    column: $table.openDiverse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get offersMale => $composableBuilder(
    column: $table.offersMale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get offersFemale => $composableBuilder(
    column: $table.offersFemale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get offersDiverse => $composableBuilder(
    column: $table.offersDiverse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get migrationMale => $composableBuilder(
    column: $table.migrationMale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get migrationFemale => $composableBuilder(
    column: $table.migrationFemale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get migrationDiverse => $composableBuilder(
    column: $table.migrationDiverse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get countable => $composableBuilder(
    column: $table.countable,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeeklyEntryTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeeklyEntryTable> {
  $$WeeklyEntryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get dates =>
      $composableBuilder(column: $table.dates, builder: (column) => column);

  GeneratedColumn<int> get under_10 =>
      $composableBuilder(column: $table.under_10, builder: (column) => column);

  GeneratedColumn<int> get age_10_13 =>
      $composableBuilder(column: $table.age_10_13, builder: (column) => column);

  GeneratedColumn<int> get age_14_17 =>
      $composableBuilder(column: $table.age_14_17, builder: (column) => column);

  GeneratedColumn<int> get age_18_24 =>
      $composableBuilder(column: $table.age_18_24, builder: (column) => column);

  GeneratedColumn<int> get over_24 =>
      $composableBuilder(column: $table.over_24, builder: (column) => column);

  GeneratedColumn<int> get allM =>
      $composableBuilder(column: $table.allM, builder: (column) => column);

  GeneratedColumn<int> get allF =>
      $composableBuilder(column: $table.allF, builder: (column) => column);

  GeneratedColumn<int> get allD =>
      $composableBuilder(column: $table.allD, builder: (column) => column);

  GeneratedColumn<int> get openMale =>
      $composableBuilder(column: $table.openMale, builder: (column) => column);

  GeneratedColumn<int> get openFemale => $composableBuilder(
    column: $table.openFemale,
    builder: (column) => column,
  );

  GeneratedColumn<int> get openDiverse => $composableBuilder(
    column: $table.openDiverse,
    builder: (column) => column,
  );

  GeneratedColumn<int> get offersMale => $composableBuilder(
    column: $table.offersMale,
    builder: (column) => column,
  );

  GeneratedColumn<int> get offersFemale => $composableBuilder(
    column: $table.offersFemale,
    builder: (column) => column,
  );

  GeneratedColumn<int> get offersDiverse => $composableBuilder(
    column: $table.offersDiverse,
    builder: (column) => column,
  );

  GeneratedColumn<int> get migrationMale => $composableBuilder(
    column: $table.migrationMale,
    builder: (column) => column,
  );

  GeneratedColumn<int> get migrationFemale => $composableBuilder(
    column: $table.migrationFemale,
    builder: (column) => column,
  );

  GeneratedColumn<int> get migrationDiverse => $composableBuilder(
    column: $table.migrationDiverse,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get countable =>
      $composableBuilder(column: $table.countable, builder: (column) => column);
}

class $$WeeklyEntryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeeklyEntryTable,
          WeeklyEntryData,
          $$WeeklyEntryTableFilterComposer,
          $$WeeklyEntryTableOrderingComposer,
          $$WeeklyEntryTableAnnotationComposer,
          $$WeeklyEntryTableCreateCompanionBuilder,
          $$WeeklyEntryTableUpdateCompanionBuilder,
          (
            WeeklyEntryData,
            BaseReferences<_$AppDatabase, $WeeklyEntryTable, WeeklyEntryData>,
          ),
          WeeklyEntryData,
          PrefetchHooks Function()
        > {
  $$WeeklyEntryTableTableManager(_$AppDatabase db, $WeeklyEntryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$WeeklyEntryTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$WeeklyEntryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$WeeklyEntryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> dates = const Value.absent(),
                Value<int> under_10 = const Value.absent(),
                Value<int> age_10_13 = const Value.absent(),
                Value<int> age_14_17 = const Value.absent(),
                Value<int> age_18_24 = const Value.absent(),
                Value<int> over_24 = const Value.absent(),
                Value<int> allM = const Value.absent(),
                Value<int> allF = const Value.absent(),
                Value<int> allD = const Value.absent(),
                Value<int> openMale = const Value.absent(),
                Value<int> openFemale = const Value.absent(),
                Value<int> openDiverse = const Value.absent(),
                Value<int> offersMale = const Value.absent(),
                Value<int> offersFemale = const Value.absent(),
                Value<int> offersDiverse = const Value.absent(),
                Value<int> migrationMale = const Value.absent(),
                Value<int> migrationFemale = const Value.absent(),
                Value<int> migrationDiverse = const Value.absent(),
                Value<bool> countable = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeeklyEntryCompanion(
                dates: dates,
                under_10: under_10,
                age_10_13: age_10_13,
                age_14_17: age_14_17,
                age_18_24: age_18_24,
                over_24: over_24,
                allM: allM,
                allF: allF,
                allD: allD,
                openMale: openMale,
                openFemale: openFemale,
                openDiverse: openDiverse,
                offersMale: offersMale,
                offersFemale: offersFemale,
                offersDiverse: offersDiverse,
                migrationMale: migrationMale,
                migrationFemale: migrationFemale,
                migrationDiverse: migrationDiverse,
                countable: countable,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required DateTime dates,
                required int under_10,
                required int age_10_13,
                required int age_14_17,
                required int age_18_24,
                required int over_24,
                required int allM,
                required int allF,
                required int allD,
                required int openMale,
                required int openFemale,
                required int openDiverse,
                required int offersMale,
                required int offersFemale,
                required int offersDiverse,
                required int migrationMale,
                required int migrationFemale,
                required int migrationDiverse,
                required bool countable,
                Value<int> rowid = const Value.absent(),
              }) => WeeklyEntryCompanion.insert(
                dates: dates,
                under_10: under_10,
                age_10_13: age_10_13,
                age_14_17: age_14_17,
                age_18_24: age_18_24,
                over_24: over_24,
                allM: allM,
                allF: allF,
                allD: allD,
                openMale: openMale,
                openFemale: openFemale,
                openDiverse: openDiverse,
                offersMale: offersMale,
                offersFemale: offersFemale,
                offersDiverse: offersDiverse,
                migrationMale: migrationMale,
                migrationFemale: migrationFemale,
                migrationDiverse: migrationDiverse,
                countable: countable,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeeklyEntryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeeklyEntryTable,
      WeeklyEntryData,
      $$WeeklyEntryTableFilterComposer,
      $$WeeklyEntryTableOrderingComposer,
      $$WeeklyEntryTableAnnotationComposer,
      $$WeeklyEntryTableCreateCompanionBuilder,
      $$WeeklyEntryTableUpdateCompanionBuilder,
      (
        WeeklyEntryData,
        BaseReferences<_$AppDatabase, $WeeklyEntryTable, WeeklyEntryData>,
      ),
      WeeklyEntryData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DirectoryPeopleTableTableManager get directoryPeople =>
      $$DirectoryPeopleTableTableManager(_db, _db.directoryPeople);
  $$DailyEntryTableTableManager get dailyEntry =>
      $$DailyEntryTableTableManager(_db, _db.dailyEntry);
  $$WeeklyEntryTableTableManager get weeklyEntry =>
      $$WeeklyEntryTableTableManager(_db, _db.weeklyEntry);
}
