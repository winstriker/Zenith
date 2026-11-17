// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CountriesTable extends Countries
    with TableInfo<$CountriesTable, Country> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CountriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 2,
      maxTextLength: 2,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _continentMeta = const VerificationMeta(
    'continent',
  );
  @override
  late final GeneratedColumn<String> continent = GeneratedColumn<String>(
    'continent',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 2,
      maxTextLength: 2,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wikipediaLinkMeta = const VerificationMeta(
    'wikipediaLink',
  );
  @override
  late final GeneratedColumn<String> wikipediaLink = GeneratedColumn<String>(
    'wikipedia_link',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _keywordsMeta = const VerificationMeta(
    'keywords',
  );
  @override
  late final GeneratedColumn<String> keywords = GeneratedColumn<String>(
    'keywords',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    code,
    name,
    continent,
    wikipediaLink,
    keywords,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'countries';
  @override
  VerificationContext validateIntegrity(
    Insertable<Country> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('continent')) {
      context.handle(
        _continentMeta,
        continent.isAcceptableOrUnknown(data['continent']!, _continentMeta),
      );
    } else if (isInserting) {
      context.missing(_continentMeta);
    }
    if (data.containsKey('wikipedia_link')) {
      context.handle(
        _wikipediaLinkMeta,
        wikipediaLink.isAcceptableOrUnknown(
          data['wikipedia_link']!,
          _wikipediaLinkMeta,
        ),
      );
    }
    if (data.containsKey('keywords')) {
      context.handle(
        _keywordsMeta,
        keywords.isAcceptableOrUnknown(data['keywords']!, _keywordsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Country map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Country(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      continent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}continent'],
      )!,
      wikipediaLink: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wikipedia_link'],
      ),
      keywords: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}keywords'],
      ),
    );
  }

  @override
  $CountriesTable createAlias(String alias) {
    return $CountriesTable(attachedDatabase, alias);
  }
}

class Country extends DataClass implements Insertable<Country> {
  final int id;
  final String code;
  final String name;
  final String continent;
  final String? wikipediaLink;
  final String? keywords;
  const Country({
    required this.id,
    required this.code,
    required this.name,
    required this.continent,
    this.wikipediaLink,
    this.keywords,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    map['continent'] = Variable<String>(continent);
    if (!nullToAbsent || wikipediaLink != null) {
      map['wikipedia_link'] = Variable<String>(wikipediaLink);
    }
    if (!nullToAbsent || keywords != null) {
      map['keywords'] = Variable<String>(keywords);
    }
    return map;
  }

  CountriesCompanion toCompanion(bool nullToAbsent) {
    return CountriesCompanion(
      id: Value(id),
      code: Value(code),
      name: Value(name),
      continent: Value(continent),
      wikipediaLink: wikipediaLink == null && nullToAbsent
          ? const Value.absent()
          : Value(wikipediaLink),
      keywords: keywords == null && nullToAbsent
          ? const Value.absent()
          : Value(keywords),
    );
  }

  factory Country.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Country(
      id: serializer.fromJson<int>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      continent: serializer.fromJson<String>(json['continent']),
      wikipediaLink: serializer.fromJson<String?>(json['wikipediaLink']),
      keywords: serializer.fromJson<String?>(json['keywords']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'continent': serializer.toJson<String>(continent),
      'wikipediaLink': serializer.toJson<String?>(wikipediaLink),
      'keywords': serializer.toJson<String?>(keywords),
    };
  }

  Country copyWith({
    int? id,
    String? code,
    String? name,
    String? continent,
    Value<String?> wikipediaLink = const Value.absent(),
    Value<String?> keywords = const Value.absent(),
  }) => Country(
    id: id ?? this.id,
    code: code ?? this.code,
    name: name ?? this.name,
    continent: continent ?? this.continent,
    wikipediaLink: wikipediaLink.present
        ? wikipediaLink.value
        : this.wikipediaLink,
    keywords: keywords.present ? keywords.value : this.keywords,
  );
  Country copyWithCompanion(CountriesCompanion data) {
    return Country(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      continent: data.continent.present ? data.continent.value : this.continent,
      wikipediaLink: data.wikipediaLink.present
          ? data.wikipediaLink.value
          : this.wikipediaLink,
      keywords: data.keywords.present ? data.keywords.value : this.keywords,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Country(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('continent: $continent, ')
          ..write('wikipediaLink: $wikipediaLink, ')
          ..write('keywords: $keywords')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, code, name, continent, wikipediaLink, keywords);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Country &&
          other.id == this.id &&
          other.code == this.code &&
          other.name == this.name &&
          other.continent == this.continent &&
          other.wikipediaLink == this.wikipediaLink &&
          other.keywords == this.keywords);
}

class CountriesCompanion extends UpdateCompanion<Country> {
  final Value<int> id;
  final Value<String> code;
  final Value<String> name;
  final Value<String> continent;
  final Value<String?> wikipediaLink;
  final Value<String?> keywords;
  const CountriesCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.continent = const Value.absent(),
    this.wikipediaLink = const Value.absent(),
    this.keywords = const Value.absent(),
  });
  CountriesCompanion.insert({
    this.id = const Value.absent(),
    required String code,
    required String name,
    required String continent,
    this.wikipediaLink = const Value.absent(),
    this.keywords = const Value.absent(),
  }) : code = Value(code),
       name = Value(name),
       continent = Value(continent);
  static Insertable<Country> custom({
    Expression<int>? id,
    Expression<String>? code,
    Expression<String>? name,
    Expression<String>? continent,
    Expression<String>? wikipediaLink,
    Expression<String>? keywords,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (continent != null) 'continent': continent,
      if (wikipediaLink != null) 'wikipedia_link': wikipediaLink,
      if (keywords != null) 'keywords': keywords,
    });
  }

  CountriesCompanion copyWith({
    Value<int>? id,
    Value<String>? code,
    Value<String>? name,
    Value<String>? continent,
    Value<String?>? wikipediaLink,
    Value<String?>? keywords,
  }) {
    return CountriesCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      continent: continent ?? this.continent,
      wikipediaLink: wikipediaLink ?? this.wikipediaLink,
      keywords: keywords ?? this.keywords,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (continent.present) {
      map['continent'] = Variable<String>(continent.value);
    }
    if (wikipediaLink.present) {
      map['wikipedia_link'] = Variable<String>(wikipediaLink.value);
    }
    if (keywords.present) {
      map['keywords'] = Variable<String>(keywords.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CountriesCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('continent: $continent, ')
          ..write('wikipediaLink: $wikipediaLink, ')
          ..write('keywords: $keywords')
          ..write(')'))
        .toString();
  }
}

class $RegionsTable extends Regions with TableInfo<$RegionsTable, Region> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RegionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 2,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _localCodeMeta = const VerificationMeta(
    'localCode',
  );
  @override
  late final GeneratedColumn<String> localCode = GeneratedColumn<String>(
    'local_code',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 0,
      maxTextLength: 20,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _continentMeta = const VerificationMeta(
    'continent',
  );
  @override
  late final GeneratedColumn<String> continent = GeneratedColumn<String>(
    'continent',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 2,
      maxTextLength: 2,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isoCountryMeta = const VerificationMeta(
    'isoCountry',
  );
  @override
  late final GeneratedColumn<String> isoCountry = GeneratedColumn<String>(
    'iso_country',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 2,
      maxTextLength: 2,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES countries (code)',
    ),
  );
  static const VerificationMeta _wikipediaLinkMeta = const VerificationMeta(
    'wikipediaLink',
  );
  @override
  late final GeneratedColumn<String> wikipediaLink = GeneratedColumn<String>(
    'wikipedia_link',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _keywordsMeta = const VerificationMeta(
    'keywords',
  );
  @override
  late final GeneratedColumn<String> keywords = GeneratedColumn<String>(
    'keywords',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    code,
    localCode,
    name,
    continent,
    isoCountry,
    wikipediaLink,
    keywords,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'regions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Region> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('local_code')) {
      context.handle(
        _localCodeMeta,
        localCode.isAcceptableOrUnknown(data['local_code']!, _localCodeMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('continent')) {
      context.handle(
        _continentMeta,
        continent.isAcceptableOrUnknown(data['continent']!, _continentMeta),
      );
    } else if (isInserting) {
      context.missing(_continentMeta);
    }
    if (data.containsKey('iso_country')) {
      context.handle(
        _isoCountryMeta,
        isoCountry.isAcceptableOrUnknown(data['iso_country']!, _isoCountryMeta),
      );
    } else if (isInserting) {
      context.missing(_isoCountryMeta);
    }
    if (data.containsKey('wikipedia_link')) {
      context.handle(
        _wikipediaLinkMeta,
        wikipediaLink.isAcceptableOrUnknown(
          data['wikipedia_link']!,
          _wikipediaLinkMeta,
        ),
      );
    }
    if (data.containsKey('keywords')) {
      context.handle(
        _keywordsMeta,
        keywords.isAcceptableOrUnknown(data['keywords']!, _keywordsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Region map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Region(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      localCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_code'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      continent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}continent'],
      )!,
      isoCountry: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}iso_country'],
      )!,
      wikipediaLink: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wikipedia_link'],
      ),
      keywords: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}keywords'],
      ),
    );
  }

  @override
  $RegionsTable createAlias(String alias) {
    return $RegionsTable(attachedDatabase, alias);
  }
}

class Region extends DataClass implements Insertable<Region> {
  final int id;
  final String code;
  final String? localCode;
  final String name;
  final String continent;
  final String isoCountry;
  final String? wikipediaLink;
  final String? keywords;
  const Region({
    required this.id,
    required this.code,
    this.localCode,
    required this.name,
    required this.continent,
    required this.isoCountry,
    this.wikipediaLink,
    this.keywords,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['code'] = Variable<String>(code);
    if (!nullToAbsent || localCode != null) {
      map['local_code'] = Variable<String>(localCode);
    }
    map['name'] = Variable<String>(name);
    map['continent'] = Variable<String>(continent);
    map['iso_country'] = Variable<String>(isoCountry);
    if (!nullToAbsent || wikipediaLink != null) {
      map['wikipedia_link'] = Variable<String>(wikipediaLink);
    }
    if (!nullToAbsent || keywords != null) {
      map['keywords'] = Variable<String>(keywords);
    }
    return map;
  }

  RegionsCompanion toCompanion(bool nullToAbsent) {
    return RegionsCompanion(
      id: Value(id),
      code: Value(code),
      localCode: localCode == null && nullToAbsent
          ? const Value.absent()
          : Value(localCode),
      name: Value(name),
      continent: Value(continent),
      isoCountry: Value(isoCountry),
      wikipediaLink: wikipediaLink == null && nullToAbsent
          ? const Value.absent()
          : Value(wikipediaLink),
      keywords: keywords == null && nullToAbsent
          ? const Value.absent()
          : Value(keywords),
    );
  }

  factory Region.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Region(
      id: serializer.fromJson<int>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      localCode: serializer.fromJson<String?>(json['localCode']),
      name: serializer.fromJson<String>(json['name']),
      continent: serializer.fromJson<String>(json['continent']),
      isoCountry: serializer.fromJson<String>(json['isoCountry']),
      wikipediaLink: serializer.fromJson<String?>(json['wikipediaLink']),
      keywords: serializer.fromJson<String?>(json['keywords']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'code': serializer.toJson<String>(code),
      'localCode': serializer.toJson<String?>(localCode),
      'name': serializer.toJson<String>(name),
      'continent': serializer.toJson<String>(continent),
      'isoCountry': serializer.toJson<String>(isoCountry),
      'wikipediaLink': serializer.toJson<String?>(wikipediaLink),
      'keywords': serializer.toJson<String?>(keywords),
    };
  }

  Region copyWith({
    int? id,
    String? code,
    Value<String?> localCode = const Value.absent(),
    String? name,
    String? continent,
    String? isoCountry,
    Value<String?> wikipediaLink = const Value.absent(),
    Value<String?> keywords = const Value.absent(),
  }) => Region(
    id: id ?? this.id,
    code: code ?? this.code,
    localCode: localCode.present ? localCode.value : this.localCode,
    name: name ?? this.name,
    continent: continent ?? this.continent,
    isoCountry: isoCountry ?? this.isoCountry,
    wikipediaLink: wikipediaLink.present
        ? wikipediaLink.value
        : this.wikipediaLink,
    keywords: keywords.present ? keywords.value : this.keywords,
  );
  Region copyWithCompanion(RegionsCompanion data) {
    return Region(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      localCode: data.localCode.present ? data.localCode.value : this.localCode,
      name: data.name.present ? data.name.value : this.name,
      continent: data.continent.present ? data.continent.value : this.continent,
      isoCountry: data.isoCountry.present
          ? data.isoCountry.value
          : this.isoCountry,
      wikipediaLink: data.wikipediaLink.present
          ? data.wikipediaLink.value
          : this.wikipediaLink,
      keywords: data.keywords.present ? data.keywords.value : this.keywords,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Region(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('localCode: $localCode, ')
          ..write('name: $name, ')
          ..write('continent: $continent, ')
          ..write('isoCountry: $isoCountry, ')
          ..write('wikipediaLink: $wikipediaLink, ')
          ..write('keywords: $keywords')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    code,
    localCode,
    name,
    continent,
    isoCountry,
    wikipediaLink,
    keywords,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Region &&
          other.id == this.id &&
          other.code == this.code &&
          other.localCode == this.localCode &&
          other.name == this.name &&
          other.continent == this.continent &&
          other.isoCountry == this.isoCountry &&
          other.wikipediaLink == this.wikipediaLink &&
          other.keywords == this.keywords);
}

class RegionsCompanion extends UpdateCompanion<Region> {
  final Value<int> id;
  final Value<String> code;
  final Value<String?> localCode;
  final Value<String> name;
  final Value<String> continent;
  final Value<String> isoCountry;
  final Value<String?> wikipediaLink;
  final Value<String?> keywords;
  const RegionsCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.localCode = const Value.absent(),
    this.name = const Value.absent(),
    this.continent = const Value.absent(),
    this.isoCountry = const Value.absent(),
    this.wikipediaLink = const Value.absent(),
    this.keywords = const Value.absent(),
  });
  RegionsCompanion.insert({
    this.id = const Value.absent(),
    required String code,
    this.localCode = const Value.absent(),
    required String name,
    required String continent,
    required String isoCountry,
    this.wikipediaLink = const Value.absent(),
    this.keywords = const Value.absent(),
  }) : code = Value(code),
       name = Value(name),
       continent = Value(continent),
       isoCountry = Value(isoCountry);
  static Insertable<Region> custom({
    Expression<int>? id,
    Expression<String>? code,
    Expression<String>? localCode,
    Expression<String>? name,
    Expression<String>? continent,
    Expression<String>? isoCountry,
    Expression<String>? wikipediaLink,
    Expression<String>? keywords,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (localCode != null) 'local_code': localCode,
      if (name != null) 'name': name,
      if (continent != null) 'continent': continent,
      if (isoCountry != null) 'iso_country': isoCountry,
      if (wikipediaLink != null) 'wikipedia_link': wikipediaLink,
      if (keywords != null) 'keywords': keywords,
    });
  }

  RegionsCompanion copyWith({
    Value<int>? id,
    Value<String>? code,
    Value<String?>? localCode,
    Value<String>? name,
    Value<String>? continent,
    Value<String>? isoCountry,
    Value<String?>? wikipediaLink,
    Value<String?>? keywords,
  }) {
    return RegionsCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      localCode: localCode ?? this.localCode,
      name: name ?? this.name,
      continent: continent ?? this.continent,
      isoCountry: isoCountry ?? this.isoCountry,
      wikipediaLink: wikipediaLink ?? this.wikipediaLink,
      keywords: keywords ?? this.keywords,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (localCode.present) {
      map['local_code'] = Variable<String>(localCode.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (continent.present) {
      map['continent'] = Variable<String>(continent.value);
    }
    if (isoCountry.present) {
      map['iso_country'] = Variable<String>(isoCountry.value);
    }
    if (wikipediaLink.present) {
      map['wikipedia_link'] = Variable<String>(wikipediaLink.value);
    }
    if (keywords.present) {
      map['keywords'] = Variable<String>(keywords.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RegionsCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('localCode: $localCode, ')
          ..write('name: $name, ')
          ..write('continent: $continent, ')
          ..write('isoCountry: $isoCountry, ')
          ..write('wikipediaLink: $wikipediaLink, ')
          ..write('keywords: $keywords')
          ..write(')'))
        .toString();
  }
}

class $AirportsTable extends Airports with TableInfo<$AirportsTable, Airport> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AirportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _identMeta = const VerificationMeta('ident');
  @override
  late final GeneratedColumn<String> ident = GeneratedColumn<String>(
    'ident',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<AirportType, int> type =
      GeneratedColumn<int>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<AirportType>($AirportsTable.$convertertype);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latitudeDegMeta = const VerificationMeta(
    'latitudeDeg',
  );
  @override
  late final GeneratedColumn<double> latitudeDeg = GeneratedColumn<double>(
    'latitude_deg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeDegMeta = const VerificationMeta(
    'longitudeDeg',
  );
  @override
  late final GeneratedColumn<double> longitudeDeg = GeneratedColumn<double>(
    'longitude_deg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _elevationFtMeta = const VerificationMeta(
    'elevationFt',
  );
  @override
  late final GeneratedColumn<int> elevationFt = GeneratedColumn<int>(
    'elevation_ft',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _continentMeta = const VerificationMeta(
    'continent',
  );
  @override
  late final GeneratedColumn<String> continent = GeneratedColumn<String>(
    'continent',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 2,
      maxTextLength: 2,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isoCountryMeta = const VerificationMeta(
    'isoCountry',
  );
  @override
  late final GeneratedColumn<String> isoCountry = GeneratedColumn<String>(
    'iso_country',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 2,
      maxTextLength: 2,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES countries (code)',
    ),
  );
  static const VerificationMeta _isoRegionMeta = const VerificationMeta(
    'isoRegion',
  );
  @override
  late final GeneratedColumn<String> isoRegion = GeneratedColumn<String>(
    'iso_region',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 2,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES regions (code)',
    ),
  );
  static const VerificationMeta _municipalityMeta = const VerificationMeta(
    'municipality',
  );
  @override
  late final GeneratedColumn<String> municipality = GeneratedColumn<String>(
    'municipality',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scheduledServiceMeta = const VerificationMeta(
    'scheduledService',
  );
  @override
  late final GeneratedColumn<bool> scheduledService = GeneratedColumn<bool>(
    'scheduled_service',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("scheduled_service" IN (0, 1))',
    ),
  );
  static const VerificationMeta _icaoCodeMeta = const VerificationMeta(
    'icaoCode',
  );
  @override
  late final GeneratedColumn<String> icaoCode = GeneratedColumn<String>(
    'icao_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iataCodeMeta = const VerificationMeta(
    'iataCode',
  );
  @override
  late final GeneratedColumn<String> iataCode = GeneratedColumn<String>(
    'iata_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gpsCodeMeta = const VerificationMeta(
    'gpsCode',
  );
  @override
  late final GeneratedColumn<String> gpsCode = GeneratedColumn<String>(
    'gps_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localCodeMeta = const VerificationMeta(
    'localCode',
  );
  @override
  late final GeneratedColumn<String> localCode = GeneratedColumn<String>(
    'local_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _homeLinkMeta = const VerificationMeta(
    'homeLink',
  );
  @override
  late final GeneratedColumn<String> homeLink = GeneratedColumn<String>(
    'home_link',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wikipediaLinkMeta = const VerificationMeta(
    'wikipediaLink',
  );
  @override
  late final GeneratedColumn<String> wikipediaLink = GeneratedColumn<String>(
    'wikipedia_link',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _keywordsMeta = const VerificationMeta(
    'keywords',
  );
  @override
  late final GeneratedColumn<String> keywords = GeneratedColumn<String>(
    'keywords',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ident,
    type,
    name,
    latitudeDeg,
    longitudeDeg,
    elevationFt,
    continent,
    isoCountry,
    isoRegion,
    municipality,
    scheduledService,
    icaoCode,
    iataCode,
    gpsCode,
    localCode,
    homeLink,
    wikipediaLink,
    keywords,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'airports';
  @override
  VerificationContext validateIntegrity(
    Insertable<Airport> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ident')) {
      context.handle(
        _identMeta,
        ident.isAcceptableOrUnknown(data['ident']!, _identMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('latitude_deg')) {
      context.handle(
        _latitudeDegMeta,
        latitudeDeg.isAcceptableOrUnknown(
          data['latitude_deg']!,
          _latitudeDegMeta,
        ),
      );
    }
    if (data.containsKey('longitude_deg')) {
      context.handle(
        _longitudeDegMeta,
        longitudeDeg.isAcceptableOrUnknown(
          data['longitude_deg']!,
          _longitudeDegMeta,
        ),
      );
    }
    if (data.containsKey('elevation_ft')) {
      context.handle(
        _elevationFtMeta,
        elevationFt.isAcceptableOrUnknown(
          data['elevation_ft']!,
          _elevationFtMeta,
        ),
      );
    }
    if (data.containsKey('continent')) {
      context.handle(
        _continentMeta,
        continent.isAcceptableOrUnknown(data['continent']!, _continentMeta),
      );
    } else if (isInserting) {
      context.missing(_continentMeta);
    }
    if (data.containsKey('iso_country')) {
      context.handle(
        _isoCountryMeta,
        isoCountry.isAcceptableOrUnknown(data['iso_country']!, _isoCountryMeta),
      );
    } else if (isInserting) {
      context.missing(_isoCountryMeta);
    }
    if (data.containsKey('iso_region')) {
      context.handle(
        _isoRegionMeta,
        isoRegion.isAcceptableOrUnknown(data['iso_region']!, _isoRegionMeta),
      );
    } else if (isInserting) {
      context.missing(_isoRegionMeta);
    }
    if (data.containsKey('municipality')) {
      context.handle(
        _municipalityMeta,
        municipality.isAcceptableOrUnknown(
          data['municipality']!,
          _municipalityMeta,
        ),
      );
    }
    if (data.containsKey('scheduled_service')) {
      context.handle(
        _scheduledServiceMeta,
        scheduledService.isAcceptableOrUnknown(
          data['scheduled_service']!,
          _scheduledServiceMeta,
        ),
      );
    }
    if (data.containsKey('icao_code')) {
      context.handle(
        _icaoCodeMeta,
        icaoCode.isAcceptableOrUnknown(data['icao_code']!, _icaoCodeMeta),
      );
    }
    if (data.containsKey('iata_code')) {
      context.handle(
        _iataCodeMeta,
        iataCode.isAcceptableOrUnknown(data['iata_code']!, _iataCodeMeta),
      );
    }
    if (data.containsKey('gps_code')) {
      context.handle(
        _gpsCodeMeta,
        gpsCode.isAcceptableOrUnknown(data['gps_code']!, _gpsCodeMeta),
      );
    }
    if (data.containsKey('local_code')) {
      context.handle(
        _localCodeMeta,
        localCode.isAcceptableOrUnknown(data['local_code']!, _localCodeMeta),
      );
    }
    if (data.containsKey('home_link')) {
      context.handle(
        _homeLinkMeta,
        homeLink.isAcceptableOrUnknown(data['home_link']!, _homeLinkMeta),
      );
    }
    if (data.containsKey('wikipedia_link')) {
      context.handle(
        _wikipediaLinkMeta,
        wikipediaLink.isAcceptableOrUnknown(
          data['wikipedia_link']!,
          _wikipediaLinkMeta,
        ),
      );
    }
    if (data.containsKey('keywords')) {
      context.handle(
        _keywordsMeta,
        keywords.isAcceptableOrUnknown(data['keywords']!, _keywordsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Airport map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Airport(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      ident: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ident'],
      ),
      type: $AirportsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}type'],
        )!,
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      latitudeDeg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude_deg'],
      ),
      longitudeDeg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude_deg'],
      ),
      elevationFt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}elevation_ft'],
      ),
      continent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}continent'],
      )!,
      isoCountry: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}iso_country'],
      )!,
      isoRegion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}iso_region'],
      )!,
      municipality: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}municipality'],
      ),
      scheduledService: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}scheduled_service'],
      ),
      icaoCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icao_code'],
      ),
      iataCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}iata_code'],
      ),
      gpsCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gps_code'],
      ),
      localCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_code'],
      ),
      homeLink: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}home_link'],
      ),
      wikipediaLink: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wikipedia_link'],
      ),
      keywords: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}keywords'],
      ),
    );
  }

  @override
  $AirportsTable createAlias(String alias) {
    return $AirportsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AirportType, int, int> $convertertype =
      const EnumIndexConverter<AirportType>(AirportType.values);
}

class Airport extends DataClass implements Insertable<Airport> {
  final int id;
  final String? ident;
  final AirportType type;
  final String? name;
  final double? latitudeDeg;
  final double? longitudeDeg;
  final int? elevationFt;
  final String continent;
  final String isoCountry;
  final String isoRegion;
  final String? municipality;
  final bool? scheduledService;
  final String? icaoCode;
  final String? iataCode;
  final String? gpsCode;
  final String? localCode;
  final String? homeLink;
  final String? wikipediaLink;
  final String? keywords;
  const Airport({
    required this.id,
    this.ident,
    required this.type,
    this.name,
    this.latitudeDeg,
    this.longitudeDeg,
    this.elevationFt,
    required this.continent,
    required this.isoCountry,
    required this.isoRegion,
    this.municipality,
    this.scheduledService,
    this.icaoCode,
    this.iataCode,
    this.gpsCode,
    this.localCode,
    this.homeLink,
    this.wikipediaLink,
    this.keywords,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || ident != null) {
      map['ident'] = Variable<String>(ident);
    }
    {
      map['type'] = Variable<int>($AirportsTable.$convertertype.toSql(type));
    }
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || latitudeDeg != null) {
      map['latitude_deg'] = Variable<double>(latitudeDeg);
    }
    if (!nullToAbsent || longitudeDeg != null) {
      map['longitude_deg'] = Variable<double>(longitudeDeg);
    }
    if (!nullToAbsent || elevationFt != null) {
      map['elevation_ft'] = Variable<int>(elevationFt);
    }
    map['continent'] = Variable<String>(continent);
    map['iso_country'] = Variable<String>(isoCountry);
    map['iso_region'] = Variable<String>(isoRegion);
    if (!nullToAbsent || municipality != null) {
      map['municipality'] = Variable<String>(municipality);
    }
    if (!nullToAbsent || scheduledService != null) {
      map['scheduled_service'] = Variable<bool>(scheduledService);
    }
    if (!nullToAbsent || icaoCode != null) {
      map['icao_code'] = Variable<String>(icaoCode);
    }
    if (!nullToAbsent || iataCode != null) {
      map['iata_code'] = Variable<String>(iataCode);
    }
    if (!nullToAbsent || gpsCode != null) {
      map['gps_code'] = Variable<String>(gpsCode);
    }
    if (!nullToAbsent || localCode != null) {
      map['local_code'] = Variable<String>(localCode);
    }
    if (!nullToAbsent || homeLink != null) {
      map['home_link'] = Variable<String>(homeLink);
    }
    if (!nullToAbsent || wikipediaLink != null) {
      map['wikipedia_link'] = Variable<String>(wikipediaLink);
    }
    if (!nullToAbsent || keywords != null) {
      map['keywords'] = Variable<String>(keywords);
    }
    return map;
  }

  AirportsCompanion toCompanion(bool nullToAbsent) {
    return AirportsCompanion(
      id: Value(id),
      ident: ident == null && nullToAbsent
          ? const Value.absent()
          : Value(ident),
      type: Value(type),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      latitudeDeg: latitudeDeg == null && nullToAbsent
          ? const Value.absent()
          : Value(latitudeDeg),
      longitudeDeg: longitudeDeg == null && nullToAbsent
          ? const Value.absent()
          : Value(longitudeDeg),
      elevationFt: elevationFt == null && nullToAbsent
          ? const Value.absent()
          : Value(elevationFt),
      continent: Value(continent),
      isoCountry: Value(isoCountry),
      isoRegion: Value(isoRegion),
      municipality: municipality == null && nullToAbsent
          ? const Value.absent()
          : Value(municipality),
      scheduledService: scheduledService == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledService),
      icaoCode: icaoCode == null && nullToAbsent
          ? const Value.absent()
          : Value(icaoCode),
      iataCode: iataCode == null && nullToAbsent
          ? const Value.absent()
          : Value(iataCode),
      gpsCode: gpsCode == null && nullToAbsent
          ? const Value.absent()
          : Value(gpsCode),
      localCode: localCode == null && nullToAbsent
          ? const Value.absent()
          : Value(localCode),
      homeLink: homeLink == null && nullToAbsent
          ? const Value.absent()
          : Value(homeLink),
      wikipediaLink: wikipediaLink == null && nullToAbsent
          ? const Value.absent()
          : Value(wikipediaLink),
      keywords: keywords == null && nullToAbsent
          ? const Value.absent()
          : Value(keywords),
    );
  }

  factory Airport.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Airport(
      id: serializer.fromJson<int>(json['id']),
      ident: serializer.fromJson<String?>(json['ident']),
      type: $AirportsTable.$convertertype.fromJson(
        serializer.fromJson<int>(json['type']),
      ),
      name: serializer.fromJson<String?>(json['name']),
      latitudeDeg: serializer.fromJson<double?>(json['latitudeDeg']),
      longitudeDeg: serializer.fromJson<double?>(json['longitudeDeg']),
      elevationFt: serializer.fromJson<int?>(json['elevationFt']),
      continent: serializer.fromJson<String>(json['continent']),
      isoCountry: serializer.fromJson<String>(json['isoCountry']),
      isoRegion: serializer.fromJson<String>(json['isoRegion']),
      municipality: serializer.fromJson<String?>(json['municipality']),
      scheduledService: serializer.fromJson<bool?>(json['scheduledService']),
      icaoCode: serializer.fromJson<String?>(json['icaoCode']),
      iataCode: serializer.fromJson<String?>(json['iataCode']),
      gpsCode: serializer.fromJson<String?>(json['gpsCode']),
      localCode: serializer.fromJson<String?>(json['localCode']),
      homeLink: serializer.fromJson<String?>(json['homeLink']),
      wikipediaLink: serializer.fromJson<String?>(json['wikipediaLink']),
      keywords: serializer.fromJson<String?>(json['keywords']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ident': serializer.toJson<String?>(ident),
      'type': serializer.toJson<int>(
        $AirportsTable.$convertertype.toJson(type),
      ),
      'name': serializer.toJson<String?>(name),
      'latitudeDeg': serializer.toJson<double?>(latitudeDeg),
      'longitudeDeg': serializer.toJson<double?>(longitudeDeg),
      'elevationFt': serializer.toJson<int?>(elevationFt),
      'continent': serializer.toJson<String>(continent),
      'isoCountry': serializer.toJson<String>(isoCountry),
      'isoRegion': serializer.toJson<String>(isoRegion),
      'municipality': serializer.toJson<String?>(municipality),
      'scheduledService': serializer.toJson<bool?>(scheduledService),
      'icaoCode': serializer.toJson<String?>(icaoCode),
      'iataCode': serializer.toJson<String?>(iataCode),
      'gpsCode': serializer.toJson<String?>(gpsCode),
      'localCode': serializer.toJson<String?>(localCode),
      'homeLink': serializer.toJson<String?>(homeLink),
      'wikipediaLink': serializer.toJson<String?>(wikipediaLink),
      'keywords': serializer.toJson<String?>(keywords),
    };
  }

  Airport copyWith({
    int? id,
    Value<String?> ident = const Value.absent(),
    AirportType? type,
    Value<String?> name = const Value.absent(),
    Value<double?> latitudeDeg = const Value.absent(),
    Value<double?> longitudeDeg = const Value.absent(),
    Value<int?> elevationFt = const Value.absent(),
    String? continent,
    String? isoCountry,
    String? isoRegion,
    Value<String?> municipality = const Value.absent(),
    Value<bool?> scheduledService = const Value.absent(),
    Value<String?> icaoCode = const Value.absent(),
    Value<String?> iataCode = const Value.absent(),
    Value<String?> gpsCode = const Value.absent(),
    Value<String?> localCode = const Value.absent(),
    Value<String?> homeLink = const Value.absent(),
    Value<String?> wikipediaLink = const Value.absent(),
    Value<String?> keywords = const Value.absent(),
  }) => Airport(
    id: id ?? this.id,
    ident: ident.present ? ident.value : this.ident,
    type: type ?? this.type,
    name: name.present ? name.value : this.name,
    latitudeDeg: latitudeDeg.present ? latitudeDeg.value : this.latitudeDeg,
    longitudeDeg: longitudeDeg.present ? longitudeDeg.value : this.longitudeDeg,
    elevationFt: elevationFt.present ? elevationFt.value : this.elevationFt,
    continent: continent ?? this.continent,
    isoCountry: isoCountry ?? this.isoCountry,
    isoRegion: isoRegion ?? this.isoRegion,
    municipality: municipality.present ? municipality.value : this.municipality,
    scheduledService: scheduledService.present
        ? scheduledService.value
        : this.scheduledService,
    icaoCode: icaoCode.present ? icaoCode.value : this.icaoCode,
    iataCode: iataCode.present ? iataCode.value : this.iataCode,
    gpsCode: gpsCode.present ? gpsCode.value : this.gpsCode,
    localCode: localCode.present ? localCode.value : this.localCode,
    homeLink: homeLink.present ? homeLink.value : this.homeLink,
    wikipediaLink: wikipediaLink.present
        ? wikipediaLink.value
        : this.wikipediaLink,
    keywords: keywords.present ? keywords.value : this.keywords,
  );
  Airport copyWithCompanion(AirportsCompanion data) {
    return Airport(
      id: data.id.present ? data.id.value : this.id,
      ident: data.ident.present ? data.ident.value : this.ident,
      type: data.type.present ? data.type.value : this.type,
      name: data.name.present ? data.name.value : this.name,
      latitudeDeg: data.latitudeDeg.present
          ? data.latitudeDeg.value
          : this.latitudeDeg,
      longitudeDeg: data.longitudeDeg.present
          ? data.longitudeDeg.value
          : this.longitudeDeg,
      elevationFt: data.elevationFt.present
          ? data.elevationFt.value
          : this.elevationFt,
      continent: data.continent.present ? data.continent.value : this.continent,
      isoCountry: data.isoCountry.present
          ? data.isoCountry.value
          : this.isoCountry,
      isoRegion: data.isoRegion.present ? data.isoRegion.value : this.isoRegion,
      municipality: data.municipality.present
          ? data.municipality.value
          : this.municipality,
      scheduledService: data.scheduledService.present
          ? data.scheduledService.value
          : this.scheduledService,
      icaoCode: data.icaoCode.present ? data.icaoCode.value : this.icaoCode,
      iataCode: data.iataCode.present ? data.iataCode.value : this.iataCode,
      gpsCode: data.gpsCode.present ? data.gpsCode.value : this.gpsCode,
      localCode: data.localCode.present ? data.localCode.value : this.localCode,
      homeLink: data.homeLink.present ? data.homeLink.value : this.homeLink,
      wikipediaLink: data.wikipediaLink.present
          ? data.wikipediaLink.value
          : this.wikipediaLink,
      keywords: data.keywords.present ? data.keywords.value : this.keywords,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Airport(')
          ..write('id: $id, ')
          ..write('ident: $ident, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('latitudeDeg: $latitudeDeg, ')
          ..write('longitudeDeg: $longitudeDeg, ')
          ..write('elevationFt: $elevationFt, ')
          ..write('continent: $continent, ')
          ..write('isoCountry: $isoCountry, ')
          ..write('isoRegion: $isoRegion, ')
          ..write('municipality: $municipality, ')
          ..write('scheduledService: $scheduledService, ')
          ..write('icaoCode: $icaoCode, ')
          ..write('iataCode: $iataCode, ')
          ..write('gpsCode: $gpsCode, ')
          ..write('localCode: $localCode, ')
          ..write('homeLink: $homeLink, ')
          ..write('wikipediaLink: $wikipediaLink, ')
          ..write('keywords: $keywords')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ident,
    type,
    name,
    latitudeDeg,
    longitudeDeg,
    elevationFt,
    continent,
    isoCountry,
    isoRegion,
    municipality,
    scheduledService,
    icaoCode,
    iataCode,
    gpsCode,
    localCode,
    homeLink,
    wikipediaLink,
    keywords,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Airport &&
          other.id == this.id &&
          other.ident == this.ident &&
          other.type == this.type &&
          other.name == this.name &&
          other.latitudeDeg == this.latitudeDeg &&
          other.longitudeDeg == this.longitudeDeg &&
          other.elevationFt == this.elevationFt &&
          other.continent == this.continent &&
          other.isoCountry == this.isoCountry &&
          other.isoRegion == this.isoRegion &&
          other.municipality == this.municipality &&
          other.scheduledService == this.scheduledService &&
          other.icaoCode == this.icaoCode &&
          other.iataCode == this.iataCode &&
          other.gpsCode == this.gpsCode &&
          other.localCode == this.localCode &&
          other.homeLink == this.homeLink &&
          other.wikipediaLink == this.wikipediaLink &&
          other.keywords == this.keywords);
}

class AirportsCompanion extends UpdateCompanion<Airport> {
  final Value<int> id;
  final Value<String?> ident;
  final Value<AirportType> type;
  final Value<String?> name;
  final Value<double?> latitudeDeg;
  final Value<double?> longitudeDeg;
  final Value<int?> elevationFt;
  final Value<String> continent;
  final Value<String> isoCountry;
  final Value<String> isoRegion;
  final Value<String?> municipality;
  final Value<bool?> scheduledService;
  final Value<String?> icaoCode;
  final Value<String?> iataCode;
  final Value<String?> gpsCode;
  final Value<String?> localCode;
  final Value<String?> homeLink;
  final Value<String?> wikipediaLink;
  final Value<String?> keywords;
  const AirportsCompanion({
    this.id = const Value.absent(),
    this.ident = const Value.absent(),
    this.type = const Value.absent(),
    this.name = const Value.absent(),
    this.latitudeDeg = const Value.absent(),
    this.longitudeDeg = const Value.absent(),
    this.elevationFt = const Value.absent(),
    this.continent = const Value.absent(),
    this.isoCountry = const Value.absent(),
    this.isoRegion = const Value.absent(),
    this.municipality = const Value.absent(),
    this.scheduledService = const Value.absent(),
    this.icaoCode = const Value.absent(),
    this.iataCode = const Value.absent(),
    this.gpsCode = const Value.absent(),
    this.localCode = const Value.absent(),
    this.homeLink = const Value.absent(),
    this.wikipediaLink = const Value.absent(),
    this.keywords = const Value.absent(),
  });
  AirportsCompanion.insert({
    this.id = const Value.absent(),
    this.ident = const Value.absent(),
    required AirportType type,
    this.name = const Value.absent(),
    this.latitudeDeg = const Value.absent(),
    this.longitudeDeg = const Value.absent(),
    this.elevationFt = const Value.absent(),
    required String continent,
    required String isoCountry,
    required String isoRegion,
    this.municipality = const Value.absent(),
    this.scheduledService = const Value.absent(),
    this.icaoCode = const Value.absent(),
    this.iataCode = const Value.absent(),
    this.gpsCode = const Value.absent(),
    this.localCode = const Value.absent(),
    this.homeLink = const Value.absent(),
    this.wikipediaLink = const Value.absent(),
    this.keywords = const Value.absent(),
  }) : type = Value(type),
       continent = Value(continent),
       isoCountry = Value(isoCountry),
       isoRegion = Value(isoRegion);
  static Insertable<Airport> custom({
    Expression<int>? id,
    Expression<String>? ident,
    Expression<int>? type,
    Expression<String>? name,
    Expression<double>? latitudeDeg,
    Expression<double>? longitudeDeg,
    Expression<int>? elevationFt,
    Expression<String>? continent,
    Expression<String>? isoCountry,
    Expression<String>? isoRegion,
    Expression<String>? municipality,
    Expression<bool>? scheduledService,
    Expression<String>? icaoCode,
    Expression<String>? iataCode,
    Expression<String>? gpsCode,
    Expression<String>? localCode,
    Expression<String>? homeLink,
    Expression<String>? wikipediaLink,
    Expression<String>? keywords,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ident != null) 'ident': ident,
      if (type != null) 'type': type,
      if (name != null) 'name': name,
      if (latitudeDeg != null) 'latitude_deg': latitudeDeg,
      if (longitudeDeg != null) 'longitude_deg': longitudeDeg,
      if (elevationFt != null) 'elevation_ft': elevationFt,
      if (continent != null) 'continent': continent,
      if (isoCountry != null) 'iso_country': isoCountry,
      if (isoRegion != null) 'iso_region': isoRegion,
      if (municipality != null) 'municipality': municipality,
      if (scheduledService != null) 'scheduled_service': scheduledService,
      if (icaoCode != null) 'icao_code': icaoCode,
      if (iataCode != null) 'iata_code': iataCode,
      if (gpsCode != null) 'gps_code': gpsCode,
      if (localCode != null) 'local_code': localCode,
      if (homeLink != null) 'home_link': homeLink,
      if (wikipediaLink != null) 'wikipedia_link': wikipediaLink,
      if (keywords != null) 'keywords': keywords,
    });
  }

  AirportsCompanion copyWith({
    Value<int>? id,
    Value<String?>? ident,
    Value<AirportType>? type,
    Value<String?>? name,
    Value<double?>? latitudeDeg,
    Value<double?>? longitudeDeg,
    Value<int?>? elevationFt,
    Value<String>? continent,
    Value<String>? isoCountry,
    Value<String>? isoRegion,
    Value<String?>? municipality,
    Value<bool?>? scheduledService,
    Value<String?>? icaoCode,
    Value<String?>? iataCode,
    Value<String?>? gpsCode,
    Value<String?>? localCode,
    Value<String?>? homeLink,
    Value<String?>? wikipediaLink,
    Value<String?>? keywords,
  }) {
    return AirportsCompanion(
      id: id ?? this.id,
      ident: ident ?? this.ident,
      type: type ?? this.type,
      name: name ?? this.name,
      latitudeDeg: latitudeDeg ?? this.latitudeDeg,
      longitudeDeg: longitudeDeg ?? this.longitudeDeg,
      elevationFt: elevationFt ?? this.elevationFt,
      continent: continent ?? this.continent,
      isoCountry: isoCountry ?? this.isoCountry,
      isoRegion: isoRegion ?? this.isoRegion,
      municipality: municipality ?? this.municipality,
      scheduledService: scheduledService ?? this.scheduledService,
      icaoCode: icaoCode ?? this.icaoCode,
      iataCode: iataCode ?? this.iataCode,
      gpsCode: gpsCode ?? this.gpsCode,
      localCode: localCode ?? this.localCode,
      homeLink: homeLink ?? this.homeLink,
      wikipediaLink: wikipediaLink ?? this.wikipediaLink,
      keywords: keywords ?? this.keywords,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ident.present) {
      map['ident'] = Variable<String>(ident.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(
        $AirportsTable.$convertertype.toSql(type.value),
      );
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (latitudeDeg.present) {
      map['latitude_deg'] = Variable<double>(latitudeDeg.value);
    }
    if (longitudeDeg.present) {
      map['longitude_deg'] = Variable<double>(longitudeDeg.value);
    }
    if (elevationFt.present) {
      map['elevation_ft'] = Variable<int>(elevationFt.value);
    }
    if (continent.present) {
      map['continent'] = Variable<String>(continent.value);
    }
    if (isoCountry.present) {
      map['iso_country'] = Variable<String>(isoCountry.value);
    }
    if (isoRegion.present) {
      map['iso_region'] = Variable<String>(isoRegion.value);
    }
    if (municipality.present) {
      map['municipality'] = Variable<String>(municipality.value);
    }
    if (scheduledService.present) {
      map['scheduled_service'] = Variable<bool>(scheduledService.value);
    }
    if (icaoCode.present) {
      map['icao_code'] = Variable<String>(icaoCode.value);
    }
    if (iataCode.present) {
      map['iata_code'] = Variable<String>(iataCode.value);
    }
    if (gpsCode.present) {
      map['gps_code'] = Variable<String>(gpsCode.value);
    }
    if (localCode.present) {
      map['local_code'] = Variable<String>(localCode.value);
    }
    if (homeLink.present) {
      map['home_link'] = Variable<String>(homeLink.value);
    }
    if (wikipediaLink.present) {
      map['wikipedia_link'] = Variable<String>(wikipediaLink.value);
    }
    if (keywords.present) {
      map['keywords'] = Variable<String>(keywords.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AirportsCompanion(')
          ..write('id: $id, ')
          ..write('ident: $ident, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('latitudeDeg: $latitudeDeg, ')
          ..write('longitudeDeg: $longitudeDeg, ')
          ..write('elevationFt: $elevationFt, ')
          ..write('continent: $continent, ')
          ..write('isoCountry: $isoCountry, ')
          ..write('isoRegion: $isoRegion, ')
          ..write('municipality: $municipality, ')
          ..write('scheduledService: $scheduledService, ')
          ..write('icaoCode: $icaoCode, ')
          ..write('iataCode: $iataCode, ')
          ..write('gpsCode: $gpsCode, ')
          ..write('localCode: $localCode, ')
          ..write('homeLink: $homeLink, ')
          ..write('wikipediaLink: $wikipediaLink, ')
          ..write('keywords: $keywords')
          ..write(')'))
        .toString();
  }
}

class $FrequenciesTable extends Frequencies
    with TableInfo<$FrequenciesTable, Frequency> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FrequenciesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _airportMeta = const VerificationMeta(
    'airport',
  );
  @override
  late final GeneratedColumn<int> airport = GeneratedColumn<int>(
    'airport',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES airports (id)',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _frequencyMhzMeta = const VerificationMeta(
    'frequencyMhz',
  );
  @override
  late final GeneratedColumn<String> frequencyMhz = GeneratedColumn<String>(
    'frequency_mhz',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 0,
      maxTextLength: 8,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    airport,
    type,
    description,
    frequencyMhz,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'frequencies';
  @override
  VerificationContext validateIntegrity(
    Insertable<Frequency> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('airport')) {
      context.handle(
        _airportMeta,
        airport.isAcceptableOrUnknown(data['airport']!, _airportMeta),
      );
    } else if (isInserting) {
      context.missing(_airportMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('frequency_mhz')) {
      context.handle(
        _frequencyMhzMeta,
        frequencyMhz.isAcceptableOrUnknown(
          data['frequency_mhz']!,
          _frequencyMhzMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Frequency map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Frequency(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      airport: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}airport'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      frequencyMhz: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frequency_mhz'],
      ),
    );
  }

  @override
  $FrequenciesTable createAlias(String alias) {
    return $FrequenciesTable(attachedDatabase, alias);
  }
}

class Frequency extends DataClass implements Insertable<Frequency> {
  final int id;
  final int airport;
  final String? type;
  final String? description;
  final String? frequencyMhz;
  const Frequency({
    required this.id,
    required this.airport,
    this.type,
    this.description,
    this.frequencyMhz,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['airport'] = Variable<int>(airport);
    if (!nullToAbsent || type != null) {
      map['type'] = Variable<String>(type);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || frequencyMhz != null) {
      map['frequency_mhz'] = Variable<String>(frequencyMhz);
    }
    return map;
  }

  FrequenciesCompanion toCompanion(bool nullToAbsent) {
    return FrequenciesCompanion(
      id: Value(id),
      airport: Value(airport),
      type: type == null && nullToAbsent ? const Value.absent() : Value(type),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      frequencyMhz: frequencyMhz == null && nullToAbsent
          ? const Value.absent()
          : Value(frequencyMhz),
    );
  }

  factory Frequency.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Frequency(
      id: serializer.fromJson<int>(json['id']),
      airport: serializer.fromJson<int>(json['airport']),
      type: serializer.fromJson<String?>(json['type']),
      description: serializer.fromJson<String?>(json['description']),
      frequencyMhz: serializer.fromJson<String?>(json['frequencyMhz']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'airport': serializer.toJson<int>(airport),
      'type': serializer.toJson<String?>(type),
      'description': serializer.toJson<String?>(description),
      'frequencyMhz': serializer.toJson<String?>(frequencyMhz),
    };
  }

  Frequency copyWith({
    int? id,
    int? airport,
    Value<String?> type = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> frequencyMhz = const Value.absent(),
  }) => Frequency(
    id: id ?? this.id,
    airport: airport ?? this.airport,
    type: type.present ? type.value : this.type,
    description: description.present ? description.value : this.description,
    frequencyMhz: frequencyMhz.present ? frequencyMhz.value : this.frequencyMhz,
  );
  Frequency copyWithCompanion(FrequenciesCompanion data) {
    return Frequency(
      id: data.id.present ? data.id.value : this.id,
      airport: data.airport.present ? data.airport.value : this.airport,
      type: data.type.present ? data.type.value : this.type,
      description: data.description.present
          ? data.description.value
          : this.description,
      frequencyMhz: data.frequencyMhz.present
          ? data.frequencyMhz.value
          : this.frequencyMhz,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Frequency(')
          ..write('id: $id, ')
          ..write('airport: $airport, ')
          ..write('type: $type, ')
          ..write('description: $description, ')
          ..write('frequencyMhz: $frequencyMhz')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, airport, type, description, frequencyMhz);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Frequency &&
          other.id == this.id &&
          other.airport == this.airport &&
          other.type == this.type &&
          other.description == this.description &&
          other.frequencyMhz == this.frequencyMhz);
}

class FrequenciesCompanion extends UpdateCompanion<Frequency> {
  final Value<int> id;
  final Value<int> airport;
  final Value<String?> type;
  final Value<String?> description;
  final Value<String?> frequencyMhz;
  const FrequenciesCompanion({
    this.id = const Value.absent(),
    this.airport = const Value.absent(),
    this.type = const Value.absent(),
    this.description = const Value.absent(),
    this.frequencyMhz = const Value.absent(),
  });
  FrequenciesCompanion.insert({
    this.id = const Value.absent(),
    required int airport,
    this.type = const Value.absent(),
    this.description = const Value.absent(),
    this.frequencyMhz = const Value.absent(),
  }) : airport = Value(airport);
  static Insertable<Frequency> custom({
    Expression<int>? id,
    Expression<int>? airport,
    Expression<String>? type,
    Expression<String>? description,
    Expression<String>? frequencyMhz,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (airport != null) 'airport': airport,
      if (type != null) 'type': type,
      if (description != null) 'description': description,
      if (frequencyMhz != null) 'frequency_mhz': frequencyMhz,
    });
  }

  FrequenciesCompanion copyWith({
    Value<int>? id,
    Value<int>? airport,
    Value<String?>? type,
    Value<String?>? description,
    Value<String?>? frequencyMhz,
  }) {
    return FrequenciesCompanion(
      id: id ?? this.id,
      airport: airport ?? this.airport,
      type: type ?? this.type,
      description: description ?? this.description,
      frequencyMhz: frequencyMhz ?? this.frequencyMhz,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (airport.present) {
      map['airport'] = Variable<int>(airport.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (frequencyMhz.present) {
      map['frequency_mhz'] = Variable<String>(frequencyMhz.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FrequenciesCompanion(')
          ..write('id: $id, ')
          ..write('airport: $airport, ')
          ..write('type: $type, ')
          ..write('description: $description, ')
          ..write('frequencyMhz: $frequencyMhz')
          ..write(')'))
        .toString();
  }
}

class $RunwaysTable extends Runways with TableInfo<$RunwaysTable, Runway> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RunwaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _airportMeta = const VerificationMeta(
    'airport',
  );
  @override
  late final GeneratedColumn<int> airport = GeneratedColumn<int>(
    'airport',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES airports (id)',
    ),
  );
  static const VerificationMeta _lengthFtMeta = const VerificationMeta(
    'lengthFt',
  );
  @override
  late final GeneratedColumn<int> lengthFt = GeneratedColumn<int>(
    'length_ft',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _widthFtMeta = const VerificationMeta(
    'widthFt',
  );
  @override
  late final GeneratedColumn<int> widthFt = GeneratedColumn<int>(
    'width_ft',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _surfaceMeta = const VerificationMeta(
    'surface',
  );
  @override
  late final GeneratedColumn<String> surface = GeneratedColumn<String>(
    'surface',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lightedMeta = const VerificationMeta(
    'lighted',
  );
  @override
  late final GeneratedColumn<bool> lighted = GeneratedColumn<bool>(
    'lighted',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("lighted" IN (0, 1))',
    ),
  );
  static const VerificationMeta _closedMeta = const VerificationMeta('closed');
  @override
  late final GeneratedColumn<bool> closed = GeneratedColumn<bool>(
    'closed',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("closed" IN (0, 1))',
    ),
  );
  static const VerificationMeta _leIdentMeta = const VerificationMeta(
    'leIdent',
  );
  @override
  late final GeneratedColumn<String> leIdent = GeneratedColumn<String>(
    'le_ident',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _leLatitudeDegMeta = const VerificationMeta(
    'leLatitudeDeg',
  );
  @override
  late final GeneratedColumn<double> leLatitudeDeg = GeneratedColumn<double>(
    'le_latitude_deg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _leLongitudeDegMeta = const VerificationMeta(
    'leLongitudeDeg',
  );
  @override
  late final GeneratedColumn<double> leLongitudeDeg = GeneratedColumn<double>(
    'le_longitude_deg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _leElevationFtMeta = const VerificationMeta(
    'leElevationFt',
  );
  @override
  late final GeneratedColumn<int> leElevationFt = GeneratedColumn<int>(
    'le_elevation_ft',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _leHeadingDegTMeta = const VerificationMeta(
    'leHeadingDegT',
  );
  @override
  late final GeneratedColumn<double> leHeadingDegT = GeneratedColumn<double>(
    'le_heading_deg_t',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _leDisplacedThresholdFtMeta =
      const VerificationMeta('leDisplacedThresholdFt');
  @override
  late final GeneratedColumn<int> leDisplacedThresholdFt = GeneratedColumn<int>(
    'le_displaced_threshold_ft',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heIdentMeta = const VerificationMeta(
    'heIdent',
  );
  @override
  late final GeneratedColumn<String> heIdent = GeneratedColumn<String>(
    'he_ident',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heLatitudeDegMeta = const VerificationMeta(
    'heLatitudeDeg',
  );
  @override
  late final GeneratedColumn<double> heLatitudeDeg = GeneratedColumn<double>(
    'he_latitude_deg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heLongitudeDegMeta = const VerificationMeta(
    'heLongitudeDeg',
  );
  @override
  late final GeneratedColumn<double> heLongitudeDeg = GeneratedColumn<double>(
    'he_longitude_deg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heElevationFtMeta = const VerificationMeta(
    'heElevationFt',
  );
  @override
  late final GeneratedColumn<int> heElevationFt = GeneratedColumn<int>(
    'he_elevation_ft',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heHeadingDegTMeta = const VerificationMeta(
    'heHeadingDegT',
  );
  @override
  late final GeneratedColumn<double> heHeadingDegT = GeneratedColumn<double>(
    'he_heading_deg_t',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heDisplacedThresholdFtMeta =
      const VerificationMeta('heDisplacedThresholdFt');
  @override
  late final GeneratedColumn<int> heDisplacedThresholdFt = GeneratedColumn<int>(
    'he_displaced_threshold_ft',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    airport,
    lengthFt,
    widthFt,
    surface,
    lighted,
    closed,
    leIdent,
    leLatitudeDeg,
    leLongitudeDeg,
    leElevationFt,
    leHeadingDegT,
    leDisplacedThresholdFt,
    heIdent,
    heLatitudeDeg,
    heLongitudeDeg,
    heElevationFt,
    heHeadingDegT,
    heDisplacedThresholdFt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'runways';
  @override
  VerificationContext validateIntegrity(
    Insertable<Runway> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('airport')) {
      context.handle(
        _airportMeta,
        airport.isAcceptableOrUnknown(data['airport']!, _airportMeta),
      );
    } else if (isInserting) {
      context.missing(_airportMeta);
    }
    if (data.containsKey('length_ft')) {
      context.handle(
        _lengthFtMeta,
        lengthFt.isAcceptableOrUnknown(data['length_ft']!, _lengthFtMeta),
      );
    }
    if (data.containsKey('width_ft')) {
      context.handle(
        _widthFtMeta,
        widthFt.isAcceptableOrUnknown(data['width_ft']!, _widthFtMeta),
      );
    }
    if (data.containsKey('surface')) {
      context.handle(
        _surfaceMeta,
        surface.isAcceptableOrUnknown(data['surface']!, _surfaceMeta),
      );
    }
    if (data.containsKey('lighted')) {
      context.handle(
        _lightedMeta,
        lighted.isAcceptableOrUnknown(data['lighted']!, _lightedMeta),
      );
    }
    if (data.containsKey('closed')) {
      context.handle(
        _closedMeta,
        closed.isAcceptableOrUnknown(data['closed']!, _closedMeta),
      );
    }
    if (data.containsKey('le_ident')) {
      context.handle(
        _leIdentMeta,
        leIdent.isAcceptableOrUnknown(data['le_ident']!, _leIdentMeta),
      );
    }
    if (data.containsKey('le_latitude_deg')) {
      context.handle(
        _leLatitudeDegMeta,
        leLatitudeDeg.isAcceptableOrUnknown(
          data['le_latitude_deg']!,
          _leLatitudeDegMeta,
        ),
      );
    }
    if (data.containsKey('le_longitude_deg')) {
      context.handle(
        _leLongitudeDegMeta,
        leLongitudeDeg.isAcceptableOrUnknown(
          data['le_longitude_deg']!,
          _leLongitudeDegMeta,
        ),
      );
    }
    if (data.containsKey('le_elevation_ft')) {
      context.handle(
        _leElevationFtMeta,
        leElevationFt.isAcceptableOrUnknown(
          data['le_elevation_ft']!,
          _leElevationFtMeta,
        ),
      );
    }
    if (data.containsKey('le_heading_deg_t')) {
      context.handle(
        _leHeadingDegTMeta,
        leHeadingDegT.isAcceptableOrUnknown(
          data['le_heading_deg_t']!,
          _leHeadingDegTMeta,
        ),
      );
    }
    if (data.containsKey('le_displaced_threshold_ft')) {
      context.handle(
        _leDisplacedThresholdFtMeta,
        leDisplacedThresholdFt.isAcceptableOrUnknown(
          data['le_displaced_threshold_ft']!,
          _leDisplacedThresholdFtMeta,
        ),
      );
    }
    if (data.containsKey('he_ident')) {
      context.handle(
        _heIdentMeta,
        heIdent.isAcceptableOrUnknown(data['he_ident']!, _heIdentMeta),
      );
    }
    if (data.containsKey('he_latitude_deg')) {
      context.handle(
        _heLatitudeDegMeta,
        heLatitudeDeg.isAcceptableOrUnknown(
          data['he_latitude_deg']!,
          _heLatitudeDegMeta,
        ),
      );
    }
    if (data.containsKey('he_longitude_deg')) {
      context.handle(
        _heLongitudeDegMeta,
        heLongitudeDeg.isAcceptableOrUnknown(
          data['he_longitude_deg']!,
          _heLongitudeDegMeta,
        ),
      );
    }
    if (data.containsKey('he_elevation_ft')) {
      context.handle(
        _heElevationFtMeta,
        heElevationFt.isAcceptableOrUnknown(
          data['he_elevation_ft']!,
          _heElevationFtMeta,
        ),
      );
    }
    if (data.containsKey('he_heading_deg_t')) {
      context.handle(
        _heHeadingDegTMeta,
        heHeadingDegT.isAcceptableOrUnknown(
          data['he_heading_deg_t']!,
          _heHeadingDegTMeta,
        ),
      );
    }
    if (data.containsKey('he_displaced_threshold_ft')) {
      context.handle(
        _heDisplacedThresholdFtMeta,
        heDisplacedThresholdFt.isAcceptableOrUnknown(
          data['he_displaced_threshold_ft']!,
          _heDisplacedThresholdFtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Runway map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Runway(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      airport: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}airport'],
      )!,
      lengthFt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}length_ft'],
      ),
      widthFt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width_ft'],
      ),
      surface: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}surface'],
      ),
      lighted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}lighted'],
      ),
      closed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}closed'],
      ),
      leIdent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}le_ident'],
      ),
      leLatitudeDeg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}le_latitude_deg'],
      ),
      leLongitudeDeg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}le_longitude_deg'],
      ),
      leElevationFt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}le_elevation_ft'],
      ),
      leHeadingDegT: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}le_heading_deg_t'],
      ),
      leDisplacedThresholdFt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}le_displaced_threshold_ft'],
      ),
      heIdent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}he_ident'],
      ),
      heLatitudeDeg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}he_latitude_deg'],
      ),
      heLongitudeDeg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}he_longitude_deg'],
      ),
      heElevationFt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}he_elevation_ft'],
      ),
      heHeadingDegT: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}he_heading_deg_t'],
      ),
      heDisplacedThresholdFt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}he_displaced_threshold_ft'],
      ),
    );
  }

  @override
  $RunwaysTable createAlias(String alias) {
    return $RunwaysTable(attachedDatabase, alias);
  }
}

class Runway extends DataClass implements Insertable<Runway> {
  final int id;
  final int airport;
  final int? lengthFt;
  final int? widthFt;
  final String? surface;
  final bool? lighted;
  final bool? closed;
  final String? leIdent;
  final double? leLatitudeDeg;
  final double? leLongitudeDeg;
  final int? leElevationFt;
  final double? leHeadingDegT;
  final int? leDisplacedThresholdFt;
  final String? heIdent;
  final double? heLatitudeDeg;
  final double? heLongitudeDeg;
  final int? heElevationFt;
  final double? heHeadingDegT;
  final int? heDisplacedThresholdFt;
  const Runway({
    required this.id,
    required this.airport,
    this.lengthFt,
    this.widthFt,
    this.surface,
    this.lighted,
    this.closed,
    this.leIdent,
    this.leLatitudeDeg,
    this.leLongitudeDeg,
    this.leElevationFt,
    this.leHeadingDegT,
    this.leDisplacedThresholdFt,
    this.heIdent,
    this.heLatitudeDeg,
    this.heLongitudeDeg,
    this.heElevationFt,
    this.heHeadingDegT,
    this.heDisplacedThresholdFt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['airport'] = Variable<int>(airport);
    if (!nullToAbsent || lengthFt != null) {
      map['length_ft'] = Variable<int>(lengthFt);
    }
    if (!nullToAbsent || widthFt != null) {
      map['width_ft'] = Variable<int>(widthFt);
    }
    if (!nullToAbsent || surface != null) {
      map['surface'] = Variable<String>(surface);
    }
    if (!nullToAbsent || lighted != null) {
      map['lighted'] = Variable<bool>(lighted);
    }
    if (!nullToAbsent || closed != null) {
      map['closed'] = Variable<bool>(closed);
    }
    if (!nullToAbsent || leIdent != null) {
      map['le_ident'] = Variable<String>(leIdent);
    }
    if (!nullToAbsent || leLatitudeDeg != null) {
      map['le_latitude_deg'] = Variable<double>(leLatitudeDeg);
    }
    if (!nullToAbsent || leLongitudeDeg != null) {
      map['le_longitude_deg'] = Variable<double>(leLongitudeDeg);
    }
    if (!nullToAbsent || leElevationFt != null) {
      map['le_elevation_ft'] = Variable<int>(leElevationFt);
    }
    if (!nullToAbsent || leHeadingDegT != null) {
      map['le_heading_deg_t'] = Variable<double>(leHeadingDegT);
    }
    if (!nullToAbsent || leDisplacedThresholdFt != null) {
      map['le_displaced_threshold_ft'] = Variable<int>(leDisplacedThresholdFt);
    }
    if (!nullToAbsent || heIdent != null) {
      map['he_ident'] = Variable<String>(heIdent);
    }
    if (!nullToAbsent || heLatitudeDeg != null) {
      map['he_latitude_deg'] = Variable<double>(heLatitudeDeg);
    }
    if (!nullToAbsent || heLongitudeDeg != null) {
      map['he_longitude_deg'] = Variable<double>(heLongitudeDeg);
    }
    if (!nullToAbsent || heElevationFt != null) {
      map['he_elevation_ft'] = Variable<int>(heElevationFt);
    }
    if (!nullToAbsent || heHeadingDegT != null) {
      map['he_heading_deg_t'] = Variable<double>(heHeadingDegT);
    }
    if (!nullToAbsent || heDisplacedThresholdFt != null) {
      map['he_displaced_threshold_ft'] = Variable<int>(heDisplacedThresholdFt);
    }
    return map;
  }

  RunwaysCompanion toCompanion(bool nullToAbsent) {
    return RunwaysCompanion(
      id: Value(id),
      airport: Value(airport),
      lengthFt: lengthFt == null && nullToAbsent
          ? const Value.absent()
          : Value(lengthFt),
      widthFt: widthFt == null && nullToAbsent
          ? const Value.absent()
          : Value(widthFt),
      surface: surface == null && nullToAbsent
          ? const Value.absent()
          : Value(surface),
      lighted: lighted == null && nullToAbsent
          ? const Value.absent()
          : Value(lighted),
      closed: closed == null && nullToAbsent
          ? const Value.absent()
          : Value(closed),
      leIdent: leIdent == null && nullToAbsent
          ? const Value.absent()
          : Value(leIdent),
      leLatitudeDeg: leLatitudeDeg == null && nullToAbsent
          ? const Value.absent()
          : Value(leLatitudeDeg),
      leLongitudeDeg: leLongitudeDeg == null && nullToAbsent
          ? const Value.absent()
          : Value(leLongitudeDeg),
      leElevationFt: leElevationFt == null && nullToAbsent
          ? const Value.absent()
          : Value(leElevationFt),
      leHeadingDegT: leHeadingDegT == null && nullToAbsent
          ? const Value.absent()
          : Value(leHeadingDegT),
      leDisplacedThresholdFt: leDisplacedThresholdFt == null && nullToAbsent
          ? const Value.absent()
          : Value(leDisplacedThresholdFt),
      heIdent: heIdent == null && nullToAbsent
          ? const Value.absent()
          : Value(heIdent),
      heLatitudeDeg: heLatitudeDeg == null && nullToAbsent
          ? const Value.absent()
          : Value(heLatitudeDeg),
      heLongitudeDeg: heLongitudeDeg == null && nullToAbsent
          ? const Value.absent()
          : Value(heLongitudeDeg),
      heElevationFt: heElevationFt == null && nullToAbsent
          ? const Value.absent()
          : Value(heElevationFt),
      heHeadingDegT: heHeadingDegT == null && nullToAbsent
          ? const Value.absent()
          : Value(heHeadingDegT),
      heDisplacedThresholdFt: heDisplacedThresholdFt == null && nullToAbsent
          ? const Value.absent()
          : Value(heDisplacedThresholdFt),
    );
  }

  factory Runway.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Runway(
      id: serializer.fromJson<int>(json['id']),
      airport: serializer.fromJson<int>(json['airport']),
      lengthFt: serializer.fromJson<int?>(json['lengthFt']),
      widthFt: serializer.fromJson<int?>(json['widthFt']),
      surface: serializer.fromJson<String?>(json['surface']),
      lighted: serializer.fromJson<bool?>(json['lighted']),
      closed: serializer.fromJson<bool?>(json['closed']),
      leIdent: serializer.fromJson<String?>(json['leIdent']),
      leLatitudeDeg: serializer.fromJson<double?>(json['leLatitudeDeg']),
      leLongitudeDeg: serializer.fromJson<double?>(json['leLongitudeDeg']),
      leElevationFt: serializer.fromJson<int?>(json['leElevationFt']),
      leHeadingDegT: serializer.fromJson<double?>(json['leHeadingDegT']),
      leDisplacedThresholdFt: serializer.fromJson<int?>(
        json['leDisplacedThresholdFt'],
      ),
      heIdent: serializer.fromJson<String?>(json['heIdent']),
      heLatitudeDeg: serializer.fromJson<double?>(json['heLatitudeDeg']),
      heLongitudeDeg: serializer.fromJson<double?>(json['heLongitudeDeg']),
      heElevationFt: serializer.fromJson<int?>(json['heElevationFt']),
      heHeadingDegT: serializer.fromJson<double?>(json['heHeadingDegT']),
      heDisplacedThresholdFt: serializer.fromJson<int?>(
        json['heDisplacedThresholdFt'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'airport': serializer.toJson<int>(airport),
      'lengthFt': serializer.toJson<int?>(lengthFt),
      'widthFt': serializer.toJson<int?>(widthFt),
      'surface': serializer.toJson<String?>(surface),
      'lighted': serializer.toJson<bool?>(lighted),
      'closed': serializer.toJson<bool?>(closed),
      'leIdent': serializer.toJson<String?>(leIdent),
      'leLatitudeDeg': serializer.toJson<double?>(leLatitudeDeg),
      'leLongitudeDeg': serializer.toJson<double?>(leLongitudeDeg),
      'leElevationFt': serializer.toJson<int?>(leElevationFt),
      'leHeadingDegT': serializer.toJson<double?>(leHeadingDegT),
      'leDisplacedThresholdFt': serializer.toJson<int?>(leDisplacedThresholdFt),
      'heIdent': serializer.toJson<String?>(heIdent),
      'heLatitudeDeg': serializer.toJson<double?>(heLatitudeDeg),
      'heLongitudeDeg': serializer.toJson<double?>(heLongitudeDeg),
      'heElevationFt': serializer.toJson<int?>(heElevationFt),
      'heHeadingDegT': serializer.toJson<double?>(heHeadingDegT),
      'heDisplacedThresholdFt': serializer.toJson<int?>(heDisplacedThresholdFt),
    };
  }

  Runway copyWith({
    int? id,
    int? airport,
    Value<int?> lengthFt = const Value.absent(),
    Value<int?> widthFt = const Value.absent(),
    Value<String?> surface = const Value.absent(),
    Value<bool?> lighted = const Value.absent(),
    Value<bool?> closed = const Value.absent(),
    Value<String?> leIdent = const Value.absent(),
    Value<double?> leLatitudeDeg = const Value.absent(),
    Value<double?> leLongitudeDeg = const Value.absent(),
    Value<int?> leElevationFt = const Value.absent(),
    Value<double?> leHeadingDegT = const Value.absent(),
    Value<int?> leDisplacedThresholdFt = const Value.absent(),
    Value<String?> heIdent = const Value.absent(),
    Value<double?> heLatitudeDeg = const Value.absent(),
    Value<double?> heLongitudeDeg = const Value.absent(),
    Value<int?> heElevationFt = const Value.absent(),
    Value<double?> heHeadingDegT = const Value.absent(),
    Value<int?> heDisplacedThresholdFt = const Value.absent(),
  }) => Runway(
    id: id ?? this.id,
    airport: airport ?? this.airport,
    lengthFt: lengthFt.present ? lengthFt.value : this.lengthFt,
    widthFt: widthFt.present ? widthFt.value : this.widthFt,
    surface: surface.present ? surface.value : this.surface,
    lighted: lighted.present ? lighted.value : this.lighted,
    closed: closed.present ? closed.value : this.closed,
    leIdent: leIdent.present ? leIdent.value : this.leIdent,
    leLatitudeDeg: leLatitudeDeg.present
        ? leLatitudeDeg.value
        : this.leLatitudeDeg,
    leLongitudeDeg: leLongitudeDeg.present
        ? leLongitudeDeg.value
        : this.leLongitudeDeg,
    leElevationFt: leElevationFt.present
        ? leElevationFt.value
        : this.leElevationFt,
    leHeadingDegT: leHeadingDegT.present
        ? leHeadingDegT.value
        : this.leHeadingDegT,
    leDisplacedThresholdFt: leDisplacedThresholdFt.present
        ? leDisplacedThresholdFt.value
        : this.leDisplacedThresholdFt,
    heIdent: heIdent.present ? heIdent.value : this.heIdent,
    heLatitudeDeg: heLatitudeDeg.present
        ? heLatitudeDeg.value
        : this.heLatitudeDeg,
    heLongitudeDeg: heLongitudeDeg.present
        ? heLongitudeDeg.value
        : this.heLongitudeDeg,
    heElevationFt: heElevationFt.present
        ? heElevationFt.value
        : this.heElevationFt,
    heHeadingDegT: heHeadingDegT.present
        ? heHeadingDegT.value
        : this.heHeadingDegT,
    heDisplacedThresholdFt: heDisplacedThresholdFt.present
        ? heDisplacedThresholdFt.value
        : this.heDisplacedThresholdFt,
  );
  Runway copyWithCompanion(RunwaysCompanion data) {
    return Runway(
      id: data.id.present ? data.id.value : this.id,
      airport: data.airport.present ? data.airport.value : this.airport,
      lengthFt: data.lengthFt.present ? data.lengthFt.value : this.lengthFt,
      widthFt: data.widthFt.present ? data.widthFt.value : this.widthFt,
      surface: data.surface.present ? data.surface.value : this.surface,
      lighted: data.lighted.present ? data.lighted.value : this.lighted,
      closed: data.closed.present ? data.closed.value : this.closed,
      leIdent: data.leIdent.present ? data.leIdent.value : this.leIdent,
      leLatitudeDeg: data.leLatitudeDeg.present
          ? data.leLatitudeDeg.value
          : this.leLatitudeDeg,
      leLongitudeDeg: data.leLongitudeDeg.present
          ? data.leLongitudeDeg.value
          : this.leLongitudeDeg,
      leElevationFt: data.leElevationFt.present
          ? data.leElevationFt.value
          : this.leElevationFt,
      leHeadingDegT: data.leHeadingDegT.present
          ? data.leHeadingDegT.value
          : this.leHeadingDegT,
      leDisplacedThresholdFt: data.leDisplacedThresholdFt.present
          ? data.leDisplacedThresholdFt.value
          : this.leDisplacedThresholdFt,
      heIdent: data.heIdent.present ? data.heIdent.value : this.heIdent,
      heLatitudeDeg: data.heLatitudeDeg.present
          ? data.heLatitudeDeg.value
          : this.heLatitudeDeg,
      heLongitudeDeg: data.heLongitudeDeg.present
          ? data.heLongitudeDeg.value
          : this.heLongitudeDeg,
      heElevationFt: data.heElevationFt.present
          ? data.heElevationFt.value
          : this.heElevationFt,
      heHeadingDegT: data.heHeadingDegT.present
          ? data.heHeadingDegT.value
          : this.heHeadingDegT,
      heDisplacedThresholdFt: data.heDisplacedThresholdFt.present
          ? data.heDisplacedThresholdFt.value
          : this.heDisplacedThresholdFt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Runway(')
          ..write('id: $id, ')
          ..write('airport: $airport, ')
          ..write('lengthFt: $lengthFt, ')
          ..write('widthFt: $widthFt, ')
          ..write('surface: $surface, ')
          ..write('lighted: $lighted, ')
          ..write('closed: $closed, ')
          ..write('leIdent: $leIdent, ')
          ..write('leLatitudeDeg: $leLatitudeDeg, ')
          ..write('leLongitudeDeg: $leLongitudeDeg, ')
          ..write('leElevationFt: $leElevationFt, ')
          ..write('leHeadingDegT: $leHeadingDegT, ')
          ..write('leDisplacedThresholdFt: $leDisplacedThresholdFt, ')
          ..write('heIdent: $heIdent, ')
          ..write('heLatitudeDeg: $heLatitudeDeg, ')
          ..write('heLongitudeDeg: $heLongitudeDeg, ')
          ..write('heElevationFt: $heElevationFt, ')
          ..write('heHeadingDegT: $heHeadingDegT, ')
          ..write('heDisplacedThresholdFt: $heDisplacedThresholdFt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    airport,
    lengthFt,
    widthFt,
    surface,
    lighted,
    closed,
    leIdent,
    leLatitudeDeg,
    leLongitudeDeg,
    leElevationFt,
    leHeadingDegT,
    leDisplacedThresholdFt,
    heIdent,
    heLatitudeDeg,
    heLongitudeDeg,
    heElevationFt,
    heHeadingDegT,
    heDisplacedThresholdFt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Runway &&
          other.id == this.id &&
          other.airport == this.airport &&
          other.lengthFt == this.lengthFt &&
          other.widthFt == this.widthFt &&
          other.surface == this.surface &&
          other.lighted == this.lighted &&
          other.closed == this.closed &&
          other.leIdent == this.leIdent &&
          other.leLatitudeDeg == this.leLatitudeDeg &&
          other.leLongitudeDeg == this.leLongitudeDeg &&
          other.leElevationFt == this.leElevationFt &&
          other.leHeadingDegT == this.leHeadingDegT &&
          other.leDisplacedThresholdFt == this.leDisplacedThresholdFt &&
          other.heIdent == this.heIdent &&
          other.heLatitudeDeg == this.heLatitudeDeg &&
          other.heLongitudeDeg == this.heLongitudeDeg &&
          other.heElevationFt == this.heElevationFt &&
          other.heHeadingDegT == this.heHeadingDegT &&
          other.heDisplacedThresholdFt == this.heDisplacedThresholdFt);
}

class RunwaysCompanion extends UpdateCompanion<Runway> {
  final Value<int> id;
  final Value<int> airport;
  final Value<int?> lengthFt;
  final Value<int?> widthFt;
  final Value<String?> surface;
  final Value<bool?> lighted;
  final Value<bool?> closed;
  final Value<String?> leIdent;
  final Value<double?> leLatitudeDeg;
  final Value<double?> leLongitudeDeg;
  final Value<int?> leElevationFt;
  final Value<double?> leHeadingDegT;
  final Value<int?> leDisplacedThresholdFt;
  final Value<String?> heIdent;
  final Value<double?> heLatitudeDeg;
  final Value<double?> heLongitudeDeg;
  final Value<int?> heElevationFt;
  final Value<double?> heHeadingDegT;
  final Value<int?> heDisplacedThresholdFt;
  const RunwaysCompanion({
    this.id = const Value.absent(),
    this.airport = const Value.absent(),
    this.lengthFt = const Value.absent(),
    this.widthFt = const Value.absent(),
    this.surface = const Value.absent(),
    this.lighted = const Value.absent(),
    this.closed = const Value.absent(),
    this.leIdent = const Value.absent(),
    this.leLatitudeDeg = const Value.absent(),
    this.leLongitudeDeg = const Value.absent(),
    this.leElevationFt = const Value.absent(),
    this.leHeadingDegT = const Value.absent(),
    this.leDisplacedThresholdFt = const Value.absent(),
    this.heIdent = const Value.absent(),
    this.heLatitudeDeg = const Value.absent(),
    this.heLongitudeDeg = const Value.absent(),
    this.heElevationFt = const Value.absent(),
    this.heHeadingDegT = const Value.absent(),
    this.heDisplacedThresholdFt = const Value.absent(),
  });
  RunwaysCompanion.insert({
    this.id = const Value.absent(),
    required int airport,
    this.lengthFt = const Value.absent(),
    this.widthFt = const Value.absent(),
    this.surface = const Value.absent(),
    this.lighted = const Value.absent(),
    this.closed = const Value.absent(),
    this.leIdent = const Value.absent(),
    this.leLatitudeDeg = const Value.absent(),
    this.leLongitudeDeg = const Value.absent(),
    this.leElevationFt = const Value.absent(),
    this.leHeadingDegT = const Value.absent(),
    this.leDisplacedThresholdFt = const Value.absent(),
    this.heIdent = const Value.absent(),
    this.heLatitudeDeg = const Value.absent(),
    this.heLongitudeDeg = const Value.absent(),
    this.heElevationFt = const Value.absent(),
    this.heHeadingDegT = const Value.absent(),
    this.heDisplacedThresholdFt = const Value.absent(),
  }) : airport = Value(airport);
  static Insertable<Runway> custom({
    Expression<int>? id,
    Expression<int>? airport,
    Expression<int>? lengthFt,
    Expression<int>? widthFt,
    Expression<String>? surface,
    Expression<bool>? lighted,
    Expression<bool>? closed,
    Expression<String>? leIdent,
    Expression<double>? leLatitudeDeg,
    Expression<double>? leLongitudeDeg,
    Expression<int>? leElevationFt,
    Expression<double>? leHeadingDegT,
    Expression<int>? leDisplacedThresholdFt,
    Expression<String>? heIdent,
    Expression<double>? heLatitudeDeg,
    Expression<double>? heLongitudeDeg,
    Expression<int>? heElevationFt,
    Expression<double>? heHeadingDegT,
    Expression<int>? heDisplacedThresholdFt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (airport != null) 'airport': airport,
      if (lengthFt != null) 'length_ft': lengthFt,
      if (widthFt != null) 'width_ft': widthFt,
      if (surface != null) 'surface': surface,
      if (lighted != null) 'lighted': lighted,
      if (closed != null) 'closed': closed,
      if (leIdent != null) 'le_ident': leIdent,
      if (leLatitudeDeg != null) 'le_latitude_deg': leLatitudeDeg,
      if (leLongitudeDeg != null) 'le_longitude_deg': leLongitudeDeg,
      if (leElevationFt != null) 'le_elevation_ft': leElevationFt,
      if (leHeadingDegT != null) 'le_heading_deg_t': leHeadingDegT,
      if (leDisplacedThresholdFt != null)
        'le_displaced_threshold_ft': leDisplacedThresholdFt,
      if (heIdent != null) 'he_ident': heIdent,
      if (heLatitudeDeg != null) 'he_latitude_deg': heLatitudeDeg,
      if (heLongitudeDeg != null) 'he_longitude_deg': heLongitudeDeg,
      if (heElevationFt != null) 'he_elevation_ft': heElevationFt,
      if (heHeadingDegT != null) 'he_heading_deg_t': heHeadingDegT,
      if (heDisplacedThresholdFt != null)
        'he_displaced_threshold_ft': heDisplacedThresholdFt,
    });
  }

  RunwaysCompanion copyWith({
    Value<int>? id,
    Value<int>? airport,
    Value<int?>? lengthFt,
    Value<int?>? widthFt,
    Value<String?>? surface,
    Value<bool?>? lighted,
    Value<bool?>? closed,
    Value<String?>? leIdent,
    Value<double?>? leLatitudeDeg,
    Value<double?>? leLongitudeDeg,
    Value<int?>? leElevationFt,
    Value<double?>? leHeadingDegT,
    Value<int?>? leDisplacedThresholdFt,
    Value<String?>? heIdent,
    Value<double?>? heLatitudeDeg,
    Value<double?>? heLongitudeDeg,
    Value<int?>? heElevationFt,
    Value<double?>? heHeadingDegT,
    Value<int?>? heDisplacedThresholdFt,
  }) {
    return RunwaysCompanion(
      id: id ?? this.id,
      airport: airport ?? this.airport,
      lengthFt: lengthFt ?? this.lengthFt,
      widthFt: widthFt ?? this.widthFt,
      surface: surface ?? this.surface,
      lighted: lighted ?? this.lighted,
      closed: closed ?? this.closed,
      leIdent: leIdent ?? this.leIdent,
      leLatitudeDeg: leLatitudeDeg ?? this.leLatitudeDeg,
      leLongitudeDeg: leLongitudeDeg ?? this.leLongitudeDeg,
      leElevationFt: leElevationFt ?? this.leElevationFt,
      leHeadingDegT: leHeadingDegT ?? this.leHeadingDegT,
      leDisplacedThresholdFt:
          leDisplacedThresholdFt ?? this.leDisplacedThresholdFt,
      heIdent: heIdent ?? this.heIdent,
      heLatitudeDeg: heLatitudeDeg ?? this.heLatitudeDeg,
      heLongitudeDeg: heLongitudeDeg ?? this.heLongitudeDeg,
      heElevationFt: heElevationFt ?? this.heElevationFt,
      heHeadingDegT: heHeadingDegT ?? this.heHeadingDegT,
      heDisplacedThresholdFt:
          heDisplacedThresholdFt ?? this.heDisplacedThresholdFt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (airport.present) {
      map['airport'] = Variable<int>(airport.value);
    }
    if (lengthFt.present) {
      map['length_ft'] = Variable<int>(lengthFt.value);
    }
    if (widthFt.present) {
      map['width_ft'] = Variable<int>(widthFt.value);
    }
    if (surface.present) {
      map['surface'] = Variable<String>(surface.value);
    }
    if (lighted.present) {
      map['lighted'] = Variable<bool>(lighted.value);
    }
    if (closed.present) {
      map['closed'] = Variable<bool>(closed.value);
    }
    if (leIdent.present) {
      map['le_ident'] = Variable<String>(leIdent.value);
    }
    if (leLatitudeDeg.present) {
      map['le_latitude_deg'] = Variable<double>(leLatitudeDeg.value);
    }
    if (leLongitudeDeg.present) {
      map['le_longitude_deg'] = Variable<double>(leLongitudeDeg.value);
    }
    if (leElevationFt.present) {
      map['le_elevation_ft'] = Variable<int>(leElevationFt.value);
    }
    if (leHeadingDegT.present) {
      map['le_heading_deg_t'] = Variable<double>(leHeadingDegT.value);
    }
    if (leDisplacedThresholdFt.present) {
      map['le_displaced_threshold_ft'] = Variable<int>(
        leDisplacedThresholdFt.value,
      );
    }
    if (heIdent.present) {
      map['he_ident'] = Variable<String>(heIdent.value);
    }
    if (heLatitudeDeg.present) {
      map['he_latitude_deg'] = Variable<double>(heLatitudeDeg.value);
    }
    if (heLongitudeDeg.present) {
      map['he_longitude_deg'] = Variable<double>(heLongitudeDeg.value);
    }
    if (heElevationFt.present) {
      map['he_elevation_ft'] = Variable<int>(heElevationFt.value);
    }
    if (heHeadingDegT.present) {
      map['he_heading_deg_t'] = Variable<double>(heHeadingDegT.value);
    }
    if (heDisplacedThresholdFt.present) {
      map['he_displaced_threshold_ft'] = Variable<int>(
        heDisplacedThresholdFt.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RunwaysCompanion(')
          ..write('id: $id, ')
          ..write('airport: $airport, ')
          ..write('lengthFt: $lengthFt, ')
          ..write('widthFt: $widthFt, ')
          ..write('surface: $surface, ')
          ..write('lighted: $lighted, ')
          ..write('closed: $closed, ')
          ..write('leIdent: $leIdent, ')
          ..write('leLatitudeDeg: $leLatitudeDeg, ')
          ..write('leLongitudeDeg: $leLongitudeDeg, ')
          ..write('leElevationFt: $leElevationFt, ')
          ..write('leHeadingDegT: $leHeadingDegT, ')
          ..write('leDisplacedThresholdFt: $leDisplacedThresholdFt, ')
          ..write('heIdent: $heIdent, ')
          ..write('heLatitudeDeg: $heLatitudeDeg, ')
          ..write('heLongitudeDeg: $heLongitudeDeg, ')
          ..write('heElevationFt: $heElevationFt, ')
          ..write('heHeadingDegT: $heHeadingDegT, ')
          ..write('heDisplacedThresholdFt: $heDisplacedThresholdFt')
          ..write(')'))
        .toString();
  }
}

class $IcaoAircraftsTable extends IcaoAircrafts
    with TableInfo<$IcaoAircraftsTable, IcaoAircraft> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IcaoAircraftsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _modelFullNameMeta = const VerificationMeta(
    'modelFullName',
  );
  @override
  late final GeneratedColumn<String> modelFullName = GeneratedColumn<String>(
    'model_full_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _designatorMeta = const VerificationMeta(
    'designator',
  );
  @override
  late final GeneratedColumn<String> designator = GeneratedColumn<String>(
    'designator',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<WakeTurbulenceCategory, String>
  wakeTurbolenceCategory =
      GeneratedColumn<String>(
        'wake_turbolence_category',
        aliasedName,
        false,
        additionalChecks: GeneratedColumn.checkTextLength(
          minTextLength: 1,
          maxTextLength: 1,
        ),
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<WakeTurbulenceCategory>(
        $IcaoAircraftsTable.$converterwakeTurbolenceCategory,
      );
  @override
  late final GeneratedColumnWithTypeConverter<WakeTurbulenceGroup, String>
  wakeTurbolenceGroup =
      GeneratedColumn<String>(
        'wake_turbolence_group',
        aliasedName,
        false,
        additionalChecks: GeneratedColumn.checkTextLength(
          minTextLength: 1,
          maxTextLength: 1,
        ),
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<WakeTurbulenceGroup>(
        $IcaoAircraftsTable.$converterwakeTurbolenceGroup,
      );
  static const VerificationMeta _manufacturerMeta = const VerificationMeta(
    'manufacturer',
  );
  @override
  late final GeneratedColumn<String> manufacturer = GeneratedColumn<String>(
    'manufacturer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AircraftDescription, String>
  description =
      GeneratedColumn<String>(
        'description',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AircraftDescription>(
        $IcaoAircraftsTable.$converterdescription,
      );
  static const VerificationMeta _engineCountMeta = const VerificationMeta(
    'engineCount',
  );
  @override
  late final GeneratedColumn<int> engineCount = GeneratedColumn<int>(
    'engine_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<EngineType, String> engineType =
      GeneratedColumn<String>(
        'engine_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<EngineType>($IcaoAircraftsTable.$converterengineType);
  static const VerificationMeta _userInsertedMeta = const VerificationMeta(
    'userInserted',
  );
  @override
  late final GeneratedColumn<bool> userInserted = GeneratedColumn<bool>(
    'user_inserted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("user_inserted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    modelFullName,
    designator,
    wakeTurbolenceCategory,
    wakeTurbolenceGroup,
    manufacturer,
    description,
    engineCount,
    engineType,
    userInserted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'icao_aircrafts';
  @override
  VerificationContext validateIntegrity(
    Insertable<IcaoAircraft> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('model_full_name')) {
      context.handle(
        _modelFullNameMeta,
        modelFullName.isAcceptableOrUnknown(
          data['model_full_name']!,
          _modelFullNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_modelFullNameMeta);
    }
    if (data.containsKey('designator')) {
      context.handle(
        _designatorMeta,
        designator.isAcceptableOrUnknown(data['designator']!, _designatorMeta),
      );
    } else if (isInserting) {
      context.missing(_designatorMeta);
    }
    if (data.containsKey('manufacturer')) {
      context.handle(
        _manufacturerMeta,
        manufacturer.isAcceptableOrUnknown(
          data['manufacturer']!,
          _manufacturerMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_manufacturerMeta);
    }
    if (data.containsKey('engine_count')) {
      context.handle(
        _engineCountMeta,
        engineCount.isAcceptableOrUnknown(
          data['engine_count']!,
          _engineCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_engineCountMeta);
    }
    if (data.containsKey('user_inserted')) {
      context.handle(
        _userInsertedMeta,
        userInserted.isAcceptableOrUnknown(
          data['user_inserted']!,
          _userInsertedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IcaoAircraft map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IcaoAircraft(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      modelFullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_full_name'],
      )!,
      designator: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}designator'],
      )!,
      wakeTurbolenceCategory: $IcaoAircraftsTable
          .$converterwakeTurbolenceCategory
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}wake_turbolence_category'],
            )!,
          ),
      wakeTurbolenceGroup: $IcaoAircraftsTable.$converterwakeTurbolenceGroup
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}wake_turbolence_group'],
            )!,
          ),
      manufacturer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manufacturer'],
      )!,
      description: $IcaoAircraftsTable.$converterdescription.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}description'],
        )!,
      ),
      engineCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}engine_count'],
      )!,
      engineType: $IcaoAircraftsTable.$converterengineType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}engine_type'],
        )!,
      ),
      userInserted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}user_inserted'],
      )!,
    );
  }

  @override
  $IcaoAircraftsTable createAlias(String alias) {
    return $IcaoAircraftsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<WakeTurbulenceCategory, String, String>
  $converterwakeTurbolenceCategory =
      const EnumNameConverter<WakeTurbulenceCategory>(
        WakeTurbulenceCategory.values,
      );
  static JsonTypeConverter2<WakeTurbulenceGroup, String, String>
  $converterwakeTurbolenceGroup = const EnumNameConverter<WakeTurbulenceGroup>(
    WakeTurbulenceGroup.values,
  );
  static JsonTypeConverter2<AircraftDescription, String, String>
  $converterdescription = const EnumNameConverter<AircraftDescription>(
    AircraftDescription.values,
  );
  static JsonTypeConverter2<EngineType, String, String> $converterengineType =
      const EnumNameConverter<EngineType>(EngineType.values);
}

class IcaoAircraft extends DataClass implements Insertable<IcaoAircraft> {
  final int id;
  final String modelFullName;
  final String designator;
  final WakeTurbulenceCategory wakeTurbolenceCategory;
  final WakeTurbulenceGroup wakeTurbolenceGroup;
  final String manufacturer;
  final AircraftDescription description;
  final int engineCount;
  final EngineType engineType;
  final bool userInserted;
  const IcaoAircraft({
    required this.id,
    required this.modelFullName,
    required this.designator,
    required this.wakeTurbolenceCategory,
    required this.wakeTurbolenceGroup,
    required this.manufacturer,
    required this.description,
    required this.engineCount,
    required this.engineType,
    required this.userInserted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['model_full_name'] = Variable<String>(modelFullName);
    map['designator'] = Variable<String>(designator);
    {
      map['wake_turbolence_category'] = Variable<String>(
        $IcaoAircraftsTable.$converterwakeTurbolenceCategory.toSql(
          wakeTurbolenceCategory,
        ),
      );
    }
    {
      map['wake_turbolence_group'] = Variable<String>(
        $IcaoAircraftsTable.$converterwakeTurbolenceGroup.toSql(
          wakeTurbolenceGroup,
        ),
      );
    }
    map['manufacturer'] = Variable<String>(manufacturer);
    {
      map['description'] = Variable<String>(
        $IcaoAircraftsTable.$converterdescription.toSql(description),
      );
    }
    map['engine_count'] = Variable<int>(engineCount);
    {
      map['engine_type'] = Variable<String>(
        $IcaoAircraftsTable.$converterengineType.toSql(engineType),
      );
    }
    map['user_inserted'] = Variable<bool>(userInserted);
    return map;
  }

  IcaoAircraftsCompanion toCompanion(bool nullToAbsent) {
    return IcaoAircraftsCompanion(
      id: Value(id),
      modelFullName: Value(modelFullName),
      designator: Value(designator),
      wakeTurbolenceCategory: Value(wakeTurbolenceCategory),
      wakeTurbolenceGroup: Value(wakeTurbolenceGroup),
      manufacturer: Value(manufacturer),
      description: Value(description),
      engineCount: Value(engineCount),
      engineType: Value(engineType),
      userInserted: Value(userInserted),
    );
  }

  factory IcaoAircraft.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IcaoAircraft(
      id: serializer.fromJson<int>(json['id']),
      modelFullName: serializer.fromJson<String>(json['modelFullName']),
      designator: serializer.fromJson<String>(json['designator']),
      wakeTurbolenceCategory: $IcaoAircraftsTable
          .$converterwakeTurbolenceCategory
          .fromJson(
            serializer.fromJson<String>(json['wakeTurbolenceCategory']),
          ),
      wakeTurbolenceGroup: $IcaoAircraftsTable.$converterwakeTurbolenceGroup
          .fromJson(serializer.fromJson<String>(json['wakeTurbolenceGroup'])),
      manufacturer: serializer.fromJson<String>(json['manufacturer']),
      description: $IcaoAircraftsTable.$converterdescription.fromJson(
        serializer.fromJson<String>(json['description']),
      ),
      engineCount: serializer.fromJson<int>(json['engineCount']),
      engineType: $IcaoAircraftsTable.$converterengineType.fromJson(
        serializer.fromJson<String>(json['engineType']),
      ),
      userInserted: serializer.fromJson<bool>(json['userInserted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'modelFullName': serializer.toJson<String>(modelFullName),
      'designator': serializer.toJson<String>(designator),
      'wakeTurbolenceCategory': serializer.toJson<String>(
        $IcaoAircraftsTable.$converterwakeTurbolenceCategory.toJson(
          wakeTurbolenceCategory,
        ),
      ),
      'wakeTurbolenceGroup': serializer.toJson<String>(
        $IcaoAircraftsTable.$converterwakeTurbolenceGroup.toJson(
          wakeTurbolenceGroup,
        ),
      ),
      'manufacturer': serializer.toJson<String>(manufacturer),
      'description': serializer.toJson<String>(
        $IcaoAircraftsTable.$converterdescription.toJson(description),
      ),
      'engineCount': serializer.toJson<int>(engineCount),
      'engineType': serializer.toJson<String>(
        $IcaoAircraftsTable.$converterengineType.toJson(engineType),
      ),
      'userInserted': serializer.toJson<bool>(userInserted),
    };
  }

  IcaoAircraft copyWith({
    int? id,
    String? modelFullName,
    String? designator,
    WakeTurbulenceCategory? wakeTurbolenceCategory,
    WakeTurbulenceGroup? wakeTurbolenceGroup,
    String? manufacturer,
    AircraftDescription? description,
    int? engineCount,
    EngineType? engineType,
    bool? userInserted,
  }) => IcaoAircraft(
    id: id ?? this.id,
    modelFullName: modelFullName ?? this.modelFullName,
    designator: designator ?? this.designator,
    wakeTurbolenceCategory:
        wakeTurbolenceCategory ?? this.wakeTurbolenceCategory,
    wakeTurbolenceGroup: wakeTurbolenceGroup ?? this.wakeTurbolenceGroup,
    manufacturer: manufacturer ?? this.manufacturer,
    description: description ?? this.description,
    engineCount: engineCount ?? this.engineCount,
    engineType: engineType ?? this.engineType,
    userInserted: userInserted ?? this.userInserted,
  );
  IcaoAircraft copyWithCompanion(IcaoAircraftsCompanion data) {
    return IcaoAircraft(
      id: data.id.present ? data.id.value : this.id,
      modelFullName: data.modelFullName.present
          ? data.modelFullName.value
          : this.modelFullName,
      designator: data.designator.present
          ? data.designator.value
          : this.designator,
      wakeTurbolenceCategory: data.wakeTurbolenceCategory.present
          ? data.wakeTurbolenceCategory.value
          : this.wakeTurbolenceCategory,
      wakeTurbolenceGroup: data.wakeTurbolenceGroup.present
          ? data.wakeTurbolenceGroup.value
          : this.wakeTurbolenceGroup,
      manufacturer: data.manufacturer.present
          ? data.manufacturer.value
          : this.manufacturer,
      description: data.description.present
          ? data.description.value
          : this.description,
      engineCount: data.engineCount.present
          ? data.engineCount.value
          : this.engineCount,
      engineType: data.engineType.present
          ? data.engineType.value
          : this.engineType,
      userInserted: data.userInserted.present
          ? data.userInserted.value
          : this.userInserted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IcaoAircraft(')
          ..write('id: $id, ')
          ..write('modelFullName: $modelFullName, ')
          ..write('designator: $designator, ')
          ..write('wakeTurbolenceCategory: $wakeTurbolenceCategory, ')
          ..write('wakeTurbolenceGroup: $wakeTurbolenceGroup, ')
          ..write('manufacturer: $manufacturer, ')
          ..write('description: $description, ')
          ..write('engineCount: $engineCount, ')
          ..write('engineType: $engineType, ')
          ..write('userInserted: $userInserted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    modelFullName,
    designator,
    wakeTurbolenceCategory,
    wakeTurbolenceGroup,
    manufacturer,
    description,
    engineCount,
    engineType,
    userInserted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IcaoAircraft &&
          other.id == this.id &&
          other.modelFullName == this.modelFullName &&
          other.designator == this.designator &&
          other.wakeTurbolenceCategory == this.wakeTurbolenceCategory &&
          other.wakeTurbolenceGroup == this.wakeTurbolenceGroup &&
          other.manufacturer == this.manufacturer &&
          other.description == this.description &&
          other.engineCount == this.engineCount &&
          other.engineType == this.engineType &&
          other.userInserted == this.userInserted);
}

class IcaoAircraftsCompanion extends UpdateCompanion<IcaoAircraft> {
  final Value<int> id;
  final Value<String> modelFullName;
  final Value<String> designator;
  final Value<WakeTurbulenceCategory> wakeTurbolenceCategory;
  final Value<WakeTurbulenceGroup> wakeTurbolenceGroup;
  final Value<String> manufacturer;
  final Value<AircraftDescription> description;
  final Value<int> engineCount;
  final Value<EngineType> engineType;
  final Value<bool> userInserted;
  const IcaoAircraftsCompanion({
    this.id = const Value.absent(),
    this.modelFullName = const Value.absent(),
    this.designator = const Value.absent(),
    this.wakeTurbolenceCategory = const Value.absent(),
    this.wakeTurbolenceGroup = const Value.absent(),
    this.manufacturer = const Value.absent(),
    this.description = const Value.absent(),
    this.engineCount = const Value.absent(),
    this.engineType = const Value.absent(),
    this.userInserted = const Value.absent(),
  });
  IcaoAircraftsCompanion.insert({
    this.id = const Value.absent(),
    required String modelFullName,
    required String designator,
    required WakeTurbulenceCategory wakeTurbolenceCategory,
    required WakeTurbulenceGroup wakeTurbolenceGroup,
    required String manufacturer,
    required AircraftDescription description,
    required int engineCount,
    required EngineType engineType,
    this.userInserted = const Value.absent(),
  }) : modelFullName = Value(modelFullName),
       designator = Value(designator),
       wakeTurbolenceCategory = Value(wakeTurbolenceCategory),
       wakeTurbolenceGroup = Value(wakeTurbolenceGroup),
       manufacturer = Value(manufacturer),
       description = Value(description),
       engineCount = Value(engineCount),
       engineType = Value(engineType);
  static Insertable<IcaoAircraft> custom({
    Expression<int>? id,
    Expression<String>? modelFullName,
    Expression<String>? designator,
    Expression<String>? wakeTurbolenceCategory,
    Expression<String>? wakeTurbolenceGroup,
    Expression<String>? manufacturer,
    Expression<String>? description,
    Expression<int>? engineCount,
    Expression<String>? engineType,
    Expression<bool>? userInserted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (modelFullName != null) 'model_full_name': modelFullName,
      if (designator != null) 'designator': designator,
      if (wakeTurbolenceCategory != null)
        'wake_turbolence_category': wakeTurbolenceCategory,
      if (wakeTurbolenceGroup != null)
        'wake_turbolence_group': wakeTurbolenceGroup,
      if (manufacturer != null) 'manufacturer': manufacturer,
      if (description != null) 'description': description,
      if (engineCount != null) 'engine_count': engineCount,
      if (engineType != null) 'engine_type': engineType,
      if (userInserted != null) 'user_inserted': userInserted,
    });
  }

  IcaoAircraftsCompanion copyWith({
    Value<int>? id,
    Value<String>? modelFullName,
    Value<String>? designator,
    Value<WakeTurbulenceCategory>? wakeTurbolenceCategory,
    Value<WakeTurbulenceGroup>? wakeTurbolenceGroup,
    Value<String>? manufacturer,
    Value<AircraftDescription>? description,
    Value<int>? engineCount,
    Value<EngineType>? engineType,
    Value<bool>? userInserted,
  }) {
    return IcaoAircraftsCompanion(
      id: id ?? this.id,
      modelFullName: modelFullName ?? this.modelFullName,
      designator: designator ?? this.designator,
      wakeTurbolenceCategory:
          wakeTurbolenceCategory ?? this.wakeTurbolenceCategory,
      wakeTurbolenceGroup: wakeTurbolenceGroup ?? this.wakeTurbolenceGroup,
      manufacturer: manufacturer ?? this.manufacturer,
      description: description ?? this.description,
      engineCount: engineCount ?? this.engineCount,
      engineType: engineType ?? this.engineType,
      userInserted: userInserted ?? this.userInserted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (modelFullName.present) {
      map['model_full_name'] = Variable<String>(modelFullName.value);
    }
    if (designator.present) {
      map['designator'] = Variable<String>(designator.value);
    }
    if (wakeTurbolenceCategory.present) {
      map['wake_turbolence_category'] = Variable<String>(
        $IcaoAircraftsTable.$converterwakeTurbolenceCategory.toSql(
          wakeTurbolenceCategory.value,
        ),
      );
    }
    if (wakeTurbolenceGroup.present) {
      map['wake_turbolence_group'] = Variable<String>(
        $IcaoAircraftsTable.$converterwakeTurbolenceGroup.toSql(
          wakeTurbolenceGroup.value,
        ),
      );
    }
    if (manufacturer.present) {
      map['manufacturer'] = Variable<String>(manufacturer.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(
        $IcaoAircraftsTable.$converterdescription.toSql(description.value),
      );
    }
    if (engineCount.present) {
      map['engine_count'] = Variable<int>(engineCount.value);
    }
    if (engineType.present) {
      map['engine_type'] = Variable<String>(
        $IcaoAircraftsTable.$converterengineType.toSql(engineType.value),
      );
    }
    if (userInserted.present) {
      map['user_inserted'] = Variable<bool>(userInserted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IcaoAircraftsCompanion(')
          ..write('id: $id, ')
          ..write('modelFullName: $modelFullName, ')
          ..write('designator: $designator, ')
          ..write('wakeTurbolenceCategory: $wakeTurbolenceCategory, ')
          ..write('wakeTurbolenceGroup: $wakeTurbolenceGroup, ')
          ..write('manufacturer: $manufacturer, ')
          ..write('description: $description, ')
          ..write('engineCount: $engineCount, ')
          ..write('engineType: $engineType, ')
          ..write('userInserted: $userInserted')
          ..write(')'))
        .toString();
  }
}

class $AircraftsTable extends Aircrafts
    with TableInfo<$AircraftsTable, Aircraft> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AircraftsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _icaoAircraftMeta = const VerificationMeta(
    'icaoAircraft',
  );
  @override
  late final GeneratedColumn<int> icaoAircraft = GeneratedColumn<int>(
    'icao_aircraft',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES icao_aircrafts (id)',
    ),
  );
  static const VerificationMeta _tailNumberMeta = const VerificationMeta(
    'tailNumber',
  );
  @override
  late final GeneratedColumn<String> tailNumber = GeneratedColumn<String>(
    'tail_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AircraftClass?, String>
  aircraftClass = GeneratedColumn<String>(
    'aircraft_class',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<AircraftClass?>($AircraftsTable.$converteraircraftClassn);
  static const VerificationMeta _typeRatingMeta = const VerificationMeta(
    'typeRating',
  );
  @override
  late final GeneratedColumn<String> typeRating = GeneratedColumn<String>(
    'type_rating',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoFileMeta = const VerificationMeta(
    'photoFile',
  );
  @override
  late final GeneratedColumn<String> photoFile = GeneratedColumn<String>(
    'photo_file',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoUrlMeta = const VerificationMeta(
    'photoUrl',
  );
  @override
  late final GeneratedColumn<String> photoUrl = GeneratedColumn<String>(
    'photo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoThumbnailUrlMeta = const VerificationMeta(
    'photoThumbnailUrl',
  );
  @override
  late final GeneratedColumn<String> photoThumbnailUrl =
      GeneratedColumn<String>(
        'photo_thumbnail_url',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _photoLinkMeta = const VerificationMeta(
    'photoLink',
  );
  @override
  late final GeneratedColumn<String> photoLink = GeneratedColumn<String>(
    'photo_link',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoCreditMeta = const VerificationMeta(
    'photoCredit',
  );
  @override
  late final GeneratedColumn<String> photoCredit = GeneratedColumn<String>(
    'photo_credit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    icaoAircraft,
    tailNumber,
    notes,
    aircraftClass,
    typeRating,
    photoFile,
    photoUrl,
    photoThumbnailUrl,
    photoLink,
    photoCredit,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'aircrafts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Aircraft> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('icao_aircraft')) {
      context.handle(
        _icaoAircraftMeta,
        icaoAircraft.isAcceptableOrUnknown(
          data['icao_aircraft']!,
          _icaoAircraftMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_icaoAircraftMeta);
    }
    if (data.containsKey('tail_number')) {
      context.handle(
        _tailNumberMeta,
        tailNumber.isAcceptableOrUnknown(data['tail_number']!, _tailNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_tailNumberMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('type_rating')) {
      context.handle(
        _typeRatingMeta,
        typeRating.isAcceptableOrUnknown(data['type_rating']!, _typeRatingMeta),
      );
    }
    if (data.containsKey('photo_file')) {
      context.handle(
        _photoFileMeta,
        photoFile.isAcceptableOrUnknown(data['photo_file']!, _photoFileMeta),
      );
    }
    if (data.containsKey('photo_url')) {
      context.handle(
        _photoUrlMeta,
        photoUrl.isAcceptableOrUnknown(data['photo_url']!, _photoUrlMeta),
      );
    }
    if (data.containsKey('photo_thumbnail_url')) {
      context.handle(
        _photoThumbnailUrlMeta,
        photoThumbnailUrl.isAcceptableOrUnknown(
          data['photo_thumbnail_url']!,
          _photoThumbnailUrlMeta,
        ),
      );
    }
    if (data.containsKey('photo_link')) {
      context.handle(
        _photoLinkMeta,
        photoLink.isAcceptableOrUnknown(data['photo_link']!, _photoLinkMeta),
      );
    }
    if (data.containsKey('photo_credit')) {
      context.handle(
        _photoCreditMeta,
        photoCredit.isAcceptableOrUnknown(
          data['photo_credit']!,
          _photoCreditMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Aircraft map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Aircraft(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      icaoAircraft: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}icao_aircraft'],
      )!,
      tailNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tail_number'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      aircraftClass: $AircraftsTable.$converteraircraftClassn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}aircraft_class'],
        ),
      ),
      typeRating: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type_rating'],
      ),
      photoFile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_file'],
      ),
      photoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_url'],
      ),
      photoThumbnailUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_thumbnail_url'],
      ),
      photoLink: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_link'],
      ),
      photoCredit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_credit'],
      ),
    );
  }

  @override
  $AircraftsTable createAlias(String alias) {
    return $AircraftsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AircraftClass, String, String>
  $converteraircraftClass = const EnumNameConverter<AircraftClass>(
    AircraftClass.values,
  );
  static JsonTypeConverter2<AircraftClass?, String?, String?>
  $converteraircraftClassn = JsonTypeConverter2.asNullable(
    $converteraircraftClass,
  );
}

class Aircraft extends DataClass implements Insertable<Aircraft> {
  final int id;
  final int icaoAircraft;
  final String tailNumber;
  final String? notes;

  /// Rating the aircraft is flown under. Null until it is chosen.
  final AircraftClass? aircraftClass;

  /// Licence endorsement of the type rating (e.g. "A320"), when
  /// [aircraftClass] is [AircraftClass.type].
  final String? typeRating;

  /// File name of a photo the user picked themselves, inside the app's
  /// aircraft photo folder. Shown instead of the online photo.
  final String? photoFile;

  /// Photo found online (JetPhotos). The picture is never stored, only where
  /// it is: full size image, small image for lists, the page it comes from
  /// and who took it.
  final String? photoUrl;
  final String? photoThumbnailUrl;
  final String? photoLink;
  final String? photoCredit;
  const Aircraft({
    required this.id,
    required this.icaoAircraft,
    required this.tailNumber,
    this.notes,
    this.aircraftClass,
    this.typeRating,
    this.photoFile,
    this.photoUrl,
    this.photoThumbnailUrl,
    this.photoLink,
    this.photoCredit,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['icao_aircraft'] = Variable<int>(icaoAircraft);
    map['tail_number'] = Variable<String>(tailNumber);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || aircraftClass != null) {
      map['aircraft_class'] = Variable<String>(
        $AircraftsTable.$converteraircraftClassn.toSql(aircraftClass),
      );
    }
    if (!nullToAbsent || typeRating != null) {
      map['type_rating'] = Variable<String>(typeRating);
    }
    if (!nullToAbsent || photoFile != null) {
      map['photo_file'] = Variable<String>(photoFile);
    }
    if (!nullToAbsent || photoUrl != null) {
      map['photo_url'] = Variable<String>(photoUrl);
    }
    if (!nullToAbsent || photoThumbnailUrl != null) {
      map['photo_thumbnail_url'] = Variable<String>(photoThumbnailUrl);
    }
    if (!nullToAbsent || photoLink != null) {
      map['photo_link'] = Variable<String>(photoLink);
    }
    if (!nullToAbsent || photoCredit != null) {
      map['photo_credit'] = Variable<String>(photoCredit);
    }
    return map;
  }

  AircraftsCompanion toCompanion(bool nullToAbsent) {
    return AircraftsCompanion(
      id: Value(id),
      icaoAircraft: Value(icaoAircraft),
      tailNumber: Value(tailNumber),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      aircraftClass: aircraftClass == null && nullToAbsent
          ? const Value.absent()
          : Value(aircraftClass),
      typeRating: typeRating == null && nullToAbsent
          ? const Value.absent()
          : Value(typeRating),
      photoFile: photoFile == null && nullToAbsent
          ? const Value.absent()
          : Value(photoFile),
      photoUrl: photoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(photoUrl),
      photoThumbnailUrl: photoThumbnailUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(photoThumbnailUrl),
      photoLink: photoLink == null && nullToAbsent
          ? const Value.absent()
          : Value(photoLink),
      photoCredit: photoCredit == null && nullToAbsent
          ? const Value.absent()
          : Value(photoCredit),
    );
  }

  factory Aircraft.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Aircraft(
      id: serializer.fromJson<int>(json['id']),
      icaoAircraft: serializer.fromJson<int>(json['icaoAircraft']),
      tailNumber: serializer.fromJson<String>(json['tailNumber']),
      notes: serializer.fromJson<String?>(json['notes']),
      aircraftClass: $AircraftsTable.$converteraircraftClassn.fromJson(
        serializer.fromJson<String?>(json['aircraftClass']),
      ),
      typeRating: serializer.fromJson<String?>(json['typeRating']),
      photoFile: serializer.fromJson<String?>(json['photoFile']),
      photoUrl: serializer.fromJson<String?>(json['photoUrl']),
      photoThumbnailUrl: serializer.fromJson<String?>(
        json['photoThumbnailUrl'],
      ),
      photoLink: serializer.fromJson<String?>(json['photoLink']),
      photoCredit: serializer.fromJson<String?>(json['photoCredit']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'icaoAircraft': serializer.toJson<int>(icaoAircraft),
      'tailNumber': serializer.toJson<String>(tailNumber),
      'notes': serializer.toJson<String?>(notes),
      'aircraftClass': serializer.toJson<String?>(
        $AircraftsTable.$converteraircraftClassn.toJson(aircraftClass),
      ),
      'typeRating': serializer.toJson<String?>(typeRating),
      'photoFile': serializer.toJson<String?>(photoFile),
      'photoUrl': serializer.toJson<String?>(photoUrl),
      'photoThumbnailUrl': serializer.toJson<String?>(photoThumbnailUrl),
      'photoLink': serializer.toJson<String?>(photoLink),
      'photoCredit': serializer.toJson<String?>(photoCredit),
    };
  }

  Aircraft copyWith({
    int? id,
    int? icaoAircraft,
    String? tailNumber,
    Value<String?> notes = const Value.absent(),
    Value<AircraftClass?> aircraftClass = const Value.absent(),
    Value<String?> typeRating = const Value.absent(),
    Value<String?> photoFile = const Value.absent(),
    Value<String?> photoUrl = const Value.absent(),
    Value<String?> photoThumbnailUrl = const Value.absent(),
    Value<String?> photoLink = const Value.absent(),
    Value<String?> photoCredit = const Value.absent(),
  }) => Aircraft(
    id: id ?? this.id,
    icaoAircraft: icaoAircraft ?? this.icaoAircraft,
    tailNumber: tailNumber ?? this.tailNumber,
    notes: notes.present ? notes.value : this.notes,
    aircraftClass: aircraftClass.present
        ? aircraftClass.value
        : this.aircraftClass,
    typeRating: typeRating.present ? typeRating.value : this.typeRating,
    photoFile: photoFile.present ? photoFile.value : this.photoFile,
    photoUrl: photoUrl.present ? photoUrl.value : this.photoUrl,
    photoThumbnailUrl: photoThumbnailUrl.present
        ? photoThumbnailUrl.value
        : this.photoThumbnailUrl,
    photoLink: photoLink.present ? photoLink.value : this.photoLink,
    photoCredit: photoCredit.present ? photoCredit.value : this.photoCredit,
  );
  Aircraft copyWithCompanion(AircraftsCompanion data) {
    return Aircraft(
      id: data.id.present ? data.id.value : this.id,
      icaoAircraft: data.icaoAircraft.present
          ? data.icaoAircraft.value
          : this.icaoAircraft,
      tailNumber: data.tailNumber.present
          ? data.tailNumber.value
          : this.tailNumber,
      notes: data.notes.present ? data.notes.value : this.notes,
      aircraftClass: data.aircraftClass.present
          ? data.aircraftClass.value
          : this.aircraftClass,
      typeRating: data.typeRating.present
          ? data.typeRating.value
          : this.typeRating,
      photoFile: data.photoFile.present ? data.photoFile.value : this.photoFile,
      photoUrl: data.photoUrl.present ? data.photoUrl.value : this.photoUrl,
      photoThumbnailUrl: data.photoThumbnailUrl.present
          ? data.photoThumbnailUrl.value
          : this.photoThumbnailUrl,
      photoLink: data.photoLink.present ? data.photoLink.value : this.photoLink,
      photoCredit: data.photoCredit.present
          ? data.photoCredit.value
          : this.photoCredit,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Aircraft(')
          ..write('id: $id, ')
          ..write('icaoAircraft: $icaoAircraft, ')
          ..write('tailNumber: $tailNumber, ')
          ..write('notes: $notes, ')
          ..write('aircraftClass: $aircraftClass, ')
          ..write('typeRating: $typeRating, ')
          ..write('photoFile: $photoFile, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('photoThumbnailUrl: $photoThumbnailUrl, ')
          ..write('photoLink: $photoLink, ')
          ..write('photoCredit: $photoCredit')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    icaoAircraft,
    tailNumber,
    notes,
    aircraftClass,
    typeRating,
    photoFile,
    photoUrl,
    photoThumbnailUrl,
    photoLink,
    photoCredit,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Aircraft &&
          other.id == this.id &&
          other.icaoAircraft == this.icaoAircraft &&
          other.tailNumber == this.tailNumber &&
          other.notes == this.notes &&
          other.aircraftClass == this.aircraftClass &&
          other.typeRating == this.typeRating &&
          other.photoFile == this.photoFile &&
          other.photoUrl == this.photoUrl &&
          other.photoThumbnailUrl == this.photoThumbnailUrl &&
          other.photoLink == this.photoLink &&
          other.photoCredit == this.photoCredit);
}

class AircraftsCompanion extends UpdateCompanion<Aircraft> {
  final Value<int> id;
  final Value<int> icaoAircraft;
  final Value<String> tailNumber;
  final Value<String?> notes;
  final Value<AircraftClass?> aircraftClass;
  final Value<String?> typeRating;
  final Value<String?> photoFile;
  final Value<String?> photoUrl;
  final Value<String?> photoThumbnailUrl;
  final Value<String?> photoLink;
  final Value<String?> photoCredit;
  const AircraftsCompanion({
    this.id = const Value.absent(),
    this.icaoAircraft = const Value.absent(),
    this.tailNumber = const Value.absent(),
    this.notes = const Value.absent(),
    this.aircraftClass = const Value.absent(),
    this.typeRating = const Value.absent(),
    this.photoFile = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.photoThumbnailUrl = const Value.absent(),
    this.photoLink = const Value.absent(),
    this.photoCredit = const Value.absent(),
  });
  AircraftsCompanion.insert({
    this.id = const Value.absent(),
    required int icaoAircraft,
    required String tailNumber,
    this.notes = const Value.absent(),
    this.aircraftClass = const Value.absent(),
    this.typeRating = const Value.absent(),
    this.photoFile = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.photoThumbnailUrl = const Value.absent(),
    this.photoLink = const Value.absent(),
    this.photoCredit = const Value.absent(),
  }) : icaoAircraft = Value(icaoAircraft),
       tailNumber = Value(tailNumber);
  static Insertable<Aircraft> custom({
    Expression<int>? id,
    Expression<int>? icaoAircraft,
    Expression<String>? tailNumber,
    Expression<String>? notes,
    Expression<String>? aircraftClass,
    Expression<String>? typeRating,
    Expression<String>? photoFile,
    Expression<String>? photoUrl,
    Expression<String>? photoThumbnailUrl,
    Expression<String>? photoLink,
    Expression<String>? photoCredit,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (icaoAircraft != null) 'icao_aircraft': icaoAircraft,
      if (tailNumber != null) 'tail_number': tailNumber,
      if (notes != null) 'notes': notes,
      if (aircraftClass != null) 'aircraft_class': aircraftClass,
      if (typeRating != null) 'type_rating': typeRating,
      if (photoFile != null) 'photo_file': photoFile,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (photoThumbnailUrl != null) 'photo_thumbnail_url': photoThumbnailUrl,
      if (photoLink != null) 'photo_link': photoLink,
      if (photoCredit != null) 'photo_credit': photoCredit,
    });
  }

  AircraftsCompanion copyWith({
    Value<int>? id,
    Value<int>? icaoAircraft,
    Value<String>? tailNumber,
    Value<String?>? notes,
    Value<AircraftClass?>? aircraftClass,
    Value<String?>? typeRating,
    Value<String?>? photoFile,
    Value<String?>? photoUrl,
    Value<String?>? photoThumbnailUrl,
    Value<String?>? photoLink,
    Value<String?>? photoCredit,
  }) {
    return AircraftsCompanion(
      id: id ?? this.id,
      icaoAircraft: icaoAircraft ?? this.icaoAircraft,
      tailNumber: tailNumber ?? this.tailNumber,
      notes: notes ?? this.notes,
      aircraftClass: aircraftClass ?? this.aircraftClass,
      typeRating: typeRating ?? this.typeRating,
      photoFile: photoFile ?? this.photoFile,
      photoUrl: photoUrl ?? this.photoUrl,
      photoThumbnailUrl: photoThumbnailUrl ?? this.photoThumbnailUrl,
      photoLink: photoLink ?? this.photoLink,
      photoCredit: photoCredit ?? this.photoCredit,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (icaoAircraft.present) {
      map['icao_aircraft'] = Variable<int>(icaoAircraft.value);
    }
    if (tailNumber.present) {
      map['tail_number'] = Variable<String>(tailNumber.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (aircraftClass.present) {
      map['aircraft_class'] = Variable<String>(
        $AircraftsTable.$converteraircraftClassn.toSql(aircraftClass.value),
      );
    }
    if (typeRating.present) {
      map['type_rating'] = Variable<String>(typeRating.value);
    }
    if (photoFile.present) {
      map['photo_file'] = Variable<String>(photoFile.value);
    }
    if (photoUrl.present) {
      map['photo_url'] = Variable<String>(photoUrl.value);
    }
    if (photoThumbnailUrl.present) {
      map['photo_thumbnail_url'] = Variable<String>(photoThumbnailUrl.value);
    }
    if (photoLink.present) {
      map['photo_link'] = Variable<String>(photoLink.value);
    }
    if (photoCredit.present) {
      map['photo_credit'] = Variable<String>(photoCredit.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AircraftsCompanion(')
          ..write('id: $id, ')
          ..write('icaoAircraft: $icaoAircraft, ')
          ..write('tailNumber: $tailNumber, ')
          ..write('notes: $notes, ')
          ..write('aircraftClass: $aircraftClass, ')
          ..write('typeRating: $typeRating, ')
          ..write('photoFile: $photoFile, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('photoThumbnailUrl: $photoThumbnailUrl, ')
          ..write('photoLink: $photoLink, ')
          ..write('photoCredit: $photoCredit')
          ..write(')'))
        .toString();
  }
}

class $SimulatorsTable extends Simulators
    with TableInfo<$SimulatorsTable, Simulator> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SimulatorsTable(this.attachedDatabase, [this._alias]);
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
  @override
  late final GeneratedColumnWithTypeConverter<SimulatorKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SimulatorKind>($SimulatorsTable.$converterkind);
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<String> level = GeneratedColumn<String>(
    'level',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _icaoAircraftMeta = const VerificationMeta(
    'icaoAircraft',
  );
  @override
  late final GeneratedColumn<int> icaoAircraft = GeneratedColumn<int>(
    'icao_aircraft',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES icao_aircrafts (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<AircraftClass?, String>
  aircraftClass = GeneratedColumn<String>(
    'aircraft_class',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<AircraftClass?>($SimulatorsTable.$converteraircraftClassn);
  static const VerificationMeta _typeRatingMeta = const VerificationMeta(
    'typeRating',
  );
  @override
  late final GeneratedColumn<String> typeRating = GeneratedColumn<String>(
    'type_rating',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _qualificationNumberMeta =
      const VerificationMeta('qualificationNumber');
  @override
  late final GeneratedColumn<String> qualificationNumber =
      GeneratedColumn<String>(
        'qualification_number',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _organisationMeta = const VerificationMeta(
    'organisation',
  );
  @override
  late final GeneratedColumn<String> organisation = GeneratedColumn<String>(
    'organisation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    level,
    icaoAircraft,
    aircraftClass,
    typeRating,
    qualificationNumber,
    organisation,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'simulators';
  @override
  VerificationContext validateIntegrity(
    Insertable<Simulator> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    }
    if (data.containsKey('icao_aircraft')) {
      context.handle(
        _icaoAircraftMeta,
        icaoAircraft.isAcceptableOrUnknown(
          data['icao_aircraft']!,
          _icaoAircraftMeta,
        ),
      );
    }
    if (data.containsKey('type_rating')) {
      context.handle(
        _typeRatingMeta,
        typeRating.isAcceptableOrUnknown(data['type_rating']!, _typeRatingMeta),
      );
    }
    if (data.containsKey('qualification_number')) {
      context.handle(
        _qualificationNumberMeta,
        qualificationNumber.isAcceptableOrUnknown(
          data['qualification_number']!,
          _qualificationNumberMeta,
        ),
      );
    }
    if (data.containsKey('organisation')) {
      context.handle(
        _organisationMeta,
        organisation.isAcceptableOrUnknown(
          data['organisation']!,
          _organisationMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Simulator map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Simulator(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kind: $SimulatorsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}level'],
      ),
      icaoAircraft: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}icao_aircraft'],
      ),
      aircraftClass: $SimulatorsTable.$converteraircraftClassn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}aircraft_class'],
        ),
      ),
      typeRating: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type_rating'],
      ),
      qualificationNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}qualification_number'],
      ),
      organisation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organisation'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $SimulatorsTable createAlias(String alias) {
    return $SimulatorsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SimulatorKind, String, String> $converterkind =
      const EnumNameConverter<SimulatorKind>(SimulatorKind.values);
  static JsonTypeConverter2<AircraftClass, String, String>
  $converteraircraftClass = const EnumNameConverter<AircraftClass>(
    AircraftClass.values,
  );
  static JsonTypeConverter2<AircraftClass?, String?, String?>
  $converteraircraftClassn = JsonTypeConverter2.asNullable(
    $converteraircraftClass,
  );
}

class Simulator extends DataClass implements Insertable<Simulator> {
  final int id;
  final SimulatorKind kind;

  /// Qualification level ("D" for an FFS, "II MCC" for an FNPT). Null when
  /// not known or the kind has none.
  final String? level;

  /// The aircraft type the device represents. Null for a generic device
  /// (an FNPT representing a class, a BITD).
  final int? icaoAircraft;

  /// Class or type rating sessions in the device count towards (FFS
  /// landings, proficiency checks).
  final AircraftClass? aircraftClass;

  /// Licence endorsement of the type rating (e.g. "A320"), when
  /// [aircraftClass] is [AircraftClass.type].
  final String? typeRating;

  /// The device's qualification number ("Q1234"), written next to its type
  /// in the logbook.
  final String? qualificationNumber;

  /// Training organisation or operator running it, and where.
  final String? organisation;
  final String? notes;
  const Simulator({
    required this.id,
    required this.kind,
    this.level,
    this.icaoAircraft,
    this.aircraftClass,
    this.typeRating,
    this.qualificationNumber,
    this.organisation,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['kind'] = Variable<String>(
        $SimulatorsTable.$converterkind.toSql(kind),
      );
    }
    if (!nullToAbsent || level != null) {
      map['level'] = Variable<String>(level);
    }
    if (!nullToAbsent || icaoAircraft != null) {
      map['icao_aircraft'] = Variable<int>(icaoAircraft);
    }
    if (!nullToAbsent || aircraftClass != null) {
      map['aircraft_class'] = Variable<String>(
        $SimulatorsTable.$converteraircraftClassn.toSql(aircraftClass),
      );
    }
    if (!nullToAbsent || typeRating != null) {
      map['type_rating'] = Variable<String>(typeRating);
    }
    if (!nullToAbsent || qualificationNumber != null) {
      map['qualification_number'] = Variable<String>(qualificationNumber);
    }
    if (!nullToAbsent || organisation != null) {
      map['organisation'] = Variable<String>(organisation);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  SimulatorsCompanion toCompanion(bool nullToAbsent) {
    return SimulatorsCompanion(
      id: Value(id),
      kind: Value(kind),
      level: level == null && nullToAbsent
          ? const Value.absent()
          : Value(level),
      icaoAircraft: icaoAircraft == null && nullToAbsent
          ? const Value.absent()
          : Value(icaoAircraft),
      aircraftClass: aircraftClass == null && nullToAbsent
          ? const Value.absent()
          : Value(aircraftClass),
      typeRating: typeRating == null && nullToAbsent
          ? const Value.absent()
          : Value(typeRating),
      qualificationNumber: qualificationNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(qualificationNumber),
      organisation: organisation == null && nullToAbsent
          ? const Value.absent()
          : Value(organisation),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory Simulator.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Simulator(
      id: serializer.fromJson<int>(json['id']),
      kind: $SimulatorsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      level: serializer.fromJson<String?>(json['level']),
      icaoAircraft: serializer.fromJson<int?>(json['icaoAircraft']),
      aircraftClass: $SimulatorsTable.$converteraircraftClassn.fromJson(
        serializer.fromJson<String?>(json['aircraftClass']),
      ),
      typeRating: serializer.fromJson<String?>(json['typeRating']),
      qualificationNumber: serializer.fromJson<String?>(
        json['qualificationNumber'],
      ),
      organisation: serializer.fromJson<String?>(json['organisation']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<String>(
        $SimulatorsTable.$converterkind.toJson(kind),
      ),
      'level': serializer.toJson<String?>(level),
      'icaoAircraft': serializer.toJson<int?>(icaoAircraft),
      'aircraftClass': serializer.toJson<String?>(
        $SimulatorsTable.$converteraircraftClassn.toJson(aircraftClass),
      ),
      'typeRating': serializer.toJson<String?>(typeRating),
      'qualificationNumber': serializer.toJson<String?>(qualificationNumber),
      'organisation': serializer.toJson<String?>(organisation),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  Simulator copyWith({
    int? id,
    SimulatorKind? kind,
    Value<String?> level = const Value.absent(),
    Value<int?> icaoAircraft = const Value.absent(),
    Value<AircraftClass?> aircraftClass = const Value.absent(),
    Value<String?> typeRating = const Value.absent(),
    Value<String?> qualificationNumber = const Value.absent(),
    Value<String?> organisation = const Value.absent(),
    Value<String?> notes = const Value.absent(),
  }) => Simulator(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    level: level.present ? level.value : this.level,
    icaoAircraft: icaoAircraft.present ? icaoAircraft.value : this.icaoAircraft,
    aircraftClass: aircraftClass.present
        ? aircraftClass.value
        : this.aircraftClass,
    typeRating: typeRating.present ? typeRating.value : this.typeRating,
    qualificationNumber: qualificationNumber.present
        ? qualificationNumber.value
        : this.qualificationNumber,
    organisation: organisation.present ? organisation.value : this.organisation,
    notes: notes.present ? notes.value : this.notes,
  );
  Simulator copyWithCompanion(SimulatorsCompanion data) {
    return Simulator(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      level: data.level.present ? data.level.value : this.level,
      icaoAircraft: data.icaoAircraft.present
          ? data.icaoAircraft.value
          : this.icaoAircraft,
      aircraftClass: data.aircraftClass.present
          ? data.aircraftClass.value
          : this.aircraftClass,
      typeRating: data.typeRating.present
          ? data.typeRating.value
          : this.typeRating,
      qualificationNumber: data.qualificationNumber.present
          ? data.qualificationNumber.value
          : this.qualificationNumber,
      organisation: data.organisation.present
          ? data.organisation.value
          : this.organisation,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Simulator(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('level: $level, ')
          ..write('icaoAircraft: $icaoAircraft, ')
          ..write('aircraftClass: $aircraftClass, ')
          ..write('typeRating: $typeRating, ')
          ..write('qualificationNumber: $qualificationNumber, ')
          ..write('organisation: $organisation, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    level,
    icaoAircraft,
    aircraftClass,
    typeRating,
    qualificationNumber,
    organisation,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Simulator &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.level == this.level &&
          other.icaoAircraft == this.icaoAircraft &&
          other.aircraftClass == this.aircraftClass &&
          other.typeRating == this.typeRating &&
          other.qualificationNumber == this.qualificationNumber &&
          other.organisation == this.organisation &&
          other.notes == this.notes);
}

class SimulatorsCompanion extends UpdateCompanion<Simulator> {
  final Value<int> id;
  final Value<SimulatorKind> kind;
  final Value<String?> level;
  final Value<int?> icaoAircraft;
  final Value<AircraftClass?> aircraftClass;
  final Value<String?> typeRating;
  final Value<String?> qualificationNumber;
  final Value<String?> organisation;
  final Value<String?> notes;
  const SimulatorsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.level = const Value.absent(),
    this.icaoAircraft = const Value.absent(),
    this.aircraftClass = const Value.absent(),
    this.typeRating = const Value.absent(),
    this.qualificationNumber = const Value.absent(),
    this.organisation = const Value.absent(),
    this.notes = const Value.absent(),
  });
  SimulatorsCompanion.insert({
    this.id = const Value.absent(),
    required SimulatorKind kind,
    this.level = const Value.absent(),
    this.icaoAircraft = const Value.absent(),
    this.aircraftClass = const Value.absent(),
    this.typeRating = const Value.absent(),
    this.qualificationNumber = const Value.absent(),
    this.organisation = const Value.absent(),
    this.notes = const Value.absent(),
  }) : kind = Value(kind);
  static Insertable<Simulator> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<String>? level,
    Expression<int>? icaoAircraft,
    Expression<String>? aircraftClass,
    Expression<String>? typeRating,
    Expression<String>? qualificationNumber,
    Expression<String>? organisation,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (level != null) 'level': level,
      if (icaoAircraft != null) 'icao_aircraft': icaoAircraft,
      if (aircraftClass != null) 'aircraft_class': aircraftClass,
      if (typeRating != null) 'type_rating': typeRating,
      if (qualificationNumber != null)
        'qualification_number': qualificationNumber,
      if (organisation != null) 'organisation': organisation,
      if (notes != null) 'notes': notes,
    });
  }

  SimulatorsCompanion copyWith({
    Value<int>? id,
    Value<SimulatorKind>? kind,
    Value<String?>? level,
    Value<int?>? icaoAircraft,
    Value<AircraftClass?>? aircraftClass,
    Value<String?>? typeRating,
    Value<String?>? qualificationNumber,
    Value<String?>? organisation,
    Value<String?>? notes,
  }) {
    return SimulatorsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      level: level ?? this.level,
      icaoAircraft: icaoAircraft ?? this.icaoAircraft,
      aircraftClass: aircraftClass ?? this.aircraftClass,
      typeRating: typeRating ?? this.typeRating,
      qualificationNumber: qualificationNumber ?? this.qualificationNumber,
      organisation: organisation ?? this.organisation,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $SimulatorsTable.$converterkind.toSql(kind.value),
      );
    }
    if (level.present) {
      map['level'] = Variable<String>(level.value);
    }
    if (icaoAircraft.present) {
      map['icao_aircraft'] = Variable<int>(icaoAircraft.value);
    }
    if (aircraftClass.present) {
      map['aircraft_class'] = Variable<String>(
        $SimulatorsTable.$converteraircraftClassn.toSql(aircraftClass.value),
      );
    }
    if (typeRating.present) {
      map['type_rating'] = Variable<String>(typeRating.value);
    }
    if (qualificationNumber.present) {
      map['qualification_number'] = Variable<String>(qualificationNumber.value);
    }
    if (organisation.present) {
      map['organisation'] = Variable<String>(organisation.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SimulatorsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('level: $level, ')
          ..write('icaoAircraft: $icaoAircraft, ')
          ..write('aircraftClass: $aircraftClass, ')
          ..write('typeRating: $typeRating, ')
          ..write('qualificationNumber: $qualificationNumber, ')
          ..write('organisation: $organisation, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $FlightsTable extends Flights with TableInfo<$FlightsTable, Flight> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FlightsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _departureMeta = const VerificationMeta(
    'departure',
  );
  @override
  late final GeneratedColumn<int> departure = GeneratedColumn<int>(
    'departure',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES airports (id)',
    ),
  );
  static const VerificationMeta _arrivalMeta = const VerificationMeta(
    'arrival',
  );
  @override
  late final GeneratedColumn<int> arrival = GeneratedColumn<int>(
    'arrival',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES airports (id)',
    ),
  );
  static const VerificationMeta _departureTimeMeta = const VerificationMeta(
    'departureTime',
  );
  @override
  late final GeneratedColumn<DateTime> departureTime =
      GeneratedColumn<DateTime>(
        'departure_time',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _arrivalTimeMeta = const VerificationMeta(
    'arrivalTime',
  );
  @override
  late final GeneratedColumn<DateTime> arrivalTime = GeneratedColumn<DateTime>(
    'arrival_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _departureIanaLocationMeta =
      const VerificationMeta('departureIanaLocation');
  @override
  late final GeneratedColumn<String> departureIanaLocation =
      GeneratedColumn<String>(
        'departure_iana_location',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _arrivalIanaLocationMeta =
      const VerificationMeta('arrivalIanaLocation');
  @override
  late final GeneratedColumn<String> arrivalIanaLocation =
      GeneratedColumn<String>(
        'arrival_iana_location',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isRecordingMeta = const VerificationMeta(
    'isRecording',
  );
  @override
  late final GeneratedColumn<bool> isRecording = GeneratedColumn<bool>(
    'is_recording',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_recording" IN (0, 1))',
    ),
  );
  static const VerificationMeta _aircraftIdMeta = const VerificationMeta(
    'aircraftId',
  );
  @override
  late final GeneratedColumn<int> aircraftId = GeneratedColumn<int>(
    'aircraft_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES aircrafts (id)',
    ),
  );
  static const VerificationMeta _simulatorIdMeta = const VerificationMeta(
    'simulatorId',
  );
  @override
  late final GeneratedColumn<int> simulatorId = GeneratedColumn<int>(
    'simulator_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES simulators (id)',
    ),
  );
  static const VerificationMeta _approachTypeMeta = const VerificationMeta(
    'approachType',
  );
  @override
  late final GeneratedColumn<String> approachType = GeneratedColumn<String>(
    'approach_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nightLandingsMeta = const VerificationMeta(
    'nightLandings',
  );
  @override
  late final GeneratedColumn<int> nightLandings = GeneratedColumn<int>(
    'night_landings',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dayLandingsMeta = const VerificationMeta(
    'dayLandings',
  );
  @override
  late final GeneratedColumn<int> dayLandings = GeneratedColumn<int>(
    'day_landings',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _flightRulesMeta = const VerificationMeta(
    'flightRules',
  );
  @override
  late final GeneratedColumn<String> flightRules = GeneratedColumn<String>(
    'flight_rules',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remarksMeta = const VerificationMeta(
    'remarks',
  );
  @override
  late final GeneratedColumn<String> remarks = GeneratedColumn<String>(
    'remarks',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pilotRoleMeta = const VerificationMeta(
    'pilotRole',
  );
  @override
  late final GeneratedColumn<String> pilotRole = GeneratedColumn<String>(
    'pilot_role',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _instrumentMinutesMeta = const VerificationMeta(
    'instrumentMinutes',
  );
  @override
  late final GeneratedColumn<int> instrumentMinutes = GeneratedColumn<int>(
    'instrument_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nightMinutesMeta = const VerificationMeta(
    'nightMinutes',
  );
  @override
  late final GeneratedColumn<int> nightMinutes = GeneratedColumn<int>(
    'night_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LogbookOverrides?, String>
  logbookOverrides = GeneratedColumn<String>(
    'logbook_overrides',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<LogbookOverrides?>($FlightsTable.$converterlogbookOverridesn);
  static const VerificationMeta _trackSourceMeta = const VerificationMeta(
    'trackSource',
  );
  @override
  late final GeneratedColumn<String> trackSource = GeneratedColumn<String>(
    'track_source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _proficiencyCheckMeta = const VerificationMeta(
    'proficiencyCheck',
  );
  @override
  late final GeneratedColumn<bool> proficiencyCheck = GeneratedColumn<bool>(
    'proficiency_check',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("proficiency_check" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _signatureFileMeta = const VerificationMeta(
    'signatureFile',
  );
  @override
  late final GeneratedColumn<String> signatureFile = GeneratedColumn<String>(
    'signature_file',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    departure,
    arrival,
    departureTime,
    arrivalTime,
    departureIanaLocation,
    arrivalIanaLocation,
    isRecording,
    aircraftId,
    simulatorId,
    approachType,
    nightLandings,
    dayLandings,
    flightRules,
    remarks,
    pilotRole,
    instrumentMinutes,
    nightMinutes,
    logbookOverrides,
    trackSource,
    proficiencyCheck,
    signatureFile,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'flights';
  @override
  VerificationContext validateIntegrity(
    Insertable<Flight> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('departure')) {
      context.handle(
        _departureMeta,
        departure.isAcceptableOrUnknown(data['departure']!, _departureMeta),
      );
    }
    if (data.containsKey('arrival')) {
      context.handle(
        _arrivalMeta,
        arrival.isAcceptableOrUnknown(data['arrival']!, _arrivalMeta),
      );
    }
    if (data.containsKey('departure_time')) {
      context.handle(
        _departureTimeMeta,
        departureTime.isAcceptableOrUnknown(
          data['departure_time']!,
          _departureTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_departureTimeMeta);
    }
    if (data.containsKey('arrival_time')) {
      context.handle(
        _arrivalTimeMeta,
        arrivalTime.isAcceptableOrUnknown(
          data['arrival_time']!,
          _arrivalTimeMeta,
        ),
      );
    }
    if (data.containsKey('departure_iana_location')) {
      context.handle(
        _departureIanaLocationMeta,
        departureIanaLocation.isAcceptableOrUnknown(
          data['departure_iana_location']!,
          _departureIanaLocationMeta,
        ),
      );
    }
    if (data.containsKey('arrival_iana_location')) {
      context.handle(
        _arrivalIanaLocationMeta,
        arrivalIanaLocation.isAcceptableOrUnknown(
          data['arrival_iana_location']!,
          _arrivalIanaLocationMeta,
        ),
      );
    }
    if (data.containsKey('is_recording')) {
      context.handle(
        _isRecordingMeta,
        isRecording.isAcceptableOrUnknown(
          data['is_recording']!,
          _isRecordingMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isRecordingMeta);
    }
    if (data.containsKey('aircraft_id')) {
      context.handle(
        _aircraftIdMeta,
        aircraftId.isAcceptableOrUnknown(data['aircraft_id']!, _aircraftIdMeta),
      );
    }
    if (data.containsKey('simulator_id')) {
      context.handle(
        _simulatorIdMeta,
        simulatorId.isAcceptableOrUnknown(
          data['simulator_id']!,
          _simulatorIdMeta,
        ),
      );
    }
    if (data.containsKey('approach_type')) {
      context.handle(
        _approachTypeMeta,
        approachType.isAcceptableOrUnknown(
          data['approach_type']!,
          _approachTypeMeta,
        ),
      );
    }
    if (data.containsKey('night_landings')) {
      context.handle(
        _nightLandingsMeta,
        nightLandings.isAcceptableOrUnknown(
          data['night_landings']!,
          _nightLandingsMeta,
        ),
      );
    }
    if (data.containsKey('day_landings')) {
      context.handle(
        _dayLandingsMeta,
        dayLandings.isAcceptableOrUnknown(
          data['day_landings']!,
          _dayLandingsMeta,
        ),
      );
    }
    if (data.containsKey('flight_rules')) {
      context.handle(
        _flightRulesMeta,
        flightRules.isAcceptableOrUnknown(
          data['flight_rules']!,
          _flightRulesMeta,
        ),
      );
    }
    if (data.containsKey('remarks')) {
      context.handle(
        _remarksMeta,
        remarks.isAcceptableOrUnknown(data['remarks']!, _remarksMeta),
      );
    }
    if (data.containsKey('pilot_role')) {
      context.handle(
        _pilotRoleMeta,
        pilotRole.isAcceptableOrUnknown(data['pilot_role']!, _pilotRoleMeta),
      );
    }
    if (data.containsKey('instrument_minutes')) {
      context.handle(
        _instrumentMinutesMeta,
        instrumentMinutes.isAcceptableOrUnknown(
          data['instrument_minutes']!,
          _instrumentMinutesMeta,
        ),
      );
    }
    if (data.containsKey('night_minutes')) {
      context.handle(
        _nightMinutesMeta,
        nightMinutes.isAcceptableOrUnknown(
          data['night_minutes']!,
          _nightMinutesMeta,
        ),
      );
    }
    if (data.containsKey('track_source')) {
      context.handle(
        _trackSourceMeta,
        trackSource.isAcceptableOrUnknown(
          data['track_source']!,
          _trackSourceMeta,
        ),
      );
    }
    if (data.containsKey('proficiency_check')) {
      context.handle(
        _proficiencyCheckMeta,
        proficiencyCheck.isAcceptableOrUnknown(
          data['proficiency_check']!,
          _proficiencyCheckMeta,
        ),
      );
    }
    if (data.containsKey('signature_file')) {
      context.handle(
        _signatureFileMeta,
        signatureFile.isAcceptableOrUnknown(
          data['signature_file']!,
          _signatureFileMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Flight map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Flight(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      departure: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}departure'],
      ),
      arrival: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}arrival'],
      ),
      departureTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}departure_time'],
      )!,
      arrivalTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}arrival_time'],
      ),
      departureIanaLocation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}departure_iana_location'],
      ),
      arrivalIanaLocation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}arrival_iana_location'],
      ),
      isRecording: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_recording'],
      )!,
      aircraftId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}aircraft_id'],
      ),
      simulatorId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}simulator_id'],
      ),
      approachType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}approach_type'],
      ),
      nightLandings: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}night_landings'],
      ),
      dayLandings: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_landings'],
      ),
      flightRules: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}flight_rules'],
      ),
      remarks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remarks'],
      ),
      pilotRole: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pilot_role'],
      ),
      instrumentMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}instrument_minutes'],
      ),
      nightMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}night_minutes'],
      ),
      logbookOverrides: $FlightsTable.$converterlogbookOverridesn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}logbook_overrides'],
        ),
      ),
      trackSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_source'],
      ),
      proficiencyCheck: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}proficiency_check'],
      )!,
      signatureFile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}signature_file'],
      ),
    );
  }

  @override
  $FlightsTable createAlias(String alias) {
    return $FlightsTable(attachedDatabase, alias);
  }

  static TypeConverter<LogbookOverrides, String> $converterlogbookOverrides =
      LogbookOverrides.converter;
  static TypeConverter<LogbookOverrides?, String?> $converterlogbookOverridesn =
      NullAwareTypeConverter.wrap($converterlogbookOverrides);
}

class Flight extends DataClass implements Insertable<Flight> {
  final int id;
  final String title;
  final int? departure;
  final int? arrival;
  final DateTime departureTime;
  final DateTime? arrivalTime;
  final String? departureIanaLocation;
  final String? arrivalIanaLocation;
  final bool isRecording;
  final int? aircraftId;

  /// Set for a session in a flight simulation training device instead of a
  /// flight: it then has no aircraft, airports, flight rules or track, and
  /// fills in the FSTD column of the logbook only.
  final int? simulatorId;
  final String? approachType;
  final int? nightLandings;
  final int? dayLandings;
  final String? flightRules;
  final String? remarks;
  final String? pilotRole;

  /// Time flown under instrument flight rules, in minutes: none for a VFR
  /// flight, all of it for an IFR one, what the pilot entered for one that
  /// changes rules on the way. Null when not known.
  final int? instrumentMinutes;

  /// Time flown at night, in minutes, worked out from the airports and times
  /// (see [NightTime]). Null when it can't be: an airport without a position,
  /// no arrival time.
  final int? nightMinutes;

  /// Logbook values the pilot entered by hand, replacing the computed ones
  /// in the exported logbook.
  final LogbookOverrides? logbookOverrides;

  /// Where the track in [FlightDataPoints] comes from: the id of the ADS-B
  /// provider it was fetched from (`AdsbTrackSource.id`). Null for a track
  /// the app recorded itself, and for flights without a track.
  final String? trackSource;

  /// Whether the flight was a proficiency check with an examiner in the
  /// crew: it then counts as the last check of the class or type rating of
  /// its aircraft.
  final bool proficiencyCheck;

  /// File name of the signature (or photo of the paper logbook's remarks)
  /// inside the app's signature folder, laid over the remarks in the
  /// exported logbook.
  final String? signatureFile;
  const Flight({
    required this.id,
    required this.title,
    this.departure,
    this.arrival,
    required this.departureTime,
    this.arrivalTime,
    this.departureIanaLocation,
    this.arrivalIanaLocation,
    required this.isRecording,
    this.aircraftId,
    this.simulatorId,
    this.approachType,
    this.nightLandings,
    this.dayLandings,
    this.flightRules,
    this.remarks,
    this.pilotRole,
    this.instrumentMinutes,
    this.nightMinutes,
    this.logbookOverrides,
    this.trackSource,
    required this.proficiencyCheck,
    this.signatureFile,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || departure != null) {
      map['departure'] = Variable<int>(departure);
    }
    if (!nullToAbsent || arrival != null) {
      map['arrival'] = Variable<int>(arrival);
    }
    map['departure_time'] = Variable<DateTime>(departureTime);
    if (!nullToAbsent || arrivalTime != null) {
      map['arrival_time'] = Variable<DateTime>(arrivalTime);
    }
    if (!nullToAbsent || departureIanaLocation != null) {
      map['departure_iana_location'] = Variable<String>(departureIanaLocation);
    }
    if (!nullToAbsent || arrivalIanaLocation != null) {
      map['arrival_iana_location'] = Variable<String>(arrivalIanaLocation);
    }
    map['is_recording'] = Variable<bool>(isRecording);
    if (!nullToAbsent || aircraftId != null) {
      map['aircraft_id'] = Variable<int>(aircraftId);
    }
    if (!nullToAbsent || simulatorId != null) {
      map['simulator_id'] = Variable<int>(simulatorId);
    }
    if (!nullToAbsent || approachType != null) {
      map['approach_type'] = Variable<String>(approachType);
    }
    if (!nullToAbsent || nightLandings != null) {
      map['night_landings'] = Variable<int>(nightLandings);
    }
    if (!nullToAbsent || dayLandings != null) {
      map['day_landings'] = Variable<int>(dayLandings);
    }
    if (!nullToAbsent || flightRules != null) {
      map['flight_rules'] = Variable<String>(flightRules);
    }
    if (!nullToAbsent || remarks != null) {
      map['remarks'] = Variable<String>(remarks);
    }
    if (!nullToAbsent || pilotRole != null) {
      map['pilot_role'] = Variable<String>(pilotRole);
    }
    if (!nullToAbsent || instrumentMinutes != null) {
      map['instrument_minutes'] = Variable<int>(instrumentMinutes);
    }
    if (!nullToAbsent || nightMinutes != null) {
      map['night_minutes'] = Variable<int>(nightMinutes);
    }
    if (!nullToAbsent || logbookOverrides != null) {
      map['logbook_overrides'] = Variable<String>(
        $FlightsTable.$converterlogbookOverridesn.toSql(logbookOverrides),
      );
    }
    if (!nullToAbsent || trackSource != null) {
      map['track_source'] = Variable<String>(trackSource);
    }
    map['proficiency_check'] = Variable<bool>(proficiencyCheck);
    if (!nullToAbsent || signatureFile != null) {
      map['signature_file'] = Variable<String>(signatureFile);
    }
    return map;
  }

  FlightsCompanion toCompanion(bool nullToAbsent) {
    return FlightsCompanion(
      id: Value(id),
      title: Value(title),
      departure: departure == null && nullToAbsent
          ? const Value.absent()
          : Value(departure),
      arrival: arrival == null && nullToAbsent
          ? const Value.absent()
          : Value(arrival),
      departureTime: Value(departureTime),
      arrivalTime: arrivalTime == null && nullToAbsent
          ? const Value.absent()
          : Value(arrivalTime),
      departureIanaLocation: departureIanaLocation == null && nullToAbsent
          ? const Value.absent()
          : Value(departureIanaLocation),
      arrivalIanaLocation: arrivalIanaLocation == null && nullToAbsent
          ? const Value.absent()
          : Value(arrivalIanaLocation),
      isRecording: Value(isRecording),
      aircraftId: aircraftId == null && nullToAbsent
          ? const Value.absent()
          : Value(aircraftId),
      simulatorId: simulatorId == null && nullToAbsent
          ? const Value.absent()
          : Value(simulatorId),
      approachType: approachType == null && nullToAbsent
          ? const Value.absent()
          : Value(approachType),
      nightLandings: nightLandings == null && nullToAbsent
          ? const Value.absent()
          : Value(nightLandings),
      dayLandings: dayLandings == null && nullToAbsent
          ? const Value.absent()
          : Value(dayLandings),
      flightRules: flightRules == null && nullToAbsent
          ? const Value.absent()
          : Value(flightRules),
      remarks: remarks == null && nullToAbsent
          ? const Value.absent()
          : Value(remarks),
      pilotRole: pilotRole == null && nullToAbsent
          ? const Value.absent()
          : Value(pilotRole),
      instrumentMinutes: instrumentMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(instrumentMinutes),
      nightMinutes: nightMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(nightMinutes),
      logbookOverrides: logbookOverrides == null && nullToAbsent
          ? const Value.absent()
          : Value(logbookOverrides),
      trackSource: trackSource == null && nullToAbsent
          ? const Value.absent()
          : Value(trackSource),
      proficiencyCheck: Value(proficiencyCheck),
      signatureFile: signatureFile == null && nullToAbsent
          ? const Value.absent()
          : Value(signatureFile),
    );
  }

  factory Flight.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Flight(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      departure: serializer.fromJson<int?>(json['departure']),
      arrival: serializer.fromJson<int?>(json['arrival']),
      departureTime: serializer.fromJson<DateTime>(json['departureTime']),
      arrivalTime: serializer.fromJson<DateTime?>(json['arrivalTime']),
      departureIanaLocation: serializer.fromJson<String?>(
        json['departureIanaLocation'],
      ),
      arrivalIanaLocation: serializer.fromJson<String?>(
        json['arrivalIanaLocation'],
      ),
      isRecording: serializer.fromJson<bool>(json['isRecording']),
      aircraftId: serializer.fromJson<int?>(json['aircraftId']),
      simulatorId: serializer.fromJson<int?>(json['simulatorId']),
      approachType: serializer.fromJson<String?>(json['approachType']),
      nightLandings: serializer.fromJson<int?>(json['nightLandings']),
      dayLandings: serializer.fromJson<int?>(json['dayLandings']),
      flightRules: serializer.fromJson<String?>(json['flightRules']),
      remarks: serializer.fromJson<String?>(json['remarks']),
      pilotRole: serializer.fromJson<String?>(json['pilotRole']),
      instrumentMinutes: serializer.fromJson<int?>(json['instrumentMinutes']),
      nightMinutes: serializer.fromJson<int?>(json['nightMinutes']),
      logbookOverrides: serializer.fromJson<LogbookOverrides?>(
        json['logbookOverrides'],
      ),
      trackSource: serializer.fromJson<String?>(json['trackSource']),
      proficiencyCheck: serializer.fromJson<bool>(json['proficiencyCheck']),
      signatureFile: serializer.fromJson<String?>(json['signatureFile']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'departure': serializer.toJson<int?>(departure),
      'arrival': serializer.toJson<int?>(arrival),
      'departureTime': serializer.toJson<DateTime>(departureTime),
      'arrivalTime': serializer.toJson<DateTime?>(arrivalTime),
      'departureIanaLocation': serializer.toJson<String?>(
        departureIanaLocation,
      ),
      'arrivalIanaLocation': serializer.toJson<String?>(arrivalIanaLocation),
      'isRecording': serializer.toJson<bool>(isRecording),
      'aircraftId': serializer.toJson<int?>(aircraftId),
      'simulatorId': serializer.toJson<int?>(simulatorId),
      'approachType': serializer.toJson<String?>(approachType),
      'nightLandings': serializer.toJson<int?>(nightLandings),
      'dayLandings': serializer.toJson<int?>(dayLandings),
      'flightRules': serializer.toJson<String?>(flightRules),
      'remarks': serializer.toJson<String?>(remarks),
      'pilotRole': serializer.toJson<String?>(pilotRole),
      'instrumentMinutes': serializer.toJson<int?>(instrumentMinutes),
      'nightMinutes': serializer.toJson<int?>(nightMinutes),
      'logbookOverrides': serializer.toJson<LogbookOverrides?>(
        logbookOverrides,
      ),
      'trackSource': serializer.toJson<String?>(trackSource),
      'proficiencyCheck': serializer.toJson<bool>(proficiencyCheck),
      'signatureFile': serializer.toJson<String?>(signatureFile),
    };
  }

  Flight copyWith({
    int? id,
    String? title,
    Value<int?> departure = const Value.absent(),
    Value<int?> arrival = const Value.absent(),
    DateTime? departureTime,
    Value<DateTime?> arrivalTime = const Value.absent(),
    Value<String?> departureIanaLocation = const Value.absent(),
    Value<String?> arrivalIanaLocation = const Value.absent(),
    bool? isRecording,
    Value<int?> aircraftId = const Value.absent(),
    Value<int?> simulatorId = const Value.absent(),
    Value<String?> approachType = const Value.absent(),
    Value<int?> nightLandings = const Value.absent(),
    Value<int?> dayLandings = const Value.absent(),
    Value<String?> flightRules = const Value.absent(),
    Value<String?> remarks = const Value.absent(),
    Value<String?> pilotRole = const Value.absent(),
    Value<int?> instrumentMinutes = const Value.absent(),
    Value<int?> nightMinutes = const Value.absent(),
    Value<LogbookOverrides?> logbookOverrides = const Value.absent(),
    Value<String?> trackSource = const Value.absent(),
    bool? proficiencyCheck,
    Value<String?> signatureFile = const Value.absent(),
  }) => Flight(
    id: id ?? this.id,
    title: title ?? this.title,
    departure: departure.present ? departure.value : this.departure,
    arrival: arrival.present ? arrival.value : this.arrival,
    departureTime: departureTime ?? this.departureTime,
    arrivalTime: arrivalTime.present ? arrivalTime.value : this.arrivalTime,
    departureIanaLocation: departureIanaLocation.present
        ? departureIanaLocation.value
        : this.departureIanaLocation,
    arrivalIanaLocation: arrivalIanaLocation.present
        ? arrivalIanaLocation.value
        : this.arrivalIanaLocation,
    isRecording: isRecording ?? this.isRecording,
    aircraftId: aircraftId.present ? aircraftId.value : this.aircraftId,
    simulatorId: simulatorId.present ? simulatorId.value : this.simulatorId,
    approachType: approachType.present ? approachType.value : this.approachType,
    nightLandings: nightLandings.present
        ? nightLandings.value
        : this.nightLandings,
    dayLandings: dayLandings.present ? dayLandings.value : this.dayLandings,
    flightRules: flightRules.present ? flightRules.value : this.flightRules,
    remarks: remarks.present ? remarks.value : this.remarks,
    pilotRole: pilotRole.present ? pilotRole.value : this.pilotRole,
    instrumentMinutes: instrumentMinutes.present
        ? instrumentMinutes.value
        : this.instrumentMinutes,
    nightMinutes: nightMinutes.present ? nightMinutes.value : this.nightMinutes,
    logbookOverrides: logbookOverrides.present
        ? logbookOverrides.value
        : this.logbookOverrides,
    trackSource: trackSource.present ? trackSource.value : this.trackSource,
    proficiencyCheck: proficiencyCheck ?? this.proficiencyCheck,
    signatureFile: signatureFile.present
        ? signatureFile.value
        : this.signatureFile,
  );
  Flight copyWithCompanion(FlightsCompanion data) {
    return Flight(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      departure: data.departure.present ? data.departure.value : this.departure,
      arrival: data.arrival.present ? data.arrival.value : this.arrival,
      departureTime: data.departureTime.present
          ? data.departureTime.value
          : this.departureTime,
      arrivalTime: data.arrivalTime.present
          ? data.arrivalTime.value
          : this.arrivalTime,
      departureIanaLocation: data.departureIanaLocation.present
          ? data.departureIanaLocation.value
          : this.departureIanaLocation,
      arrivalIanaLocation: data.arrivalIanaLocation.present
          ? data.arrivalIanaLocation.value
          : this.arrivalIanaLocation,
      isRecording: data.isRecording.present
          ? data.isRecording.value
          : this.isRecording,
      aircraftId: data.aircraftId.present
          ? data.aircraftId.value
          : this.aircraftId,
      simulatorId: data.simulatorId.present
          ? data.simulatorId.value
          : this.simulatorId,
      approachType: data.approachType.present
          ? data.approachType.value
          : this.approachType,
      nightLandings: data.nightLandings.present
          ? data.nightLandings.value
          : this.nightLandings,
      dayLandings: data.dayLandings.present
          ? data.dayLandings.value
          : this.dayLandings,
      flightRules: data.flightRules.present
          ? data.flightRules.value
          : this.flightRules,
      remarks: data.remarks.present ? data.remarks.value : this.remarks,
      pilotRole: data.pilotRole.present ? data.pilotRole.value : this.pilotRole,
      instrumentMinutes: data.instrumentMinutes.present
          ? data.instrumentMinutes.value
          : this.instrumentMinutes,
      nightMinutes: data.nightMinutes.present
          ? data.nightMinutes.value
          : this.nightMinutes,
      logbookOverrides: data.logbookOverrides.present
          ? data.logbookOverrides.value
          : this.logbookOverrides,
      trackSource: data.trackSource.present
          ? data.trackSource.value
          : this.trackSource,
      proficiencyCheck: data.proficiencyCheck.present
          ? data.proficiencyCheck.value
          : this.proficiencyCheck,
      signatureFile: data.signatureFile.present
          ? data.signatureFile.value
          : this.signatureFile,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Flight(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('departure: $departure, ')
          ..write('arrival: $arrival, ')
          ..write('departureTime: $departureTime, ')
          ..write('arrivalTime: $arrivalTime, ')
          ..write('departureIanaLocation: $departureIanaLocation, ')
          ..write('arrivalIanaLocation: $arrivalIanaLocation, ')
          ..write('isRecording: $isRecording, ')
          ..write('aircraftId: $aircraftId, ')
          ..write('simulatorId: $simulatorId, ')
          ..write('approachType: $approachType, ')
          ..write('nightLandings: $nightLandings, ')
          ..write('dayLandings: $dayLandings, ')
          ..write('flightRules: $flightRules, ')
          ..write('remarks: $remarks, ')
          ..write('pilotRole: $pilotRole, ')
          ..write('instrumentMinutes: $instrumentMinutes, ')
          ..write('nightMinutes: $nightMinutes, ')
          ..write('logbookOverrides: $logbookOverrides, ')
          ..write('trackSource: $trackSource, ')
          ..write('proficiencyCheck: $proficiencyCheck, ')
          ..write('signatureFile: $signatureFile')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    title,
    departure,
    arrival,
    departureTime,
    arrivalTime,
    departureIanaLocation,
    arrivalIanaLocation,
    isRecording,
    aircraftId,
    simulatorId,
    approachType,
    nightLandings,
    dayLandings,
    flightRules,
    remarks,
    pilotRole,
    instrumentMinutes,
    nightMinutes,
    logbookOverrides,
    trackSource,
    proficiencyCheck,
    signatureFile,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Flight &&
          other.id == this.id &&
          other.title == this.title &&
          other.departure == this.departure &&
          other.arrival == this.arrival &&
          other.departureTime == this.departureTime &&
          other.arrivalTime == this.arrivalTime &&
          other.departureIanaLocation == this.departureIanaLocation &&
          other.arrivalIanaLocation == this.arrivalIanaLocation &&
          other.isRecording == this.isRecording &&
          other.aircraftId == this.aircraftId &&
          other.simulatorId == this.simulatorId &&
          other.approachType == this.approachType &&
          other.nightLandings == this.nightLandings &&
          other.dayLandings == this.dayLandings &&
          other.flightRules == this.flightRules &&
          other.remarks == this.remarks &&
          other.pilotRole == this.pilotRole &&
          other.instrumentMinutes == this.instrumentMinutes &&
          other.nightMinutes == this.nightMinutes &&
          other.logbookOverrides == this.logbookOverrides &&
          other.trackSource == this.trackSource &&
          other.proficiencyCheck == this.proficiencyCheck &&
          other.signatureFile == this.signatureFile);
}

class FlightsCompanion extends UpdateCompanion<Flight> {
  final Value<int> id;
  final Value<String> title;
  final Value<int?> departure;
  final Value<int?> arrival;
  final Value<DateTime> departureTime;
  final Value<DateTime?> arrivalTime;
  final Value<String?> departureIanaLocation;
  final Value<String?> arrivalIanaLocation;
  final Value<bool> isRecording;
  final Value<int?> aircraftId;
  final Value<int?> simulatorId;
  final Value<String?> approachType;
  final Value<int?> nightLandings;
  final Value<int?> dayLandings;
  final Value<String?> flightRules;
  final Value<String?> remarks;
  final Value<String?> pilotRole;
  final Value<int?> instrumentMinutes;
  final Value<int?> nightMinutes;
  final Value<LogbookOverrides?> logbookOverrides;
  final Value<String?> trackSource;
  final Value<bool> proficiencyCheck;
  final Value<String?> signatureFile;
  const FlightsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.departure = const Value.absent(),
    this.arrival = const Value.absent(),
    this.departureTime = const Value.absent(),
    this.arrivalTime = const Value.absent(),
    this.departureIanaLocation = const Value.absent(),
    this.arrivalIanaLocation = const Value.absent(),
    this.isRecording = const Value.absent(),
    this.aircraftId = const Value.absent(),
    this.simulatorId = const Value.absent(),
    this.approachType = const Value.absent(),
    this.nightLandings = const Value.absent(),
    this.dayLandings = const Value.absent(),
    this.flightRules = const Value.absent(),
    this.remarks = const Value.absent(),
    this.pilotRole = const Value.absent(),
    this.instrumentMinutes = const Value.absent(),
    this.nightMinutes = const Value.absent(),
    this.logbookOverrides = const Value.absent(),
    this.trackSource = const Value.absent(),
    this.proficiencyCheck = const Value.absent(),
    this.signatureFile = const Value.absent(),
  });
  FlightsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.departure = const Value.absent(),
    this.arrival = const Value.absent(),
    required DateTime departureTime,
    this.arrivalTime = const Value.absent(),
    this.departureIanaLocation = const Value.absent(),
    this.arrivalIanaLocation = const Value.absent(),
    required bool isRecording,
    this.aircraftId = const Value.absent(),
    this.simulatorId = const Value.absent(),
    this.approachType = const Value.absent(),
    this.nightLandings = const Value.absent(),
    this.dayLandings = const Value.absent(),
    this.flightRules = const Value.absent(),
    this.remarks = const Value.absent(),
    this.pilotRole = const Value.absent(),
    this.instrumentMinutes = const Value.absent(),
    this.nightMinutes = const Value.absent(),
    this.logbookOverrides = const Value.absent(),
    this.trackSource = const Value.absent(),
    this.proficiencyCheck = const Value.absent(),
    this.signatureFile = const Value.absent(),
  }) : title = Value(title),
       departureTime = Value(departureTime),
       isRecording = Value(isRecording);
  static Insertable<Flight> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<int>? departure,
    Expression<int>? arrival,
    Expression<DateTime>? departureTime,
    Expression<DateTime>? arrivalTime,
    Expression<String>? departureIanaLocation,
    Expression<String>? arrivalIanaLocation,
    Expression<bool>? isRecording,
    Expression<int>? aircraftId,
    Expression<int>? simulatorId,
    Expression<String>? approachType,
    Expression<int>? nightLandings,
    Expression<int>? dayLandings,
    Expression<String>? flightRules,
    Expression<String>? remarks,
    Expression<String>? pilotRole,
    Expression<int>? instrumentMinutes,
    Expression<int>? nightMinutes,
    Expression<String>? logbookOverrides,
    Expression<String>? trackSource,
    Expression<bool>? proficiencyCheck,
    Expression<String>? signatureFile,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (departure != null) 'departure': departure,
      if (arrival != null) 'arrival': arrival,
      if (departureTime != null) 'departure_time': departureTime,
      if (arrivalTime != null) 'arrival_time': arrivalTime,
      if (departureIanaLocation != null)
        'departure_iana_location': departureIanaLocation,
      if (arrivalIanaLocation != null)
        'arrival_iana_location': arrivalIanaLocation,
      if (isRecording != null) 'is_recording': isRecording,
      if (aircraftId != null) 'aircraft_id': aircraftId,
      if (simulatorId != null) 'simulator_id': simulatorId,
      if (approachType != null) 'approach_type': approachType,
      if (nightLandings != null) 'night_landings': nightLandings,
      if (dayLandings != null) 'day_landings': dayLandings,
      if (flightRules != null) 'flight_rules': flightRules,
      if (remarks != null) 'remarks': remarks,
      if (pilotRole != null) 'pilot_role': pilotRole,
      if (instrumentMinutes != null) 'instrument_minutes': instrumentMinutes,
      if (nightMinutes != null) 'night_minutes': nightMinutes,
      if (logbookOverrides != null) 'logbook_overrides': logbookOverrides,
      if (trackSource != null) 'track_source': trackSource,
      if (proficiencyCheck != null) 'proficiency_check': proficiencyCheck,
      if (signatureFile != null) 'signature_file': signatureFile,
    });
  }

  FlightsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<int?>? departure,
    Value<int?>? arrival,
    Value<DateTime>? departureTime,
    Value<DateTime?>? arrivalTime,
    Value<String?>? departureIanaLocation,
    Value<String?>? arrivalIanaLocation,
    Value<bool>? isRecording,
    Value<int?>? aircraftId,
    Value<int?>? simulatorId,
    Value<String?>? approachType,
    Value<int?>? nightLandings,
    Value<int?>? dayLandings,
    Value<String?>? flightRules,
    Value<String?>? remarks,
    Value<String?>? pilotRole,
    Value<int?>? instrumentMinutes,
    Value<int?>? nightMinutes,
    Value<LogbookOverrides?>? logbookOverrides,
    Value<String?>? trackSource,
    Value<bool>? proficiencyCheck,
    Value<String?>? signatureFile,
  }) {
    return FlightsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      departure: departure ?? this.departure,
      arrival: arrival ?? this.arrival,
      departureTime: departureTime ?? this.departureTime,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      departureIanaLocation:
          departureIanaLocation ?? this.departureIanaLocation,
      arrivalIanaLocation: arrivalIanaLocation ?? this.arrivalIanaLocation,
      isRecording: isRecording ?? this.isRecording,
      aircraftId: aircraftId ?? this.aircraftId,
      simulatorId: simulatorId ?? this.simulatorId,
      approachType: approachType ?? this.approachType,
      nightLandings: nightLandings ?? this.nightLandings,
      dayLandings: dayLandings ?? this.dayLandings,
      flightRules: flightRules ?? this.flightRules,
      remarks: remarks ?? this.remarks,
      pilotRole: pilotRole ?? this.pilotRole,
      instrumentMinutes: instrumentMinutes ?? this.instrumentMinutes,
      nightMinutes: nightMinutes ?? this.nightMinutes,
      logbookOverrides: logbookOverrides ?? this.logbookOverrides,
      trackSource: trackSource ?? this.trackSource,
      proficiencyCheck: proficiencyCheck ?? this.proficiencyCheck,
      signatureFile: signatureFile ?? this.signatureFile,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (departure.present) {
      map['departure'] = Variable<int>(departure.value);
    }
    if (arrival.present) {
      map['arrival'] = Variable<int>(arrival.value);
    }
    if (departureTime.present) {
      map['departure_time'] = Variable<DateTime>(departureTime.value);
    }
    if (arrivalTime.present) {
      map['arrival_time'] = Variable<DateTime>(arrivalTime.value);
    }
    if (departureIanaLocation.present) {
      map['departure_iana_location'] = Variable<String>(
        departureIanaLocation.value,
      );
    }
    if (arrivalIanaLocation.present) {
      map['arrival_iana_location'] = Variable<String>(
        arrivalIanaLocation.value,
      );
    }
    if (isRecording.present) {
      map['is_recording'] = Variable<bool>(isRecording.value);
    }
    if (aircraftId.present) {
      map['aircraft_id'] = Variable<int>(aircraftId.value);
    }
    if (simulatorId.present) {
      map['simulator_id'] = Variable<int>(simulatorId.value);
    }
    if (approachType.present) {
      map['approach_type'] = Variable<String>(approachType.value);
    }
    if (nightLandings.present) {
      map['night_landings'] = Variable<int>(nightLandings.value);
    }
    if (dayLandings.present) {
      map['day_landings'] = Variable<int>(dayLandings.value);
    }
    if (flightRules.present) {
      map['flight_rules'] = Variable<String>(flightRules.value);
    }
    if (remarks.present) {
      map['remarks'] = Variable<String>(remarks.value);
    }
    if (pilotRole.present) {
      map['pilot_role'] = Variable<String>(pilotRole.value);
    }
    if (instrumentMinutes.present) {
      map['instrument_minutes'] = Variable<int>(instrumentMinutes.value);
    }
    if (nightMinutes.present) {
      map['night_minutes'] = Variable<int>(nightMinutes.value);
    }
    if (logbookOverrides.present) {
      map['logbook_overrides'] = Variable<String>(
        $FlightsTable.$converterlogbookOverridesn.toSql(logbookOverrides.value),
      );
    }
    if (trackSource.present) {
      map['track_source'] = Variable<String>(trackSource.value);
    }
    if (proficiencyCheck.present) {
      map['proficiency_check'] = Variable<bool>(proficiencyCheck.value);
    }
    if (signatureFile.present) {
      map['signature_file'] = Variable<String>(signatureFile.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FlightsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('departure: $departure, ')
          ..write('arrival: $arrival, ')
          ..write('departureTime: $departureTime, ')
          ..write('arrivalTime: $arrivalTime, ')
          ..write('departureIanaLocation: $departureIanaLocation, ')
          ..write('arrivalIanaLocation: $arrivalIanaLocation, ')
          ..write('isRecording: $isRecording, ')
          ..write('aircraftId: $aircraftId, ')
          ..write('simulatorId: $simulatorId, ')
          ..write('approachType: $approachType, ')
          ..write('nightLandings: $nightLandings, ')
          ..write('dayLandings: $dayLandings, ')
          ..write('flightRules: $flightRules, ')
          ..write('remarks: $remarks, ')
          ..write('pilotRole: $pilotRole, ')
          ..write('instrumentMinutes: $instrumentMinutes, ')
          ..write('nightMinutes: $nightMinutes, ')
          ..write('logbookOverrides: $logbookOverrides, ')
          ..write('trackSource: $trackSource, ')
          ..write('proficiencyCheck: $proficiencyCheck, ')
          ..write('signatureFile: $signatureFile')
          ..write(')'))
        .toString();
  }
}

class $FlightDataPointsTable extends FlightDataPoints
    with TableInfo<$FlightDataPointsTable, FlightDataPoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FlightDataPointsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _flightMeta = const VerificationMeta('flight');
  @override
  late final GeneratedColumn<int> flight = GeneratedColumn<int>(
    'flight',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES flights (id)',
    ),
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _altitudeMeta = const VerificationMeta(
    'altitude',
  );
  @override
  late final GeneratedColumn<int> altitude = GeneratedColumn<int>(
    'altitude',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _speedMeta = const VerificationMeta('speed');
  @override
  late final GeneratedColumn<double> speed = GeneratedColumn<double>(
    'speed',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _headingMeta = const VerificationMeta(
    'heading',
  );
  @override
  late final GeneratedColumn<double> heading = GeneratedColumn<double>(
    'heading',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    flight,
    longitude,
    latitude,
    altitude,
    timestamp,
    speed,
    heading,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'flight_data_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<FlightDataPoint> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('flight')) {
      context.handle(
        _flightMeta,
        flight.isAcceptableOrUnknown(data['flight']!, _flightMeta),
      );
    } else if (isInserting) {
      context.missing(_flightMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('altitude')) {
      context.handle(
        _altitudeMeta,
        altitude.isAcceptableOrUnknown(data['altitude']!, _altitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_altitudeMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('speed')) {
      context.handle(
        _speedMeta,
        speed.isAcceptableOrUnknown(data['speed']!, _speedMeta),
      );
    }
    if (data.containsKey('heading')) {
      context.handle(
        _headingMeta,
        heading.isAcceptableOrUnknown(data['heading']!, _headingMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FlightDataPoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FlightDataPoint(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      flight: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}flight'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      altitude: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}altitude'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      speed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed'],
      ),
      heading: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}heading'],
      ),
    );
  }

  @override
  $FlightDataPointsTable createAlias(String alias) {
    return $FlightDataPointsTable(attachedDatabase, alias);
  }
}

class FlightDataPoint extends DataClass implements Insertable<FlightDataPoint> {
  final int id;
  final int flight;
  final double longitude;
  final double latitude;

  /// Metres.
  final int altitude;
  final DateTime timestamp;

  /// Ground speed, km/h.
  final double? speed;

  /// Degrees.
  final double? heading;
  const FlightDataPoint({
    required this.id,
    required this.flight,
    required this.longitude,
    required this.latitude,
    required this.altitude,
    required this.timestamp,
    this.speed,
    this.heading,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['flight'] = Variable<int>(flight);
    map['longitude'] = Variable<double>(longitude);
    map['latitude'] = Variable<double>(latitude);
    map['altitude'] = Variable<int>(altitude);
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || speed != null) {
      map['speed'] = Variable<double>(speed);
    }
    if (!nullToAbsent || heading != null) {
      map['heading'] = Variable<double>(heading);
    }
    return map;
  }

  FlightDataPointsCompanion toCompanion(bool nullToAbsent) {
    return FlightDataPointsCompanion(
      id: Value(id),
      flight: Value(flight),
      longitude: Value(longitude),
      latitude: Value(latitude),
      altitude: Value(altitude),
      timestamp: Value(timestamp),
      speed: speed == null && nullToAbsent
          ? const Value.absent()
          : Value(speed),
      heading: heading == null && nullToAbsent
          ? const Value.absent()
          : Value(heading),
    );
  }

  factory FlightDataPoint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FlightDataPoint(
      id: serializer.fromJson<int>(json['id']),
      flight: serializer.fromJson<int>(json['flight']),
      longitude: serializer.fromJson<double>(json['longitude']),
      latitude: serializer.fromJson<double>(json['latitude']),
      altitude: serializer.fromJson<int>(json['altitude']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      speed: serializer.fromJson<double?>(json['speed']),
      heading: serializer.fromJson<double?>(json['heading']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'flight': serializer.toJson<int>(flight),
      'longitude': serializer.toJson<double>(longitude),
      'latitude': serializer.toJson<double>(latitude),
      'altitude': serializer.toJson<int>(altitude),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'speed': serializer.toJson<double?>(speed),
      'heading': serializer.toJson<double?>(heading),
    };
  }

  FlightDataPoint copyWith({
    int? id,
    int? flight,
    double? longitude,
    double? latitude,
    int? altitude,
    DateTime? timestamp,
    Value<double?> speed = const Value.absent(),
    Value<double?> heading = const Value.absent(),
  }) => FlightDataPoint(
    id: id ?? this.id,
    flight: flight ?? this.flight,
    longitude: longitude ?? this.longitude,
    latitude: latitude ?? this.latitude,
    altitude: altitude ?? this.altitude,
    timestamp: timestamp ?? this.timestamp,
    speed: speed.present ? speed.value : this.speed,
    heading: heading.present ? heading.value : this.heading,
  );
  FlightDataPoint copyWithCompanion(FlightDataPointsCompanion data) {
    return FlightDataPoint(
      id: data.id.present ? data.id.value : this.id,
      flight: data.flight.present ? data.flight.value : this.flight,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      altitude: data.altitude.present ? data.altitude.value : this.altitude,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      speed: data.speed.present ? data.speed.value : this.speed,
      heading: data.heading.present ? data.heading.value : this.heading,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FlightDataPoint(')
          ..write('id: $id, ')
          ..write('flight: $flight, ')
          ..write('longitude: $longitude, ')
          ..write('latitude: $latitude, ')
          ..write('altitude: $altitude, ')
          ..write('timestamp: $timestamp, ')
          ..write('speed: $speed, ')
          ..write('heading: $heading')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    flight,
    longitude,
    latitude,
    altitude,
    timestamp,
    speed,
    heading,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FlightDataPoint &&
          other.id == this.id &&
          other.flight == this.flight &&
          other.longitude == this.longitude &&
          other.latitude == this.latitude &&
          other.altitude == this.altitude &&
          other.timestamp == this.timestamp &&
          other.speed == this.speed &&
          other.heading == this.heading);
}

class FlightDataPointsCompanion extends UpdateCompanion<FlightDataPoint> {
  final Value<int> id;
  final Value<int> flight;
  final Value<double> longitude;
  final Value<double> latitude;
  final Value<int> altitude;
  final Value<DateTime> timestamp;
  final Value<double?> speed;
  final Value<double?> heading;
  const FlightDataPointsCompanion({
    this.id = const Value.absent(),
    this.flight = const Value.absent(),
    this.longitude = const Value.absent(),
    this.latitude = const Value.absent(),
    this.altitude = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.speed = const Value.absent(),
    this.heading = const Value.absent(),
  });
  FlightDataPointsCompanion.insert({
    this.id = const Value.absent(),
    required int flight,
    required double longitude,
    required double latitude,
    required int altitude,
    required DateTime timestamp,
    this.speed = const Value.absent(),
    this.heading = const Value.absent(),
  }) : flight = Value(flight),
       longitude = Value(longitude),
       latitude = Value(latitude),
       altitude = Value(altitude),
       timestamp = Value(timestamp);
  static Insertable<FlightDataPoint> custom({
    Expression<int>? id,
    Expression<int>? flight,
    Expression<double>? longitude,
    Expression<double>? latitude,
    Expression<int>? altitude,
    Expression<DateTime>? timestamp,
    Expression<double>? speed,
    Expression<double>? heading,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (flight != null) 'flight': flight,
      if (longitude != null) 'longitude': longitude,
      if (latitude != null) 'latitude': latitude,
      if (altitude != null) 'altitude': altitude,
      if (timestamp != null) 'timestamp': timestamp,
      if (speed != null) 'speed': speed,
      if (heading != null) 'heading': heading,
    });
  }

  FlightDataPointsCompanion copyWith({
    Value<int>? id,
    Value<int>? flight,
    Value<double>? longitude,
    Value<double>? latitude,
    Value<int>? altitude,
    Value<DateTime>? timestamp,
    Value<double?>? speed,
    Value<double?>? heading,
  }) {
    return FlightDataPointsCompanion(
      id: id ?? this.id,
      flight: flight ?? this.flight,
      longitude: longitude ?? this.longitude,
      latitude: latitude ?? this.latitude,
      altitude: altitude ?? this.altitude,
      timestamp: timestamp ?? this.timestamp,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (flight.present) {
      map['flight'] = Variable<int>(flight.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (altitude.present) {
      map['altitude'] = Variable<int>(altitude.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (speed.present) {
      map['speed'] = Variable<double>(speed.value);
    }
    if (heading.present) {
      map['heading'] = Variable<double>(heading.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FlightDataPointsCompanion(')
          ..write('id: $id, ')
          ..write('flight: $flight, ')
          ..write('longitude: $longitude, ')
          ..write('latitude: $latitude, ')
          ..write('altitude: $altitude, ')
          ..write('timestamp: $timestamp, ')
          ..write('speed: $speed, ')
          ..write('heading: $heading')
          ..write(')'))
        .toString();
  }
}

class $PeopleTable extends People with TableInfo<$PeopleTable, Person> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeopleTable(this.attachedDatabase, [this._alias]);
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
  );
  static const VerificationMeta _surnameMeta = const VerificationMeta(
    'surname',
  );
  @override
  late final GeneratedColumn<String> surname = GeneratedColumn<String>(
    'surname',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _photoMeta = const VerificationMeta('photo');
  @override
  late final GeneratedColumn<String> photo = GeneratedColumn<String>(
    'photo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, surname, photo];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'people';
  @override
  VerificationContext validateIntegrity(
    Insertable<Person> instance, {
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
    if (data.containsKey('surname')) {
      context.handle(
        _surnameMeta,
        surname.isAcceptableOrUnknown(data['surname']!, _surnameMeta),
      );
    } else if (isInserting) {
      context.missing(_surnameMeta);
    }
    if (data.containsKey('photo')) {
      context.handle(
        _photoMeta,
        photo.isAcceptableOrUnknown(data['photo']!, _photoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Person map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Person(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      surname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}surname'],
      )!,
      photo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo'],
      ),
    );
  }

  @override
  $PeopleTable createAlias(String alias) {
    return $PeopleTable(attachedDatabase, alias);
  }
}

class Person extends DataClass implements Insertable<Person> {
  final int id;
  final String name;
  final String surname;

  /// File name of the profile picture inside the app's people photo folder.
  final String? photo;
  const Person({
    required this.id,
    required this.name,
    required this.surname,
    this.photo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['surname'] = Variable<String>(surname);
    if (!nullToAbsent || photo != null) {
      map['photo'] = Variable<String>(photo);
    }
    return map;
  }

  PeopleCompanion toCompanion(bool nullToAbsent) {
    return PeopleCompanion(
      id: Value(id),
      name: Value(name),
      surname: Value(surname),
      photo: photo == null && nullToAbsent
          ? const Value.absent()
          : Value(photo),
    );
  }

  factory Person.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Person(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      surname: serializer.fromJson<String>(json['surname']),
      photo: serializer.fromJson<String?>(json['photo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'surname': serializer.toJson<String>(surname),
      'photo': serializer.toJson<String?>(photo),
    };
  }

  Person copyWith({
    int? id,
    String? name,
    String? surname,
    Value<String?> photo = const Value.absent(),
  }) => Person(
    id: id ?? this.id,
    name: name ?? this.name,
    surname: surname ?? this.surname,
    photo: photo.present ? photo.value : this.photo,
  );
  Person copyWithCompanion(PeopleCompanion data) {
    return Person(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      surname: data.surname.present ? data.surname.value : this.surname,
      photo: data.photo.present ? data.photo.value : this.photo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Person(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('surname: $surname, ')
          ..write('photo: $photo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, surname, photo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Person &&
          other.id == this.id &&
          other.name == this.name &&
          other.surname == this.surname &&
          other.photo == this.photo);
}

class PeopleCompanion extends UpdateCompanion<Person> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> surname;
  final Value<String?> photo;
  const PeopleCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.surname = const Value.absent(),
    this.photo = const Value.absent(),
  });
  PeopleCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String surname,
    this.photo = const Value.absent(),
  }) : name = Value(name),
       surname = Value(surname);
  static Insertable<Person> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? surname,
    Expression<String>? photo,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (surname != null) 'surname': surname,
      if (photo != null) 'photo': photo,
    });
  }

  PeopleCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? surname,
    Value<String?>? photo,
  }) {
    return PeopleCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      photo: photo ?? this.photo,
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
    if (surname.present) {
      map['surname'] = Variable<String>(surname.value);
    }
    if (photo.present) {
      map['photo'] = Variable<String>(photo.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeopleCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('surname: $surname, ')
          ..write('photo: $photo')
          ..write(')'))
        .toString();
  }
}

class $FlightCrewTable extends FlightCrew
    with TableInfo<$FlightCrewTable, FlightCrewEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FlightCrewTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _flightMeta = const VerificationMeta('flight');
  @override
  late final GeneratedColumn<int> flight = GeneratedColumn<int>(
    'flight',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES flights (id)',
    ),
  );
  static const VerificationMeta _personMeta = const VerificationMeta('person');
  @override
  late final GeneratedColumn<int> person = GeneratedColumn<int>(
    'person',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES people (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<CrewRole, String> role =
      GeneratedColumn<String>(
        'role',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CrewRole>($FlightCrewTable.$converterrole);
  @override
  List<GeneratedColumn> get $columns => [flight, person, role];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'flight_crew';
  @override
  VerificationContext validateIntegrity(
    Insertable<FlightCrewEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('flight')) {
      context.handle(
        _flightMeta,
        flight.isAcceptableOrUnknown(data['flight']!, _flightMeta),
      );
    } else if (isInserting) {
      context.missing(_flightMeta);
    }
    if (data.containsKey('person')) {
      context.handle(
        _personMeta,
        person.isAcceptableOrUnknown(data['person']!, _personMeta),
      );
    } else if (isInserting) {
      context.missing(_personMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {flight, person};
  @override
  FlightCrewEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FlightCrewEntry(
      flight: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}flight'],
      )!,
      person: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}person'],
      )!,
      role: $FlightCrewTable.$converterrole.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}role'],
        )!,
      ),
    );
  }

  @override
  $FlightCrewTable createAlias(String alias) {
    return $FlightCrewTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CrewRole, String, String> $converterrole =
      const EnumNameConverter<CrewRole>(CrewRole.values);
}

class FlightCrewEntry extends DataClass implements Insertable<FlightCrewEntry> {
  final int flight;
  final int person;
  final CrewRole role;
  const FlightCrewEntry({
    required this.flight,
    required this.person,
    required this.role,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['flight'] = Variable<int>(flight);
    map['person'] = Variable<int>(person);
    {
      map['role'] = Variable<String>(
        $FlightCrewTable.$converterrole.toSql(role),
      );
    }
    return map;
  }

  FlightCrewCompanion toCompanion(bool nullToAbsent) {
    return FlightCrewCompanion(
      flight: Value(flight),
      person: Value(person),
      role: Value(role),
    );
  }

  factory FlightCrewEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FlightCrewEntry(
      flight: serializer.fromJson<int>(json['flight']),
      person: serializer.fromJson<int>(json['person']),
      role: $FlightCrewTable.$converterrole.fromJson(
        serializer.fromJson<String>(json['role']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'flight': serializer.toJson<int>(flight),
      'person': serializer.toJson<int>(person),
      'role': serializer.toJson<String>(
        $FlightCrewTable.$converterrole.toJson(role),
      ),
    };
  }

  FlightCrewEntry copyWith({int? flight, int? person, CrewRole? role}) =>
      FlightCrewEntry(
        flight: flight ?? this.flight,
        person: person ?? this.person,
        role: role ?? this.role,
      );
  FlightCrewEntry copyWithCompanion(FlightCrewCompanion data) {
    return FlightCrewEntry(
      flight: data.flight.present ? data.flight.value : this.flight,
      person: data.person.present ? data.person.value : this.person,
      role: data.role.present ? data.role.value : this.role,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FlightCrewEntry(')
          ..write('flight: $flight, ')
          ..write('person: $person, ')
          ..write('role: $role')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(flight, person, role);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FlightCrewEntry &&
          other.flight == this.flight &&
          other.person == this.person &&
          other.role == this.role);
}

class FlightCrewCompanion extends UpdateCompanion<FlightCrewEntry> {
  final Value<int> flight;
  final Value<int> person;
  final Value<CrewRole> role;
  final Value<int> rowid;
  const FlightCrewCompanion({
    this.flight = const Value.absent(),
    this.person = const Value.absent(),
    this.role = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FlightCrewCompanion.insert({
    required int flight,
    required int person,
    required CrewRole role,
    this.rowid = const Value.absent(),
  }) : flight = Value(flight),
       person = Value(person),
       role = Value(role);
  static Insertable<FlightCrewEntry> custom({
    Expression<int>? flight,
    Expression<int>? person,
    Expression<String>? role,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (flight != null) 'flight': flight,
      if (person != null) 'person': person,
      if (role != null) 'role': role,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FlightCrewCompanion copyWith({
    Value<int>? flight,
    Value<int>? person,
    Value<CrewRole>? role,
    Value<int>? rowid,
  }) {
    return FlightCrewCompanion(
      flight: flight ?? this.flight,
      person: person ?? this.person,
      role: role ?? this.role,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (flight.present) {
      map['flight'] = Variable<int>(flight.value);
    }
    if (person.present) {
      map['person'] = Variable<int>(person.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(
        $FlightCrewTable.$converterrole.toSql(role.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FlightCrewCompanion(')
          ..write('flight: $flight, ')
          ..write('person: $person, ')
          ..write('role: $role, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LicencesTable extends Licences with TableInfo<$LicencesTable, Licence> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LicencesTable(this.attachedDatabase, [this._alias]);
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
  @override
  late final GeneratedColumnWithTypeConverter<LicenceKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LicenceKind>($LicencesTable.$converterkind);
  @override
  late final GeneratedColumnWithTypeConverter<AircraftCategory, String>
  category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<AircraftCategory>($LicencesTable.$convertercategory);
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<String> number = GeneratedColumn<String>(
    'number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _issuedByMeta = const VerificationMeta(
    'issuedBy',
  );
  @override
  late final GeneratedColumn<String> issuedBy = GeneratedColumn<String>(
    'issued_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _issueDateMeta = const VerificationMeta(
    'issueDate',
  );
  @override
  late final GeneratedColumn<DateTime> issueDate = GeneratedColumn<DateTime>(
    'issue_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _proficiencyCheckDateMeta =
      const VerificationMeta('proficiencyCheckDate');
  @override
  late final GeneratedColumn<DateTime> proficiencyCheckDate =
      GeneratedColumn<DateTime>(
        'proficiency_check_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    category,
    number,
    issuedBy,
    issueDate,
    proficiencyCheckDate,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'licences';
  @override
  VerificationContext validateIntegrity(
    Insertable<Licence> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    }
    if (data.containsKey('issued_by')) {
      context.handle(
        _issuedByMeta,
        issuedBy.isAcceptableOrUnknown(data['issued_by']!, _issuedByMeta),
      );
    }
    if (data.containsKey('issue_date')) {
      context.handle(
        _issueDateMeta,
        issueDate.isAcceptableOrUnknown(data['issue_date']!, _issueDateMeta),
      );
    }
    if (data.containsKey('proficiency_check_date')) {
      context.handle(
        _proficiencyCheckDateMeta,
        proficiencyCheckDate.isAcceptableOrUnknown(
          data['proficiency_check_date']!,
          _proficiencyCheckDateMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Licence map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Licence(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kind: $LicencesTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      category: $LicencesTable.$convertercategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}category'],
        )!,
      ),
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}number'],
      ),
      issuedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}issued_by'],
      ),
      issueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}issue_date'],
      ),
      proficiencyCheckDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}proficiency_check_date'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $LicencesTable createAlias(String alias) {
    return $LicencesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<LicenceKind, String, String> $converterkind =
      const EnumNameConverter<LicenceKind>(LicenceKind.values);
  static JsonTypeConverter2<AircraftCategory, String, String>
  $convertercategory = const EnumNameConverter<AircraftCategory>(
    AircraftCategory.values,
  );
}

class Licence extends DataClass implements Insertable<Licence> {
  final int id;
  final LicenceKind kind;
  final AircraftCategory category;

  /// Licence number, as printed on it.
  final String? number;

  /// Who issued it: the competent authority ("ENAC", "LBA"...).
  final String? issuedBy;
  final DateTime? issueDate;

  /// Last proficiency check with an examiner, which keeps a LAPL(A) recent
  /// for 2 years on its own (FCL.140.A(a)(2)).
  final DateTime? proficiencyCheckDate;
  final String? notes;
  const Licence({
    required this.id,
    required this.kind,
    required this.category,
    this.number,
    this.issuedBy,
    this.issueDate,
    this.proficiencyCheckDate,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['kind'] = Variable<String>($LicencesTable.$converterkind.toSql(kind));
    }
    {
      map['category'] = Variable<String>(
        $LicencesTable.$convertercategory.toSql(category),
      );
    }
    if (!nullToAbsent || number != null) {
      map['number'] = Variable<String>(number);
    }
    if (!nullToAbsent || issuedBy != null) {
      map['issued_by'] = Variable<String>(issuedBy);
    }
    if (!nullToAbsent || issueDate != null) {
      map['issue_date'] = Variable<DateTime>(issueDate);
    }
    if (!nullToAbsent || proficiencyCheckDate != null) {
      map['proficiency_check_date'] = Variable<DateTime>(proficiencyCheckDate);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  LicencesCompanion toCompanion(bool nullToAbsent) {
    return LicencesCompanion(
      id: Value(id),
      kind: Value(kind),
      category: Value(category),
      number: number == null && nullToAbsent
          ? const Value.absent()
          : Value(number),
      issuedBy: issuedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(issuedBy),
      issueDate: issueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(issueDate),
      proficiencyCheckDate: proficiencyCheckDate == null && nullToAbsent
          ? const Value.absent()
          : Value(proficiencyCheckDate),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory Licence.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Licence(
      id: serializer.fromJson<int>(json['id']),
      kind: $LicencesTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      category: $LicencesTable.$convertercategory.fromJson(
        serializer.fromJson<String>(json['category']),
      ),
      number: serializer.fromJson<String?>(json['number']),
      issuedBy: serializer.fromJson<String?>(json['issuedBy']),
      issueDate: serializer.fromJson<DateTime?>(json['issueDate']),
      proficiencyCheckDate: serializer.fromJson<DateTime?>(
        json['proficiencyCheckDate'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<String>(
        $LicencesTable.$converterkind.toJson(kind),
      ),
      'category': serializer.toJson<String>(
        $LicencesTable.$convertercategory.toJson(category),
      ),
      'number': serializer.toJson<String?>(number),
      'issuedBy': serializer.toJson<String?>(issuedBy),
      'issueDate': serializer.toJson<DateTime?>(issueDate),
      'proficiencyCheckDate': serializer.toJson<DateTime?>(
        proficiencyCheckDate,
      ),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  Licence copyWith({
    int? id,
    LicenceKind? kind,
    AircraftCategory? category,
    Value<String?> number = const Value.absent(),
    Value<String?> issuedBy = const Value.absent(),
    Value<DateTime?> issueDate = const Value.absent(),
    Value<DateTime?> proficiencyCheckDate = const Value.absent(),
    Value<String?> notes = const Value.absent(),
  }) => Licence(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    category: category ?? this.category,
    number: number.present ? number.value : this.number,
    issuedBy: issuedBy.present ? issuedBy.value : this.issuedBy,
    issueDate: issueDate.present ? issueDate.value : this.issueDate,
    proficiencyCheckDate: proficiencyCheckDate.present
        ? proficiencyCheckDate.value
        : this.proficiencyCheckDate,
    notes: notes.present ? notes.value : this.notes,
  );
  Licence copyWithCompanion(LicencesCompanion data) {
    return Licence(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      category: data.category.present ? data.category.value : this.category,
      number: data.number.present ? data.number.value : this.number,
      issuedBy: data.issuedBy.present ? data.issuedBy.value : this.issuedBy,
      issueDate: data.issueDate.present ? data.issueDate.value : this.issueDate,
      proficiencyCheckDate: data.proficiencyCheckDate.present
          ? data.proficiencyCheckDate.value
          : this.proficiencyCheckDate,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Licence(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('category: $category, ')
          ..write('number: $number, ')
          ..write('issuedBy: $issuedBy, ')
          ..write('issueDate: $issueDate, ')
          ..write('proficiencyCheckDate: $proficiencyCheckDate, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    category,
    number,
    issuedBy,
    issueDate,
    proficiencyCheckDate,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Licence &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.category == this.category &&
          other.number == this.number &&
          other.issuedBy == this.issuedBy &&
          other.issueDate == this.issueDate &&
          other.proficiencyCheckDate == this.proficiencyCheckDate &&
          other.notes == this.notes);
}

class LicencesCompanion extends UpdateCompanion<Licence> {
  final Value<int> id;
  final Value<LicenceKind> kind;
  final Value<AircraftCategory> category;
  final Value<String?> number;
  final Value<String?> issuedBy;
  final Value<DateTime?> issueDate;
  final Value<DateTime?> proficiencyCheckDate;
  final Value<String?> notes;
  const LicencesCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.category = const Value.absent(),
    this.number = const Value.absent(),
    this.issuedBy = const Value.absent(),
    this.issueDate = const Value.absent(),
    this.proficiencyCheckDate = const Value.absent(),
    this.notes = const Value.absent(),
  });
  LicencesCompanion.insert({
    this.id = const Value.absent(),
    required LicenceKind kind,
    required AircraftCategory category,
    this.number = const Value.absent(),
    this.issuedBy = const Value.absent(),
    this.issueDate = const Value.absent(),
    this.proficiencyCheckDate = const Value.absent(),
    this.notes = const Value.absent(),
  }) : kind = Value(kind),
       category = Value(category);
  static Insertable<Licence> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<String>? category,
    Expression<String>? number,
    Expression<String>? issuedBy,
    Expression<DateTime>? issueDate,
    Expression<DateTime>? proficiencyCheckDate,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (category != null) 'category': category,
      if (number != null) 'number': number,
      if (issuedBy != null) 'issued_by': issuedBy,
      if (issueDate != null) 'issue_date': issueDate,
      if (proficiencyCheckDate != null)
        'proficiency_check_date': proficiencyCheckDate,
      if (notes != null) 'notes': notes,
    });
  }

  LicencesCompanion copyWith({
    Value<int>? id,
    Value<LicenceKind>? kind,
    Value<AircraftCategory>? category,
    Value<String?>? number,
    Value<String?>? issuedBy,
    Value<DateTime?>? issueDate,
    Value<DateTime?>? proficiencyCheckDate,
    Value<String?>? notes,
  }) {
    return LicencesCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      category: category ?? this.category,
      number: number ?? this.number,
      issuedBy: issuedBy ?? this.issuedBy,
      issueDate: issueDate ?? this.issueDate,
      proficiencyCheckDate: proficiencyCheckDate ?? this.proficiencyCheckDate,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $LicencesTable.$converterkind.toSql(kind.value),
      );
    }
    if (category.present) {
      map['category'] = Variable<String>(
        $LicencesTable.$convertercategory.toSql(category.value),
      );
    }
    if (number.present) {
      map['number'] = Variable<String>(number.value);
    }
    if (issuedBy.present) {
      map['issued_by'] = Variable<String>(issuedBy.value);
    }
    if (issueDate.present) {
      map['issue_date'] = Variable<DateTime>(issueDate.value);
    }
    if (proficiencyCheckDate.present) {
      map['proficiency_check_date'] = Variable<DateTime>(
        proficiencyCheckDate.value,
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LicencesCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('category: $category, ')
          ..write('number: $number, ')
          ..write('issuedBy: $issuedBy, ')
          ..write('issueDate: $issueDate, ')
          ..write('proficiencyCheckDate: $proficiencyCheckDate, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $LicenceRatingsTable extends LicenceRatings
    with TableInfo<$LicenceRatingsTable, LicenceRating> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LicenceRatingsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _licenceMeta = const VerificationMeta(
    'licence',
  );
  @override
  late final GeneratedColumn<int> licence = GeneratedColumn<int>(
    'licence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES licences (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<RatingKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<RatingKind>($LicenceRatingsTable.$converterkind);
  @override
  late final GeneratedColumnWithTypeConverter<AircraftClass?, String>
  aircraftClass =
      GeneratedColumn<String>(
        'aircraft_class',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<AircraftClass?>(
        $LicenceRatingsTable.$converteraircraftClassn,
      );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _issueDateMeta = const VerificationMeta(
    'issueDate',
  );
  @override
  late final GeneratedColumn<DateTime> issueDate = GeneratedColumn<DateTime>(
    'issue_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastCheckDateMeta = const VerificationMeta(
    'lastCheckDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastCheckDate =
      GeneratedColumn<DateTime>(
        'last_check_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _expiryDateMeta = const VerificationMeta(
    'expiryDate',
  );
  @override
  late final GeneratedColumn<DateTime> expiryDate = GeneratedColumn<DateTime>(
    'expiry_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    licence,
    kind,
    aircraftClass,
    name,
    level,
    issueDate,
    lastCheckDate,
    expiryDate,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'licence_ratings';
  @override
  VerificationContext validateIntegrity(
    Insertable<LicenceRating> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('licence')) {
      context.handle(
        _licenceMeta,
        licence.isAcceptableOrUnknown(data['licence']!, _licenceMeta),
      );
    } else if (isInserting) {
      context.missing(_licenceMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    }
    if (data.containsKey('issue_date')) {
      context.handle(
        _issueDateMeta,
        issueDate.isAcceptableOrUnknown(data['issue_date']!, _issueDateMeta),
      );
    }
    if (data.containsKey('last_check_date')) {
      context.handle(
        _lastCheckDateMeta,
        lastCheckDate.isAcceptableOrUnknown(
          data['last_check_date']!,
          _lastCheckDateMeta,
        ),
      );
    }
    if (data.containsKey('expiry_date')) {
      context.handle(
        _expiryDateMeta,
        expiryDate.isAcceptableOrUnknown(data['expiry_date']!, _expiryDateMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LicenceRating map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LicenceRating(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      licence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}licence'],
      )!,
      kind: $LicenceRatingsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      aircraftClass: $LicenceRatingsTable.$converteraircraftClassn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}aircraft_class'],
        ),
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      ),
      issueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}issue_date'],
      ),
      lastCheckDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_check_date'],
      ),
      expiryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expiry_date'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $LicenceRatingsTable createAlias(String alias) {
    return $LicenceRatingsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<RatingKind, String, String> $converterkind =
      const EnumNameConverter<RatingKind>(RatingKind.values);
  static JsonTypeConverter2<AircraftClass, String, String>
  $converteraircraftClass = const EnumNameConverter<AircraftClass>(
    AircraftClass.values,
  );
  static JsonTypeConverter2<AircraftClass?, String?, String?>
  $converteraircraftClassn = JsonTypeConverter2.asNullable(
    $converteraircraftClass,
  );
}

class LicenceRating extends DataClass implements Insertable<LicenceRating> {
  final int id;
  final int licence;
  final RatingKind kind;

  /// The class, for a [RatingKind.classRating].
  final AircraftClass? aircraftClass;

  /// What the pilot calls it: the type rating endorsement ("A320"), the
  /// instructor certificate ("FI(A)"), the language...
  final String? name;

  /// Language proficiency level (4 to 6).
  final int? level;
  final DateTime? issueDate;

  /// Last proficiency check (or skill test, assessment of competence).
  final DateTime? lastCheckDate;

  /// Last day of validity, as endorsed on the licence. Null when it doesn't
  /// expire.
  final DateTime? expiryDate;
  final String? notes;
  const LicenceRating({
    required this.id,
    required this.licence,
    required this.kind,
    this.aircraftClass,
    this.name,
    this.level,
    this.issueDate,
    this.lastCheckDate,
    this.expiryDate,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['licence'] = Variable<int>(licence);
    {
      map['kind'] = Variable<String>(
        $LicenceRatingsTable.$converterkind.toSql(kind),
      );
    }
    if (!nullToAbsent || aircraftClass != null) {
      map['aircraft_class'] = Variable<String>(
        $LicenceRatingsTable.$converteraircraftClassn.toSql(aircraftClass),
      );
    }
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || level != null) {
      map['level'] = Variable<int>(level);
    }
    if (!nullToAbsent || issueDate != null) {
      map['issue_date'] = Variable<DateTime>(issueDate);
    }
    if (!nullToAbsent || lastCheckDate != null) {
      map['last_check_date'] = Variable<DateTime>(lastCheckDate);
    }
    if (!nullToAbsent || expiryDate != null) {
      map['expiry_date'] = Variable<DateTime>(expiryDate);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  LicenceRatingsCompanion toCompanion(bool nullToAbsent) {
    return LicenceRatingsCompanion(
      id: Value(id),
      licence: Value(licence),
      kind: Value(kind),
      aircraftClass: aircraftClass == null && nullToAbsent
          ? const Value.absent()
          : Value(aircraftClass),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      level: level == null && nullToAbsent
          ? const Value.absent()
          : Value(level),
      issueDate: issueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(issueDate),
      lastCheckDate: lastCheckDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCheckDate),
      expiryDate: expiryDate == null && nullToAbsent
          ? const Value.absent()
          : Value(expiryDate),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory LicenceRating.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LicenceRating(
      id: serializer.fromJson<int>(json['id']),
      licence: serializer.fromJson<int>(json['licence']),
      kind: $LicenceRatingsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      aircraftClass: $LicenceRatingsTable.$converteraircraftClassn.fromJson(
        serializer.fromJson<String?>(json['aircraftClass']),
      ),
      name: serializer.fromJson<String?>(json['name']),
      level: serializer.fromJson<int?>(json['level']),
      issueDate: serializer.fromJson<DateTime?>(json['issueDate']),
      lastCheckDate: serializer.fromJson<DateTime?>(json['lastCheckDate']),
      expiryDate: serializer.fromJson<DateTime?>(json['expiryDate']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'licence': serializer.toJson<int>(licence),
      'kind': serializer.toJson<String>(
        $LicenceRatingsTable.$converterkind.toJson(kind),
      ),
      'aircraftClass': serializer.toJson<String?>(
        $LicenceRatingsTable.$converteraircraftClassn.toJson(aircraftClass),
      ),
      'name': serializer.toJson<String?>(name),
      'level': serializer.toJson<int?>(level),
      'issueDate': serializer.toJson<DateTime?>(issueDate),
      'lastCheckDate': serializer.toJson<DateTime?>(lastCheckDate),
      'expiryDate': serializer.toJson<DateTime?>(expiryDate),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  LicenceRating copyWith({
    int? id,
    int? licence,
    RatingKind? kind,
    Value<AircraftClass?> aircraftClass = const Value.absent(),
    Value<String?> name = const Value.absent(),
    Value<int?> level = const Value.absent(),
    Value<DateTime?> issueDate = const Value.absent(),
    Value<DateTime?> lastCheckDate = const Value.absent(),
    Value<DateTime?> expiryDate = const Value.absent(),
    Value<String?> notes = const Value.absent(),
  }) => LicenceRating(
    id: id ?? this.id,
    licence: licence ?? this.licence,
    kind: kind ?? this.kind,
    aircraftClass: aircraftClass.present
        ? aircraftClass.value
        : this.aircraftClass,
    name: name.present ? name.value : this.name,
    level: level.present ? level.value : this.level,
    issueDate: issueDate.present ? issueDate.value : this.issueDate,
    lastCheckDate: lastCheckDate.present
        ? lastCheckDate.value
        : this.lastCheckDate,
    expiryDate: expiryDate.present ? expiryDate.value : this.expiryDate,
    notes: notes.present ? notes.value : this.notes,
  );
  LicenceRating copyWithCompanion(LicenceRatingsCompanion data) {
    return LicenceRating(
      id: data.id.present ? data.id.value : this.id,
      licence: data.licence.present ? data.licence.value : this.licence,
      kind: data.kind.present ? data.kind.value : this.kind,
      aircraftClass: data.aircraftClass.present
          ? data.aircraftClass.value
          : this.aircraftClass,
      name: data.name.present ? data.name.value : this.name,
      level: data.level.present ? data.level.value : this.level,
      issueDate: data.issueDate.present ? data.issueDate.value : this.issueDate,
      lastCheckDate: data.lastCheckDate.present
          ? data.lastCheckDate.value
          : this.lastCheckDate,
      expiryDate: data.expiryDate.present
          ? data.expiryDate.value
          : this.expiryDate,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LicenceRating(')
          ..write('id: $id, ')
          ..write('licence: $licence, ')
          ..write('kind: $kind, ')
          ..write('aircraftClass: $aircraftClass, ')
          ..write('name: $name, ')
          ..write('level: $level, ')
          ..write('issueDate: $issueDate, ')
          ..write('lastCheckDate: $lastCheckDate, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    licence,
    kind,
    aircraftClass,
    name,
    level,
    issueDate,
    lastCheckDate,
    expiryDate,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LicenceRating &&
          other.id == this.id &&
          other.licence == this.licence &&
          other.kind == this.kind &&
          other.aircraftClass == this.aircraftClass &&
          other.name == this.name &&
          other.level == this.level &&
          other.issueDate == this.issueDate &&
          other.lastCheckDate == this.lastCheckDate &&
          other.expiryDate == this.expiryDate &&
          other.notes == this.notes);
}

class LicenceRatingsCompanion extends UpdateCompanion<LicenceRating> {
  final Value<int> id;
  final Value<int> licence;
  final Value<RatingKind> kind;
  final Value<AircraftClass?> aircraftClass;
  final Value<String?> name;
  final Value<int?> level;
  final Value<DateTime?> issueDate;
  final Value<DateTime?> lastCheckDate;
  final Value<DateTime?> expiryDate;
  final Value<String?> notes;
  const LicenceRatingsCompanion({
    this.id = const Value.absent(),
    this.licence = const Value.absent(),
    this.kind = const Value.absent(),
    this.aircraftClass = const Value.absent(),
    this.name = const Value.absent(),
    this.level = const Value.absent(),
    this.issueDate = const Value.absent(),
    this.lastCheckDate = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.notes = const Value.absent(),
  });
  LicenceRatingsCompanion.insert({
    this.id = const Value.absent(),
    required int licence,
    required RatingKind kind,
    this.aircraftClass = const Value.absent(),
    this.name = const Value.absent(),
    this.level = const Value.absent(),
    this.issueDate = const Value.absent(),
    this.lastCheckDate = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.notes = const Value.absent(),
  }) : licence = Value(licence),
       kind = Value(kind);
  static Insertable<LicenceRating> custom({
    Expression<int>? id,
    Expression<int>? licence,
    Expression<String>? kind,
    Expression<String>? aircraftClass,
    Expression<String>? name,
    Expression<int>? level,
    Expression<DateTime>? issueDate,
    Expression<DateTime>? lastCheckDate,
    Expression<DateTime>? expiryDate,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (licence != null) 'licence': licence,
      if (kind != null) 'kind': kind,
      if (aircraftClass != null) 'aircraft_class': aircraftClass,
      if (name != null) 'name': name,
      if (level != null) 'level': level,
      if (issueDate != null) 'issue_date': issueDate,
      if (lastCheckDate != null) 'last_check_date': lastCheckDate,
      if (expiryDate != null) 'expiry_date': expiryDate,
      if (notes != null) 'notes': notes,
    });
  }

  LicenceRatingsCompanion copyWith({
    Value<int>? id,
    Value<int>? licence,
    Value<RatingKind>? kind,
    Value<AircraftClass?>? aircraftClass,
    Value<String?>? name,
    Value<int?>? level,
    Value<DateTime?>? issueDate,
    Value<DateTime?>? lastCheckDate,
    Value<DateTime?>? expiryDate,
    Value<String?>? notes,
  }) {
    return LicenceRatingsCompanion(
      id: id ?? this.id,
      licence: licence ?? this.licence,
      kind: kind ?? this.kind,
      aircraftClass: aircraftClass ?? this.aircraftClass,
      name: name ?? this.name,
      level: level ?? this.level,
      issueDate: issueDate ?? this.issueDate,
      lastCheckDate: lastCheckDate ?? this.lastCheckDate,
      expiryDate: expiryDate ?? this.expiryDate,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (licence.present) {
      map['licence'] = Variable<int>(licence.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $LicenceRatingsTable.$converterkind.toSql(kind.value),
      );
    }
    if (aircraftClass.present) {
      map['aircraft_class'] = Variable<String>(
        $LicenceRatingsTable.$converteraircraftClassn.toSql(
          aircraftClass.value,
        ),
      );
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (issueDate.present) {
      map['issue_date'] = Variable<DateTime>(issueDate.value);
    }
    if (lastCheckDate.present) {
      map['last_check_date'] = Variable<DateTime>(lastCheckDate.value);
    }
    if (expiryDate.present) {
      map['expiry_date'] = Variable<DateTime>(expiryDate.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LicenceRatingsCompanion(')
          ..write('id: $id, ')
          ..write('licence: $licence, ')
          ..write('kind: $kind, ')
          ..write('aircraftClass: $aircraftClass, ')
          ..write('name: $name, ')
          ..write('level: $level, ')
          ..write('issueDate: $issueDate, ')
          ..write('lastCheckDate: $lastCheckDate, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $MedicalCertificatesTable extends MedicalCertificates
    with TableInfo<$MedicalCertificatesTable, MedicalCertificate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicalCertificatesTable(this.attachedDatabase, [this._alias]);
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
  @override
  late final GeneratedColumnWithTypeConverter<MedicalClass, String>
  medicalClass =
      GeneratedColumn<String>(
        'medical_class',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<MedicalClass>(
        $MedicalCertificatesTable.$convertermedicalClass,
      );
  static const VerificationMeta _examinationDateMeta = const VerificationMeta(
    'examinationDate',
  );
  @override
  late final GeneratedColumn<DateTime> examinationDate =
      GeneratedColumn<DateTime>(
        'examination_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _expiryDateMeta = const VerificationMeta(
    'expiryDate',
  );
  @override
  late final GeneratedColumn<DateTime> expiryDate = GeneratedColumn<DateTime>(
    'expiry_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _limitationsMeta = const VerificationMeta(
    'limitations',
  );
  @override
  late final GeneratedColumn<String> limitations = GeneratedColumn<String>(
    'limitations',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    medicalClass,
    examinationDate,
    expiryDate,
    limitations,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medical_certificates';
  @override
  VerificationContext validateIntegrity(
    Insertable<MedicalCertificate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('examination_date')) {
      context.handle(
        _examinationDateMeta,
        examinationDate.isAcceptableOrUnknown(
          data['examination_date']!,
          _examinationDateMeta,
        ),
      );
    }
    if (data.containsKey('expiry_date')) {
      context.handle(
        _expiryDateMeta,
        expiryDate.isAcceptableOrUnknown(data['expiry_date']!, _expiryDateMeta),
      );
    } else if (isInserting) {
      context.missing(_expiryDateMeta);
    }
    if (data.containsKey('limitations')) {
      context.handle(
        _limitationsMeta,
        limitations.isAcceptableOrUnknown(
          data['limitations']!,
          _limitationsMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MedicalCertificate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MedicalCertificate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      medicalClass: $MedicalCertificatesTable.$convertermedicalClass.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}medical_class'],
        )!,
      ),
      examinationDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}examination_date'],
      ),
      expiryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expiry_date'],
      )!,
      limitations: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}limitations'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $MedicalCertificatesTable createAlias(String alias) {
    return $MedicalCertificatesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MedicalClass, String, String>
  $convertermedicalClass = const EnumNameConverter<MedicalClass>(
    MedicalClass.values,
  );
}

class MedicalCertificate extends DataClass
    implements Insertable<MedicalCertificate> {
  final int id;
  final MedicalClass medicalClass;
  final DateTime? examinationDate;

  /// Last day of validity, as written on the certificate.
  final DateTime expiryDate;

  /// Limitations on the certificate (VML, SSL...).
  final String? limitations;
  final String? notes;
  const MedicalCertificate({
    required this.id,
    required this.medicalClass,
    this.examinationDate,
    required this.expiryDate,
    this.limitations,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['medical_class'] = Variable<String>(
        $MedicalCertificatesTable.$convertermedicalClass.toSql(medicalClass),
      );
    }
    if (!nullToAbsent || examinationDate != null) {
      map['examination_date'] = Variable<DateTime>(examinationDate);
    }
    map['expiry_date'] = Variable<DateTime>(expiryDate);
    if (!nullToAbsent || limitations != null) {
      map['limitations'] = Variable<String>(limitations);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  MedicalCertificatesCompanion toCompanion(bool nullToAbsent) {
    return MedicalCertificatesCompanion(
      id: Value(id),
      medicalClass: Value(medicalClass),
      examinationDate: examinationDate == null && nullToAbsent
          ? const Value.absent()
          : Value(examinationDate),
      expiryDate: Value(expiryDate),
      limitations: limitations == null && nullToAbsent
          ? const Value.absent()
          : Value(limitations),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory MedicalCertificate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MedicalCertificate(
      id: serializer.fromJson<int>(json['id']),
      medicalClass: $MedicalCertificatesTable.$convertermedicalClass.fromJson(
        serializer.fromJson<String>(json['medicalClass']),
      ),
      examinationDate: serializer.fromJson<DateTime?>(json['examinationDate']),
      expiryDate: serializer.fromJson<DateTime>(json['expiryDate']),
      limitations: serializer.fromJson<String?>(json['limitations']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'medicalClass': serializer.toJson<String>(
        $MedicalCertificatesTable.$convertermedicalClass.toJson(medicalClass),
      ),
      'examinationDate': serializer.toJson<DateTime?>(examinationDate),
      'expiryDate': serializer.toJson<DateTime>(expiryDate),
      'limitations': serializer.toJson<String?>(limitations),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  MedicalCertificate copyWith({
    int? id,
    MedicalClass? medicalClass,
    Value<DateTime?> examinationDate = const Value.absent(),
    DateTime? expiryDate,
    Value<String?> limitations = const Value.absent(),
    Value<String?> notes = const Value.absent(),
  }) => MedicalCertificate(
    id: id ?? this.id,
    medicalClass: medicalClass ?? this.medicalClass,
    examinationDate: examinationDate.present
        ? examinationDate.value
        : this.examinationDate,
    expiryDate: expiryDate ?? this.expiryDate,
    limitations: limitations.present ? limitations.value : this.limitations,
    notes: notes.present ? notes.value : this.notes,
  );
  MedicalCertificate copyWithCompanion(MedicalCertificatesCompanion data) {
    return MedicalCertificate(
      id: data.id.present ? data.id.value : this.id,
      medicalClass: data.medicalClass.present
          ? data.medicalClass.value
          : this.medicalClass,
      examinationDate: data.examinationDate.present
          ? data.examinationDate.value
          : this.examinationDate,
      expiryDate: data.expiryDate.present
          ? data.expiryDate.value
          : this.expiryDate,
      limitations: data.limitations.present
          ? data.limitations.value
          : this.limitations,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MedicalCertificate(')
          ..write('id: $id, ')
          ..write('medicalClass: $medicalClass, ')
          ..write('examinationDate: $examinationDate, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('limitations: $limitations, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    medicalClass,
    examinationDate,
    expiryDate,
    limitations,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MedicalCertificate &&
          other.id == this.id &&
          other.medicalClass == this.medicalClass &&
          other.examinationDate == this.examinationDate &&
          other.expiryDate == this.expiryDate &&
          other.limitations == this.limitations &&
          other.notes == this.notes);
}

class MedicalCertificatesCompanion extends UpdateCompanion<MedicalCertificate> {
  final Value<int> id;
  final Value<MedicalClass> medicalClass;
  final Value<DateTime?> examinationDate;
  final Value<DateTime> expiryDate;
  final Value<String?> limitations;
  final Value<String?> notes;
  const MedicalCertificatesCompanion({
    this.id = const Value.absent(),
    this.medicalClass = const Value.absent(),
    this.examinationDate = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.limitations = const Value.absent(),
    this.notes = const Value.absent(),
  });
  MedicalCertificatesCompanion.insert({
    this.id = const Value.absent(),
    required MedicalClass medicalClass,
    this.examinationDate = const Value.absent(),
    required DateTime expiryDate,
    this.limitations = const Value.absent(),
    this.notes = const Value.absent(),
  }) : medicalClass = Value(medicalClass),
       expiryDate = Value(expiryDate);
  static Insertable<MedicalCertificate> custom({
    Expression<int>? id,
    Expression<String>? medicalClass,
    Expression<DateTime>? examinationDate,
    Expression<DateTime>? expiryDate,
    Expression<String>? limitations,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (medicalClass != null) 'medical_class': medicalClass,
      if (examinationDate != null) 'examination_date': examinationDate,
      if (expiryDate != null) 'expiry_date': expiryDate,
      if (limitations != null) 'limitations': limitations,
      if (notes != null) 'notes': notes,
    });
  }

  MedicalCertificatesCompanion copyWith({
    Value<int>? id,
    Value<MedicalClass>? medicalClass,
    Value<DateTime?>? examinationDate,
    Value<DateTime>? expiryDate,
    Value<String?>? limitations,
    Value<String?>? notes,
  }) {
    return MedicalCertificatesCompanion(
      id: id ?? this.id,
      medicalClass: medicalClass ?? this.medicalClass,
      examinationDate: examinationDate ?? this.examinationDate,
      expiryDate: expiryDate ?? this.expiryDate,
      limitations: limitations ?? this.limitations,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (medicalClass.present) {
      map['medical_class'] = Variable<String>(
        $MedicalCertificatesTable.$convertermedicalClass.toSql(
          medicalClass.value,
        ),
      );
    }
    if (examinationDate.present) {
      map['examination_date'] = Variable<DateTime>(examinationDate.value);
    }
    if (expiryDate.present) {
      map['expiry_date'] = Variable<DateTime>(expiryDate.value);
    }
    if (limitations.present) {
      map['limitations'] = Variable<String>(limitations.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicalCertificatesCompanion(')
          ..write('id: $id, ')
          ..write('medicalClass: $medicalClass, ')
          ..write('examinationDate: $examinationDate, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('limitations: $limitations, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class AircraftWithStats extends DataClass {
  final int id;
  final String tailNumber;
  final String? notes;
  final int icaoAircraft;
  final AircraftClass? aircraftClass;
  final String? typeRating;
  final String? photoFile;
  final String? photoUrl;
  final String? photoThumbnailUrl;
  final String? photoLink;
  final String? photoCredit;
  final AircraftDescription description;
  final String modelFullName;
  final String designator;
  final String manufacturer;
  final int engineCount;
  final EngineType engineType;
  final WakeTurbulenceCategory wakeTurbolenceCategory;
  final WakeTurbulenceGroup wakeTurbolenceGroup;
  final bool userInserted;
  final int? dayLandings;
  final int? nightLandings;
  final int? flightCount;
  final int? totalFlightTime;
  const AircraftWithStats({
    required this.id,
    required this.tailNumber,
    this.notes,
    required this.icaoAircraft,
    this.aircraftClass,
    this.typeRating,
    this.photoFile,
    this.photoUrl,
    this.photoThumbnailUrl,
    this.photoLink,
    this.photoCredit,
    required this.description,
    required this.modelFullName,
    required this.designator,
    required this.manufacturer,
    required this.engineCount,
    required this.engineType,
    required this.wakeTurbolenceCategory,
    required this.wakeTurbolenceGroup,
    required this.userInserted,
    this.dayLandings,
    this.nightLandings,
    this.flightCount,
    this.totalFlightTime,
  });
  factory AircraftWithStats.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AircraftWithStats(
      id: serializer.fromJson<int>(json['id']),
      tailNumber: serializer.fromJson<String>(json['tailNumber']),
      notes: serializer.fromJson<String?>(json['notes']),
      icaoAircraft: serializer.fromJson<int>(json['icaoAircraft']),
      aircraftClass: $AircraftsTable.$converteraircraftClassn.fromJson(
        serializer.fromJson<String?>(json['aircraftClass']),
      ),
      typeRating: serializer.fromJson<String?>(json['typeRating']),
      photoFile: serializer.fromJson<String?>(json['photoFile']),
      photoUrl: serializer.fromJson<String?>(json['photoUrl']),
      photoThumbnailUrl: serializer.fromJson<String?>(
        json['photoThumbnailUrl'],
      ),
      photoLink: serializer.fromJson<String?>(json['photoLink']),
      photoCredit: serializer.fromJson<String?>(json['photoCredit']),
      description: $IcaoAircraftsTable.$converterdescription.fromJson(
        serializer.fromJson<String>(json['description']),
      ),
      modelFullName: serializer.fromJson<String>(json['modelFullName']),
      designator: serializer.fromJson<String>(json['designator']),
      manufacturer: serializer.fromJson<String>(json['manufacturer']),
      engineCount: serializer.fromJson<int>(json['engineCount']),
      engineType: $IcaoAircraftsTable.$converterengineType.fromJson(
        serializer.fromJson<String>(json['engineType']),
      ),
      wakeTurbolenceCategory: $IcaoAircraftsTable
          .$converterwakeTurbolenceCategory
          .fromJson(
            serializer.fromJson<String>(json['wakeTurbolenceCategory']),
          ),
      wakeTurbolenceGroup: $IcaoAircraftsTable.$converterwakeTurbolenceGroup
          .fromJson(serializer.fromJson<String>(json['wakeTurbolenceGroup'])),
      userInserted: serializer.fromJson<bool>(json['userInserted']),
      dayLandings: serializer.fromJson<int?>(json['dayLandings']),
      nightLandings: serializer.fromJson<int?>(json['nightLandings']),
      flightCount: serializer.fromJson<int?>(json['flightCount']),
      totalFlightTime: serializer.fromJson<int?>(json['totalFlightTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tailNumber': serializer.toJson<String>(tailNumber),
      'notes': serializer.toJson<String?>(notes),
      'icaoAircraft': serializer.toJson<int>(icaoAircraft),
      'aircraftClass': serializer.toJson<String?>(
        $AircraftsTable.$converteraircraftClassn.toJson(aircraftClass),
      ),
      'typeRating': serializer.toJson<String?>(typeRating),
      'photoFile': serializer.toJson<String?>(photoFile),
      'photoUrl': serializer.toJson<String?>(photoUrl),
      'photoThumbnailUrl': serializer.toJson<String?>(photoThumbnailUrl),
      'photoLink': serializer.toJson<String?>(photoLink),
      'photoCredit': serializer.toJson<String?>(photoCredit),
      'description': serializer.toJson<String>(
        $IcaoAircraftsTable.$converterdescription.toJson(description),
      ),
      'modelFullName': serializer.toJson<String>(modelFullName),
      'designator': serializer.toJson<String>(designator),
      'manufacturer': serializer.toJson<String>(manufacturer),
      'engineCount': serializer.toJson<int>(engineCount),
      'engineType': serializer.toJson<String>(
        $IcaoAircraftsTable.$converterengineType.toJson(engineType),
      ),
      'wakeTurbolenceCategory': serializer.toJson<String>(
        $IcaoAircraftsTable.$converterwakeTurbolenceCategory.toJson(
          wakeTurbolenceCategory,
        ),
      ),
      'wakeTurbolenceGroup': serializer.toJson<String>(
        $IcaoAircraftsTable.$converterwakeTurbolenceGroup.toJson(
          wakeTurbolenceGroup,
        ),
      ),
      'userInserted': serializer.toJson<bool>(userInserted),
      'dayLandings': serializer.toJson<int?>(dayLandings),
      'nightLandings': serializer.toJson<int?>(nightLandings),
      'flightCount': serializer.toJson<int?>(flightCount),
      'totalFlightTime': serializer.toJson<int?>(totalFlightTime),
    };
  }

  AircraftWithStats copyWith({
    int? id,
    String? tailNumber,
    Value<String?> notes = const Value.absent(),
    int? icaoAircraft,
    Value<AircraftClass?> aircraftClass = const Value.absent(),
    Value<String?> typeRating = const Value.absent(),
    Value<String?> photoFile = const Value.absent(),
    Value<String?> photoUrl = const Value.absent(),
    Value<String?> photoThumbnailUrl = const Value.absent(),
    Value<String?> photoLink = const Value.absent(),
    Value<String?> photoCredit = const Value.absent(),
    AircraftDescription? description,
    String? modelFullName,
    String? designator,
    String? manufacturer,
    int? engineCount,
    EngineType? engineType,
    WakeTurbulenceCategory? wakeTurbolenceCategory,
    WakeTurbulenceGroup? wakeTurbolenceGroup,
    bool? userInserted,
    Value<int?> dayLandings = const Value.absent(),
    Value<int?> nightLandings = const Value.absent(),
    Value<int?> flightCount = const Value.absent(),
    Value<int?> totalFlightTime = const Value.absent(),
  }) => AircraftWithStats(
    id: id ?? this.id,
    tailNumber: tailNumber ?? this.tailNumber,
    notes: notes.present ? notes.value : this.notes,
    icaoAircraft: icaoAircraft ?? this.icaoAircraft,
    aircraftClass: aircraftClass.present
        ? aircraftClass.value
        : this.aircraftClass,
    typeRating: typeRating.present ? typeRating.value : this.typeRating,
    photoFile: photoFile.present ? photoFile.value : this.photoFile,
    photoUrl: photoUrl.present ? photoUrl.value : this.photoUrl,
    photoThumbnailUrl: photoThumbnailUrl.present
        ? photoThumbnailUrl.value
        : this.photoThumbnailUrl,
    photoLink: photoLink.present ? photoLink.value : this.photoLink,
    photoCredit: photoCredit.present ? photoCredit.value : this.photoCredit,
    description: description ?? this.description,
    modelFullName: modelFullName ?? this.modelFullName,
    designator: designator ?? this.designator,
    manufacturer: manufacturer ?? this.manufacturer,
    engineCount: engineCount ?? this.engineCount,
    engineType: engineType ?? this.engineType,
    wakeTurbolenceCategory:
        wakeTurbolenceCategory ?? this.wakeTurbolenceCategory,
    wakeTurbolenceGroup: wakeTurbolenceGroup ?? this.wakeTurbolenceGroup,
    userInserted: userInserted ?? this.userInserted,
    dayLandings: dayLandings.present ? dayLandings.value : this.dayLandings,
    nightLandings: nightLandings.present
        ? nightLandings.value
        : this.nightLandings,
    flightCount: flightCount.present ? flightCount.value : this.flightCount,
    totalFlightTime: totalFlightTime.present
        ? totalFlightTime.value
        : this.totalFlightTime,
  );
  @override
  String toString() {
    return (StringBuffer('AircraftWithStats(')
          ..write('id: $id, ')
          ..write('tailNumber: $tailNumber, ')
          ..write('notes: $notes, ')
          ..write('icaoAircraft: $icaoAircraft, ')
          ..write('aircraftClass: $aircraftClass, ')
          ..write('typeRating: $typeRating, ')
          ..write('photoFile: $photoFile, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('photoThumbnailUrl: $photoThumbnailUrl, ')
          ..write('photoLink: $photoLink, ')
          ..write('photoCredit: $photoCredit, ')
          ..write('description: $description, ')
          ..write('modelFullName: $modelFullName, ')
          ..write('designator: $designator, ')
          ..write('manufacturer: $manufacturer, ')
          ..write('engineCount: $engineCount, ')
          ..write('engineType: $engineType, ')
          ..write('wakeTurbolenceCategory: $wakeTurbolenceCategory, ')
          ..write('wakeTurbolenceGroup: $wakeTurbolenceGroup, ')
          ..write('userInserted: $userInserted, ')
          ..write('dayLandings: $dayLandings, ')
          ..write('nightLandings: $nightLandings, ')
          ..write('flightCount: $flightCount, ')
          ..write('totalFlightTime: $totalFlightTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    tailNumber,
    notes,
    icaoAircraft,
    aircraftClass,
    typeRating,
    photoFile,
    photoUrl,
    photoThumbnailUrl,
    photoLink,
    photoCredit,
    description,
    modelFullName,
    designator,
    manufacturer,
    engineCount,
    engineType,
    wakeTurbolenceCategory,
    wakeTurbolenceGroup,
    userInserted,
    dayLandings,
    nightLandings,
    flightCount,
    totalFlightTime,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AircraftWithStats &&
          other.id == this.id &&
          other.tailNumber == this.tailNumber &&
          other.notes == this.notes &&
          other.icaoAircraft == this.icaoAircraft &&
          other.aircraftClass == this.aircraftClass &&
          other.typeRating == this.typeRating &&
          other.photoFile == this.photoFile &&
          other.photoUrl == this.photoUrl &&
          other.photoThumbnailUrl == this.photoThumbnailUrl &&
          other.photoLink == this.photoLink &&
          other.photoCredit == this.photoCredit &&
          other.description == this.description &&
          other.modelFullName == this.modelFullName &&
          other.designator == this.designator &&
          other.manufacturer == this.manufacturer &&
          other.engineCount == this.engineCount &&
          other.engineType == this.engineType &&
          other.wakeTurbolenceCategory == this.wakeTurbolenceCategory &&
          other.wakeTurbolenceGroup == this.wakeTurbolenceGroup &&
          other.userInserted == this.userInserted &&
          other.dayLandings == this.dayLandings &&
          other.nightLandings == this.nightLandings &&
          other.flightCount == this.flightCount &&
          other.totalFlightTime == this.totalFlightTime);
}

class $AircraftWithStatssView
    extends ViewInfo<$AircraftWithStatssView, AircraftWithStats>
    implements HasResultSet {
  final String? _alias;
  @override
  final _$LogbookDatabase attachedDatabase;
  $AircraftWithStatssView(this.attachedDatabase, [this._alias]);
  $AircraftsTable get aircrafts => attachedDatabase.aircrafts.createAlias('t0');
  $FlightsTable get flights => attachedDatabase.flights.createAlias('t1');
  $IcaoAircraftsTable get icaoAircrafts =>
      attachedDatabase.icaoAircrafts.createAlias('t2');
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tailNumber,
    notes,
    icaoAircraft,
    aircraftClass,
    typeRating,
    photoFile,
    photoUrl,
    photoThumbnailUrl,
    photoLink,
    photoCredit,
    description,
    modelFullName,
    designator,
    manufacturer,
    engineCount,
    engineType,
    wakeTurbolenceCategory,
    wakeTurbolenceGroup,
    userInserted,
    dayLandings,
    nightLandings,
    flightCount,
    totalFlightTime,
  ];
  @override
  String get aliasedName => _alias ?? entityName;
  @override
  String get entityName => 'aircraft_with_statss';
  @override
  Map<SqlDialect, String>? get createViewStatements => null;
  @override
  $AircraftWithStatssView get asDslTable => this;
  @override
  AircraftWithStats map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AircraftWithStats(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      tailNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tail_number'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      icaoAircraft: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}icao_aircraft'],
      )!,
      aircraftClass: $AircraftsTable.$converteraircraftClassn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}aircraft_class'],
        ),
      ),
      typeRating: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type_rating'],
      ),
      photoFile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_file'],
      ),
      photoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_url'],
      ),
      photoThumbnailUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_thumbnail_url'],
      ),
      photoLink: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_link'],
      ),
      photoCredit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_credit'],
      ),
      description: $IcaoAircraftsTable.$converterdescription.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}description'],
        )!,
      ),
      modelFullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_full_name'],
      )!,
      designator: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}designator'],
      )!,
      manufacturer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manufacturer'],
      )!,
      engineCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}engine_count'],
      )!,
      engineType: $IcaoAircraftsTable.$converterengineType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}engine_type'],
        )!,
      ),
      wakeTurbolenceCategory: $IcaoAircraftsTable
          .$converterwakeTurbolenceCategory
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}wake_turbolence_category'],
            )!,
          ),
      wakeTurbolenceGroup: $IcaoAircraftsTable.$converterwakeTurbolenceGroup
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}wake_turbolence_group'],
            )!,
          ),
      userInserted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}user_inserted'],
      )!,
      dayLandings: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_landings'],
      ),
      nightLandings: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}night_landings'],
      ),
      flightCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}flight_count'],
      ),
      totalFlightTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_flight_time'],
      ),
    );
  }

  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    generatedAs: GeneratedAs(aircrafts.id, false),
    type: DriftSqlType.int,
  );
  late final GeneratedColumn<String> tailNumber = GeneratedColumn<String>(
    'tail_number',
    aliasedName,
    false,
    generatedAs: GeneratedAs(aircrafts.tailNumber, false),
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    generatedAs: GeneratedAs(aircrafts.notes, false),
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<int> icaoAircraft = GeneratedColumn<int>(
    'icao_aircraft',
    aliasedName,
    false,
    generatedAs: GeneratedAs(aircrafts.icaoAircraft, false),
    type: DriftSqlType.int,
  );
  late final GeneratedColumnWithTypeConverter<AircraftClass?, String>
  aircraftClass = GeneratedColumn<String>(
    'aircraft_class',
    aliasedName,
    true,
    generatedAs: GeneratedAs(aircrafts.aircraftClass, false),
    type: DriftSqlType.string,
  ).withConverter<AircraftClass?>($AircraftsTable.$converteraircraftClassn);
  late final GeneratedColumn<String> typeRating = GeneratedColumn<String>(
    'type_rating',
    aliasedName,
    true,
    generatedAs: GeneratedAs(aircrafts.typeRating, false),
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<String> photoFile = GeneratedColumn<String>(
    'photo_file',
    aliasedName,
    true,
    generatedAs: GeneratedAs(aircrafts.photoFile, false),
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<String> photoUrl = GeneratedColumn<String>(
    'photo_url',
    aliasedName,
    true,
    generatedAs: GeneratedAs(aircrafts.photoUrl, false),
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<String> photoThumbnailUrl =
      GeneratedColumn<String>(
        'photo_thumbnail_url',
        aliasedName,
        true,
        generatedAs: GeneratedAs(aircrafts.photoThumbnailUrl, false),
        type: DriftSqlType.string,
      );
  late final GeneratedColumn<String> photoLink = GeneratedColumn<String>(
    'photo_link',
    aliasedName,
    true,
    generatedAs: GeneratedAs(aircrafts.photoLink, false),
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<String> photoCredit = GeneratedColumn<String>(
    'photo_credit',
    aliasedName,
    true,
    generatedAs: GeneratedAs(aircrafts.photoCredit, false),
    type: DriftSqlType.string,
  );
  late final GeneratedColumnWithTypeConverter<AircraftDescription, String>
  description =
      GeneratedColumn<String>(
        'description',
        aliasedName,
        false,
        generatedAs: GeneratedAs(icaoAircrafts.description, false),
        type: DriftSqlType.string,
      ).withConverter<AircraftDescription>(
        $IcaoAircraftsTable.$converterdescription,
      );
  late final GeneratedColumn<String> modelFullName = GeneratedColumn<String>(
    'model_full_name',
    aliasedName,
    false,
    generatedAs: GeneratedAs(icaoAircrafts.modelFullName, false),
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<String> designator = GeneratedColumn<String>(
    'designator',
    aliasedName,
    false,
    generatedAs: GeneratedAs(icaoAircrafts.designator, false),
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<String> manufacturer = GeneratedColumn<String>(
    'manufacturer',
    aliasedName,
    false,
    generatedAs: GeneratedAs(icaoAircrafts.manufacturer, false),
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<int> engineCount = GeneratedColumn<int>(
    'engine_count',
    aliasedName,
    false,
    generatedAs: GeneratedAs(icaoAircrafts.engineCount, false),
    type: DriftSqlType.int,
  );
  late final GeneratedColumnWithTypeConverter<EngineType, String> engineType =
      GeneratedColumn<String>(
        'engine_type',
        aliasedName,
        false,
        generatedAs: GeneratedAs(icaoAircrafts.engineType, false),
        type: DriftSqlType.string,
      ).withConverter<EngineType>($IcaoAircraftsTable.$converterengineType);
  late final GeneratedColumnWithTypeConverter<WakeTurbulenceCategory, String>
  wakeTurbolenceCategory =
      GeneratedColumn<String>(
        'wake_turbolence_category',
        aliasedName,
        false,
        generatedAs: GeneratedAs(icaoAircrafts.wakeTurbolenceCategory, false),
        type: DriftSqlType.string,
      ).withConverter<WakeTurbulenceCategory>(
        $IcaoAircraftsTable.$converterwakeTurbolenceCategory,
      );
  late final GeneratedColumnWithTypeConverter<WakeTurbulenceGroup, String>
  wakeTurbolenceGroup =
      GeneratedColumn<String>(
        'wake_turbolence_group',
        aliasedName,
        false,
        generatedAs: GeneratedAs(icaoAircrafts.wakeTurbolenceGroup, false),
        type: DriftSqlType.string,
      ).withConverter<WakeTurbulenceGroup>(
        $IcaoAircraftsTable.$converterwakeTurbolenceGroup,
      );
  late final GeneratedColumn<bool> userInserted = GeneratedColumn<bool>(
    'user_inserted',
    aliasedName,
    false,
    generatedAs: GeneratedAs(icaoAircrafts.userInserted, false),
    type: DriftSqlType.bool,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("user_inserted" IN (0, 1))',
    ),
  );
  late final GeneratedColumn<int> dayLandings = GeneratedColumn<int>(
    'day_landings',
    aliasedName,
    true,
    generatedAs: GeneratedAs(
      ArithmeticAggregates(flights.dayLandings).sum(),
      false,
    ),
    type: DriftSqlType.int,
  );
  late final GeneratedColumn<int> nightLandings = GeneratedColumn<int>(
    'night_landings',
    aliasedName,
    true,
    generatedAs: GeneratedAs(
      ArithmeticAggregates(flights.nightLandings).sum(),
      false,
    ),
    type: DriftSqlType.int,
  );
  late final GeneratedColumn<int> flightCount = GeneratedColumn<int>(
    'flight_count',
    aliasedName,
    true,
    generatedAs: GeneratedAs(BaseAggregate(flights.id).count(), false),
    type: DriftSqlType.int,
  );
  late final GeneratedColumn<int> totalFlightTime = GeneratedColumn<int>(
    'total_flight_time',
    aliasedName,
    true,
    generatedAs: GeneratedAs(
      CustomExpression<int>('''
    SUM(
      CAST(
        (
          ${flights.arrivalTime.escapedNameFor(SqlDialect.sqlite)} -
          ${flights.departureTime.escapedNameFor(SqlDialect.sqlite)}
        ) / 60
        AS INTEGER
      )
    )
    '''),
      false,
    ),
    type: DriftSqlType.int,
  );
  @override
  $AircraftWithStatssView createAlias(String alias) {
    return $AircraftWithStatssView(attachedDatabase, alias);
  }

  @override
  Query? get query =>
      (attachedDatabase.selectOnly(aircrafts)..addColumns($columns)).join([
        leftOuterJoin(flights, flights.aircraftId.equalsExp(aircrafts.id)),
        innerJoin(
          icaoAircrafts,
          aircrafts.icaoAircraft.equalsExp(icaoAircrafts.id),
        ),
      ])..groupBy([aircrafts.id]);
  @override
  Set<String> get readTables => const {
    'aircrafts',
    'flights',
    'icao_aircrafts',
    'airports',
    'simulators',
    'countries',
    'regions',
  };
}

class FlightStat extends DataClass {
  final int id;
  final int? aircraftId;
  final int? flightTime;
  final int? dayLandings;
  final int? nightLandings;
  const FlightStat({
    required this.id,
    this.aircraftId,
    this.flightTime,
    this.dayLandings,
    this.nightLandings,
  });
  factory FlightStat.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FlightStat(
      id: serializer.fromJson<int>(json['id']),
      aircraftId: serializer.fromJson<int?>(json['aircraftId']),
      flightTime: serializer.fromJson<int?>(json['flightTime']),
      dayLandings: serializer.fromJson<int?>(json['dayLandings']),
      nightLandings: serializer.fromJson<int?>(json['nightLandings']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'aircraftId': serializer.toJson<int?>(aircraftId),
      'flightTime': serializer.toJson<int?>(flightTime),
      'dayLandings': serializer.toJson<int?>(dayLandings),
      'nightLandings': serializer.toJson<int?>(nightLandings),
    };
  }

  FlightStat copyWith({
    int? id,
    Value<int?> aircraftId = const Value.absent(),
    Value<int?> flightTime = const Value.absent(),
    Value<int?> dayLandings = const Value.absent(),
    Value<int?> nightLandings = const Value.absent(),
  }) => FlightStat(
    id: id ?? this.id,
    aircraftId: aircraftId.present ? aircraftId.value : this.aircraftId,
    flightTime: flightTime.present ? flightTime.value : this.flightTime,
    dayLandings: dayLandings.present ? dayLandings.value : this.dayLandings,
    nightLandings: nightLandings.present
        ? nightLandings.value
        : this.nightLandings,
  );
  @override
  String toString() {
    return (StringBuffer('FlightStat(')
          ..write('id: $id, ')
          ..write('aircraftId: $aircraftId, ')
          ..write('flightTime: $flightTime, ')
          ..write('dayLandings: $dayLandings, ')
          ..write('nightLandings: $nightLandings')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, aircraftId, flightTime, dayLandings, nightLandings);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FlightStat &&
          other.id == this.id &&
          other.aircraftId == this.aircraftId &&
          other.flightTime == this.flightTime &&
          other.dayLandings == this.dayLandings &&
          other.nightLandings == this.nightLandings);
}

class $FlightStatsView extends ViewInfo<$FlightStatsView, FlightStat>
    implements HasResultSet {
  final String? _alias;
  @override
  final _$LogbookDatabase attachedDatabase;
  $FlightStatsView(this.attachedDatabase, [this._alias]);
  $FlightsTable get flights => attachedDatabase.flights.createAlias('t0');
  @override
  List<GeneratedColumn> get $columns => [
    id,
    aircraftId,
    flightTime,
    dayLandings,
    nightLandings,
  ];
  @override
  String get aliasedName => _alias ?? entityName;
  @override
  String get entityName => 'flight_stats';
  @override
  Map<SqlDialect, String>? get createViewStatements => null;
  @override
  $FlightStatsView get asDslTable => this;
  @override
  FlightStat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FlightStat(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      aircraftId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}aircraft_id'],
      ),
      flightTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}flight_time'],
      ),
      dayLandings: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_landings'],
      ),
      nightLandings: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}night_landings'],
      ),
    );
  }

  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    generatedAs: GeneratedAs(flights.id, false),
    type: DriftSqlType.int,
  );
  late final GeneratedColumn<int> aircraftId = GeneratedColumn<int>(
    'aircraft_id',
    aliasedName,
    true,
    generatedAs: GeneratedAs(flights.aircraftId, false),
    type: DriftSqlType.int,
  );
  late final GeneratedColumn<int> flightTime = GeneratedColumn<int>(
    'flight_time',
    aliasedName,
    true,
    generatedAs: GeneratedAs(
      CustomExpression<int>('''
      CAST(
        (
          ${flights.arrivalTime.escapedNameFor(SqlDialect.sqlite)} -
          ${flights.departureTime.escapedNameFor(SqlDialect.sqlite)}
        ) / 60
        AS INTEGER
      )
    '''),
      false,
    ),
    type: DriftSqlType.int,
  );
  late final GeneratedColumn<int> dayLandings = GeneratedColumn<int>(
    'day_landings',
    aliasedName,
    true,
    generatedAs: GeneratedAs(flights.dayLandings, false),
    type: DriftSqlType.int,
  );
  late final GeneratedColumn<int> nightLandings = GeneratedColumn<int>(
    'night_landings',
    aliasedName,
    true,
    generatedAs: GeneratedAs(flights.nightLandings, false),
    type: DriftSqlType.int,
  );
  @override
  $FlightStatsView createAlias(String alias) {
    return $FlightStatsView(attachedDatabase, alias);
  }

  @override
  Query? get query =>
      (attachedDatabase.selectOnly(flights)..addColumns($columns));
  @override
  Set<String> get readTables => const {
    'flights',
    'airports',
    'aircrafts',
    'simulators',
    'icao_aircrafts',
    'countries',
    'regions',
  };
}

class AircraftWithIcao extends DataClass {
  final int id;
  final String tailNumber;
  final String? notes;
  final int icaoAircraft;
  final AircraftClass? aircraftClass;
  final String? typeRating;
  final String? photoFile;
  final String? photoUrl;
  final String? photoThumbnailUrl;
  final String? photoLink;
  final String? photoCredit;
  final AircraftDescription description;
  final String modelFullName;
  final String designator;
  final String manufacturer;
  final int engineCount;
  final EngineType engineType;
  final WakeTurbulenceCategory wakeTurbolenceCategory;
  final WakeTurbulenceGroup wakeTurbolenceGroup;
  final bool userInserted;
  const AircraftWithIcao({
    required this.id,
    required this.tailNumber,
    this.notes,
    required this.icaoAircraft,
    this.aircraftClass,
    this.typeRating,
    this.photoFile,
    this.photoUrl,
    this.photoThumbnailUrl,
    this.photoLink,
    this.photoCredit,
    required this.description,
    required this.modelFullName,
    required this.designator,
    required this.manufacturer,
    required this.engineCount,
    required this.engineType,
    required this.wakeTurbolenceCategory,
    required this.wakeTurbolenceGroup,
    required this.userInserted,
  });
  factory AircraftWithIcao.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AircraftWithIcao(
      id: serializer.fromJson<int>(json['id']),
      tailNumber: serializer.fromJson<String>(json['tailNumber']),
      notes: serializer.fromJson<String?>(json['notes']),
      icaoAircraft: serializer.fromJson<int>(json['icaoAircraft']),
      aircraftClass: $AircraftsTable.$converteraircraftClassn.fromJson(
        serializer.fromJson<String?>(json['aircraftClass']),
      ),
      typeRating: serializer.fromJson<String?>(json['typeRating']),
      photoFile: serializer.fromJson<String?>(json['photoFile']),
      photoUrl: serializer.fromJson<String?>(json['photoUrl']),
      photoThumbnailUrl: serializer.fromJson<String?>(
        json['photoThumbnailUrl'],
      ),
      photoLink: serializer.fromJson<String?>(json['photoLink']),
      photoCredit: serializer.fromJson<String?>(json['photoCredit']),
      description: $IcaoAircraftsTable.$converterdescription.fromJson(
        serializer.fromJson<String>(json['description']),
      ),
      modelFullName: serializer.fromJson<String>(json['modelFullName']),
      designator: serializer.fromJson<String>(json['designator']),
      manufacturer: serializer.fromJson<String>(json['manufacturer']),
      engineCount: serializer.fromJson<int>(json['engineCount']),
      engineType: $IcaoAircraftsTable.$converterengineType.fromJson(
        serializer.fromJson<String>(json['engineType']),
      ),
      wakeTurbolenceCategory: $IcaoAircraftsTable
          .$converterwakeTurbolenceCategory
          .fromJson(
            serializer.fromJson<String>(json['wakeTurbolenceCategory']),
          ),
      wakeTurbolenceGroup: $IcaoAircraftsTable.$converterwakeTurbolenceGroup
          .fromJson(serializer.fromJson<String>(json['wakeTurbolenceGroup'])),
      userInserted: serializer.fromJson<bool>(json['userInserted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tailNumber': serializer.toJson<String>(tailNumber),
      'notes': serializer.toJson<String?>(notes),
      'icaoAircraft': serializer.toJson<int>(icaoAircraft),
      'aircraftClass': serializer.toJson<String?>(
        $AircraftsTable.$converteraircraftClassn.toJson(aircraftClass),
      ),
      'typeRating': serializer.toJson<String?>(typeRating),
      'photoFile': serializer.toJson<String?>(photoFile),
      'photoUrl': serializer.toJson<String?>(photoUrl),
      'photoThumbnailUrl': serializer.toJson<String?>(photoThumbnailUrl),
      'photoLink': serializer.toJson<String?>(photoLink),
      'photoCredit': serializer.toJson<String?>(photoCredit),
      'description': serializer.toJson<String>(
        $IcaoAircraftsTable.$converterdescription.toJson(description),
      ),
      'modelFullName': serializer.toJson<String>(modelFullName),
      'designator': serializer.toJson<String>(designator),
      'manufacturer': serializer.toJson<String>(manufacturer),
      'engineCount': serializer.toJson<int>(engineCount),
      'engineType': serializer.toJson<String>(
        $IcaoAircraftsTable.$converterengineType.toJson(engineType),
      ),
      'wakeTurbolenceCategory': serializer.toJson<String>(
        $IcaoAircraftsTable.$converterwakeTurbolenceCategory.toJson(
          wakeTurbolenceCategory,
        ),
      ),
      'wakeTurbolenceGroup': serializer.toJson<String>(
        $IcaoAircraftsTable.$converterwakeTurbolenceGroup.toJson(
          wakeTurbolenceGroup,
        ),
      ),
      'userInserted': serializer.toJson<bool>(userInserted),
    };
  }

  AircraftWithIcao copyWith({
    int? id,
    String? tailNumber,
    Value<String?> notes = const Value.absent(),
    int? icaoAircraft,
    Value<AircraftClass?> aircraftClass = const Value.absent(),
    Value<String?> typeRating = const Value.absent(),
    Value<String?> photoFile = const Value.absent(),
    Value<String?> photoUrl = const Value.absent(),
    Value<String?> photoThumbnailUrl = const Value.absent(),
    Value<String?> photoLink = const Value.absent(),
    Value<String?> photoCredit = const Value.absent(),
    AircraftDescription? description,
    String? modelFullName,
    String? designator,
    String? manufacturer,
    int? engineCount,
    EngineType? engineType,
    WakeTurbulenceCategory? wakeTurbolenceCategory,
    WakeTurbulenceGroup? wakeTurbolenceGroup,
    bool? userInserted,
  }) => AircraftWithIcao(
    id: id ?? this.id,
    tailNumber: tailNumber ?? this.tailNumber,
    notes: notes.present ? notes.value : this.notes,
    icaoAircraft: icaoAircraft ?? this.icaoAircraft,
    aircraftClass: aircraftClass.present
        ? aircraftClass.value
        : this.aircraftClass,
    typeRating: typeRating.present ? typeRating.value : this.typeRating,
    photoFile: photoFile.present ? photoFile.value : this.photoFile,
    photoUrl: photoUrl.present ? photoUrl.value : this.photoUrl,
    photoThumbnailUrl: photoThumbnailUrl.present
        ? photoThumbnailUrl.value
        : this.photoThumbnailUrl,
    photoLink: photoLink.present ? photoLink.value : this.photoLink,
    photoCredit: photoCredit.present ? photoCredit.value : this.photoCredit,
    description: description ?? this.description,
    modelFullName: modelFullName ?? this.modelFullName,
    designator: designator ?? this.designator,
    manufacturer: manufacturer ?? this.manufacturer,
    engineCount: engineCount ?? this.engineCount,
    engineType: engineType ?? this.engineType,
    wakeTurbolenceCategory:
        wakeTurbolenceCategory ?? this.wakeTurbolenceCategory,
    wakeTurbolenceGroup: wakeTurbolenceGroup ?? this.wakeTurbolenceGroup,
    userInserted: userInserted ?? this.userInserted,
  );
  @override
  String toString() {
    return (StringBuffer('AircraftWithIcao(')
          ..write('id: $id, ')
          ..write('tailNumber: $tailNumber, ')
          ..write('notes: $notes, ')
          ..write('icaoAircraft: $icaoAircraft, ')
          ..write('aircraftClass: $aircraftClass, ')
          ..write('typeRating: $typeRating, ')
          ..write('photoFile: $photoFile, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('photoThumbnailUrl: $photoThumbnailUrl, ')
          ..write('photoLink: $photoLink, ')
          ..write('photoCredit: $photoCredit, ')
          ..write('description: $description, ')
          ..write('modelFullName: $modelFullName, ')
          ..write('designator: $designator, ')
          ..write('manufacturer: $manufacturer, ')
          ..write('engineCount: $engineCount, ')
          ..write('engineType: $engineType, ')
          ..write('wakeTurbolenceCategory: $wakeTurbolenceCategory, ')
          ..write('wakeTurbolenceGroup: $wakeTurbolenceGroup, ')
          ..write('userInserted: $userInserted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tailNumber,
    notes,
    icaoAircraft,
    aircraftClass,
    typeRating,
    photoFile,
    photoUrl,
    photoThumbnailUrl,
    photoLink,
    photoCredit,
    description,
    modelFullName,
    designator,
    manufacturer,
    engineCount,
    engineType,
    wakeTurbolenceCategory,
    wakeTurbolenceGroup,
    userInserted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AircraftWithIcao &&
          other.id == this.id &&
          other.tailNumber == this.tailNumber &&
          other.notes == this.notes &&
          other.icaoAircraft == this.icaoAircraft &&
          other.aircraftClass == this.aircraftClass &&
          other.typeRating == this.typeRating &&
          other.photoFile == this.photoFile &&
          other.photoUrl == this.photoUrl &&
          other.photoThumbnailUrl == this.photoThumbnailUrl &&
          other.photoLink == this.photoLink &&
          other.photoCredit == this.photoCredit &&
          other.description == this.description &&
          other.modelFullName == this.modelFullName &&
          other.designator == this.designator &&
          other.manufacturer == this.manufacturer &&
          other.engineCount == this.engineCount &&
          other.engineType == this.engineType &&
          other.wakeTurbolenceCategory == this.wakeTurbolenceCategory &&
          other.wakeTurbolenceGroup == this.wakeTurbolenceGroup &&
          other.userInserted == this.userInserted);
}

class $AircraftWithIcaosView
    extends ViewInfo<$AircraftWithIcaosView, AircraftWithIcao>
    implements HasResultSet {
  final String? _alias;
  @override
  final _$LogbookDatabase attachedDatabase;
  $AircraftWithIcaosView(this.attachedDatabase, [this._alias]);
  $AircraftsTable get aircrafts => attachedDatabase.aircrafts.createAlias('t0');
  $IcaoAircraftsTable get icaoAircrafts =>
      attachedDatabase.icaoAircrafts.createAlias('t1');
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tailNumber,
    notes,
    icaoAircraft,
    aircraftClass,
    typeRating,
    photoFile,
    photoUrl,
    photoThumbnailUrl,
    photoLink,
    photoCredit,
    description,
    modelFullName,
    designator,
    manufacturer,
    engineCount,
    engineType,
    wakeTurbolenceCategory,
    wakeTurbolenceGroup,
    userInserted,
  ];
  @override
  String get aliasedName => _alias ?? entityName;
  @override
  String get entityName => 'aircraft_with_icaos';
  @override
  Map<SqlDialect, String>? get createViewStatements => null;
  @override
  $AircraftWithIcaosView get asDslTable => this;
  @override
  AircraftWithIcao map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AircraftWithIcao(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      tailNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tail_number'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      icaoAircraft: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}icao_aircraft'],
      )!,
      aircraftClass: $AircraftsTable.$converteraircraftClassn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}aircraft_class'],
        ),
      ),
      typeRating: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type_rating'],
      ),
      photoFile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_file'],
      ),
      photoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_url'],
      ),
      photoThumbnailUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_thumbnail_url'],
      ),
      photoLink: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_link'],
      ),
      photoCredit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_credit'],
      ),
      description: $IcaoAircraftsTable.$converterdescription.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}description'],
        )!,
      ),
      modelFullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_full_name'],
      )!,
      designator: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}designator'],
      )!,
      manufacturer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manufacturer'],
      )!,
      engineCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}engine_count'],
      )!,
      engineType: $IcaoAircraftsTable.$converterengineType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}engine_type'],
        )!,
      ),
      wakeTurbolenceCategory: $IcaoAircraftsTable
          .$converterwakeTurbolenceCategory
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}wake_turbolence_category'],
            )!,
          ),
      wakeTurbolenceGroup: $IcaoAircraftsTable.$converterwakeTurbolenceGroup
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}wake_turbolence_group'],
            )!,
          ),
      userInserted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}user_inserted'],
      )!,
    );
  }

  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    generatedAs: GeneratedAs(aircrafts.id, false),
    type: DriftSqlType.int,
  );
  late final GeneratedColumn<String> tailNumber = GeneratedColumn<String>(
    'tail_number',
    aliasedName,
    false,
    generatedAs: GeneratedAs(aircrafts.tailNumber, false),
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    generatedAs: GeneratedAs(aircrafts.notes, false),
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<int> icaoAircraft = GeneratedColumn<int>(
    'icao_aircraft',
    aliasedName,
    false,
    generatedAs: GeneratedAs(aircrafts.icaoAircraft, false),
    type: DriftSqlType.int,
  );
  late final GeneratedColumnWithTypeConverter<AircraftClass?, String>
  aircraftClass = GeneratedColumn<String>(
    'aircraft_class',
    aliasedName,
    true,
    generatedAs: GeneratedAs(aircrafts.aircraftClass, false),
    type: DriftSqlType.string,
  ).withConverter<AircraftClass?>($AircraftsTable.$converteraircraftClassn);
  late final GeneratedColumn<String> typeRating = GeneratedColumn<String>(
    'type_rating',
    aliasedName,
    true,
    generatedAs: GeneratedAs(aircrafts.typeRating, false),
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<String> photoFile = GeneratedColumn<String>(
    'photo_file',
    aliasedName,
    true,
    generatedAs: GeneratedAs(aircrafts.photoFile, false),
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<String> photoUrl = GeneratedColumn<String>(
    'photo_url',
    aliasedName,
    true,
    generatedAs: GeneratedAs(aircrafts.photoUrl, false),
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<String> photoThumbnailUrl =
      GeneratedColumn<String>(
        'photo_thumbnail_url',
        aliasedName,
        true,
        generatedAs: GeneratedAs(aircrafts.photoThumbnailUrl, false),
        type: DriftSqlType.string,
      );
  late final GeneratedColumn<String> photoLink = GeneratedColumn<String>(
    'photo_link',
    aliasedName,
    true,
    generatedAs: GeneratedAs(aircrafts.photoLink, false),
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<String> photoCredit = GeneratedColumn<String>(
    'photo_credit',
    aliasedName,
    true,
    generatedAs: GeneratedAs(aircrafts.photoCredit, false),
    type: DriftSqlType.string,
  );
  late final GeneratedColumnWithTypeConverter<AircraftDescription, String>
  description =
      GeneratedColumn<String>(
        'description',
        aliasedName,
        false,
        generatedAs: GeneratedAs(icaoAircrafts.description, false),
        type: DriftSqlType.string,
      ).withConverter<AircraftDescription>(
        $IcaoAircraftsTable.$converterdescription,
      );
  late final GeneratedColumn<String> modelFullName = GeneratedColumn<String>(
    'model_full_name',
    aliasedName,
    false,
    generatedAs: GeneratedAs(icaoAircrafts.modelFullName, false),
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<String> designator = GeneratedColumn<String>(
    'designator',
    aliasedName,
    false,
    generatedAs: GeneratedAs(icaoAircrafts.designator, false),
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<String> manufacturer = GeneratedColumn<String>(
    'manufacturer',
    aliasedName,
    false,
    generatedAs: GeneratedAs(icaoAircrafts.manufacturer, false),
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<int> engineCount = GeneratedColumn<int>(
    'engine_count',
    aliasedName,
    false,
    generatedAs: GeneratedAs(icaoAircrafts.engineCount, false),
    type: DriftSqlType.int,
  );
  late final GeneratedColumnWithTypeConverter<EngineType, String> engineType =
      GeneratedColumn<String>(
        'engine_type',
        aliasedName,
        false,
        generatedAs: GeneratedAs(icaoAircrafts.engineType, false),
        type: DriftSqlType.string,
      ).withConverter<EngineType>($IcaoAircraftsTable.$converterengineType);
  late final GeneratedColumnWithTypeConverter<WakeTurbulenceCategory, String>
  wakeTurbolenceCategory =
      GeneratedColumn<String>(
        'wake_turbolence_category',
        aliasedName,
        false,
        generatedAs: GeneratedAs(icaoAircrafts.wakeTurbolenceCategory, false),
        type: DriftSqlType.string,
      ).withConverter<WakeTurbulenceCategory>(
        $IcaoAircraftsTable.$converterwakeTurbolenceCategory,
      );
  late final GeneratedColumnWithTypeConverter<WakeTurbulenceGroup, String>
  wakeTurbolenceGroup =
      GeneratedColumn<String>(
        'wake_turbolence_group',
        aliasedName,
        false,
        generatedAs: GeneratedAs(icaoAircrafts.wakeTurbolenceGroup, false),
        type: DriftSqlType.string,
      ).withConverter<WakeTurbulenceGroup>(
        $IcaoAircraftsTable.$converterwakeTurbolenceGroup,
      );
  late final GeneratedColumn<bool> userInserted = GeneratedColumn<bool>(
    'user_inserted',
    aliasedName,
    false,
    generatedAs: GeneratedAs(icaoAircrafts.userInserted, false),
    type: DriftSqlType.bool,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("user_inserted" IN (0, 1))',
    ),
  );
  @override
  $AircraftWithIcaosView createAlias(String alias) {
    return $AircraftWithIcaosView(attachedDatabase, alias);
  }

  @override
  Query? get query =>
      (attachedDatabase.selectOnly(aircrafts)..addColumns($columns)).join([
        innerJoin(
          icaoAircrafts,
          aircrafts.icaoAircraft.equalsExp(icaoAircrafts.id),
        ),
      ])..groupBy([aircrafts.id]);
  @override
  Set<String> get readTables => const {'aircrafts', 'icao_aircrafts'};
}

abstract class _$LogbookDatabase extends GeneratedDatabase {
  _$LogbookDatabase(QueryExecutor e) : super(e);
  $LogbookDatabaseManager get managers => $LogbookDatabaseManager(this);
  late final $CountriesTable countries = $CountriesTable(this);
  late final $RegionsTable regions = $RegionsTable(this);
  late final $AirportsTable airports = $AirportsTable(this);
  late final $FrequenciesTable frequencies = $FrequenciesTable(this);
  late final $RunwaysTable runways = $RunwaysTable(this);
  late final $IcaoAircraftsTable icaoAircrafts = $IcaoAircraftsTable(this);
  late final $AircraftsTable aircrafts = $AircraftsTable(this);
  late final $SimulatorsTable simulators = $SimulatorsTable(this);
  late final $FlightsTable flights = $FlightsTable(this);
  late final $FlightDataPointsTable flightDataPoints = $FlightDataPointsTable(
    this,
  );
  late final $PeopleTable people = $PeopleTable(this);
  late final $FlightCrewTable flightCrew = $FlightCrewTable(this);
  late final $LicencesTable licences = $LicencesTable(this);
  late final $LicenceRatingsTable licenceRatings = $LicenceRatingsTable(this);
  late final $MedicalCertificatesTable medicalCertificates =
      $MedicalCertificatesTable(this);
  late final $AircraftWithStatssView aircraftWithStatss =
      $AircraftWithStatssView(this);
  late final $FlightStatsView flightStats = $FlightStatsView(this);
  late final $AircraftWithIcaosView aircraftWithIcaos = $AircraftWithIcaosView(
    this,
  );
  late final Index flightsSimulatorIdIdx = Index(
    'flights_simulator_id_idx',
    'CREATE INDEX flights_simulator_id_idx ON flights (simulator_id)',
  );
  late final Index flightDataPointsFlightTimestampIdx = Index(
    'flight_data_points_flight_timestamp_idx',
    'CREATE INDEX flight_data_points_flight_timestamp_idx ON flight_data_points (flight, timestamp)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    countries,
    regions,
    airports,
    frequencies,
    runways,
    icaoAircrafts,
    aircrafts,
    simulators,
    flights,
    flightDataPoints,
    people,
    flightCrew,
    licences,
    licenceRatings,
    medicalCertificates,
    aircraftWithStatss,
    flightStats,
    aircraftWithIcaos,
    flightsSimulatorIdIdx,
    flightDataPointsFlightTimestampIdx,
  ];
}

typedef $$CountriesTableCreateCompanionBuilder =
    CountriesCompanion Function({
      Value<int> id,
      required String code,
      required String name,
      required String continent,
      Value<String?> wikipediaLink,
      Value<String?> keywords,
    });
typedef $$CountriesTableUpdateCompanionBuilder =
    CountriesCompanion Function({
      Value<int> id,
      Value<String> code,
      Value<String> name,
      Value<String> continent,
      Value<String?> wikipediaLink,
      Value<String?> keywords,
    });

final class $$CountriesTableReferences
    extends BaseReferences<_$LogbookDatabase, $CountriesTable, Country> {
  $$CountriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RegionsTable, List<Region>> _regionsRefsTable(
    _$LogbookDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.regions,
    aliasName: 'countries__code__regions__iso_country',
  );

  $$RegionsTableProcessedTableManager get regionsRefs {
    final manager = $$RegionsTableTableManager(
      $_db,
      $_db.regions,
    ).filter((f) => f.isoCountry.code.sqlEquals($_itemColumn<String>('code')!));

    final cache = $_typedResult.readTableOrNull(_regionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AirportsTable, List<Airport>> _airportsRefsTable(
    _$LogbookDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.airports,
    aliasName: 'countries__code__airports__iso_country',
  );

  $$AirportsTableProcessedTableManager get airportsRefs {
    final manager = $$AirportsTableTableManager(
      $_db,
      $_db.airports,
    ).filter((f) => f.isoCountry.code.sqlEquals($_itemColumn<String>('code')!));

    final cache = $_typedResult.readTableOrNull(_airportsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CountriesTableFilterComposer
    extends Composer<_$LogbookDatabase, $CountriesTable> {
  $$CountriesTableFilterComposer({
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

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get continent => $composableBuilder(
    column: $table.continent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wikipediaLink => $composableBuilder(
    column: $table.wikipediaLink,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keywords => $composableBuilder(
    column: $table.keywords,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> regionsRefs(
    Expression<bool> Function($$RegionsTableFilterComposer f) f,
  ) {
    final $$RegionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.regions,
      getReferencedColumn: (t) => t.isoCountry,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RegionsTableFilterComposer(
            $db: $db,
            $table: $db.regions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> airportsRefs(
    Expression<bool> Function($$AirportsTableFilterComposer f) f,
  ) {
    final $$AirportsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.airports,
      getReferencedColumn: (t) => t.isoCountry,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AirportsTableFilterComposer(
            $db: $db,
            $table: $db.airports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CountriesTableOrderingComposer
    extends Composer<_$LogbookDatabase, $CountriesTable> {
  $$CountriesTableOrderingComposer({
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

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get continent => $composableBuilder(
    column: $table.continent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wikipediaLink => $composableBuilder(
    column: $table.wikipediaLink,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keywords => $composableBuilder(
    column: $table.keywords,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CountriesTableAnnotationComposer
    extends Composer<_$LogbookDatabase, $CountriesTable> {
  $$CountriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get continent =>
      $composableBuilder(column: $table.continent, builder: (column) => column);

  GeneratedColumn<String> get wikipediaLink => $composableBuilder(
    column: $table.wikipediaLink,
    builder: (column) => column,
  );

  GeneratedColumn<String> get keywords =>
      $composableBuilder(column: $table.keywords, builder: (column) => column);

  Expression<T> regionsRefs<T extends Object>(
    Expression<T> Function($$RegionsTableAnnotationComposer a) f,
  ) {
    final $$RegionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.regions,
      getReferencedColumn: (t) => t.isoCountry,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RegionsTableAnnotationComposer(
            $db: $db,
            $table: $db.regions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> airportsRefs<T extends Object>(
    Expression<T> Function($$AirportsTableAnnotationComposer a) f,
  ) {
    final $$AirportsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.airports,
      getReferencedColumn: (t) => t.isoCountry,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AirportsTableAnnotationComposer(
            $db: $db,
            $table: $db.airports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CountriesTableTableManager
    extends
        RootTableManager<
          _$LogbookDatabase,
          $CountriesTable,
          Country,
          $$CountriesTableFilterComposer,
          $$CountriesTableOrderingComposer,
          $$CountriesTableAnnotationComposer,
          $$CountriesTableCreateCompanionBuilder,
          $$CountriesTableUpdateCompanionBuilder,
          (Country, $$CountriesTableReferences),
          Country,
          PrefetchHooks Function({bool regionsRefs, bool airportsRefs})
        > {
  $$CountriesTableTableManager(_$LogbookDatabase db, $CountriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CountriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CountriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CountriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> continent = const Value.absent(),
                Value<String?> wikipediaLink = const Value.absent(),
                Value<String?> keywords = const Value.absent(),
              }) => CountriesCompanion(
                id: id,
                code: code,
                name: name,
                continent: continent,
                wikipediaLink: wikipediaLink,
                keywords: keywords,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String code,
                required String name,
                required String continent,
                Value<String?> wikipediaLink = const Value.absent(),
                Value<String?> keywords = const Value.absent(),
              }) => CountriesCompanion.insert(
                id: id,
                code: code,
                name: name,
                continent: continent,
                wikipediaLink: wikipediaLink,
                keywords: keywords,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CountriesTable, Country>(table),
                  $$CountriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({regionsRefs = false, airportsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (regionsRefs) db.regions,
                if (airportsRefs) db.airports,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (regionsRefs)
                    await $_getPrefetchedData<Country, $CountriesTable, Region>(
                      currentTable: table,
                      referencedTable: $$CountriesTableReferences
                          ._regionsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CountriesTableReferences(db, table, p0).regionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.isoCountry == item.code,
                          ),
                      typedResults: items,
                    ),
                  if (airportsRefs)
                    await $_getPrefetchedData<
                      Country,
                      $CountriesTable,
                      Airport
                    >(
                      currentTable: table,
                      referencedTable: $$CountriesTableReferences
                          ._airportsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CountriesTableReferences(
                            db,
                            table,
                            p0,
                          ).airportsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.isoCountry == item.code,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CountriesTableProcessedTableManager =
    ProcessedTableManager<
      _$LogbookDatabase,
      $CountriesTable,
      Country,
      $$CountriesTableFilterComposer,
      $$CountriesTableOrderingComposer,
      $$CountriesTableAnnotationComposer,
      $$CountriesTableCreateCompanionBuilder,
      $$CountriesTableUpdateCompanionBuilder,
      (Country, $$CountriesTableReferences),
      Country,
      PrefetchHooks Function({bool regionsRefs, bool airportsRefs})
    >;
typedef $$RegionsTableCreateCompanionBuilder =
    RegionsCompanion Function({
      Value<int> id,
      required String code,
      Value<String?> localCode,
      required String name,
      required String continent,
      required String isoCountry,
      Value<String?> wikipediaLink,
      Value<String?> keywords,
    });
typedef $$RegionsTableUpdateCompanionBuilder =
    RegionsCompanion Function({
      Value<int> id,
      Value<String> code,
      Value<String?> localCode,
      Value<String> name,
      Value<String> continent,
      Value<String> isoCountry,
      Value<String?> wikipediaLink,
      Value<String?> keywords,
    });

final class $$RegionsTableReferences
    extends BaseReferences<_$LogbookDatabase, $RegionsTable, Region> {
  $$RegionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CountriesTable _isoCountryTable(_$LogbookDatabase db) =>
      db.countries.createAlias('regions__iso_country__countries__code');

  $$CountriesTableProcessedTableManager get isoCountry {
    final $_column = $_itemColumn<String>('iso_country')!;

    final manager = $$CountriesTableTableManager(
      $_db,
      $_db.countries,
    ).filter((f) => f.code.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_isoCountryTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AirportsTable, List<Airport>> _airportsRefsTable(
    _$LogbookDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.airports,
    aliasName: 'regions__code__airports__iso_region',
  );

  $$AirportsTableProcessedTableManager get airportsRefs {
    final manager = $$AirportsTableTableManager(
      $_db,
      $_db.airports,
    ).filter((f) => f.isoRegion.code.sqlEquals($_itemColumn<String>('code')!));

    final cache = $_typedResult.readTableOrNull(_airportsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RegionsTableFilterComposer
    extends Composer<_$LogbookDatabase, $RegionsTable> {
  $$RegionsTableFilterComposer({
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

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localCode => $composableBuilder(
    column: $table.localCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get continent => $composableBuilder(
    column: $table.continent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wikipediaLink => $composableBuilder(
    column: $table.wikipediaLink,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keywords => $composableBuilder(
    column: $table.keywords,
    builder: (column) => ColumnFilters(column),
  );

  $$CountriesTableFilterComposer get isoCountry {
    final $$CountriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.isoCountry,
      referencedTable: $db.countries,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CountriesTableFilterComposer(
            $db: $db,
            $table: $db.countries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> airportsRefs(
    Expression<bool> Function($$AirportsTableFilterComposer f) f,
  ) {
    final $$AirportsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.airports,
      getReferencedColumn: (t) => t.isoRegion,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AirportsTableFilterComposer(
            $db: $db,
            $table: $db.airports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RegionsTableOrderingComposer
    extends Composer<_$LogbookDatabase, $RegionsTable> {
  $$RegionsTableOrderingComposer({
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

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localCode => $composableBuilder(
    column: $table.localCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get continent => $composableBuilder(
    column: $table.continent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wikipediaLink => $composableBuilder(
    column: $table.wikipediaLink,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keywords => $composableBuilder(
    column: $table.keywords,
    builder: (column) => ColumnOrderings(column),
  );

  $$CountriesTableOrderingComposer get isoCountry {
    final $$CountriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.isoCountry,
      referencedTable: $db.countries,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CountriesTableOrderingComposer(
            $db: $db,
            $table: $db.countries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RegionsTableAnnotationComposer
    extends Composer<_$LogbookDatabase, $RegionsTable> {
  $$RegionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get localCode =>
      $composableBuilder(column: $table.localCode, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get continent =>
      $composableBuilder(column: $table.continent, builder: (column) => column);

  GeneratedColumn<String> get wikipediaLink => $composableBuilder(
    column: $table.wikipediaLink,
    builder: (column) => column,
  );

  GeneratedColumn<String> get keywords =>
      $composableBuilder(column: $table.keywords, builder: (column) => column);

  $$CountriesTableAnnotationComposer get isoCountry {
    final $$CountriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.isoCountry,
      referencedTable: $db.countries,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CountriesTableAnnotationComposer(
            $db: $db,
            $table: $db.countries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> airportsRefs<T extends Object>(
    Expression<T> Function($$AirportsTableAnnotationComposer a) f,
  ) {
    final $$AirportsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.airports,
      getReferencedColumn: (t) => t.isoRegion,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AirportsTableAnnotationComposer(
            $db: $db,
            $table: $db.airports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RegionsTableTableManager
    extends
        RootTableManager<
          _$LogbookDatabase,
          $RegionsTable,
          Region,
          $$RegionsTableFilterComposer,
          $$RegionsTableOrderingComposer,
          $$RegionsTableAnnotationComposer,
          $$RegionsTableCreateCompanionBuilder,
          $$RegionsTableUpdateCompanionBuilder,
          (Region, $$RegionsTableReferences),
          Region,
          PrefetchHooks Function({bool isoCountry, bool airportsRefs})
        > {
  $$RegionsTableTableManager(_$LogbookDatabase db, $RegionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RegionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RegionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RegionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String?> localCode = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> continent = const Value.absent(),
                Value<String> isoCountry = const Value.absent(),
                Value<String?> wikipediaLink = const Value.absent(),
                Value<String?> keywords = const Value.absent(),
              }) => RegionsCompanion(
                id: id,
                code: code,
                localCode: localCode,
                name: name,
                continent: continent,
                isoCountry: isoCountry,
                wikipediaLink: wikipediaLink,
                keywords: keywords,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String code,
                Value<String?> localCode = const Value.absent(),
                required String name,
                required String continent,
                required String isoCountry,
                Value<String?> wikipediaLink = const Value.absent(),
                Value<String?> keywords = const Value.absent(),
              }) => RegionsCompanion.insert(
                id: id,
                code: code,
                localCode: localCode,
                name: name,
                continent: continent,
                isoCountry: isoCountry,
                wikipediaLink: wikipediaLink,
                keywords: keywords,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RegionsTable, Region>(table),
                  $$RegionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({isoCountry = false, airportsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (airportsRefs) db.airports],
              addJoins:
                  <
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
                    if (isoCountry) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.isoCountry,
                                referencedTable: $$RegionsTableReferences
                                    ._isoCountryTable(db),
                                referencedColumn: $$RegionsTableReferences
                                    ._isoCountryTable(db)
                                    .code,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (airportsRefs)
                    await $_getPrefetchedData<Region, $RegionsTable, Airport>(
                      currentTable: table,
                      referencedTable: $$RegionsTableReferences
                          ._airportsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$RegionsTableReferences(db, table, p0).airportsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.isoRegion == item.code,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RegionsTableProcessedTableManager =
    ProcessedTableManager<
      _$LogbookDatabase,
      $RegionsTable,
      Region,
      $$RegionsTableFilterComposer,
      $$RegionsTableOrderingComposer,
      $$RegionsTableAnnotationComposer,
      $$RegionsTableCreateCompanionBuilder,
      $$RegionsTableUpdateCompanionBuilder,
      (Region, $$RegionsTableReferences),
      Region,
      PrefetchHooks Function({bool isoCountry, bool airportsRefs})
    >;
typedef $$AirportsTableCreateCompanionBuilder =
    AirportsCompanion Function({
      Value<int> id,
      Value<String?> ident,
      required AirportType type,
      Value<String?> name,
      Value<double?> latitudeDeg,
      Value<double?> longitudeDeg,
      Value<int?> elevationFt,
      required String continent,
      required String isoCountry,
      required String isoRegion,
      Value<String?> municipality,
      Value<bool?> scheduledService,
      Value<String?> icaoCode,
      Value<String?> iataCode,
      Value<String?> gpsCode,
      Value<String?> localCode,
      Value<String?> homeLink,
      Value<String?> wikipediaLink,
      Value<String?> keywords,
    });
typedef $$AirportsTableUpdateCompanionBuilder =
    AirportsCompanion Function({
      Value<int> id,
      Value<String?> ident,
      Value<AirportType> type,
      Value<String?> name,
      Value<double?> latitudeDeg,
      Value<double?> longitudeDeg,
      Value<int?> elevationFt,
      Value<String> continent,
      Value<String> isoCountry,
      Value<String> isoRegion,
      Value<String?> municipality,
      Value<bool?> scheduledService,
      Value<String?> icaoCode,
      Value<String?> iataCode,
      Value<String?> gpsCode,
      Value<String?> localCode,
      Value<String?> homeLink,
      Value<String?> wikipediaLink,
      Value<String?> keywords,
    });

final class $$AirportsTableReferences
    extends BaseReferences<_$LogbookDatabase, $AirportsTable, Airport> {
  $$AirportsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CountriesTable _isoCountryTable(_$LogbookDatabase db) =>
      db.countries.createAlias('airports__iso_country__countries__code');

  $$CountriesTableProcessedTableManager get isoCountry {
    final $_column = $_itemColumn<String>('iso_country')!;

    final manager = $$CountriesTableTableManager(
      $_db,
      $_db.countries,
    ).filter((f) => f.code.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_isoCountryTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $RegionsTable _isoRegionTable(_$LogbookDatabase db) =>
      db.regions.createAlias('airports__iso_region__regions__code');

  $$RegionsTableProcessedTableManager get isoRegion {
    final $_column = $_itemColumn<String>('iso_region')!;

    final manager = $$RegionsTableTableManager(
      $_db,
      $_db.regions,
    ).filter((f) => f.code.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_isoRegionTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$FrequenciesTable, List<Frequency>>
  _frequencyRefsTable(_$LogbookDatabase db) => MultiTypedResultKey.fromTable(
    db.frequencies,
    aliasName: 'airports__id__frequencies__airport',
  );

  $$FrequenciesTableProcessedTableManager get frequencyRefs {
    final manager = $$FrequenciesTableTableManager(
      $_db,
      $_db.frequencies,
    ).filter((f) => f.airport.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_frequencyRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RunwaysTable, List<Runway>> _runwayRefsTable(
    _$LogbookDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.runways,
    aliasName: 'airports__id__runways__airport',
  );

  $$RunwaysTableProcessedTableManager get runwayRefs {
    final manager = $$RunwaysTableTableManager(
      $_db,
      $_db.runways,
    ).filter((f) => f.airport.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_runwayRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FlightsTable, List<Flight>>
  _departureAirportRefsTable(_$LogbookDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.flights,
        aliasName: 'airports__id__flights__departure',
      );

  $$FlightsTableProcessedTableManager get departureAirportRefs {
    final manager = $$FlightsTableTableManager(
      $_db,
      $_db.flights,
    ).filter((f) => f.departure.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _departureAirportRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FlightsTable, List<Flight>>
  _arrivalAirportsRefsTable(_$LogbookDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.flights,
        aliasName: 'airports__id__flights__arrival',
      );

  $$FlightsTableProcessedTableManager get arrivalAirportsRefs {
    final manager = $$FlightsTableTableManager(
      $_db,
      $_db.flights,
    ).filter((f) => f.arrival.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _arrivalAirportsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AirportsTableFilterComposer
    extends Composer<_$LogbookDatabase, $AirportsTable> {
  $$AirportsTableFilterComposer({
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

  ColumnFilters<String> get ident => $composableBuilder(
    column: $table.ident,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AirportType, AirportType, int> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitudeDeg => $composableBuilder(
    column: $table.latitudeDeg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitudeDeg => $composableBuilder(
    column: $table.longitudeDeg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get elevationFt => $composableBuilder(
    column: $table.elevationFt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get continent => $composableBuilder(
    column: $table.continent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get municipality => $composableBuilder(
    column: $table.municipality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get scheduledService => $composableBuilder(
    column: $table.scheduledService,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icaoCode => $composableBuilder(
    column: $table.icaoCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iataCode => $composableBuilder(
    column: $table.iataCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gpsCode => $composableBuilder(
    column: $table.gpsCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localCode => $composableBuilder(
    column: $table.localCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get homeLink => $composableBuilder(
    column: $table.homeLink,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wikipediaLink => $composableBuilder(
    column: $table.wikipediaLink,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keywords => $composableBuilder(
    column: $table.keywords,
    builder: (column) => ColumnFilters(column),
  );

  $$CountriesTableFilterComposer get isoCountry {
    final $$CountriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.isoCountry,
      referencedTable: $db.countries,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CountriesTableFilterComposer(
            $db: $db,
            $table: $db.countries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RegionsTableFilterComposer get isoRegion {
    final $$RegionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.isoRegion,
      referencedTable: $db.regions,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RegionsTableFilterComposer(
            $db: $db,
            $table: $db.regions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> frequencyRefs(
    Expression<bool> Function($$FrequenciesTableFilterComposer f) f,
  ) {
    final $$FrequenciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.frequencies,
      getReferencedColumn: (t) => t.airport,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FrequenciesTableFilterComposer(
            $db: $db,
            $table: $db.frequencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> runwayRefs(
    Expression<bool> Function($$RunwaysTableFilterComposer f) f,
  ) {
    final $$RunwaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.runways,
      getReferencedColumn: (t) => t.airport,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RunwaysTableFilterComposer(
            $db: $db,
            $table: $db.runways,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> departureAirportRefs(
    Expression<bool> Function($$FlightsTableFilterComposer f) f,
  ) {
    final $$FlightsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.flights,
      getReferencedColumn: (t) => t.departure,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightsTableFilterComposer(
            $db: $db,
            $table: $db.flights,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> arrivalAirportsRefs(
    Expression<bool> Function($$FlightsTableFilterComposer f) f,
  ) {
    final $$FlightsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.flights,
      getReferencedColumn: (t) => t.arrival,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightsTableFilterComposer(
            $db: $db,
            $table: $db.flights,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AirportsTableOrderingComposer
    extends Composer<_$LogbookDatabase, $AirportsTable> {
  $$AirportsTableOrderingComposer({
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

  ColumnOrderings<String> get ident => $composableBuilder(
    column: $table.ident,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitudeDeg => $composableBuilder(
    column: $table.latitudeDeg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitudeDeg => $composableBuilder(
    column: $table.longitudeDeg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get elevationFt => $composableBuilder(
    column: $table.elevationFt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get continent => $composableBuilder(
    column: $table.continent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get municipality => $composableBuilder(
    column: $table.municipality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get scheduledService => $composableBuilder(
    column: $table.scheduledService,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icaoCode => $composableBuilder(
    column: $table.icaoCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iataCode => $composableBuilder(
    column: $table.iataCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gpsCode => $composableBuilder(
    column: $table.gpsCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localCode => $composableBuilder(
    column: $table.localCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get homeLink => $composableBuilder(
    column: $table.homeLink,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wikipediaLink => $composableBuilder(
    column: $table.wikipediaLink,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keywords => $composableBuilder(
    column: $table.keywords,
    builder: (column) => ColumnOrderings(column),
  );

  $$CountriesTableOrderingComposer get isoCountry {
    final $$CountriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.isoCountry,
      referencedTable: $db.countries,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CountriesTableOrderingComposer(
            $db: $db,
            $table: $db.countries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RegionsTableOrderingComposer get isoRegion {
    final $$RegionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.isoRegion,
      referencedTable: $db.regions,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RegionsTableOrderingComposer(
            $db: $db,
            $table: $db.regions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AirportsTableAnnotationComposer
    extends Composer<_$LogbookDatabase, $AirportsTable> {
  $$AirportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ident =>
      $composableBuilder(column: $table.ident, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AirportType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get latitudeDeg => $composableBuilder(
    column: $table.latitudeDeg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get longitudeDeg => $composableBuilder(
    column: $table.longitudeDeg,
    builder: (column) => column,
  );

  GeneratedColumn<int> get elevationFt => $composableBuilder(
    column: $table.elevationFt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get continent =>
      $composableBuilder(column: $table.continent, builder: (column) => column);

  GeneratedColumn<String> get municipality => $composableBuilder(
    column: $table.municipality,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get scheduledService => $composableBuilder(
    column: $table.scheduledService,
    builder: (column) => column,
  );

  GeneratedColumn<String> get icaoCode =>
      $composableBuilder(column: $table.icaoCode, builder: (column) => column);

  GeneratedColumn<String> get iataCode =>
      $composableBuilder(column: $table.iataCode, builder: (column) => column);

  GeneratedColumn<String> get gpsCode =>
      $composableBuilder(column: $table.gpsCode, builder: (column) => column);

  GeneratedColumn<String> get localCode =>
      $composableBuilder(column: $table.localCode, builder: (column) => column);

  GeneratedColumn<String> get homeLink =>
      $composableBuilder(column: $table.homeLink, builder: (column) => column);

  GeneratedColumn<String> get wikipediaLink => $composableBuilder(
    column: $table.wikipediaLink,
    builder: (column) => column,
  );

  GeneratedColumn<String> get keywords =>
      $composableBuilder(column: $table.keywords, builder: (column) => column);

  $$CountriesTableAnnotationComposer get isoCountry {
    final $$CountriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.isoCountry,
      referencedTable: $db.countries,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CountriesTableAnnotationComposer(
            $db: $db,
            $table: $db.countries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RegionsTableAnnotationComposer get isoRegion {
    final $$RegionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.isoRegion,
      referencedTable: $db.regions,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RegionsTableAnnotationComposer(
            $db: $db,
            $table: $db.regions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> frequencyRefs<T extends Object>(
    Expression<T> Function($$FrequenciesTableAnnotationComposer a) f,
  ) {
    final $$FrequenciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.frequencies,
      getReferencedColumn: (t) => t.airport,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FrequenciesTableAnnotationComposer(
            $db: $db,
            $table: $db.frequencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> runwayRefs<T extends Object>(
    Expression<T> Function($$RunwaysTableAnnotationComposer a) f,
  ) {
    final $$RunwaysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.runways,
      getReferencedColumn: (t) => t.airport,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RunwaysTableAnnotationComposer(
            $db: $db,
            $table: $db.runways,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> departureAirportRefs<T extends Object>(
    Expression<T> Function($$FlightsTableAnnotationComposer a) f,
  ) {
    final $$FlightsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.flights,
      getReferencedColumn: (t) => t.departure,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightsTableAnnotationComposer(
            $db: $db,
            $table: $db.flights,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> arrivalAirportsRefs<T extends Object>(
    Expression<T> Function($$FlightsTableAnnotationComposer a) f,
  ) {
    final $$FlightsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.flights,
      getReferencedColumn: (t) => t.arrival,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightsTableAnnotationComposer(
            $db: $db,
            $table: $db.flights,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AirportsTableTableManager
    extends
        RootTableManager<
          _$LogbookDatabase,
          $AirportsTable,
          Airport,
          $$AirportsTableFilterComposer,
          $$AirportsTableOrderingComposer,
          $$AirportsTableAnnotationComposer,
          $$AirportsTableCreateCompanionBuilder,
          $$AirportsTableUpdateCompanionBuilder,
          (Airport, $$AirportsTableReferences),
          Airport,
          PrefetchHooks Function({
            bool isoCountry,
            bool isoRegion,
            bool frequencyRefs,
            bool runwayRefs,
            bool departureAirportRefs,
            bool arrivalAirportsRefs,
          })
        > {
  $$AirportsTableTableManager(_$LogbookDatabase db, $AirportsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AirportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AirportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AirportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> ident = const Value.absent(),
                Value<AirportType> type = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<double?> latitudeDeg = const Value.absent(),
                Value<double?> longitudeDeg = const Value.absent(),
                Value<int?> elevationFt = const Value.absent(),
                Value<String> continent = const Value.absent(),
                Value<String> isoCountry = const Value.absent(),
                Value<String> isoRegion = const Value.absent(),
                Value<String?> municipality = const Value.absent(),
                Value<bool?> scheduledService = const Value.absent(),
                Value<String?> icaoCode = const Value.absent(),
                Value<String?> iataCode = const Value.absent(),
                Value<String?> gpsCode = const Value.absent(),
                Value<String?> localCode = const Value.absent(),
                Value<String?> homeLink = const Value.absent(),
                Value<String?> wikipediaLink = const Value.absent(),
                Value<String?> keywords = const Value.absent(),
              }) => AirportsCompanion(
                id: id,
                ident: ident,
                type: type,
                name: name,
                latitudeDeg: latitudeDeg,
                longitudeDeg: longitudeDeg,
                elevationFt: elevationFt,
                continent: continent,
                isoCountry: isoCountry,
                isoRegion: isoRegion,
                municipality: municipality,
                scheduledService: scheduledService,
                icaoCode: icaoCode,
                iataCode: iataCode,
                gpsCode: gpsCode,
                localCode: localCode,
                homeLink: homeLink,
                wikipediaLink: wikipediaLink,
                keywords: keywords,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> ident = const Value.absent(),
                required AirportType type,
                Value<String?> name = const Value.absent(),
                Value<double?> latitudeDeg = const Value.absent(),
                Value<double?> longitudeDeg = const Value.absent(),
                Value<int?> elevationFt = const Value.absent(),
                required String continent,
                required String isoCountry,
                required String isoRegion,
                Value<String?> municipality = const Value.absent(),
                Value<bool?> scheduledService = const Value.absent(),
                Value<String?> icaoCode = const Value.absent(),
                Value<String?> iataCode = const Value.absent(),
                Value<String?> gpsCode = const Value.absent(),
                Value<String?> localCode = const Value.absent(),
                Value<String?> homeLink = const Value.absent(),
                Value<String?> wikipediaLink = const Value.absent(),
                Value<String?> keywords = const Value.absent(),
              }) => AirportsCompanion.insert(
                id: id,
                ident: ident,
                type: type,
                name: name,
                latitudeDeg: latitudeDeg,
                longitudeDeg: longitudeDeg,
                elevationFt: elevationFt,
                continent: continent,
                isoCountry: isoCountry,
                isoRegion: isoRegion,
                municipality: municipality,
                scheduledService: scheduledService,
                icaoCode: icaoCode,
                iataCode: iataCode,
                gpsCode: gpsCode,
                localCode: localCode,
                homeLink: homeLink,
                wikipediaLink: wikipediaLink,
                keywords: keywords,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AirportsTable, Airport>(table),
                  $$AirportsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                isoCountry = false,
                isoRegion = false,
                frequencyRefs = false,
                runwayRefs = false,
                departureAirportRefs = false,
                arrivalAirportsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (frequencyRefs) db.frequencies,
                    if (runwayRefs) db.runways,
                    if (departureAirportRefs) db.flights,
                    if (arrivalAirportsRefs) db.flights,
                  ],
                  addJoins:
                      <
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
                        if (isoCountry) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.isoCountry,
                                    referencedTable: $$AirportsTableReferences
                                        ._isoCountryTable(db),
                                    referencedColumn: $$AirportsTableReferences
                                        ._isoCountryTable(db)
                                        .code,
                                  )
                                  as T;
                        }
                        if (isoRegion) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.isoRegion,
                                    referencedTable: $$AirportsTableReferences
                                        ._isoRegionTable(db),
                                    referencedColumn: $$AirportsTableReferences
                                        ._isoRegionTable(db)
                                        .code,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (frequencyRefs)
                        await $_getPrefetchedData<
                          Airport,
                          $AirportsTable,
                          Frequency
                        >(
                          currentTable: table,
                          referencedTable: $$AirportsTableReferences
                              ._frequencyRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AirportsTableReferences(
                                db,
                                table,
                                p0,
                              ).frequencyRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.airport == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (runwayRefs)
                        await $_getPrefetchedData<
                          Airport,
                          $AirportsTable,
                          Runway
                        >(
                          currentTable: table,
                          referencedTable: $$AirportsTableReferences
                              ._runwayRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AirportsTableReferences(
                                db,
                                table,
                                p0,
                              ).runwayRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.airport == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (departureAirportRefs)
                        await $_getPrefetchedData<
                          Airport,
                          $AirportsTable,
                          Flight
                        >(
                          currentTable: table,
                          referencedTable: $$AirportsTableReferences
                              ._departureAirportRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AirportsTableReferences(
                                db,
                                table,
                                p0,
                              ).departureAirportRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.departure == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (arrivalAirportsRefs)
                        await $_getPrefetchedData<
                          Airport,
                          $AirportsTable,
                          Flight
                        >(
                          currentTable: table,
                          referencedTable: $$AirportsTableReferences
                              ._arrivalAirportsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AirportsTableReferences(
                                db,
                                table,
                                p0,
                              ).arrivalAirportsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.arrival == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AirportsTableProcessedTableManager =
    ProcessedTableManager<
      _$LogbookDatabase,
      $AirportsTable,
      Airport,
      $$AirportsTableFilterComposer,
      $$AirportsTableOrderingComposer,
      $$AirportsTableAnnotationComposer,
      $$AirportsTableCreateCompanionBuilder,
      $$AirportsTableUpdateCompanionBuilder,
      (Airport, $$AirportsTableReferences),
      Airport,
      PrefetchHooks Function({
        bool isoCountry,
        bool isoRegion,
        bool frequencyRefs,
        bool runwayRefs,
        bool departureAirportRefs,
        bool arrivalAirportsRefs,
      })
    >;
typedef $$FrequenciesTableCreateCompanionBuilder =
    FrequenciesCompanion Function({
      Value<int> id,
      required int airport,
      Value<String?> type,
      Value<String?> description,
      Value<String?> frequencyMhz,
    });
typedef $$FrequenciesTableUpdateCompanionBuilder =
    FrequenciesCompanion Function({
      Value<int> id,
      Value<int> airport,
      Value<String?> type,
      Value<String?> description,
      Value<String?> frequencyMhz,
    });

final class $$FrequenciesTableReferences
    extends BaseReferences<_$LogbookDatabase, $FrequenciesTable, Frequency> {
  $$FrequenciesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AirportsTable _airportTable(_$LogbookDatabase db) =>
      db.airports.createAlias('frequencies__airport__airports__id');

  $$AirportsTableProcessedTableManager get airport {
    final $_column = $_itemColumn<int>('airport')!;

    final manager = $$AirportsTableTableManager(
      $_db,
      $_db.airports,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_airportTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FrequenciesTableFilterComposer
    extends Composer<_$LogbookDatabase, $FrequenciesTable> {
  $$FrequenciesTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frequencyMhz => $composableBuilder(
    column: $table.frequencyMhz,
    builder: (column) => ColumnFilters(column),
  );

  $$AirportsTableFilterComposer get airport {
    final $$AirportsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.airport,
      referencedTable: $db.airports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AirportsTableFilterComposer(
            $db: $db,
            $table: $db.airports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FrequenciesTableOrderingComposer
    extends Composer<_$LogbookDatabase, $FrequenciesTable> {
  $$FrequenciesTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequencyMhz => $composableBuilder(
    column: $table.frequencyMhz,
    builder: (column) => ColumnOrderings(column),
  );

  $$AirportsTableOrderingComposer get airport {
    final $$AirportsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.airport,
      referencedTable: $db.airports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AirportsTableOrderingComposer(
            $db: $db,
            $table: $db.airports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FrequenciesTableAnnotationComposer
    extends Composer<_$LogbookDatabase, $FrequenciesTable> {
  $$FrequenciesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get frequencyMhz => $composableBuilder(
    column: $table.frequencyMhz,
    builder: (column) => column,
  );

  $$AirportsTableAnnotationComposer get airport {
    final $$AirportsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.airport,
      referencedTable: $db.airports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AirportsTableAnnotationComposer(
            $db: $db,
            $table: $db.airports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FrequenciesTableTableManager
    extends
        RootTableManager<
          _$LogbookDatabase,
          $FrequenciesTable,
          Frequency,
          $$FrequenciesTableFilterComposer,
          $$FrequenciesTableOrderingComposer,
          $$FrequenciesTableAnnotationComposer,
          $$FrequenciesTableCreateCompanionBuilder,
          $$FrequenciesTableUpdateCompanionBuilder,
          (Frequency, $$FrequenciesTableReferences),
          Frequency,
          PrefetchHooks Function({bool airport})
        > {
  $$FrequenciesTableTableManager(_$LogbookDatabase db, $FrequenciesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FrequenciesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FrequenciesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FrequenciesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> airport = const Value.absent(),
                Value<String?> type = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> frequencyMhz = const Value.absent(),
              }) => FrequenciesCompanion(
                id: id,
                airport: airport,
                type: type,
                description: description,
                frequencyMhz: frequencyMhz,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int airport,
                Value<String?> type = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> frequencyMhz = const Value.absent(),
              }) => FrequenciesCompanion.insert(
                id: id,
                airport: airport,
                type: type,
                description: description,
                frequencyMhz: frequencyMhz,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FrequenciesTable, Frequency>(table),
                  $$FrequenciesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({airport = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                    if (airport) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.airport,
                                referencedTable: $$FrequenciesTableReferences
                                    ._airportTable(db),
                                referencedColumn: $$FrequenciesTableReferences
                                    ._airportTable(db)
                                    .id,
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

typedef $$FrequenciesTableProcessedTableManager =
    ProcessedTableManager<
      _$LogbookDatabase,
      $FrequenciesTable,
      Frequency,
      $$FrequenciesTableFilterComposer,
      $$FrequenciesTableOrderingComposer,
      $$FrequenciesTableAnnotationComposer,
      $$FrequenciesTableCreateCompanionBuilder,
      $$FrequenciesTableUpdateCompanionBuilder,
      (Frequency, $$FrequenciesTableReferences),
      Frequency,
      PrefetchHooks Function({bool airport})
    >;
typedef $$RunwaysTableCreateCompanionBuilder =
    RunwaysCompanion Function({
      Value<int> id,
      required int airport,
      Value<int?> lengthFt,
      Value<int?> widthFt,
      Value<String?> surface,
      Value<bool?> lighted,
      Value<bool?> closed,
      Value<String?> leIdent,
      Value<double?> leLatitudeDeg,
      Value<double?> leLongitudeDeg,
      Value<int?> leElevationFt,
      Value<double?> leHeadingDegT,
      Value<int?> leDisplacedThresholdFt,
      Value<String?> heIdent,
      Value<double?> heLatitudeDeg,
      Value<double?> heLongitudeDeg,
      Value<int?> heElevationFt,
      Value<double?> heHeadingDegT,
      Value<int?> heDisplacedThresholdFt,
    });
typedef $$RunwaysTableUpdateCompanionBuilder =
    RunwaysCompanion Function({
      Value<int> id,
      Value<int> airport,
      Value<int?> lengthFt,
      Value<int?> widthFt,
      Value<String?> surface,
      Value<bool?> lighted,
      Value<bool?> closed,
      Value<String?> leIdent,
      Value<double?> leLatitudeDeg,
      Value<double?> leLongitudeDeg,
      Value<int?> leElevationFt,
      Value<double?> leHeadingDegT,
      Value<int?> leDisplacedThresholdFt,
      Value<String?> heIdent,
      Value<double?> heLatitudeDeg,
      Value<double?> heLongitudeDeg,
      Value<int?> heElevationFt,
      Value<double?> heHeadingDegT,
      Value<int?> heDisplacedThresholdFt,
    });

final class $$RunwaysTableReferences
    extends BaseReferences<_$LogbookDatabase, $RunwaysTable, Runway> {
  $$RunwaysTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AirportsTable _airportTable(_$LogbookDatabase db) =>
      db.airports.createAlias('runways__airport__airports__id');

  $$AirportsTableProcessedTableManager get airport {
    final $_column = $_itemColumn<int>('airport')!;

    final manager = $$AirportsTableTableManager(
      $_db,
      $_db.airports,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_airportTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RunwaysTableFilterComposer
    extends Composer<_$LogbookDatabase, $RunwaysTable> {
  $$RunwaysTableFilterComposer({
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

  ColumnFilters<int> get lengthFt => $composableBuilder(
    column: $table.lengthFt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get widthFt => $composableBuilder(
    column: $table.widthFt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get surface => $composableBuilder(
    column: $table.surface,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get lighted => $composableBuilder(
    column: $table.lighted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get closed => $composableBuilder(
    column: $table.closed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get leIdent => $composableBuilder(
    column: $table.leIdent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get leLatitudeDeg => $composableBuilder(
    column: $table.leLatitudeDeg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get leLongitudeDeg => $composableBuilder(
    column: $table.leLongitudeDeg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get leElevationFt => $composableBuilder(
    column: $table.leElevationFt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get leHeadingDegT => $composableBuilder(
    column: $table.leHeadingDegT,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get leDisplacedThresholdFt => $composableBuilder(
    column: $table.leDisplacedThresholdFt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get heIdent => $composableBuilder(
    column: $table.heIdent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get heLatitudeDeg => $composableBuilder(
    column: $table.heLatitudeDeg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get heLongitudeDeg => $composableBuilder(
    column: $table.heLongitudeDeg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get heElevationFt => $composableBuilder(
    column: $table.heElevationFt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get heHeadingDegT => $composableBuilder(
    column: $table.heHeadingDegT,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get heDisplacedThresholdFt => $composableBuilder(
    column: $table.heDisplacedThresholdFt,
    builder: (column) => ColumnFilters(column),
  );

  $$AirportsTableFilterComposer get airport {
    final $$AirportsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.airport,
      referencedTable: $db.airports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AirportsTableFilterComposer(
            $db: $db,
            $table: $db.airports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RunwaysTableOrderingComposer
    extends Composer<_$LogbookDatabase, $RunwaysTable> {
  $$RunwaysTableOrderingComposer({
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

  ColumnOrderings<int> get lengthFt => $composableBuilder(
    column: $table.lengthFt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get widthFt => $composableBuilder(
    column: $table.widthFt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get surface => $composableBuilder(
    column: $table.surface,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get lighted => $composableBuilder(
    column: $table.lighted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get closed => $composableBuilder(
    column: $table.closed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get leIdent => $composableBuilder(
    column: $table.leIdent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get leLatitudeDeg => $composableBuilder(
    column: $table.leLatitudeDeg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get leLongitudeDeg => $composableBuilder(
    column: $table.leLongitudeDeg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get leElevationFt => $composableBuilder(
    column: $table.leElevationFt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get leHeadingDegT => $composableBuilder(
    column: $table.leHeadingDegT,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get leDisplacedThresholdFt => $composableBuilder(
    column: $table.leDisplacedThresholdFt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get heIdent => $composableBuilder(
    column: $table.heIdent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heLatitudeDeg => $composableBuilder(
    column: $table.heLatitudeDeg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heLongitudeDeg => $composableBuilder(
    column: $table.heLongitudeDeg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get heElevationFt => $composableBuilder(
    column: $table.heElevationFt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heHeadingDegT => $composableBuilder(
    column: $table.heHeadingDegT,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get heDisplacedThresholdFt => $composableBuilder(
    column: $table.heDisplacedThresholdFt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AirportsTableOrderingComposer get airport {
    final $$AirportsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.airport,
      referencedTable: $db.airports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AirportsTableOrderingComposer(
            $db: $db,
            $table: $db.airports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RunwaysTableAnnotationComposer
    extends Composer<_$LogbookDatabase, $RunwaysTable> {
  $$RunwaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get lengthFt =>
      $composableBuilder(column: $table.lengthFt, builder: (column) => column);

  GeneratedColumn<int> get widthFt =>
      $composableBuilder(column: $table.widthFt, builder: (column) => column);

  GeneratedColumn<String> get surface =>
      $composableBuilder(column: $table.surface, builder: (column) => column);

  GeneratedColumn<bool> get lighted =>
      $composableBuilder(column: $table.lighted, builder: (column) => column);

  GeneratedColumn<bool> get closed =>
      $composableBuilder(column: $table.closed, builder: (column) => column);

  GeneratedColumn<String> get leIdent =>
      $composableBuilder(column: $table.leIdent, builder: (column) => column);

  GeneratedColumn<double> get leLatitudeDeg => $composableBuilder(
    column: $table.leLatitudeDeg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get leLongitudeDeg => $composableBuilder(
    column: $table.leLongitudeDeg,
    builder: (column) => column,
  );

  GeneratedColumn<int> get leElevationFt => $composableBuilder(
    column: $table.leElevationFt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get leHeadingDegT => $composableBuilder(
    column: $table.leHeadingDegT,
    builder: (column) => column,
  );

  GeneratedColumn<int> get leDisplacedThresholdFt => $composableBuilder(
    column: $table.leDisplacedThresholdFt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get heIdent =>
      $composableBuilder(column: $table.heIdent, builder: (column) => column);

  GeneratedColumn<double> get heLatitudeDeg => $composableBuilder(
    column: $table.heLatitudeDeg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get heLongitudeDeg => $composableBuilder(
    column: $table.heLongitudeDeg,
    builder: (column) => column,
  );

  GeneratedColumn<int> get heElevationFt => $composableBuilder(
    column: $table.heElevationFt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get heHeadingDegT => $composableBuilder(
    column: $table.heHeadingDegT,
    builder: (column) => column,
  );

  GeneratedColumn<int> get heDisplacedThresholdFt => $composableBuilder(
    column: $table.heDisplacedThresholdFt,
    builder: (column) => column,
  );

  $$AirportsTableAnnotationComposer get airport {
    final $$AirportsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.airport,
      referencedTable: $db.airports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AirportsTableAnnotationComposer(
            $db: $db,
            $table: $db.airports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RunwaysTableTableManager
    extends
        RootTableManager<
          _$LogbookDatabase,
          $RunwaysTable,
          Runway,
          $$RunwaysTableFilterComposer,
          $$RunwaysTableOrderingComposer,
          $$RunwaysTableAnnotationComposer,
          $$RunwaysTableCreateCompanionBuilder,
          $$RunwaysTableUpdateCompanionBuilder,
          (Runway, $$RunwaysTableReferences),
          Runway,
          PrefetchHooks Function({bool airport})
        > {
  $$RunwaysTableTableManager(_$LogbookDatabase db, $RunwaysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RunwaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RunwaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RunwaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> airport = const Value.absent(),
                Value<int?> lengthFt = const Value.absent(),
                Value<int?> widthFt = const Value.absent(),
                Value<String?> surface = const Value.absent(),
                Value<bool?> lighted = const Value.absent(),
                Value<bool?> closed = const Value.absent(),
                Value<String?> leIdent = const Value.absent(),
                Value<double?> leLatitudeDeg = const Value.absent(),
                Value<double?> leLongitudeDeg = const Value.absent(),
                Value<int?> leElevationFt = const Value.absent(),
                Value<double?> leHeadingDegT = const Value.absent(),
                Value<int?> leDisplacedThresholdFt = const Value.absent(),
                Value<String?> heIdent = const Value.absent(),
                Value<double?> heLatitudeDeg = const Value.absent(),
                Value<double?> heLongitudeDeg = const Value.absent(),
                Value<int?> heElevationFt = const Value.absent(),
                Value<double?> heHeadingDegT = const Value.absent(),
                Value<int?> heDisplacedThresholdFt = const Value.absent(),
              }) => RunwaysCompanion(
                id: id,
                airport: airport,
                lengthFt: lengthFt,
                widthFt: widthFt,
                surface: surface,
                lighted: lighted,
                closed: closed,
                leIdent: leIdent,
                leLatitudeDeg: leLatitudeDeg,
                leLongitudeDeg: leLongitudeDeg,
                leElevationFt: leElevationFt,
                leHeadingDegT: leHeadingDegT,
                leDisplacedThresholdFt: leDisplacedThresholdFt,
                heIdent: heIdent,
                heLatitudeDeg: heLatitudeDeg,
                heLongitudeDeg: heLongitudeDeg,
                heElevationFt: heElevationFt,
                heHeadingDegT: heHeadingDegT,
                heDisplacedThresholdFt: heDisplacedThresholdFt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int airport,
                Value<int?> lengthFt = const Value.absent(),
                Value<int?> widthFt = const Value.absent(),
                Value<String?> surface = const Value.absent(),
                Value<bool?> lighted = const Value.absent(),
                Value<bool?> closed = const Value.absent(),
                Value<String?> leIdent = const Value.absent(),
                Value<double?> leLatitudeDeg = const Value.absent(),
                Value<double?> leLongitudeDeg = const Value.absent(),
                Value<int?> leElevationFt = const Value.absent(),
                Value<double?> leHeadingDegT = const Value.absent(),
                Value<int?> leDisplacedThresholdFt = const Value.absent(),
                Value<String?> heIdent = const Value.absent(),
                Value<double?> heLatitudeDeg = const Value.absent(),
                Value<double?> heLongitudeDeg = const Value.absent(),
                Value<int?> heElevationFt = const Value.absent(),
                Value<double?> heHeadingDegT = const Value.absent(),
                Value<int?> heDisplacedThresholdFt = const Value.absent(),
              }) => RunwaysCompanion.insert(
                id: id,
                airport: airport,
                lengthFt: lengthFt,
                widthFt: widthFt,
                surface: surface,
                lighted: lighted,
                closed: closed,
                leIdent: leIdent,
                leLatitudeDeg: leLatitudeDeg,
                leLongitudeDeg: leLongitudeDeg,
                leElevationFt: leElevationFt,
                leHeadingDegT: leHeadingDegT,
                leDisplacedThresholdFt: leDisplacedThresholdFt,
                heIdent: heIdent,
                heLatitudeDeg: heLatitudeDeg,
                heLongitudeDeg: heLongitudeDeg,
                heElevationFt: heElevationFt,
                heHeadingDegT: heHeadingDegT,
                heDisplacedThresholdFt: heDisplacedThresholdFt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RunwaysTable, Runway>(table),
                  $$RunwaysTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({airport = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                    if (airport) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.airport,
                                referencedTable: $$RunwaysTableReferences
                                    ._airportTable(db),
                                referencedColumn: $$RunwaysTableReferences
                                    ._airportTable(db)
                                    .id,
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

typedef $$RunwaysTableProcessedTableManager =
    ProcessedTableManager<
      _$LogbookDatabase,
      $RunwaysTable,
      Runway,
      $$RunwaysTableFilterComposer,
      $$RunwaysTableOrderingComposer,
      $$RunwaysTableAnnotationComposer,
      $$RunwaysTableCreateCompanionBuilder,
      $$RunwaysTableUpdateCompanionBuilder,
      (Runway, $$RunwaysTableReferences),
      Runway,
      PrefetchHooks Function({bool airport})
    >;
typedef $$IcaoAircraftsTableCreateCompanionBuilder =
    IcaoAircraftsCompanion Function({
      Value<int> id,
      required String modelFullName,
      required String designator,
      required WakeTurbulenceCategory wakeTurbolenceCategory,
      required WakeTurbulenceGroup wakeTurbolenceGroup,
      required String manufacturer,
      required AircraftDescription description,
      required int engineCount,
      required EngineType engineType,
      Value<bool> userInserted,
    });
typedef $$IcaoAircraftsTableUpdateCompanionBuilder =
    IcaoAircraftsCompanion Function({
      Value<int> id,
      Value<String> modelFullName,
      Value<String> designator,
      Value<WakeTurbulenceCategory> wakeTurbolenceCategory,
      Value<WakeTurbulenceGroup> wakeTurbolenceGroup,
      Value<String> manufacturer,
      Value<AircraftDescription> description,
      Value<int> engineCount,
      Value<EngineType> engineType,
      Value<bool> userInserted,
    });

final class $$IcaoAircraftsTableReferences
    extends
        BaseReferences<_$LogbookDatabase, $IcaoAircraftsTable, IcaoAircraft> {
  $$IcaoAircraftsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$AircraftsTable, List<Aircraft>>
  _aircraftsRefsTable(_$LogbookDatabase db) => MultiTypedResultKey.fromTable(
    db.aircrafts,
    aliasName: 'icao_aircrafts__id__aircrafts__icao_aircraft',
  );

  $$AircraftsTableProcessedTableManager get aircraftsRefs {
    final manager = $$AircraftsTableTableManager(
      $_db,
      $_db.aircrafts,
    ).filter((f) => f.icaoAircraft.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_aircraftsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SimulatorsTable, List<Simulator>>
  _simulatorsRefsTable(_$LogbookDatabase db) => MultiTypedResultKey.fromTable(
    db.simulators,
    aliasName: 'icao_aircrafts__id__simulators__icao_aircraft',
  );

  $$SimulatorsTableProcessedTableManager get simulatorsRefs {
    final manager = $$SimulatorsTableTableManager(
      $_db,
      $_db.simulators,
    ).filter((f) => f.icaoAircraft.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_simulatorsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$IcaoAircraftsTableFilterComposer
    extends Composer<_$LogbookDatabase, $IcaoAircraftsTable> {
  $$IcaoAircraftsTableFilterComposer({
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

  ColumnFilters<String> get modelFullName => $composableBuilder(
    column: $table.modelFullName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get designator => $composableBuilder(
    column: $table.designator,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    WakeTurbulenceCategory,
    WakeTurbulenceCategory,
    String
  >
  get wakeTurbolenceCategory => $composableBuilder(
    column: $table.wakeTurbolenceCategory,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<
    WakeTurbulenceGroup,
    WakeTurbulenceGroup,
    String
  >
  get wakeTurbolenceGroup => $composableBuilder(
    column: $table.wakeTurbolenceGroup,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    AircraftDescription,
    AircraftDescription,
    String
  >
  get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get engineCount => $composableBuilder(
    column: $table.engineCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<EngineType, EngineType, String>
  get engineType => $composableBuilder(
    column: $table.engineType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get userInserted => $composableBuilder(
    column: $table.userInserted,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> aircraftsRefs(
    Expression<bool> Function($$AircraftsTableFilterComposer f) f,
  ) {
    final $$AircraftsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.aircrafts,
      getReferencedColumn: (t) => t.icaoAircraft,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AircraftsTableFilterComposer(
            $db: $db,
            $table: $db.aircrafts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> simulatorsRefs(
    Expression<bool> Function($$SimulatorsTableFilterComposer f) f,
  ) {
    final $$SimulatorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.simulators,
      getReferencedColumn: (t) => t.icaoAircraft,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SimulatorsTableFilterComposer(
            $db: $db,
            $table: $db.simulators,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$IcaoAircraftsTableOrderingComposer
    extends Composer<_$LogbookDatabase, $IcaoAircraftsTable> {
  $$IcaoAircraftsTableOrderingComposer({
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

  ColumnOrderings<String> get modelFullName => $composableBuilder(
    column: $table.modelFullName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get designator => $composableBuilder(
    column: $table.designator,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wakeTurbolenceCategory => $composableBuilder(
    column: $table.wakeTurbolenceCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wakeTurbolenceGroup => $composableBuilder(
    column: $table.wakeTurbolenceGroup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get engineCount => $composableBuilder(
    column: $table.engineCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get engineType => $composableBuilder(
    column: $table.engineType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get userInserted => $composableBuilder(
    column: $table.userInserted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IcaoAircraftsTableAnnotationComposer
    extends Composer<_$LogbookDatabase, $IcaoAircraftsTable> {
  $$IcaoAircraftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get modelFullName => $composableBuilder(
    column: $table.modelFullName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get designator => $composableBuilder(
    column: $table.designator,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<WakeTurbulenceCategory, String>
  get wakeTurbolenceCategory => $composableBuilder(
    column: $table.wakeTurbolenceCategory,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<WakeTurbulenceGroup, String>
  get wakeTurbolenceGroup => $composableBuilder(
    column: $table.wakeTurbolenceGroup,
    builder: (column) => column,
  );

  GeneratedColumn<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<AircraftDescription, String>
  get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get engineCount => $composableBuilder(
    column: $table.engineCount,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<EngineType, String> get engineType =>
      $composableBuilder(
        column: $table.engineType,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get userInserted => $composableBuilder(
    column: $table.userInserted,
    builder: (column) => column,
  );

  Expression<T> aircraftsRefs<T extends Object>(
    Expression<T> Function($$AircraftsTableAnnotationComposer a) f,
  ) {
    final $$AircraftsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.aircrafts,
      getReferencedColumn: (t) => t.icaoAircraft,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AircraftsTableAnnotationComposer(
            $db: $db,
            $table: $db.aircrafts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> simulatorsRefs<T extends Object>(
    Expression<T> Function($$SimulatorsTableAnnotationComposer a) f,
  ) {
    final $$SimulatorsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.simulators,
      getReferencedColumn: (t) => t.icaoAircraft,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SimulatorsTableAnnotationComposer(
            $db: $db,
            $table: $db.simulators,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$IcaoAircraftsTableTableManager
    extends
        RootTableManager<
          _$LogbookDatabase,
          $IcaoAircraftsTable,
          IcaoAircraft,
          $$IcaoAircraftsTableFilterComposer,
          $$IcaoAircraftsTableOrderingComposer,
          $$IcaoAircraftsTableAnnotationComposer,
          $$IcaoAircraftsTableCreateCompanionBuilder,
          $$IcaoAircraftsTableUpdateCompanionBuilder,
          (IcaoAircraft, $$IcaoAircraftsTableReferences),
          IcaoAircraft,
          PrefetchHooks Function({bool aircraftsRefs, bool simulatorsRefs})
        > {
  $$IcaoAircraftsTableTableManager(
    _$LogbookDatabase db,
    $IcaoAircraftsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IcaoAircraftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IcaoAircraftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IcaoAircraftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> modelFullName = const Value.absent(),
                Value<String> designator = const Value.absent(),
                Value<WakeTurbulenceCategory> wakeTurbolenceCategory =
                    const Value.absent(),
                Value<WakeTurbulenceGroup> wakeTurbolenceGroup =
                    const Value.absent(),
                Value<String> manufacturer = const Value.absent(),
                Value<AircraftDescription> description = const Value.absent(),
                Value<int> engineCount = const Value.absent(),
                Value<EngineType> engineType = const Value.absent(),
                Value<bool> userInserted = const Value.absent(),
              }) => IcaoAircraftsCompanion(
                id: id,
                modelFullName: modelFullName,
                designator: designator,
                wakeTurbolenceCategory: wakeTurbolenceCategory,
                wakeTurbolenceGroup: wakeTurbolenceGroup,
                manufacturer: manufacturer,
                description: description,
                engineCount: engineCount,
                engineType: engineType,
                userInserted: userInserted,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String modelFullName,
                required String designator,
                required WakeTurbulenceCategory wakeTurbolenceCategory,
                required WakeTurbulenceGroup wakeTurbolenceGroup,
                required String manufacturer,
                required AircraftDescription description,
                required int engineCount,
                required EngineType engineType,
                Value<bool> userInserted = const Value.absent(),
              }) => IcaoAircraftsCompanion.insert(
                id: id,
                modelFullName: modelFullName,
                designator: designator,
                wakeTurbolenceCategory: wakeTurbolenceCategory,
                wakeTurbolenceGroup: wakeTurbolenceGroup,
                manufacturer: manufacturer,
                description: description,
                engineCount: engineCount,
                engineType: engineType,
                userInserted: userInserted,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$IcaoAircraftsTable, IcaoAircraft>(table),
                  $$IcaoAircraftsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({aircraftsRefs = false, simulatorsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (aircraftsRefs) db.aircrafts,
                    if (simulatorsRefs) db.simulators,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (aircraftsRefs)
                        await $_getPrefetchedData<
                          IcaoAircraft,
                          $IcaoAircraftsTable,
                          Aircraft
                        >(
                          currentTable: table,
                          referencedTable: $$IcaoAircraftsTableReferences
                              ._aircraftsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$IcaoAircraftsTableReferences(
                                db,
                                table,
                                p0,
                              ).aircraftsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.icaoAircraft == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (simulatorsRefs)
                        await $_getPrefetchedData<
                          IcaoAircraft,
                          $IcaoAircraftsTable,
                          Simulator
                        >(
                          currentTable: table,
                          referencedTable: $$IcaoAircraftsTableReferences
                              ._simulatorsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$IcaoAircraftsTableReferences(
                                db,
                                table,
                                p0,
                              ).simulatorsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.icaoAircraft == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$IcaoAircraftsTableProcessedTableManager =
    ProcessedTableManager<
      _$LogbookDatabase,
      $IcaoAircraftsTable,
      IcaoAircraft,
      $$IcaoAircraftsTableFilterComposer,
      $$IcaoAircraftsTableOrderingComposer,
      $$IcaoAircraftsTableAnnotationComposer,
      $$IcaoAircraftsTableCreateCompanionBuilder,
      $$IcaoAircraftsTableUpdateCompanionBuilder,
      (IcaoAircraft, $$IcaoAircraftsTableReferences),
      IcaoAircraft,
      PrefetchHooks Function({bool aircraftsRefs, bool simulatorsRefs})
    >;
typedef $$AircraftsTableCreateCompanionBuilder =
    AircraftsCompanion Function({
      Value<int> id,
      required int icaoAircraft,
      required String tailNumber,
      Value<String?> notes,
      Value<AircraftClass?> aircraftClass,
      Value<String?> typeRating,
      Value<String?> photoFile,
      Value<String?> photoUrl,
      Value<String?> photoThumbnailUrl,
      Value<String?> photoLink,
      Value<String?> photoCredit,
    });
typedef $$AircraftsTableUpdateCompanionBuilder =
    AircraftsCompanion Function({
      Value<int> id,
      Value<int> icaoAircraft,
      Value<String> tailNumber,
      Value<String?> notes,
      Value<AircraftClass?> aircraftClass,
      Value<String?> typeRating,
      Value<String?> photoFile,
      Value<String?> photoUrl,
      Value<String?> photoThumbnailUrl,
      Value<String?> photoLink,
      Value<String?> photoCredit,
    });

final class $$AircraftsTableReferences
    extends BaseReferences<_$LogbookDatabase, $AircraftsTable, Aircraft> {
  $$AircraftsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $IcaoAircraftsTable _icaoAircraftTable(_$LogbookDatabase db) => db
      .icaoAircrafts
      .createAlias('aircrafts__icao_aircraft__icao_aircrafts__id');

  $$IcaoAircraftsTableProcessedTableManager get icaoAircraft {
    final $_column = $_itemColumn<int>('icao_aircraft')!;

    final manager = $$IcaoAircraftsTableTableManager(
      $_db,
      $_db.icaoAircrafts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_icaoAircraftTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$FlightsTable, List<Flight>> _flightsRefsTable(
    _$LogbookDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.flights,
    aliasName: 'aircrafts__id__flights__aircraft_id',
  );

  $$FlightsTableProcessedTableManager get flightsRefs {
    final manager = $$FlightsTableTableManager(
      $_db,
      $_db.flights,
    ).filter((f) => f.aircraftId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_flightsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AircraftsTableFilterComposer
    extends Composer<_$LogbookDatabase, $AircraftsTable> {
  $$AircraftsTableFilterComposer({
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

  ColumnFilters<String> get tailNumber => $composableBuilder(
    column: $table.tailNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AircraftClass?, AircraftClass, String>
  get aircraftClass => $composableBuilder(
    column: $table.aircraftClass,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get typeRating => $composableBuilder(
    column: $table.typeRating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoFile => $composableBuilder(
    column: $table.photoFile,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoThumbnailUrl => $composableBuilder(
    column: $table.photoThumbnailUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoLink => $composableBuilder(
    column: $table.photoLink,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoCredit => $composableBuilder(
    column: $table.photoCredit,
    builder: (column) => ColumnFilters(column),
  );

  $$IcaoAircraftsTableFilterComposer get icaoAircraft {
    final $$IcaoAircraftsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.icaoAircraft,
      referencedTable: $db.icaoAircrafts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IcaoAircraftsTableFilterComposer(
            $db: $db,
            $table: $db.icaoAircrafts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> flightsRefs(
    Expression<bool> Function($$FlightsTableFilterComposer f) f,
  ) {
    final $$FlightsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.flights,
      getReferencedColumn: (t) => t.aircraftId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightsTableFilterComposer(
            $db: $db,
            $table: $db.flights,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AircraftsTableOrderingComposer
    extends Composer<_$LogbookDatabase, $AircraftsTable> {
  $$AircraftsTableOrderingComposer({
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

  ColumnOrderings<String> get tailNumber => $composableBuilder(
    column: $table.tailNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aircraftClass => $composableBuilder(
    column: $table.aircraftClass,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get typeRating => $composableBuilder(
    column: $table.typeRating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoFile => $composableBuilder(
    column: $table.photoFile,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoThumbnailUrl => $composableBuilder(
    column: $table.photoThumbnailUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoLink => $composableBuilder(
    column: $table.photoLink,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoCredit => $composableBuilder(
    column: $table.photoCredit,
    builder: (column) => ColumnOrderings(column),
  );

  $$IcaoAircraftsTableOrderingComposer get icaoAircraft {
    final $$IcaoAircraftsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.icaoAircraft,
      referencedTable: $db.icaoAircrafts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IcaoAircraftsTableOrderingComposer(
            $db: $db,
            $table: $db.icaoAircrafts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AircraftsTableAnnotationComposer
    extends Composer<_$LogbookDatabase, $AircraftsTable> {
  $$AircraftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tailNumber => $composableBuilder(
    column: $table.tailNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AircraftClass?, String> get aircraftClass =>
      $composableBuilder(
        column: $table.aircraftClass,
        builder: (column) => column,
      );

  GeneratedColumn<String> get typeRating => $composableBuilder(
    column: $table.typeRating,
    builder: (column) => column,
  );

  GeneratedColumn<String> get photoFile =>
      $composableBuilder(column: $table.photoFile, builder: (column) => column);

  GeneratedColumn<String> get photoUrl =>
      $composableBuilder(column: $table.photoUrl, builder: (column) => column);

  GeneratedColumn<String> get photoThumbnailUrl => $composableBuilder(
    column: $table.photoThumbnailUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get photoLink =>
      $composableBuilder(column: $table.photoLink, builder: (column) => column);

  GeneratedColumn<String> get photoCredit => $composableBuilder(
    column: $table.photoCredit,
    builder: (column) => column,
  );

  $$IcaoAircraftsTableAnnotationComposer get icaoAircraft {
    final $$IcaoAircraftsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.icaoAircraft,
      referencedTable: $db.icaoAircrafts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IcaoAircraftsTableAnnotationComposer(
            $db: $db,
            $table: $db.icaoAircrafts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> flightsRefs<T extends Object>(
    Expression<T> Function($$FlightsTableAnnotationComposer a) f,
  ) {
    final $$FlightsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.flights,
      getReferencedColumn: (t) => t.aircraftId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightsTableAnnotationComposer(
            $db: $db,
            $table: $db.flights,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AircraftsTableTableManager
    extends
        RootTableManager<
          _$LogbookDatabase,
          $AircraftsTable,
          Aircraft,
          $$AircraftsTableFilterComposer,
          $$AircraftsTableOrderingComposer,
          $$AircraftsTableAnnotationComposer,
          $$AircraftsTableCreateCompanionBuilder,
          $$AircraftsTableUpdateCompanionBuilder,
          (Aircraft, $$AircraftsTableReferences),
          Aircraft,
          PrefetchHooks Function({bool icaoAircraft, bool flightsRefs})
        > {
  $$AircraftsTableTableManager(_$LogbookDatabase db, $AircraftsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AircraftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AircraftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AircraftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> icaoAircraft = const Value.absent(),
                Value<String> tailNumber = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<AircraftClass?> aircraftClass = const Value.absent(),
                Value<String?> typeRating = const Value.absent(),
                Value<String?> photoFile = const Value.absent(),
                Value<String?> photoUrl = const Value.absent(),
                Value<String?> photoThumbnailUrl = const Value.absent(),
                Value<String?> photoLink = const Value.absent(),
                Value<String?> photoCredit = const Value.absent(),
              }) => AircraftsCompanion(
                id: id,
                icaoAircraft: icaoAircraft,
                tailNumber: tailNumber,
                notes: notes,
                aircraftClass: aircraftClass,
                typeRating: typeRating,
                photoFile: photoFile,
                photoUrl: photoUrl,
                photoThumbnailUrl: photoThumbnailUrl,
                photoLink: photoLink,
                photoCredit: photoCredit,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int icaoAircraft,
                required String tailNumber,
                Value<String?> notes = const Value.absent(),
                Value<AircraftClass?> aircraftClass = const Value.absent(),
                Value<String?> typeRating = const Value.absent(),
                Value<String?> photoFile = const Value.absent(),
                Value<String?> photoUrl = const Value.absent(),
                Value<String?> photoThumbnailUrl = const Value.absent(),
                Value<String?> photoLink = const Value.absent(),
                Value<String?> photoCredit = const Value.absent(),
              }) => AircraftsCompanion.insert(
                id: id,
                icaoAircraft: icaoAircraft,
                tailNumber: tailNumber,
                notes: notes,
                aircraftClass: aircraftClass,
                typeRating: typeRating,
                photoFile: photoFile,
                photoUrl: photoUrl,
                photoThumbnailUrl: photoThumbnailUrl,
                photoLink: photoLink,
                photoCredit: photoCredit,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AircraftsTable, Aircraft>(table),
                  $$AircraftsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({icaoAircraft = false, flightsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (flightsRefs) db.flights],
              addJoins:
                  <
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
                    if (icaoAircraft) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.icaoAircraft,
                                referencedTable: $$AircraftsTableReferences
                                    ._icaoAircraftTable(db),
                                referencedColumn: $$AircraftsTableReferences
                                    ._icaoAircraftTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (flightsRefs)
                    await $_getPrefetchedData<
                      Aircraft,
                      $AircraftsTable,
                      Flight
                    >(
                      currentTable: table,
                      referencedTable: $$AircraftsTableReferences
                          ._flightsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$AircraftsTableReferences(db, table, p0).flightsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.aircraftId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$AircraftsTableProcessedTableManager =
    ProcessedTableManager<
      _$LogbookDatabase,
      $AircraftsTable,
      Aircraft,
      $$AircraftsTableFilterComposer,
      $$AircraftsTableOrderingComposer,
      $$AircraftsTableAnnotationComposer,
      $$AircraftsTableCreateCompanionBuilder,
      $$AircraftsTableUpdateCompanionBuilder,
      (Aircraft, $$AircraftsTableReferences),
      Aircraft,
      PrefetchHooks Function({bool icaoAircraft, bool flightsRefs})
    >;
typedef $$SimulatorsTableCreateCompanionBuilder =
    SimulatorsCompanion Function({
      Value<int> id,
      required SimulatorKind kind,
      Value<String?> level,
      Value<int?> icaoAircraft,
      Value<AircraftClass?> aircraftClass,
      Value<String?> typeRating,
      Value<String?> qualificationNumber,
      Value<String?> organisation,
      Value<String?> notes,
    });
typedef $$SimulatorsTableUpdateCompanionBuilder =
    SimulatorsCompanion Function({
      Value<int> id,
      Value<SimulatorKind> kind,
      Value<String?> level,
      Value<int?> icaoAircraft,
      Value<AircraftClass?> aircraftClass,
      Value<String?> typeRating,
      Value<String?> qualificationNumber,
      Value<String?> organisation,
      Value<String?> notes,
    });

final class $$SimulatorsTableReferences
    extends BaseReferences<_$LogbookDatabase, $SimulatorsTable, Simulator> {
  $$SimulatorsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $IcaoAircraftsTable _icaoAircraftTable(_$LogbookDatabase db) => db
      .icaoAircrafts
      .createAlias('simulators__icao_aircraft__icao_aircrafts__id');

  $$IcaoAircraftsTableProcessedTableManager? get icaoAircraft {
    final $_column = $_itemColumn<int>('icao_aircraft');
    if ($_column == null) return null;
    final manager = $$IcaoAircraftsTableTableManager(
      $_db,
      $_db.icaoAircrafts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_icaoAircraftTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$FlightsTable, List<Flight>> _flightsRefsTable(
    _$LogbookDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.flights,
    aliasName: 'simulators__id__flights__simulator_id',
  );

  $$FlightsTableProcessedTableManager get flightsRefs {
    final manager = $$FlightsTableTableManager(
      $_db,
      $_db.flights,
    ).filter((f) => f.simulatorId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_flightsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SimulatorsTableFilterComposer
    extends Composer<_$LogbookDatabase, $SimulatorsTable> {
  $$SimulatorsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<SimulatorKind, SimulatorKind, String>
  get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AircraftClass?, AircraftClass, String>
  get aircraftClass => $composableBuilder(
    column: $table.aircraftClass,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get typeRating => $composableBuilder(
    column: $table.typeRating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get qualificationNumber => $composableBuilder(
    column: $table.qualificationNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get organisation => $composableBuilder(
    column: $table.organisation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  $$IcaoAircraftsTableFilterComposer get icaoAircraft {
    final $$IcaoAircraftsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.icaoAircraft,
      referencedTable: $db.icaoAircrafts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IcaoAircraftsTableFilterComposer(
            $db: $db,
            $table: $db.icaoAircrafts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> flightsRefs(
    Expression<bool> Function($$FlightsTableFilterComposer f) f,
  ) {
    final $$FlightsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.flights,
      getReferencedColumn: (t) => t.simulatorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightsTableFilterComposer(
            $db: $db,
            $table: $db.flights,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SimulatorsTableOrderingComposer
    extends Composer<_$LogbookDatabase, $SimulatorsTable> {
  $$SimulatorsTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aircraftClass => $composableBuilder(
    column: $table.aircraftClass,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get typeRating => $composableBuilder(
    column: $table.typeRating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get qualificationNumber => $composableBuilder(
    column: $table.qualificationNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get organisation => $composableBuilder(
    column: $table.organisation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  $$IcaoAircraftsTableOrderingComposer get icaoAircraft {
    final $$IcaoAircraftsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.icaoAircraft,
      referencedTable: $db.icaoAircrafts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IcaoAircraftsTableOrderingComposer(
            $db: $db,
            $table: $db.icaoAircrafts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SimulatorsTableAnnotationComposer
    extends Composer<_$LogbookDatabase, $SimulatorsTable> {
  $$SimulatorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SimulatorKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AircraftClass?, String> get aircraftClass =>
      $composableBuilder(
        column: $table.aircraftClass,
        builder: (column) => column,
      );

  GeneratedColumn<String> get typeRating => $composableBuilder(
    column: $table.typeRating,
    builder: (column) => column,
  );

  GeneratedColumn<String> get qualificationNumber => $composableBuilder(
    column: $table.qualificationNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get organisation => $composableBuilder(
    column: $table.organisation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $$IcaoAircraftsTableAnnotationComposer get icaoAircraft {
    final $$IcaoAircraftsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.icaoAircraft,
      referencedTable: $db.icaoAircrafts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IcaoAircraftsTableAnnotationComposer(
            $db: $db,
            $table: $db.icaoAircrafts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> flightsRefs<T extends Object>(
    Expression<T> Function($$FlightsTableAnnotationComposer a) f,
  ) {
    final $$FlightsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.flights,
      getReferencedColumn: (t) => t.simulatorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightsTableAnnotationComposer(
            $db: $db,
            $table: $db.flights,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SimulatorsTableTableManager
    extends
        RootTableManager<
          _$LogbookDatabase,
          $SimulatorsTable,
          Simulator,
          $$SimulatorsTableFilterComposer,
          $$SimulatorsTableOrderingComposer,
          $$SimulatorsTableAnnotationComposer,
          $$SimulatorsTableCreateCompanionBuilder,
          $$SimulatorsTableUpdateCompanionBuilder,
          (Simulator, $$SimulatorsTableReferences),
          Simulator,
          PrefetchHooks Function({bool icaoAircraft, bool flightsRefs})
        > {
  $$SimulatorsTableTableManager(_$LogbookDatabase db, $SimulatorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SimulatorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SimulatorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SimulatorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<SimulatorKind> kind = const Value.absent(),
                Value<String?> level = const Value.absent(),
                Value<int?> icaoAircraft = const Value.absent(),
                Value<AircraftClass?> aircraftClass = const Value.absent(),
                Value<String?> typeRating = const Value.absent(),
                Value<String?> qualificationNumber = const Value.absent(),
                Value<String?> organisation = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => SimulatorsCompanion(
                id: id,
                kind: kind,
                level: level,
                icaoAircraft: icaoAircraft,
                aircraftClass: aircraftClass,
                typeRating: typeRating,
                qualificationNumber: qualificationNumber,
                organisation: organisation,
                notes: notes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required SimulatorKind kind,
                Value<String?> level = const Value.absent(),
                Value<int?> icaoAircraft = const Value.absent(),
                Value<AircraftClass?> aircraftClass = const Value.absent(),
                Value<String?> typeRating = const Value.absent(),
                Value<String?> qualificationNumber = const Value.absent(),
                Value<String?> organisation = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => SimulatorsCompanion.insert(
                id: id,
                kind: kind,
                level: level,
                icaoAircraft: icaoAircraft,
                aircraftClass: aircraftClass,
                typeRating: typeRating,
                qualificationNumber: qualificationNumber,
                organisation: organisation,
                notes: notes,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SimulatorsTable, Simulator>(table),
                  $$SimulatorsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({icaoAircraft = false, flightsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (flightsRefs) db.flights],
              addJoins:
                  <
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
                    if (icaoAircraft) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.icaoAircraft,
                                referencedTable: $$SimulatorsTableReferences
                                    ._icaoAircraftTable(db),
                                referencedColumn: $$SimulatorsTableReferences
                                    ._icaoAircraftTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (flightsRefs)
                    await $_getPrefetchedData<
                      Simulator,
                      $SimulatorsTable,
                      Flight
                    >(
                      currentTable: table,
                      referencedTable: $$SimulatorsTableReferences
                          ._flightsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SimulatorsTableReferences(
                            db,
                            table,
                            p0,
                          ).flightsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.simulatorId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SimulatorsTableProcessedTableManager =
    ProcessedTableManager<
      _$LogbookDatabase,
      $SimulatorsTable,
      Simulator,
      $$SimulatorsTableFilterComposer,
      $$SimulatorsTableOrderingComposer,
      $$SimulatorsTableAnnotationComposer,
      $$SimulatorsTableCreateCompanionBuilder,
      $$SimulatorsTableUpdateCompanionBuilder,
      (Simulator, $$SimulatorsTableReferences),
      Simulator,
      PrefetchHooks Function({bool icaoAircraft, bool flightsRefs})
    >;
typedef $$FlightsTableCreateCompanionBuilder =
    FlightsCompanion Function({
      Value<int> id,
      required String title,
      Value<int?> departure,
      Value<int?> arrival,
      required DateTime departureTime,
      Value<DateTime?> arrivalTime,
      Value<String?> departureIanaLocation,
      Value<String?> arrivalIanaLocation,
      required bool isRecording,
      Value<int?> aircraftId,
      Value<int?> simulatorId,
      Value<String?> approachType,
      Value<int?> nightLandings,
      Value<int?> dayLandings,
      Value<String?> flightRules,
      Value<String?> remarks,
      Value<String?> pilotRole,
      Value<int?> instrumentMinutes,
      Value<int?> nightMinutes,
      Value<LogbookOverrides?> logbookOverrides,
      Value<String?> trackSource,
      Value<bool> proficiencyCheck,
      Value<String?> signatureFile,
    });
typedef $$FlightsTableUpdateCompanionBuilder =
    FlightsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<int?> departure,
      Value<int?> arrival,
      Value<DateTime> departureTime,
      Value<DateTime?> arrivalTime,
      Value<String?> departureIanaLocation,
      Value<String?> arrivalIanaLocation,
      Value<bool> isRecording,
      Value<int?> aircraftId,
      Value<int?> simulatorId,
      Value<String?> approachType,
      Value<int?> nightLandings,
      Value<int?> dayLandings,
      Value<String?> flightRules,
      Value<String?> remarks,
      Value<String?> pilotRole,
      Value<int?> instrumentMinutes,
      Value<int?> nightMinutes,
      Value<LogbookOverrides?> logbookOverrides,
      Value<String?> trackSource,
      Value<bool> proficiencyCheck,
      Value<String?> signatureFile,
    });

final class $$FlightsTableReferences
    extends BaseReferences<_$LogbookDatabase, $FlightsTable, Flight> {
  $$FlightsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AirportsTable _departureTable(_$LogbookDatabase db) =>
      db.airports.createAlias('flights__departure__airports__id');

  $$AirportsTableProcessedTableManager? get departure {
    final $_column = $_itemColumn<int>('departure');
    if ($_column == null) return null;
    final manager = $$AirportsTableTableManager(
      $_db,
      $_db.airports,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_departureTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AirportsTable _arrivalTable(_$LogbookDatabase db) =>
      db.airports.createAlias('flights__arrival__airports__id');

  $$AirportsTableProcessedTableManager? get arrival {
    final $_column = $_itemColumn<int>('arrival');
    if ($_column == null) return null;
    final manager = $$AirportsTableTableManager(
      $_db,
      $_db.airports,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_arrivalTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AircraftsTable _aircraftIdTable(_$LogbookDatabase db) =>
      db.aircrafts.createAlias('flights__aircraft_id__aircrafts__id');

  $$AircraftsTableProcessedTableManager? get aircraftId {
    final $_column = $_itemColumn<int>('aircraft_id');
    if ($_column == null) return null;
    final manager = $$AircraftsTableTableManager(
      $_db,
      $_db.aircrafts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_aircraftIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SimulatorsTable _simulatorIdTable(_$LogbookDatabase db) =>
      db.simulators.createAlias('flights__simulator_id__simulators__id');

  $$SimulatorsTableProcessedTableManager? get simulatorId {
    final $_column = $_itemColumn<int>('simulator_id');
    if ($_column == null) return null;
    final manager = $$SimulatorsTableTableManager(
      $_db,
      $_db.simulators,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_simulatorIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$FlightDataPointsTable, List<FlightDataPoint>>
  _flightDataPointsRefsTable(_$LogbookDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.flightDataPoints,
        aliasName: 'flights__id__flight_data_points__flight',
      );

  $$FlightDataPointsTableProcessedTableManager get flightDataPointsRefs {
    final manager = $$FlightDataPointsTableTableManager(
      $_db,
      $_db.flightDataPoints,
    ).filter((f) => f.flight.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _flightDataPointsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FlightCrewTable, List<FlightCrewEntry>>
  _flightCrewRefsTable(_$LogbookDatabase db) => MultiTypedResultKey.fromTable(
    db.flightCrew,
    aliasName: 'flights__id__flight_crew__flight',
  );

  $$FlightCrewTableProcessedTableManager get flightCrewRefs {
    final manager = $$FlightCrewTableTableManager(
      $_db,
      $_db.flightCrew,
    ).filter((f) => f.flight.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_flightCrewRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FlightsTableFilterComposer
    extends Composer<_$LogbookDatabase, $FlightsTable> {
  $$FlightsTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get departureTime => $composableBuilder(
    column: $table.departureTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get arrivalTime => $composableBuilder(
    column: $table.arrivalTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get departureIanaLocation => $composableBuilder(
    column: $table.departureIanaLocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get arrivalIanaLocation => $composableBuilder(
    column: $table.arrivalIanaLocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRecording => $composableBuilder(
    column: $table.isRecording,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get approachType => $composableBuilder(
    column: $table.approachType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nightLandings => $composableBuilder(
    column: $table.nightLandings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayLandings => $composableBuilder(
    column: $table.dayLandings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get flightRules => $composableBuilder(
    column: $table.flightRules,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remarks => $composableBuilder(
    column: $table.remarks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pilotRole => $composableBuilder(
    column: $table.pilotRole,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get instrumentMinutes => $composableBuilder(
    column: $table.instrumentMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nightMinutes => $composableBuilder(
    column: $table.nightMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<LogbookOverrides?, LogbookOverrides, String>
  get logbookOverrides => $composableBuilder(
    column: $table.logbookOverrides,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get trackSource => $composableBuilder(
    column: $table.trackSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get proficiencyCheck => $composableBuilder(
    column: $table.proficiencyCheck,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get signatureFile => $composableBuilder(
    column: $table.signatureFile,
    builder: (column) => ColumnFilters(column),
  );

  $$AirportsTableFilterComposer get departure {
    final $$AirportsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.departure,
      referencedTable: $db.airports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AirportsTableFilterComposer(
            $db: $db,
            $table: $db.airports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AirportsTableFilterComposer get arrival {
    final $$AirportsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.arrival,
      referencedTable: $db.airports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AirportsTableFilterComposer(
            $db: $db,
            $table: $db.airports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AircraftsTableFilterComposer get aircraftId {
    final $$AircraftsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.aircraftId,
      referencedTable: $db.aircrafts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AircraftsTableFilterComposer(
            $db: $db,
            $table: $db.aircrafts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SimulatorsTableFilterComposer get simulatorId {
    final $$SimulatorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.simulatorId,
      referencedTable: $db.simulators,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SimulatorsTableFilterComposer(
            $db: $db,
            $table: $db.simulators,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> flightDataPointsRefs(
    Expression<bool> Function($$FlightDataPointsTableFilterComposer f) f,
  ) {
    final $$FlightDataPointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.flightDataPoints,
      getReferencedColumn: (t) => t.flight,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightDataPointsTableFilterComposer(
            $db: $db,
            $table: $db.flightDataPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> flightCrewRefs(
    Expression<bool> Function($$FlightCrewTableFilterComposer f) f,
  ) {
    final $$FlightCrewTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.flightCrew,
      getReferencedColumn: (t) => t.flight,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightCrewTableFilterComposer(
            $db: $db,
            $table: $db.flightCrew,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FlightsTableOrderingComposer
    extends Composer<_$LogbookDatabase, $FlightsTable> {
  $$FlightsTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get departureTime => $composableBuilder(
    column: $table.departureTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get arrivalTime => $composableBuilder(
    column: $table.arrivalTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get departureIanaLocation => $composableBuilder(
    column: $table.departureIanaLocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get arrivalIanaLocation => $composableBuilder(
    column: $table.arrivalIanaLocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRecording => $composableBuilder(
    column: $table.isRecording,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get approachType => $composableBuilder(
    column: $table.approachType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nightLandings => $composableBuilder(
    column: $table.nightLandings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayLandings => $composableBuilder(
    column: $table.dayLandings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get flightRules => $composableBuilder(
    column: $table.flightRules,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remarks => $composableBuilder(
    column: $table.remarks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pilotRole => $composableBuilder(
    column: $table.pilotRole,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get instrumentMinutes => $composableBuilder(
    column: $table.instrumentMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nightMinutes => $composableBuilder(
    column: $table.nightMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logbookOverrides => $composableBuilder(
    column: $table.logbookOverrides,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackSource => $composableBuilder(
    column: $table.trackSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get proficiencyCheck => $composableBuilder(
    column: $table.proficiencyCheck,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get signatureFile => $composableBuilder(
    column: $table.signatureFile,
    builder: (column) => ColumnOrderings(column),
  );

  $$AirportsTableOrderingComposer get departure {
    final $$AirportsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.departure,
      referencedTable: $db.airports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AirportsTableOrderingComposer(
            $db: $db,
            $table: $db.airports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AirportsTableOrderingComposer get arrival {
    final $$AirportsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.arrival,
      referencedTable: $db.airports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AirportsTableOrderingComposer(
            $db: $db,
            $table: $db.airports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AircraftsTableOrderingComposer get aircraftId {
    final $$AircraftsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.aircraftId,
      referencedTable: $db.aircrafts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AircraftsTableOrderingComposer(
            $db: $db,
            $table: $db.aircrafts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SimulatorsTableOrderingComposer get simulatorId {
    final $$SimulatorsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.simulatorId,
      referencedTable: $db.simulators,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SimulatorsTableOrderingComposer(
            $db: $db,
            $table: $db.simulators,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FlightsTableAnnotationComposer
    extends Composer<_$LogbookDatabase, $FlightsTable> {
  $$FlightsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get departureTime => $composableBuilder(
    column: $table.departureTime,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get arrivalTime => $composableBuilder(
    column: $table.arrivalTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get departureIanaLocation => $composableBuilder(
    column: $table.departureIanaLocation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get arrivalIanaLocation => $composableBuilder(
    column: $table.arrivalIanaLocation,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isRecording => $composableBuilder(
    column: $table.isRecording,
    builder: (column) => column,
  );

  GeneratedColumn<String> get approachType => $composableBuilder(
    column: $table.approachType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get nightLandings => $composableBuilder(
    column: $table.nightLandings,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dayLandings => $composableBuilder(
    column: $table.dayLandings,
    builder: (column) => column,
  );

  GeneratedColumn<String> get flightRules => $composableBuilder(
    column: $table.flightRules,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remarks =>
      $composableBuilder(column: $table.remarks, builder: (column) => column);

  GeneratedColumn<String> get pilotRole =>
      $composableBuilder(column: $table.pilotRole, builder: (column) => column);

  GeneratedColumn<int> get instrumentMinutes => $composableBuilder(
    column: $table.instrumentMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get nightMinutes => $composableBuilder(
    column: $table.nightMinutes,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<LogbookOverrides?, String>
  get logbookOverrides => $composableBuilder(
    column: $table.logbookOverrides,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trackSource => $composableBuilder(
    column: $table.trackSource,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get proficiencyCheck => $composableBuilder(
    column: $table.proficiencyCheck,
    builder: (column) => column,
  );

  GeneratedColumn<String> get signatureFile => $composableBuilder(
    column: $table.signatureFile,
    builder: (column) => column,
  );

  $$AirportsTableAnnotationComposer get departure {
    final $$AirportsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.departure,
      referencedTable: $db.airports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AirportsTableAnnotationComposer(
            $db: $db,
            $table: $db.airports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AirportsTableAnnotationComposer get arrival {
    final $$AirportsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.arrival,
      referencedTable: $db.airports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AirportsTableAnnotationComposer(
            $db: $db,
            $table: $db.airports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AircraftsTableAnnotationComposer get aircraftId {
    final $$AircraftsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.aircraftId,
      referencedTable: $db.aircrafts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AircraftsTableAnnotationComposer(
            $db: $db,
            $table: $db.aircrafts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SimulatorsTableAnnotationComposer get simulatorId {
    final $$SimulatorsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.simulatorId,
      referencedTable: $db.simulators,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SimulatorsTableAnnotationComposer(
            $db: $db,
            $table: $db.simulators,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> flightDataPointsRefs<T extends Object>(
    Expression<T> Function($$FlightDataPointsTableAnnotationComposer a) f,
  ) {
    final $$FlightDataPointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.flightDataPoints,
      getReferencedColumn: (t) => t.flight,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightDataPointsTableAnnotationComposer(
            $db: $db,
            $table: $db.flightDataPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> flightCrewRefs<T extends Object>(
    Expression<T> Function($$FlightCrewTableAnnotationComposer a) f,
  ) {
    final $$FlightCrewTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.flightCrew,
      getReferencedColumn: (t) => t.flight,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightCrewTableAnnotationComposer(
            $db: $db,
            $table: $db.flightCrew,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FlightsTableTableManager
    extends
        RootTableManager<
          _$LogbookDatabase,
          $FlightsTable,
          Flight,
          $$FlightsTableFilterComposer,
          $$FlightsTableOrderingComposer,
          $$FlightsTableAnnotationComposer,
          $$FlightsTableCreateCompanionBuilder,
          $$FlightsTableUpdateCompanionBuilder,
          (Flight, $$FlightsTableReferences),
          Flight,
          PrefetchHooks Function({
            bool departure,
            bool arrival,
            bool aircraftId,
            bool simulatorId,
            bool flightDataPointsRefs,
            bool flightCrewRefs,
          })
        > {
  $$FlightsTableTableManager(_$LogbookDatabase db, $FlightsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FlightsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FlightsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FlightsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int?> departure = const Value.absent(),
                Value<int?> arrival = const Value.absent(),
                Value<DateTime> departureTime = const Value.absent(),
                Value<DateTime?> arrivalTime = const Value.absent(),
                Value<String?> departureIanaLocation = const Value.absent(),
                Value<String?> arrivalIanaLocation = const Value.absent(),
                Value<bool> isRecording = const Value.absent(),
                Value<int?> aircraftId = const Value.absent(),
                Value<int?> simulatorId = const Value.absent(),
                Value<String?> approachType = const Value.absent(),
                Value<int?> nightLandings = const Value.absent(),
                Value<int?> dayLandings = const Value.absent(),
                Value<String?> flightRules = const Value.absent(),
                Value<String?> remarks = const Value.absent(),
                Value<String?> pilotRole = const Value.absent(),
                Value<int?> instrumentMinutes = const Value.absent(),
                Value<int?> nightMinutes = const Value.absent(),
                Value<LogbookOverrides?> logbookOverrides =
                    const Value.absent(),
                Value<String?> trackSource = const Value.absent(),
                Value<bool> proficiencyCheck = const Value.absent(),
                Value<String?> signatureFile = const Value.absent(),
              }) => FlightsCompanion(
                id: id,
                title: title,
                departure: departure,
                arrival: arrival,
                departureTime: departureTime,
                arrivalTime: arrivalTime,
                departureIanaLocation: departureIanaLocation,
                arrivalIanaLocation: arrivalIanaLocation,
                isRecording: isRecording,
                aircraftId: aircraftId,
                simulatorId: simulatorId,
                approachType: approachType,
                nightLandings: nightLandings,
                dayLandings: dayLandings,
                flightRules: flightRules,
                remarks: remarks,
                pilotRole: pilotRole,
                instrumentMinutes: instrumentMinutes,
                nightMinutes: nightMinutes,
                logbookOverrides: logbookOverrides,
                trackSource: trackSource,
                proficiencyCheck: proficiencyCheck,
                signatureFile: signatureFile,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<int?> departure = const Value.absent(),
                Value<int?> arrival = const Value.absent(),
                required DateTime departureTime,
                Value<DateTime?> arrivalTime = const Value.absent(),
                Value<String?> departureIanaLocation = const Value.absent(),
                Value<String?> arrivalIanaLocation = const Value.absent(),
                required bool isRecording,
                Value<int?> aircraftId = const Value.absent(),
                Value<int?> simulatorId = const Value.absent(),
                Value<String?> approachType = const Value.absent(),
                Value<int?> nightLandings = const Value.absent(),
                Value<int?> dayLandings = const Value.absent(),
                Value<String?> flightRules = const Value.absent(),
                Value<String?> remarks = const Value.absent(),
                Value<String?> pilotRole = const Value.absent(),
                Value<int?> instrumentMinutes = const Value.absent(),
                Value<int?> nightMinutes = const Value.absent(),
                Value<LogbookOverrides?> logbookOverrides =
                    const Value.absent(),
                Value<String?> trackSource = const Value.absent(),
                Value<bool> proficiencyCheck = const Value.absent(),
                Value<String?> signatureFile = const Value.absent(),
              }) => FlightsCompanion.insert(
                id: id,
                title: title,
                departure: departure,
                arrival: arrival,
                departureTime: departureTime,
                arrivalTime: arrivalTime,
                departureIanaLocation: departureIanaLocation,
                arrivalIanaLocation: arrivalIanaLocation,
                isRecording: isRecording,
                aircraftId: aircraftId,
                simulatorId: simulatorId,
                approachType: approachType,
                nightLandings: nightLandings,
                dayLandings: dayLandings,
                flightRules: flightRules,
                remarks: remarks,
                pilotRole: pilotRole,
                instrumentMinutes: instrumentMinutes,
                nightMinutes: nightMinutes,
                logbookOverrides: logbookOverrides,
                trackSource: trackSource,
                proficiencyCheck: proficiencyCheck,
                signatureFile: signatureFile,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FlightsTable, Flight>(table),
                  $$FlightsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                departure = false,
                arrival = false,
                aircraftId = false,
                simulatorId = false,
                flightDataPointsRefs = false,
                flightCrewRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (flightDataPointsRefs) db.flightDataPoints,
                    if (flightCrewRefs) db.flightCrew,
                  ],
                  addJoins:
                      <
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
                        if (departure) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.departure,
                                    referencedTable: $$FlightsTableReferences
                                        ._departureTable(db),
                                    referencedColumn: $$FlightsTableReferences
                                        ._departureTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (arrival) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.arrival,
                                    referencedTable: $$FlightsTableReferences
                                        ._arrivalTable(db),
                                    referencedColumn: $$FlightsTableReferences
                                        ._arrivalTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (aircraftId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.aircraftId,
                                    referencedTable: $$FlightsTableReferences
                                        ._aircraftIdTable(db),
                                    referencedColumn: $$FlightsTableReferences
                                        ._aircraftIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (simulatorId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.simulatorId,
                                    referencedTable: $$FlightsTableReferences
                                        ._simulatorIdTable(db),
                                    referencedColumn: $$FlightsTableReferences
                                        ._simulatorIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (flightDataPointsRefs)
                        await $_getPrefetchedData<
                          Flight,
                          $FlightsTable,
                          FlightDataPoint
                        >(
                          currentTable: table,
                          referencedTable: $$FlightsTableReferences
                              ._flightDataPointsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FlightsTableReferences(
                                db,
                                table,
                                p0,
                              ).flightDataPointsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.flight == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (flightCrewRefs)
                        await $_getPrefetchedData<
                          Flight,
                          $FlightsTable,
                          FlightCrewEntry
                        >(
                          currentTable: table,
                          referencedTable: $$FlightsTableReferences
                              ._flightCrewRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FlightsTableReferences(
                                db,
                                table,
                                p0,
                              ).flightCrewRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.flight == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$FlightsTableProcessedTableManager =
    ProcessedTableManager<
      _$LogbookDatabase,
      $FlightsTable,
      Flight,
      $$FlightsTableFilterComposer,
      $$FlightsTableOrderingComposer,
      $$FlightsTableAnnotationComposer,
      $$FlightsTableCreateCompanionBuilder,
      $$FlightsTableUpdateCompanionBuilder,
      (Flight, $$FlightsTableReferences),
      Flight,
      PrefetchHooks Function({
        bool departure,
        bool arrival,
        bool aircraftId,
        bool simulatorId,
        bool flightDataPointsRefs,
        bool flightCrewRefs,
      })
    >;
typedef $$FlightDataPointsTableCreateCompanionBuilder =
    FlightDataPointsCompanion Function({
      Value<int> id,
      required int flight,
      required double longitude,
      required double latitude,
      required int altitude,
      required DateTime timestamp,
      Value<double?> speed,
      Value<double?> heading,
    });
typedef $$FlightDataPointsTableUpdateCompanionBuilder =
    FlightDataPointsCompanion Function({
      Value<int> id,
      Value<int> flight,
      Value<double> longitude,
      Value<double> latitude,
      Value<int> altitude,
      Value<DateTime> timestamp,
      Value<double?> speed,
      Value<double?> heading,
    });

final class $$FlightDataPointsTableReferences
    extends
        BaseReferences<
          _$LogbookDatabase,
          $FlightDataPointsTable,
          FlightDataPoint
        > {
  $$FlightDataPointsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $FlightsTable _flightTable(_$LogbookDatabase db) =>
      db.flights.createAlias('flight_data_points__flight__flights__id');

  $$FlightsTableProcessedTableManager get flight {
    final $_column = $_itemColumn<int>('flight')!;

    final manager = $$FlightsTableTableManager(
      $_db,
      $_db.flights,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_flightTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FlightDataPointsTableFilterComposer
    extends Composer<_$LogbookDatabase, $FlightDataPointsTable> {
  $$FlightDataPointsTableFilterComposer({
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

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get altitude => $composableBuilder(
    column: $table.altitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get heading => $composableBuilder(
    column: $table.heading,
    builder: (column) => ColumnFilters(column),
  );

  $$FlightsTableFilterComposer get flight {
    final $$FlightsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.flight,
      referencedTable: $db.flights,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightsTableFilterComposer(
            $db: $db,
            $table: $db.flights,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FlightDataPointsTableOrderingComposer
    extends Composer<_$LogbookDatabase, $FlightDataPointsTable> {
  $$FlightDataPointsTableOrderingComposer({
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

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get altitude => $composableBuilder(
    column: $table.altitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heading => $composableBuilder(
    column: $table.heading,
    builder: (column) => ColumnOrderings(column),
  );

  $$FlightsTableOrderingComposer get flight {
    final $$FlightsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.flight,
      referencedTable: $db.flights,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightsTableOrderingComposer(
            $db: $db,
            $table: $db.flights,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FlightDataPointsTableAnnotationComposer
    extends Composer<_$LogbookDatabase, $FlightDataPointsTable> {
  $$FlightDataPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<int> get altitude =>
      $composableBuilder(column: $table.altitude, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<double> get speed =>
      $composableBuilder(column: $table.speed, builder: (column) => column);

  GeneratedColumn<double> get heading =>
      $composableBuilder(column: $table.heading, builder: (column) => column);

  $$FlightsTableAnnotationComposer get flight {
    final $$FlightsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.flight,
      referencedTable: $db.flights,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightsTableAnnotationComposer(
            $db: $db,
            $table: $db.flights,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FlightDataPointsTableTableManager
    extends
        RootTableManager<
          _$LogbookDatabase,
          $FlightDataPointsTable,
          FlightDataPoint,
          $$FlightDataPointsTableFilterComposer,
          $$FlightDataPointsTableOrderingComposer,
          $$FlightDataPointsTableAnnotationComposer,
          $$FlightDataPointsTableCreateCompanionBuilder,
          $$FlightDataPointsTableUpdateCompanionBuilder,
          (FlightDataPoint, $$FlightDataPointsTableReferences),
          FlightDataPoint,
          PrefetchHooks Function({bool flight})
        > {
  $$FlightDataPointsTableTableManager(
    _$LogbookDatabase db,
    $FlightDataPointsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FlightDataPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FlightDataPointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FlightDataPointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> flight = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<int> altitude = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<double?> speed = const Value.absent(),
                Value<double?> heading = const Value.absent(),
              }) => FlightDataPointsCompanion(
                id: id,
                flight: flight,
                longitude: longitude,
                latitude: latitude,
                altitude: altitude,
                timestamp: timestamp,
                speed: speed,
                heading: heading,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int flight,
                required double longitude,
                required double latitude,
                required int altitude,
                required DateTime timestamp,
                Value<double?> speed = const Value.absent(),
                Value<double?> heading = const Value.absent(),
              }) => FlightDataPointsCompanion.insert(
                id: id,
                flight: flight,
                longitude: longitude,
                latitude: latitude,
                altitude: altitude,
                timestamp: timestamp,
                speed: speed,
                heading: heading,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FlightDataPointsTable, FlightDataPoint>(table),
                  $$FlightDataPointsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({flight = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                    if (flight) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.flight,
                                referencedTable:
                                    $$FlightDataPointsTableReferences
                                        ._flightTable(db),
                                referencedColumn:
                                    $$FlightDataPointsTableReferences
                                        ._flightTable(db)
                                        .id,
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

typedef $$FlightDataPointsTableProcessedTableManager =
    ProcessedTableManager<
      _$LogbookDatabase,
      $FlightDataPointsTable,
      FlightDataPoint,
      $$FlightDataPointsTableFilterComposer,
      $$FlightDataPointsTableOrderingComposer,
      $$FlightDataPointsTableAnnotationComposer,
      $$FlightDataPointsTableCreateCompanionBuilder,
      $$FlightDataPointsTableUpdateCompanionBuilder,
      (FlightDataPoint, $$FlightDataPointsTableReferences),
      FlightDataPoint,
      PrefetchHooks Function({bool flight})
    >;
typedef $$PeopleTableCreateCompanionBuilder =
    PeopleCompanion Function({
      Value<int> id,
      required String name,
      required String surname,
      Value<String?> photo,
    });
typedef $$PeopleTableUpdateCompanionBuilder =
    PeopleCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> surname,
      Value<String?> photo,
    });

final class $$PeopleTableReferences
    extends BaseReferences<_$LogbookDatabase, $PeopleTable, Person> {
  $$PeopleTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$FlightCrewTable, List<FlightCrewEntry>>
  _flightCrewRefsTable(_$LogbookDatabase db) => MultiTypedResultKey.fromTable(
    db.flightCrew,
    aliasName: 'people__id__flight_crew__person',
  );

  $$FlightCrewTableProcessedTableManager get flightCrewRefs {
    final manager = $$FlightCrewTableTableManager(
      $_db,
      $_db.flightCrew,
    ).filter((f) => f.person.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_flightCrewRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PeopleTableFilterComposer
    extends Composer<_$LogbookDatabase, $PeopleTable> {
  $$PeopleTableFilterComposer({
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

  ColumnFilters<String> get surname => $composableBuilder(
    column: $table.surname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photo => $composableBuilder(
    column: $table.photo,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> flightCrewRefs(
    Expression<bool> Function($$FlightCrewTableFilterComposer f) f,
  ) {
    final $$FlightCrewTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.flightCrew,
      getReferencedColumn: (t) => t.person,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightCrewTableFilterComposer(
            $db: $db,
            $table: $db.flightCrew,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PeopleTableOrderingComposer
    extends Composer<_$LogbookDatabase, $PeopleTable> {
  $$PeopleTableOrderingComposer({
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

  ColumnOrderings<String> get surname => $composableBuilder(
    column: $table.surname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photo => $composableBuilder(
    column: $table.photo,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PeopleTableAnnotationComposer
    extends Composer<_$LogbookDatabase, $PeopleTable> {
  $$PeopleTableAnnotationComposer({
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

  GeneratedColumn<String> get surname =>
      $composableBuilder(column: $table.surname, builder: (column) => column);

  GeneratedColumn<String> get photo =>
      $composableBuilder(column: $table.photo, builder: (column) => column);

  Expression<T> flightCrewRefs<T extends Object>(
    Expression<T> Function($$FlightCrewTableAnnotationComposer a) f,
  ) {
    final $$FlightCrewTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.flightCrew,
      getReferencedColumn: (t) => t.person,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightCrewTableAnnotationComposer(
            $db: $db,
            $table: $db.flightCrew,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PeopleTableTableManager
    extends
        RootTableManager<
          _$LogbookDatabase,
          $PeopleTable,
          Person,
          $$PeopleTableFilterComposer,
          $$PeopleTableOrderingComposer,
          $$PeopleTableAnnotationComposer,
          $$PeopleTableCreateCompanionBuilder,
          $$PeopleTableUpdateCompanionBuilder,
          (Person, $$PeopleTableReferences),
          Person,
          PrefetchHooks Function({bool flightCrewRefs})
        > {
  $$PeopleTableTableManager(_$LogbookDatabase db, $PeopleTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeopleTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeopleTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeopleTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> surname = const Value.absent(),
                Value<String?> photo = const Value.absent(),
              }) => PeopleCompanion(
                id: id,
                name: name,
                surname: surname,
                photo: photo,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String surname,
                Value<String?> photo = const Value.absent(),
              }) => PeopleCompanion.insert(
                id: id,
                name: name,
                surname: surname,
                photo: photo,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PeopleTable, Person>(table),
                  $$PeopleTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({flightCrewRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (flightCrewRefs) db.flightCrew],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (flightCrewRefs)
                    await $_getPrefetchedData<
                      Person,
                      $PeopleTable,
                      FlightCrewEntry
                    >(
                      currentTable: table,
                      referencedTable: $$PeopleTableReferences
                          ._flightCrewRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PeopleTableReferences(db, table, p0).flightCrewRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.person == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PeopleTableProcessedTableManager =
    ProcessedTableManager<
      _$LogbookDatabase,
      $PeopleTable,
      Person,
      $$PeopleTableFilterComposer,
      $$PeopleTableOrderingComposer,
      $$PeopleTableAnnotationComposer,
      $$PeopleTableCreateCompanionBuilder,
      $$PeopleTableUpdateCompanionBuilder,
      (Person, $$PeopleTableReferences),
      Person,
      PrefetchHooks Function({bool flightCrewRefs})
    >;
typedef $$FlightCrewTableCreateCompanionBuilder =
    FlightCrewCompanion Function({
      required int flight,
      required int person,
      required CrewRole role,
      Value<int> rowid,
    });
typedef $$FlightCrewTableUpdateCompanionBuilder =
    FlightCrewCompanion Function({
      Value<int> flight,
      Value<int> person,
      Value<CrewRole> role,
      Value<int> rowid,
    });

final class $$FlightCrewTableReferences
    extends
        BaseReferences<_$LogbookDatabase, $FlightCrewTable, FlightCrewEntry> {
  $$FlightCrewTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FlightsTable _flightTable(_$LogbookDatabase db) =>
      db.flights.createAlias('flight_crew__flight__flights__id');

  $$FlightsTableProcessedTableManager get flight {
    final $_column = $_itemColumn<int>('flight')!;

    final manager = $$FlightsTableTableManager(
      $_db,
      $_db.flights,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_flightTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PeopleTable _personTable(_$LogbookDatabase db) =>
      db.people.createAlias('flight_crew__person__people__id');

  $$PeopleTableProcessedTableManager get person {
    final $_column = $_itemColumn<int>('person')!;

    final manager = $$PeopleTableTableManager(
      $_db,
      $_db.people,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FlightCrewTableFilterComposer
    extends Composer<_$LogbookDatabase, $FlightCrewTable> {
  $$FlightCrewTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<CrewRole, CrewRole, String> get role =>
      $composableBuilder(
        column: $table.role,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$FlightsTableFilterComposer get flight {
    final $$FlightsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.flight,
      referencedTable: $db.flights,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightsTableFilterComposer(
            $db: $db,
            $table: $db.flights,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PeopleTableFilterComposer get person {
    final $$PeopleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.person,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableFilterComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FlightCrewTableOrderingComposer
    extends Composer<_$LogbookDatabase, $FlightCrewTable> {
  $$FlightCrewTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  $$FlightsTableOrderingComposer get flight {
    final $$FlightsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.flight,
      referencedTable: $db.flights,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightsTableOrderingComposer(
            $db: $db,
            $table: $db.flights,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PeopleTableOrderingComposer get person {
    final $$PeopleTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.person,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableOrderingComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FlightCrewTableAnnotationComposer
    extends Composer<_$LogbookDatabase, $FlightCrewTable> {
  $$FlightCrewTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<CrewRole, String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  $$FlightsTableAnnotationComposer get flight {
    final $$FlightsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.flight,
      referencedTable: $db.flights,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightsTableAnnotationComposer(
            $db: $db,
            $table: $db.flights,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PeopleTableAnnotationComposer get person {
    final $$PeopleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.person,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableAnnotationComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FlightCrewTableTableManager
    extends
        RootTableManager<
          _$LogbookDatabase,
          $FlightCrewTable,
          FlightCrewEntry,
          $$FlightCrewTableFilterComposer,
          $$FlightCrewTableOrderingComposer,
          $$FlightCrewTableAnnotationComposer,
          $$FlightCrewTableCreateCompanionBuilder,
          $$FlightCrewTableUpdateCompanionBuilder,
          (FlightCrewEntry, $$FlightCrewTableReferences),
          FlightCrewEntry,
          PrefetchHooks Function({bool flight, bool person})
        > {
  $$FlightCrewTableTableManager(_$LogbookDatabase db, $FlightCrewTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FlightCrewTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FlightCrewTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FlightCrewTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> flight = const Value.absent(),
                Value<int> person = const Value.absent(),
                Value<CrewRole> role = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FlightCrewCompanion(
                flight: flight,
                person: person,
                role: role,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int flight,
                required int person,
                required CrewRole role,
                Value<int> rowid = const Value.absent(),
              }) => FlightCrewCompanion.insert(
                flight: flight,
                person: person,
                role: role,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FlightCrewTable, FlightCrewEntry>(table),
                  $$FlightCrewTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({flight = false, person = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                    if (flight) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.flight,
                                referencedTable: $$FlightCrewTableReferences
                                    ._flightTable(db),
                                referencedColumn: $$FlightCrewTableReferences
                                    ._flightTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (person) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.person,
                                referencedTable: $$FlightCrewTableReferences
                                    ._personTable(db),
                                referencedColumn: $$FlightCrewTableReferences
                                    ._personTable(db)
                                    .id,
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

typedef $$FlightCrewTableProcessedTableManager =
    ProcessedTableManager<
      _$LogbookDatabase,
      $FlightCrewTable,
      FlightCrewEntry,
      $$FlightCrewTableFilterComposer,
      $$FlightCrewTableOrderingComposer,
      $$FlightCrewTableAnnotationComposer,
      $$FlightCrewTableCreateCompanionBuilder,
      $$FlightCrewTableUpdateCompanionBuilder,
      (FlightCrewEntry, $$FlightCrewTableReferences),
      FlightCrewEntry,
      PrefetchHooks Function({bool flight, bool person})
    >;
typedef $$LicencesTableCreateCompanionBuilder =
    LicencesCompanion Function({
      Value<int> id,
      required LicenceKind kind,
      required AircraftCategory category,
      Value<String?> number,
      Value<String?> issuedBy,
      Value<DateTime?> issueDate,
      Value<DateTime?> proficiencyCheckDate,
      Value<String?> notes,
    });
typedef $$LicencesTableUpdateCompanionBuilder =
    LicencesCompanion Function({
      Value<int> id,
      Value<LicenceKind> kind,
      Value<AircraftCategory> category,
      Value<String?> number,
      Value<String?> issuedBy,
      Value<DateTime?> issueDate,
      Value<DateTime?> proficiencyCheckDate,
      Value<String?> notes,
    });

final class $$LicencesTableReferences
    extends BaseReferences<_$LogbookDatabase, $LicencesTable, Licence> {
  $$LicencesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LicenceRatingsTable, List<LicenceRating>>
  _licenceRatingsRefsTable(_$LogbookDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.licenceRatings,
        aliasName: 'licences__id__licence_ratings__licence',
      );

  $$LicenceRatingsTableProcessedTableManager get licenceRatingsRefs {
    final manager = $$LicenceRatingsTableTableManager(
      $_db,
      $_db.licenceRatings,
    ).filter((f) => f.licence.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_licenceRatingsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LicencesTableFilterComposer
    extends Composer<_$LogbookDatabase, $LicencesTable> {
  $$LicencesTableFilterComposer({
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

  ColumnWithTypeConverterFilters<LicenceKind, LicenceKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<AircraftCategory, AircraftCategory, String>
  get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get issuedBy => $composableBuilder(
    column: $table.issuedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get issueDate => $composableBuilder(
    column: $table.issueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get proficiencyCheckDate => $composableBuilder(
    column: $table.proficiencyCheckDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> licenceRatingsRefs(
    Expression<bool> Function($$LicenceRatingsTableFilterComposer f) f,
  ) {
    final $$LicenceRatingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.licenceRatings,
      getReferencedColumn: (t) => t.licence,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LicenceRatingsTableFilterComposer(
            $db: $db,
            $table: $db.licenceRatings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LicencesTableOrderingComposer
    extends Composer<_$LogbookDatabase, $LicencesTable> {
  $$LicencesTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get issuedBy => $composableBuilder(
    column: $table.issuedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get issueDate => $composableBuilder(
    column: $table.issueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get proficiencyCheckDate => $composableBuilder(
    column: $table.proficiencyCheckDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LicencesTableAnnotationComposer
    extends Composer<_$LogbookDatabase, $LicencesTable> {
  $$LicencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LicenceKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AircraftCategory, String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get issuedBy =>
      $composableBuilder(column: $table.issuedBy, builder: (column) => column);

  GeneratedColumn<DateTime> get issueDate =>
      $composableBuilder(column: $table.issueDate, builder: (column) => column);

  GeneratedColumn<DateTime> get proficiencyCheckDate => $composableBuilder(
    column: $table.proficiencyCheckDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  Expression<T> licenceRatingsRefs<T extends Object>(
    Expression<T> Function($$LicenceRatingsTableAnnotationComposer a) f,
  ) {
    final $$LicenceRatingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.licenceRatings,
      getReferencedColumn: (t) => t.licence,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LicenceRatingsTableAnnotationComposer(
            $db: $db,
            $table: $db.licenceRatings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LicencesTableTableManager
    extends
        RootTableManager<
          _$LogbookDatabase,
          $LicencesTable,
          Licence,
          $$LicencesTableFilterComposer,
          $$LicencesTableOrderingComposer,
          $$LicencesTableAnnotationComposer,
          $$LicencesTableCreateCompanionBuilder,
          $$LicencesTableUpdateCompanionBuilder,
          (Licence, $$LicencesTableReferences),
          Licence,
          PrefetchHooks Function({bool licenceRatingsRefs})
        > {
  $$LicencesTableTableManager(_$LogbookDatabase db, $LicencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LicencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LicencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LicencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<LicenceKind> kind = const Value.absent(),
                Value<AircraftCategory> category = const Value.absent(),
                Value<String?> number = const Value.absent(),
                Value<String?> issuedBy = const Value.absent(),
                Value<DateTime?> issueDate = const Value.absent(),
                Value<DateTime?> proficiencyCheckDate = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => LicencesCompanion(
                id: id,
                kind: kind,
                category: category,
                number: number,
                issuedBy: issuedBy,
                issueDate: issueDate,
                proficiencyCheckDate: proficiencyCheckDate,
                notes: notes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required LicenceKind kind,
                required AircraftCategory category,
                Value<String?> number = const Value.absent(),
                Value<String?> issuedBy = const Value.absent(),
                Value<DateTime?> issueDate = const Value.absent(),
                Value<DateTime?> proficiencyCheckDate = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => LicencesCompanion.insert(
                id: id,
                kind: kind,
                category: category,
                number: number,
                issuedBy: issuedBy,
                issueDate: issueDate,
                proficiencyCheckDate: proficiencyCheckDate,
                notes: notes,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LicencesTable, Licence>(table),
                  $$LicencesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({licenceRatingsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (licenceRatingsRefs) db.licenceRatings,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (licenceRatingsRefs)
                    await $_getPrefetchedData<
                      Licence,
                      $LicencesTable,
                      LicenceRating
                    >(
                      currentTable: table,
                      referencedTable: $$LicencesTableReferences
                          ._licenceRatingsRefsTable(db),
                      managerFromTypedResult: (p0) => $$LicencesTableReferences(
                        db,
                        table,
                        p0,
                      ).licenceRatingsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.licence == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$LicencesTableProcessedTableManager =
    ProcessedTableManager<
      _$LogbookDatabase,
      $LicencesTable,
      Licence,
      $$LicencesTableFilterComposer,
      $$LicencesTableOrderingComposer,
      $$LicencesTableAnnotationComposer,
      $$LicencesTableCreateCompanionBuilder,
      $$LicencesTableUpdateCompanionBuilder,
      (Licence, $$LicencesTableReferences),
      Licence,
      PrefetchHooks Function({bool licenceRatingsRefs})
    >;
typedef $$LicenceRatingsTableCreateCompanionBuilder =
    LicenceRatingsCompanion Function({
      Value<int> id,
      required int licence,
      required RatingKind kind,
      Value<AircraftClass?> aircraftClass,
      Value<String?> name,
      Value<int?> level,
      Value<DateTime?> issueDate,
      Value<DateTime?> lastCheckDate,
      Value<DateTime?> expiryDate,
      Value<String?> notes,
    });
typedef $$LicenceRatingsTableUpdateCompanionBuilder =
    LicenceRatingsCompanion Function({
      Value<int> id,
      Value<int> licence,
      Value<RatingKind> kind,
      Value<AircraftClass?> aircraftClass,
      Value<String?> name,
      Value<int?> level,
      Value<DateTime?> issueDate,
      Value<DateTime?> lastCheckDate,
      Value<DateTime?> expiryDate,
      Value<String?> notes,
    });

final class $$LicenceRatingsTableReferences
    extends
        BaseReferences<_$LogbookDatabase, $LicenceRatingsTable, LicenceRating> {
  $$LicenceRatingsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LicencesTable _licenceTable(_$LogbookDatabase db) =>
      db.licences.createAlias('licence_ratings__licence__licences__id');

  $$LicencesTableProcessedTableManager get licence {
    final $_column = $_itemColumn<int>('licence')!;

    final manager = $$LicencesTableTableManager(
      $_db,
      $_db.licences,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_licenceTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LicenceRatingsTableFilterComposer
    extends Composer<_$LogbookDatabase, $LicenceRatingsTable> {
  $$LicenceRatingsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<RatingKind, RatingKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<AircraftClass?, AircraftClass, String>
  get aircraftClass => $composableBuilder(
    column: $table.aircraftClass,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get issueDate => $composableBuilder(
    column: $table.issueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastCheckDate => $composableBuilder(
    column: $table.lastCheckDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  $$LicencesTableFilterComposer get licence {
    final $$LicencesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.licence,
      referencedTable: $db.licences,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LicencesTableFilterComposer(
            $db: $db,
            $table: $db.licences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LicenceRatingsTableOrderingComposer
    extends Composer<_$LogbookDatabase, $LicenceRatingsTable> {
  $$LicenceRatingsTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aircraftClass => $composableBuilder(
    column: $table.aircraftClass,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get issueDate => $composableBuilder(
    column: $table.issueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastCheckDate => $composableBuilder(
    column: $table.lastCheckDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  $$LicencesTableOrderingComposer get licence {
    final $$LicencesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.licence,
      referencedTable: $db.licences,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LicencesTableOrderingComposer(
            $db: $db,
            $table: $db.licences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LicenceRatingsTableAnnotationComposer
    extends Composer<_$LogbookDatabase, $LicenceRatingsTable> {
  $$LicenceRatingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<RatingKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AircraftClass?, String> get aircraftClass =>
      $composableBuilder(
        column: $table.aircraftClass,
        builder: (column) => column,
      );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<DateTime> get issueDate =>
      $composableBuilder(column: $table.issueDate, builder: (column) => column);

  GeneratedColumn<DateTime> get lastCheckDate => $composableBuilder(
    column: $table.lastCheckDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $$LicencesTableAnnotationComposer get licence {
    final $$LicencesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.licence,
      referencedTable: $db.licences,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LicencesTableAnnotationComposer(
            $db: $db,
            $table: $db.licences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LicenceRatingsTableTableManager
    extends
        RootTableManager<
          _$LogbookDatabase,
          $LicenceRatingsTable,
          LicenceRating,
          $$LicenceRatingsTableFilterComposer,
          $$LicenceRatingsTableOrderingComposer,
          $$LicenceRatingsTableAnnotationComposer,
          $$LicenceRatingsTableCreateCompanionBuilder,
          $$LicenceRatingsTableUpdateCompanionBuilder,
          (LicenceRating, $$LicenceRatingsTableReferences),
          LicenceRating,
          PrefetchHooks Function({bool licence})
        > {
  $$LicenceRatingsTableTableManager(
    _$LogbookDatabase db,
    $LicenceRatingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LicenceRatingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LicenceRatingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LicenceRatingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> licence = const Value.absent(),
                Value<RatingKind> kind = const Value.absent(),
                Value<AircraftClass?> aircraftClass = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<int?> level = const Value.absent(),
                Value<DateTime?> issueDate = const Value.absent(),
                Value<DateTime?> lastCheckDate = const Value.absent(),
                Value<DateTime?> expiryDate = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => LicenceRatingsCompanion(
                id: id,
                licence: licence,
                kind: kind,
                aircraftClass: aircraftClass,
                name: name,
                level: level,
                issueDate: issueDate,
                lastCheckDate: lastCheckDate,
                expiryDate: expiryDate,
                notes: notes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int licence,
                required RatingKind kind,
                Value<AircraftClass?> aircraftClass = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<int?> level = const Value.absent(),
                Value<DateTime?> issueDate = const Value.absent(),
                Value<DateTime?> lastCheckDate = const Value.absent(),
                Value<DateTime?> expiryDate = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => LicenceRatingsCompanion.insert(
                id: id,
                licence: licence,
                kind: kind,
                aircraftClass: aircraftClass,
                name: name,
                level: level,
                issueDate: issueDate,
                lastCheckDate: lastCheckDate,
                expiryDate: expiryDate,
                notes: notes,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LicenceRatingsTable, LicenceRating>(table),
                  $$LicenceRatingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({licence = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                    if (licence) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.licence,
                                referencedTable: $$LicenceRatingsTableReferences
                                    ._licenceTable(db),
                                referencedColumn:
                                    $$LicenceRatingsTableReferences
                                        ._licenceTable(db)
                                        .id,
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

typedef $$LicenceRatingsTableProcessedTableManager =
    ProcessedTableManager<
      _$LogbookDatabase,
      $LicenceRatingsTable,
      LicenceRating,
      $$LicenceRatingsTableFilterComposer,
      $$LicenceRatingsTableOrderingComposer,
      $$LicenceRatingsTableAnnotationComposer,
      $$LicenceRatingsTableCreateCompanionBuilder,
      $$LicenceRatingsTableUpdateCompanionBuilder,
      (LicenceRating, $$LicenceRatingsTableReferences),
      LicenceRating,
      PrefetchHooks Function({bool licence})
    >;
typedef $$MedicalCertificatesTableCreateCompanionBuilder =
    MedicalCertificatesCompanion Function({
      Value<int> id,
      required MedicalClass medicalClass,
      Value<DateTime?> examinationDate,
      required DateTime expiryDate,
      Value<String?> limitations,
      Value<String?> notes,
    });
typedef $$MedicalCertificatesTableUpdateCompanionBuilder =
    MedicalCertificatesCompanion Function({
      Value<int> id,
      Value<MedicalClass> medicalClass,
      Value<DateTime?> examinationDate,
      Value<DateTime> expiryDate,
      Value<String?> limitations,
      Value<String?> notes,
    });

class $$MedicalCertificatesTableFilterComposer
    extends Composer<_$LogbookDatabase, $MedicalCertificatesTable> {
  $$MedicalCertificatesTableFilterComposer({
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

  ColumnWithTypeConverterFilters<MedicalClass, MedicalClass, String>
  get medicalClass => $composableBuilder(
    column: $table.medicalClass,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get examinationDate => $composableBuilder(
    column: $table.examinationDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get limitations => $composableBuilder(
    column: $table.limitations,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MedicalCertificatesTableOrderingComposer
    extends Composer<_$LogbookDatabase, $MedicalCertificatesTable> {
  $$MedicalCertificatesTableOrderingComposer({
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

  ColumnOrderings<String> get medicalClass => $composableBuilder(
    column: $table.medicalClass,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get examinationDate => $composableBuilder(
    column: $table.examinationDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get limitations => $composableBuilder(
    column: $table.limitations,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MedicalCertificatesTableAnnotationComposer
    extends Composer<_$LogbookDatabase, $MedicalCertificatesTable> {
  $$MedicalCertificatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MedicalClass, String> get medicalClass =>
      $composableBuilder(
        column: $table.medicalClass,
        builder: (column) => column,
      );

  GeneratedColumn<DateTime> get examinationDate => $composableBuilder(
    column: $table.examinationDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get limitations => $composableBuilder(
    column: $table.limitations,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$MedicalCertificatesTableTableManager
    extends
        RootTableManager<
          _$LogbookDatabase,
          $MedicalCertificatesTable,
          MedicalCertificate,
          $$MedicalCertificatesTableFilterComposer,
          $$MedicalCertificatesTableOrderingComposer,
          $$MedicalCertificatesTableAnnotationComposer,
          $$MedicalCertificatesTableCreateCompanionBuilder,
          $$MedicalCertificatesTableUpdateCompanionBuilder,
          (
            MedicalCertificate,
            BaseReferences<
              _$LogbookDatabase,
              $MedicalCertificatesTable,
              MedicalCertificate
            >,
          ),
          MedicalCertificate,
          PrefetchHooks Function()
        > {
  $$MedicalCertificatesTableTableManager(
    _$LogbookDatabase db,
    $MedicalCertificatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MedicalCertificatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MedicalCertificatesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MedicalCertificatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<MedicalClass> medicalClass = const Value.absent(),
                Value<DateTime?> examinationDate = const Value.absent(),
                Value<DateTime> expiryDate = const Value.absent(),
                Value<String?> limitations = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => MedicalCertificatesCompanion(
                id: id,
                medicalClass: medicalClass,
                examinationDate: examinationDate,
                expiryDate: expiryDate,
                limitations: limitations,
                notes: notes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required MedicalClass medicalClass,
                Value<DateTime?> examinationDate = const Value.absent(),
                required DateTime expiryDate,
                Value<String?> limitations = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => MedicalCertificatesCompanion.insert(
                id: id,
                medicalClass: medicalClass,
                examinationDate: examinationDate,
                expiryDate: expiryDate,
                limitations: limitations,
                notes: notes,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MedicalCertificatesTable, MedicalCertificate>(
                    table,
                  ),
                  BaseReferences<
                    _$LogbookDatabase,
                    $MedicalCertificatesTable,
                    MedicalCertificate
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MedicalCertificatesTableProcessedTableManager =
    ProcessedTableManager<
      _$LogbookDatabase,
      $MedicalCertificatesTable,
      MedicalCertificate,
      $$MedicalCertificatesTableFilterComposer,
      $$MedicalCertificatesTableOrderingComposer,
      $$MedicalCertificatesTableAnnotationComposer,
      $$MedicalCertificatesTableCreateCompanionBuilder,
      $$MedicalCertificatesTableUpdateCompanionBuilder,
      (
        MedicalCertificate,
        BaseReferences<
          _$LogbookDatabase,
          $MedicalCertificatesTable,
          MedicalCertificate
        >,
      ),
      MedicalCertificate,
      PrefetchHooks Function()
    >;

class $LogbookDatabaseManager {
  final _$LogbookDatabase _db;
  $LogbookDatabaseManager(this._db);
  $$CountriesTableTableManager get countries =>
      $$CountriesTableTableManager(_db, _db.countries);
  $$RegionsTableTableManager get regions =>
      $$RegionsTableTableManager(_db, _db.regions);
  $$AirportsTableTableManager get airports =>
      $$AirportsTableTableManager(_db, _db.airports);
  $$FrequenciesTableTableManager get frequencies =>
      $$FrequenciesTableTableManager(_db, _db.frequencies);
  $$RunwaysTableTableManager get runways =>
      $$RunwaysTableTableManager(_db, _db.runways);
  $$IcaoAircraftsTableTableManager get icaoAircrafts =>
      $$IcaoAircraftsTableTableManager(_db, _db.icaoAircrafts);
  $$AircraftsTableTableManager get aircrafts =>
      $$AircraftsTableTableManager(_db, _db.aircrafts);
  $$SimulatorsTableTableManager get simulators =>
      $$SimulatorsTableTableManager(_db, _db.simulators);
  $$FlightsTableTableManager get flights =>
      $$FlightsTableTableManager(_db, _db.flights);
  $$FlightDataPointsTableTableManager get flightDataPoints =>
      $$FlightDataPointsTableTableManager(_db, _db.flightDataPoints);
  $$PeopleTableTableManager get people =>
      $$PeopleTableTableManager(_db, _db.people);
  $$FlightCrewTableTableManager get flightCrew =>
      $$FlightCrewTableTableManager(_db, _db.flightCrew);
  $$LicencesTableTableManager get licences =>
      $$LicencesTableTableManager(_db, _db.licences);
  $$LicenceRatingsTableTableManager get licenceRatings =>
      $$LicenceRatingsTableTableManager(_db, _db.licenceRatings);
  $$MedicalCertificatesTableTableManager get medicalCertificates =>
      $$MedicalCertificatesTableTableManager(_db, _db.medicalCertificates);
}
