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
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    model,
    manufacturer,
    tailNumber,
    notes,
    createdAt,
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
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    } else if (isInserting) {
      context.missing(_modelMeta);
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
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
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
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      )!,
      manufacturer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manufacturer'],
      )!,
      tailNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tail_number'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AircraftsTable createAlias(String alias) {
    return $AircraftsTable(attachedDatabase, alias);
  }
}

class Aircraft extends DataClass implements Insertable<Aircraft> {
  final int id;
  final String type;
  final String model;
  final String manufacturer;
  final String tailNumber;
  final String? notes;
  final DateTime createdAt;
  const Aircraft({
    required this.id,
    required this.type,
    required this.model,
    required this.manufacturer,
    required this.tailNumber,
    this.notes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['model'] = Variable<String>(model);
    map['manufacturer'] = Variable<String>(manufacturer);
    map['tail_number'] = Variable<String>(tailNumber);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AircraftsCompanion toCompanion(bool nullToAbsent) {
    return AircraftsCompanion(
      id: Value(id),
      type: Value(type),
      model: Value(model),
      manufacturer: Value(manufacturer),
      tailNumber: Value(tailNumber),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory Aircraft.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Aircraft(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      model: serializer.fromJson<String>(json['model']),
      manufacturer: serializer.fromJson<String>(json['manufacturer']),
      tailNumber: serializer.fromJson<String>(json['tailNumber']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'model': serializer.toJson<String>(model),
      'manufacturer': serializer.toJson<String>(manufacturer),
      'tailNumber': serializer.toJson<String>(tailNumber),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Aircraft copyWith({
    int? id,
    String? type,
    String? model,
    String? manufacturer,
    String? tailNumber,
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
  }) => Aircraft(
    id: id ?? this.id,
    type: type ?? this.type,
    model: model ?? this.model,
    manufacturer: manufacturer ?? this.manufacturer,
    tailNumber: tailNumber ?? this.tailNumber,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
  );
  Aircraft copyWithCompanion(AircraftsCompanion data) {
    return Aircraft(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      model: data.model.present ? data.model.value : this.model,
      manufacturer: data.manufacturer.present
          ? data.manufacturer.value
          : this.manufacturer,
      tailNumber: data.tailNumber.present
          ? data.tailNumber.value
          : this.tailNumber,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Aircraft(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('model: $model, ')
          ..write('manufacturer: $manufacturer, ')
          ..write('tailNumber: $tailNumber, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, type, model, manufacturer, tailNumber, notes, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Aircraft &&
          other.id == this.id &&
          other.type == this.type &&
          other.model == this.model &&
          other.manufacturer == this.manufacturer &&
          other.tailNumber == this.tailNumber &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class AircraftsCompanion extends UpdateCompanion<Aircraft> {
  final Value<int> id;
  final Value<String> type;
  final Value<String> model;
  final Value<String> manufacturer;
  final Value<String> tailNumber;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  const AircraftsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.model = const Value.absent(),
    this.manufacturer = const Value.absent(),
    this.tailNumber = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AircraftsCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    required String model,
    required String manufacturer,
    required String tailNumber,
    this.notes = const Value.absent(),
    required DateTime createdAt,
  }) : type = Value(type),
       model = Value(model),
       manufacturer = Value(manufacturer),
       tailNumber = Value(tailNumber),
       createdAt = Value(createdAt);
  static Insertable<Aircraft> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<String>? model,
    Expression<String>? manufacturer,
    Expression<String>? tailNumber,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (model != null) 'model': model,
      if (manufacturer != null) 'manufacturer': manufacturer,
      if (tailNumber != null) 'tail_number': tailNumber,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AircraftsCompanion copyWith({
    Value<int>? id,
    Value<String>? type,
    Value<String>? model,
    Value<String>? manufacturer,
    Value<String>? tailNumber,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
  }) {
    return AircraftsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      model: model ?? this.model,
      manufacturer: manufacturer ?? this.manufacturer,
      tailNumber: tailNumber ?? this.tailNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (manufacturer.present) {
      map['manufacturer'] = Variable<String>(manufacturer.value);
    }
    if (tailNumber.present) {
      map['tail_number'] = Variable<String>(tailNumber.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AircraftsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('model: $model, ')
          ..write('manufacturer: $manufacturer, ')
          ..write('tailNumber: $tailNumber, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
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
    approachType,
    nightLandings,
    dayLandings,
    flightRules,
    remarks,
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
    );
  }

  @override
  $FlightsTable createAlias(String alias) {
    return $FlightsTable(attachedDatabase, alias);
  }
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
  final String? approachType;
  final int? nightLandings;
  final int? dayLandings;
  final String? flightRules;
  final String? remarks;
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
    this.approachType,
    this.nightLandings,
    this.dayLandings,
    this.flightRules,
    this.remarks,
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
      approachType: serializer.fromJson<String?>(json['approachType']),
      nightLandings: serializer.fromJson<int?>(json['nightLandings']),
      dayLandings: serializer.fromJson<int?>(json['dayLandings']),
      flightRules: serializer.fromJson<String?>(json['flightRules']),
      remarks: serializer.fromJson<String?>(json['remarks']),
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
      'approachType': serializer.toJson<String?>(approachType),
      'nightLandings': serializer.toJson<int?>(nightLandings),
      'dayLandings': serializer.toJson<int?>(dayLandings),
      'flightRules': serializer.toJson<String?>(flightRules),
      'remarks': serializer.toJson<String?>(remarks),
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
    Value<String?> approachType = const Value.absent(),
    Value<int?> nightLandings = const Value.absent(),
    Value<int?> dayLandings = const Value.absent(),
    Value<String?> flightRules = const Value.absent(),
    Value<String?> remarks = const Value.absent(),
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
    approachType: approachType.present ? approachType.value : this.approachType,
    nightLandings: nightLandings.present
        ? nightLandings.value
        : this.nightLandings,
    dayLandings: dayLandings.present ? dayLandings.value : this.dayLandings,
    flightRules: flightRules.present ? flightRules.value : this.flightRules,
    remarks: remarks.present ? remarks.value : this.remarks,
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
          ..write('approachType: $approachType, ')
          ..write('nightLandings: $nightLandings, ')
          ..write('dayLandings: $dayLandings, ')
          ..write('flightRules: $flightRules, ')
          ..write('remarks: $remarks')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
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
    approachType,
    nightLandings,
    dayLandings,
    flightRules,
    remarks,
  );
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
          other.approachType == this.approachType &&
          other.nightLandings == this.nightLandings &&
          other.dayLandings == this.dayLandings &&
          other.flightRules == this.flightRules &&
          other.remarks == this.remarks);
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
  final Value<String?> approachType;
  final Value<int?> nightLandings;
  final Value<int?> dayLandings;
  final Value<String?> flightRules;
  final Value<String?> remarks;
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
    this.approachType = const Value.absent(),
    this.nightLandings = const Value.absent(),
    this.dayLandings = const Value.absent(),
    this.flightRules = const Value.absent(),
    this.remarks = const Value.absent(),
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
    this.approachType = const Value.absent(),
    this.nightLandings = const Value.absent(),
    this.dayLandings = const Value.absent(),
    this.flightRules = const Value.absent(),
    this.remarks = const Value.absent(),
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
    Expression<String>? approachType,
    Expression<int>? nightLandings,
    Expression<int>? dayLandings,
    Expression<String>? flightRules,
    Expression<String>? remarks,
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
      if (approachType != null) 'approach_type': approachType,
      if (nightLandings != null) 'night_landings': nightLandings,
      if (dayLandings != null) 'day_landings': dayLandings,
      if (flightRules != null) 'flight_rules': flightRules,
      if (remarks != null) 'remarks': remarks,
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
    Value<String?>? approachType,
    Value<int?>? nightLandings,
    Value<int?>? dayLandings,
    Value<String?>? flightRules,
    Value<String?>? remarks,
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
      approachType: approachType ?? this.approachType,
      nightLandings: nightLandings ?? this.nightLandings,
      dayLandings: dayLandings ?? this.dayLandings,
      flightRules: flightRules ?? this.flightRules,
      remarks: remarks ?? this.remarks,
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
          ..write('approachType: $approachType, ')
          ..write('nightLandings: $nightLandings, ')
          ..write('dayLandings: $dayLandings, ')
          ..write('flightRules: $flightRules, ')
          ..write('remarks: $remarks')
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
  final int altitude;
  final DateTime timestamp;
  final double? speed;
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
  @override
  late final GeneratedColumnWithTypeConverter<WakeTurbolenceCategory, String>
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
      ).withConverter<WakeTurbolenceCategory>(
        $IcaoAircraftsTable.$converterwakeTurbolenceCategory,
      );
  @override
  late final GeneratedColumnWithTypeConverter<WakeTurbolenceGroup, String>
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
      ).withConverter<WakeTurbolenceGroup>(
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

  static JsonTypeConverter2<WakeTurbolenceCategory, String, String>
  $converterwakeTurbolenceCategory =
      const EnumNameConverter<WakeTurbolenceCategory>(
        WakeTurbolenceCategory.values,
      );
  static JsonTypeConverter2<WakeTurbolenceGroup, String, String>
  $converterwakeTurbolenceGroup = const EnumNameConverter<WakeTurbolenceGroup>(
    WakeTurbolenceGroup.values,
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
  final WakeTurbolenceCategory wakeTurbolenceCategory;
  final WakeTurbolenceGroup wakeTurbolenceGroup;
  final String manufacturer;
  final AircraftDescription description;
  final int engineCount;
  final EngineType engineType;
  final bool userInserted;
  const IcaoAircraft({
    required this.id,
    required this.modelFullName,
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
    WakeTurbolenceCategory? wakeTurbolenceCategory,
    WakeTurbolenceGroup? wakeTurbolenceGroup,
    String? manufacturer,
    AircraftDescription? description,
    int? engineCount,
    EngineType? engineType,
    bool? userInserted,
  }) => IcaoAircraft(
    id: id ?? this.id,
    modelFullName: modelFullName ?? this.modelFullName,
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
  final Value<WakeTurbolenceCategory> wakeTurbolenceCategory;
  final Value<WakeTurbolenceGroup> wakeTurbolenceGroup;
  final Value<String> manufacturer;
  final Value<AircraftDescription> description;
  final Value<int> engineCount;
  final Value<EngineType> engineType;
  final Value<bool> userInserted;
  const IcaoAircraftsCompanion({
    this.id = const Value.absent(),
    this.modelFullName = const Value.absent(),
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
    required WakeTurbolenceCategory wakeTurbolenceCategory,
    required WakeTurbolenceGroup wakeTurbolenceGroup,
    required String manufacturer,
    required AircraftDescription description,
    required int engineCount,
    required EngineType engineType,
    this.userInserted = const Value.absent(),
  }) : modelFullName = Value(modelFullName),
       wakeTurbolenceCategory = Value(wakeTurbolenceCategory),
       wakeTurbolenceGroup = Value(wakeTurbolenceGroup),
       manufacturer = Value(manufacturer),
       description = Value(description),
       engineCount = Value(engineCount),
       engineType = Value(engineType);
  static Insertable<IcaoAircraft> custom({
    Expression<int>? id,
    Expression<String>? modelFullName,
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
    Value<WakeTurbolenceCategory>? wakeTurbolenceCategory,
    Value<WakeTurbolenceGroup>? wakeTurbolenceGroup,
    Value<String>? manufacturer,
    Value<AircraftDescription>? description,
    Value<int>? engineCount,
    Value<EngineType>? engineType,
    Value<bool>? userInserted,
  }) {
    return IcaoAircraftsCompanion(
      id: id ?? this.id,
      modelFullName: modelFullName ?? this.modelFullName,
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

abstract class _$LogbookDatabase extends GeneratedDatabase {
  _$LogbookDatabase(QueryExecutor e) : super(e);
  $LogbookDatabaseManager get managers => $LogbookDatabaseManager(this);
  late final $CountriesTable countries = $CountriesTable(this);
  late final $RegionsTable regions = $RegionsTable(this);
  late final $AirportsTable airports = $AirportsTable(this);
  late final $FrequenciesTable frequencies = $FrequenciesTable(this);
  late final $RunwaysTable runways = $RunwaysTable(this);
  late final $AircraftsTable aircrafts = $AircraftsTable(this);
  late final $FlightsTable flights = $FlightsTable(this);
  late final $FlightDataPointsTable flightDataPoints = $FlightDataPointsTable(
    this,
  );
  late final $IcaoAircraftsTable icaoAircrafts = $IcaoAircraftsTable(this);
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
    aircrafts,
    flights,
    flightDataPoints,
    icaoAircrafts,
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
    aliasName: $_aliasNameGenerator(db.countries.code, db.regions.isoCountry),
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
    aliasName: $_aliasNameGenerator(db.countries.code, db.airports.isoCountry),
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
                  e.readTable(table),
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
      db.countries.createAlias(
        $_aliasNameGenerator(db.regions.isoCountry, db.countries.code),
      );

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
    aliasName: $_aliasNameGenerator(db.regions.code, db.airports.isoRegion),
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
                  e.readTable(table),
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
      db.countries.createAlias(
        $_aliasNameGenerator(db.airports.isoCountry, db.countries.code),
      );

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
      db.regions.createAlias(
        $_aliasNameGenerator(db.airports.isoRegion, db.regions.code),
      );

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
  _frequenciesRefsTable(_$LogbookDatabase db) => MultiTypedResultKey.fromTable(
    db.frequencies,
    aliasName: $_aliasNameGenerator(db.airports.id, db.frequencies.airport),
  );

  $$FrequenciesTableProcessedTableManager get frequenciesRefs {
    final manager = $$FrequenciesTableTableManager(
      $_db,
      $_db.frequencies,
    ).filter((f) => f.airport.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_frequenciesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RunwaysTable, List<Runway>> _runwaysRefsTable(
    _$LogbookDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.runways,
    aliasName: $_aliasNameGenerator(db.airports.id, db.runways.airport),
  );

  $$RunwaysTableProcessedTableManager get runwaysRefs {
    final manager = $$RunwaysTableTableManager(
      $_db,
      $_db.runways,
    ).filter((f) => f.airport.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_runwaysRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FlightsTable, List<Flight>>
  _departureAirportRefsTable(_$LogbookDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.flights,
        aliasName: $_aliasNameGenerator(db.airports.id, db.flights.departure),
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
        aliasName: $_aliasNameGenerator(db.airports.id, db.flights.arrival),
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

  Expression<bool> frequenciesRefs(
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

  Expression<bool> runwaysRefs(
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

  Expression<T> frequenciesRefs<T extends Object>(
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

  Expression<T> runwaysRefs<T extends Object>(
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
            bool frequenciesRefs,
            bool runwaysRefs,
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
                  e.readTable(table),
                  $$AirportsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                isoCountry = false,
                isoRegion = false,
                frequenciesRefs = false,
                runwaysRefs = false,
                departureAirportRefs = false,
                arrivalAirportsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (frequenciesRefs) db.frequencies,
                    if (runwaysRefs) db.runways,
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
                      if (frequenciesRefs)
                        await $_getPrefetchedData<
                          Airport,
                          $AirportsTable,
                          Frequency
                        >(
                          currentTable: table,
                          referencedTable: $$AirportsTableReferences
                              ._frequenciesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AirportsTableReferences(
                                db,
                                table,
                                p0,
                              ).frequenciesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.airport == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (runwaysRefs)
                        await $_getPrefetchedData<
                          Airport,
                          $AirportsTable,
                          Runway
                        >(
                          currentTable: table,
                          referencedTable: $$AirportsTableReferences
                              ._runwaysRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AirportsTableReferences(
                                db,
                                table,
                                p0,
                              ).runwaysRefs,
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
        bool frequenciesRefs,
        bool runwaysRefs,
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
      db.airports.createAlias(
        $_aliasNameGenerator(db.frequencies.airport, db.airports.id),
      );

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
                  e.readTable(table),
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

  static $AirportsTable _airportTable(_$LogbookDatabase db) => db.airports
      .createAlias($_aliasNameGenerator(db.runways.airport, db.airports.id));

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
                  e.readTable(table),
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
typedef $$AircraftsTableCreateCompanionBuilder =
    AircraftsCompanion Function({
      Value<int> id,
      required String type,
      required String model,
      required String manufacturer,
      required String tailNumber,
      Value<String?> notes,
      required DateTime createdAt,
    });
typedef $$AircraftsTableUpdateCompanionBuilder =
    AircraftsCompanion Function({
      Value<int> id,
      Value<String> type,
      Value<String> model,
      Value<String> manufacturer,
      Value<String> tailNumber,
      Value<String?> notes,
      Value<DateTime> createdAt,
    });

final class $$AircraftsTableReferences
    extends BaseReferences<_$LogbookDatabase, $AircraftsTable, Aircraft> {
  $$AircraftsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$FlightsTable, List<Flight>> _flightsRefsTable(
    _$LogbookDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.flights,
    aliasName: $_aliasNameGenerator(db.aircrafts.id, db.flights.aircraftId),
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
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

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tailNumber => $composableBuilder(
    column: $table.tailNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

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
          PrefetchHooks Function({bool flightsRefs})
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
                Value<String> type = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<String> manufacturer = const Value.absent(),
                Value<String> tailNumber = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => AircraftsCompanion(
                id: id,
                type: type,
                model: model,
                manufacturer: manufacturer,
                tailNumber: tailNumber,
                notes: notes,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String type,
                required String model,
                required String manufacturer,
                required String tailNumber,
                Value<String?> notes = const Value.absent(),
                required DateTime createdAt,
              }) => AircraftsCompanion.insert(
                id: id,
                type: type,
                model: model,
                manufacturer: manufacturer,
                tailNumber: tailNumber,
                notes: notes,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AircraftsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({flightsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (flightsRefs) db.flights],
              addJoins: null,
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
      PrefetchHooks Function({bool flightsRefs})
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
      Value<String?> approachType,
      Value<int?> nightLandings,
      Value<int?> dayLandings,
      Value<String?> flightRules,
      Value<String?> remarks,
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
      Value<String?> approachType,
      Value<int?> nightLandings,
      Value<int?> dayLandings,
      Value<String?> flightRules,
      Value<String?> remarks,
    });

final class $$FlightsTableReferences
    extends BaseReferences<_$LogbookDatabase, $FlightsTable, Flight> {
  $$FlightsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AirportsTable _departureTable(_$LogbookDatabase db) => db.airports
      .createAlias($_aliasNameGenerator(db.flights.departure, db.airports.id));

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

  static $AirportsTable _arrivalTable(_$LogbookDatabase db) => db.airports
      .createAlias($_aliasNameGenerator(db.flights.arrival, db.airports.id));

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
      db.aircrafts.createAlias(
        $_aliasNameGenerator(db.flights.aircraftId, db.aircrafts.id),
      );

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

  static MultiTypedResultKey<$FlightDataPointsTable, List<FlightDataPoint>>
  _flightDataPointsRefsTable(_$LogbookDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.flightDataPoints,
        aliasName: $_aliasNameGenerator(
          db.flights.id,
          db.flightDataPoints.flight,
        ),
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
            bool flightDataPointsRefs,
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
                Value<String?> approachType = const Value.absent(),
                Value<int?> nightLandings = const Value.absent(),
                Value<int?> dayLandings = const Value.absent(),
                Value<String?> flightRules = const Value.absent(),
                Value<String?> remarks = const Value.absent(),
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
                approachType: approachType,
                nightLandings: nightLandings,
                dayLandings: dayLandings,
                flightRules: flightRules,
                remarks: remarks,
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
                Value<String?> approachType = const Value.absent(),
                Value<int?> nightLandings = const Value.absent(),
                Value<int?> dayLandings = const Value.absent(),
                Value<String?> flightRules = const Value.absent(),
                Value<String?> remarks = const Value.absent(),
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
                approachType: approachType,
                nightLandings: nightLandings,
                dayLandings: dayLandings,
                flightRules: flightRules,
                remarks: remarks,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FlightsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                departure = false,
                arrival = false,
                aircraftId = false,
                flightDataPointsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (flightDataPointsRefs) db.flightDataPoints,
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
        bool flightDataPointsRefs,
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
      db.flights.createAlias(
        $_aliasNameGenerator(db.flightDataPoints.flight, db.flights.id),
      );

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
                  e.readTable(table),
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
typedef $$IcaoAircraftsTableCreateCompanionBuilder =
    IcaoAircraftsCompanion Function({
      Value<int> id,
      required String modelFullName,
      required WakeTurbolenceCategory wakeTurbolenceCategory,
      required WakeTurbolenceGroup wakeTurbolenceGroup,
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
      Value<WakeTurbolenceCategory> wakeTurbolenceCategory,
      Value<WakeTurbolenceGroup> wakeTurbolenceGroup,
      Value<String> manufacturer,
      Value<AircraftDescription> description,
      Value<int> engineCount,
      Value<EngineType> engineType,
      Value<bool> userInserted,
    });

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

  ColumnWithTypeConverterFilters<
    WakeTurbolenceCategory,
    WakeTurbolenceCategory,
    String
  >
  get wakeTurbolenceCategory => $composableBuilder(
    column: $table.wakeTurbolenceCategory,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<
    WakeTurbolenceGroup,
    WakeTurbolenceGroup,
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

  GeneratedColumnWithTypeConverter<WakeTurbolenceCategory, String>
  get wakeTurbolenceCategory => $composableBuilder(
    column: $table.wakeTurbolenceCategory,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<WakeTurbolenceGroup, String>
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
          (
            IcaoAircraft,
            BaseReferences<
              _$LogbookDatabase,
              $IcaoAircraftsTable,
              IcaoAircraft
            >,
          ),
          IcaoAircraft,
          PrefetchHooks Function()
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
                Value<WakeTurbolenceCategory> wakeTurbolenceCategory =
                    const Value.absent(),
                Value<WakeTurbolenceGroup> wakeTurbolenceGroup =
                    const Value.absent(),
                Value<String> manufacturer = const Value.absent(),
                Value<AircraftDescription> description = const Value.absent(),
                Value<int> engineCount = const Value.absent(),
                Value<EngineType> engineType = const Value.absent(),
                Value<bool> userInserted = const Value.absent(),
              }) => IcaoAircraftsCompanion(
                id: id,
                modelFullName: modelFullName,
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
                required WakeTurbolenceCategory wakeTurbolenceCategory,
                required WakeTurbolenceGroup wakeTurbolenceGroup,
                required String manufacturer,
                required AircraftDescription description,
                required int engineCount,
                required EngineType engineType,
                Value<bool> userInserted = const Value.absent(),
              }) => IcaoAircraftsCompanion.insert(
                id: id,
                modelFullName: modelFullName,
                wakeTurbolenceCategory: wakeTurbolenceCategory,
                wakeTurbolenceGroup: wakeTurbolenceGroup,
                manufacturer: manufacturer,
                description: description,
                engineCount: engineCount,
                engineType: engineType,
                userInserted: userInserted,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
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
      (
        IcaoAircraft,
        BaseReferences<_$LogbookDatabase, $IcaoAircraftsTable, IcaoAircraft>,
      ),
      IcaoAircraft,
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
  $$AircraftsTableTableManager get aircrafts =>
      $$AircraftsTableTableManager(_db, _db.aircrafts);
  $$FlightsTableTableManager get flights =>
      $$FlightsTableTableManager(_db, _db.flights);
  $$FlightDataPointsTableTableManager get flightDataPoints =>
      $$FlightDataPointsTableTableManager(_db, _db.flightDataPoints);
  $$IcaoAircraftsTableTableManager get icaoAircrafts =>
      $$IcaoAircraftsTableTableManager(_db, _db.icaoAircrafts);
}
