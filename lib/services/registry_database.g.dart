// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'registry_database.dart';

// ignore_for_file: type=lint
class $RegisteredAircraftsTable extends RegisteredAircrafts
    with TableInfo<$RegisteredAircraftsTable, RegisteredAircraft> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RegisteredAircraftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _registrationMeta = const VerificationMeta(
    'registration',
  );
  @override
  late final GeneratedColumn<String> registration = GeneratedColumn<String>(
    'registration',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hexMeta = const VerificationMeta('hex');
  @override
  late final GeneratedColumn<String> hex = GeneratedColumn<String>(
    'hex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [registration, hex];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'registered_aircrafts';
  @override
  VerificationContext validateIntegrity(
    Insertable<RegisteredAircraft> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('registration')) {
      context.handle(
        _registrationMeta,
        registration.isAcceptableOrUnknown(
          data['registration']!,
          _registrationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_registrationMeta);
    }
    if (data.containsKey('hex')) {
      context.handle(
        _hexMeta,
        hex.isAcceptableOrUnknown(data['hex']!, _hexMeta),
      );
    } else if (isInserting) {
      context.missing(_hexMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {registration, hex};
  @override
  RegisteredAircraft map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RegisteredAircraft(
      registration: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}registration'],
      )!,
      hex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hex'],
      )!,
    );
  }

  @override
  $RegisteredAircraftsTable createAlias(String alias) {
    return $RegisteredAircraftsTable(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
}

class RegisteredAircraft extends DataClass
    implements Insertable<RegisteredAircraft> {
  /// Upper case letters and digits only: "D-EABC" is stored as "DEABC".
  final String registration;

  /// Six hex digits, lower case.
  final String hex;
  const RegisteredAircraft({required this.registration, required this.hex});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['registration'] = Variable<String>(registration);
    map['hex'] = Variable<String>(hex);
    return map;
  }

  RegisteredAircraftsCompanion toCompanion(bool nullToAbsent) {
    return RegisteredAircraftsCompanion(
      registration: Value(registration),
      hex: Value(hex),
    );
  }

  factory RegisteredAircraft.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RegisteredAircraft(
      registration: serializer.fromJson<String>(json['registration']),
      hex: serializer.fromJson<String>(json['hex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'registration': serializer.toJson<String>(registration),
      'hex': serializer.toJson<String>(hex),
    };
  }

  RegisteredAircraft copyWith({String? registration, String? hex}) =>
      RegisteredAircraft(
        registration: registration ?? this.registration,
        hex: hex ?? this.hex,
      );
  RegisteredAircraft copyWithCompanion(RegisteredAircraftsCompanion data) {
    return RegisteredAircraft(
      registration: data.registration.present
          ? data.registration.value
          : this.registration,
      hex: data.hex.present ? data.hex.value : this.hex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RegisteredAircraft(')
          ..write('registration: $registration, ')
          ..write('hex: $hex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(registration, hex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RegisteredAircraft &&
          other.registration == this.registration &&
          other.hex == this.hex);
}

class RegisteredAircraftsCompanion extends UpdateCompanion<RegisteredAircraft> {
  final Value<String> registration;
  final Value<String> hex;
  const RegisteredAircraftsCompanion({
    this.registration = const Value.absent(),
    this.hex = const Value.absent(),
  });
  RegisteredAircraftsCompanion.insert({
    required String registration,
    required String hex,
  }) : registration = Value(registration),
       hex = Value(hex);
  static Insertable<RegisteredAircraft> custom({
    Expression<String>? registration,
    Expression<String>? hex,
  }) {
    return RawValuesInsertable({
      if (registration != null) 'registration': registration,
      if (hex != null) 'hex': hex,
    });
  }

  RegisteredAircraftsCompanion copyWith({
    Value<String>? registration,
    Value<String>? hex,
  }) {
    return RegisteredAircraftsCompanion(
      registration: registration ?? this.registration,
      hex: hex ?? this.hex,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (registration.present) {
      map['registration'] = Variable<String>(registration.value);
    }
    if (hex.present) {
      map['hex'] = Variable<String>(hex.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RegisteredAircraftsCompanion(')
          ..write('registration: $registration, ')
          ..write('hex: $hex')
          ..write(')'))
        .toString();
  }
}

class $RegistryMetaTable extends RegistryMeta
    with TableInfo<$RegistryMetaTable, RegistryMetaEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RegistryMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'registry_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<RegistryMetaEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  RegistryMetaEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RegistryMetaEntry(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $RegistryMetaTable createAlias(String alias) {
    return $RegistryMetaTable(attachedDatabase, alias);
  }
}

class RegistryMetaEntry extends DataClass
    implements Insertable<RegistryMetaEntry> {
  final String key;
  final String value;
  const RegistryMetaEntry({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  RegistryMetaCompanion toCompanion(bool nullToAbsent) {
    return RegistryMetaCompanion(key: Value(key), value: Value(value));
  }

  factory RegistryMetaEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RegistryMetaEntry(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  RegistryMetaEntry copyWith({String? key, String? value}) =>
      RegistryMetaEntry(key: key ?? this.key, value: value ?? this.value);
  RegistryMetaEntry copyWithCompanion(RegistryMetaCompanion data) {
    return RegistryMetaEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RegistryMetaEntry(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RegistryMetaEntry &&
          other.key == this.key &&
          other.value == this.value);
}

class RegistryMetaCompanion extends UpdateCompanion<RegistryMetaEntry> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const RegistryMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RegistryMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<RegistryMetaEntry> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RegistryMetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return RegistryMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RegistryMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$RegistryDatabase extends GeneratedDatabase {
  _$RegistryDatabase(QueryExecutor e) : super(e);
  $RegistryDatabaseManager get managers => $RegistryDatabaseManager(this);
  late final $RegisteredAircraftsTable registeredAircrafts =
      $RegisteredAircraftsTable(this);
  late final $RegistryMetaTable registryMeta = $RegistryMetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    registeredAircrafts,
    registryMeta,
  ];
}

typedef $$RegisteredAircraftsTableCreateCompanionBuilder =
    RegisteredAircraftsCompanion Function({
      required String registration,
      required String hex,
    });
typedef $$RegisteredAircraftsTableUpdateCompanionBuilder =
    RegisteredAircraftsCompanion Function({
      Value<String> registration,
      Value<String> hex,
    });

class $$RegisteredAircraftsTableFilterComposer
    extends Composer<_$RegistryDatabase, $RegisteredAircraftsTable> {
  $$RegisteredAircraftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get registration => $composableBuilder(
    column: $table.registration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hex => $composableBuilder(
    column: $table.hex,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RegisteredAircraftsTableOrderingComposer
    extends Composer<_$RegistryDatabase, $RegisteredAircraftsTable> {
  $$RegisteredAircraftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get registration => $composableBuilder(
    column: $table.registration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hex => $composableBuilder(
    column: $table.hex,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RegisteredAircraftsTableAnnotationComposer
    extends Composer<_$RegistryDatabase, $RegisteredAircraftsTable> {
  $$RegisteredAircraftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get registration => $composableBuilder(
    column: $table.registration,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hex =>
      $composableBuilder(column: $table.hex, builder: (column) => column);
}

class $$RegisteredAircraftsTableTableManager
    extends
        RootTableManager<
          _$RegistryDatabase,
          $RegisteredAircraftsTable,
          RegisteredAircraft,
          $$RegisteredAircraftsTableFilterComposer,
          $$RegisteredAircraftsTableOrderingComposer,
          $$RegisteredAircraftsTableAnnotationComposer,
          $$RegisteredAircraftsTableCreateCompanionBuilder,
          $$RegisteredAircraftsTableUpdateCompanionBuilder,
          (
            RegisteredAircraft,
            BaseReferences<
              _$RegistryDatabase,
              $RegisteredAircraftsTable,
              RegisteredAircraft
            >,
          ),
          RegisteredAircraft,
          PrefetchHooks Function()
        > {
  $$RegisteredAircraftsTableTableManager(
    _$RegistryDatabase db,
    $RegisteredAircraftsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RegisteredAircraftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RegisteredAircraftsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RegisteredAircraftsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> registration = const Value.absent(),
                Value<String> hex = const Value.absent(),
              }) => RegisteredAircraftsCompanion(
                registration: registration,
                hex: hex,
              ),
          createCompanionCallback:
              ({required String registration, required String hex}) =>
                  RegisteredAircraftsCompanion.insert(
                    registration: registration,
                    hex: hex,
                  ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RegisteredAircraftsTable, RegisteredAircraft>(
                    table,
                  ),
                  BaseReferences<
                    _$RegistryDatabase,
                    $RegisteredAircraftsTable,
                    RegisteredAircraft
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RegisteredAircraftsTableProcessedTableManager =
    ProcessedTableManager<
      _$RegistryDatabase,
      $RegisteredAircraftsTable,
      RegisteredAircraft,
      $$RegisteredAircraftsTableFilterComposer,
      $$RegisteredAircraftsTableOrderingComposer,
      $$RegisteredAircraftsTableAnnotationComposer,
      $$RegisteredAircraftsTableCreateCompanionBuilder,
      $$RegisteredAircraftsTableUpdateCompanionBuilder,
      (
        RegisteredAircraft,
        BaseReferences<
          _$RegistryDatabase,
          $RegisteredAircraftsTable,
          RegisteredAircraft
        >,
      ),
      RegisteredAircraft,
      PrefetchHooks Function()
    >;
typedef $$RegistryMetaTableCreateCompanionBuilder =
    RegistryMetaCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$RegistryMetaTableUpdateCompanionBuilder =
    RegistryMetaCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$RegistryMetaTableFilterComposer
    extends Composer<_$RegistryDatabase, $RegistryMetaTable> {
  $$RegistryMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RegistryMetaTableOrderingComposer
    extends Composer<_$RegistryDatabase, $RegistryMetaTable> {
  $$RegistryMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RegistryMetaTableAnnotationComposer
    extends Composer<_$RegistryDatabase, $RegistryMetaTable> {
  $$RegistryMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$RegistryMetaTableTableManager
    extends
        RootTableManager<
          _$RegistryDatabase,
          $RegistryMetaTable,
          RegistryMetaEntry,
          $$RegistryMetaTableFilterComposer,
          $$RegistryMetaTableOrderingComposer,
          $$RegistryMetaTableAnnotationComposer,
          $$RegistryMetaTableCreateCompanionBuilder,
          $$RegistryMetaTableUpdateCompanionBuilder,
          (
            RegistryMetaEntry,
            BaseReferences<
              _$RegistryDatabase,
              $RegistryMetaTable,
              RegistryMetaEntry
            >,
          ),
          RegistryMetaEntry,
          PrefetchHooks Function()
        > {
  $$RegistryMetaTableTableManager(
    _$RegistryDatabase db,
    $RegistryMetaTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RegistryMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RegistryMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RegistryMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RegistryMetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => RegistryMetaCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RegistryMetaTable, RegistryMetaEntry>(table),
                  BaseReferences<
                    _$RegistryDatabase,
                    $RegistryMetaTable,
                    RegistryMetaEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RegistryMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$RegistryDatabase,
      $RegistryMetaTable,
      RegistryMetaEntry,
      $$RegistryMetaTableFilterComposer,
      $$RegistryMetaTableOrderingComposer,
      $$RegistryMetaTableAnnotationComposer,
      $$RegistryMetaTableCreateCompanionBuilder,
      $$RegistryMetaTableUpdateCompanionBuilder,
      (
        RegistryMetaEntry,
        BaseReferences<
          _$RegistryDatabase,
          $RegistryMetaTable,
          RegistryMetaEntry
        >,
      ),
      RegistryMetaEntry,
      PrefetchHooks Function()
    >;

class $RegistryDatabaseManager {
  final _$RegistryDatabase _db;
  $RegistryDatabaseManager(this._db);
  $$RegisteredAircraftsTableTableManager get registeredAircrafts =>
      $$RegisteredAircraftsTableTableManager(_db, _db.registeredAircrafts);
  $$RegistryMetaTableTableManager get registryMeta =>
      $$RegistryMetaTableTableManager(_db, _db.registryMeta);
}
