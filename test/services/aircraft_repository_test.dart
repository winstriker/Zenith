import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/repositories/aircraft_repository.dart';
import 'package:zenith/services/database.dart';
import 'package:zenith/services/person_photo_store.dart';

IcaoAircraftsCompanion _type(
  String designator, {
  AircraftDescription description = AircraftDescription.landplane,
  int engines = 1,
  EngineType engine = EngineType.piston,
}) => IcaoAircraftsCompanion.insert(
  modelFullName: 'Model $designator',
  designator: designator,
  wakeTurbolenceCategory: WakeTurbulenceCategory.L,
  wakeTurbolenceGroup: WakeTurbulenceGroup.Z,
  manufacturer: 'ACME',
  description: description,
  engineCount: engines,
  engineType: engine,
);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late LogbookDatabase db;
  late Directory root;
  late AircraftPhotoStore store;
  late AircraftRepository repo;

  setUp(() async {
    db = LogbookDatabase(NativeDatabase.memory());
    root = await Directory.systemTemp.createTemp('zenith_aircraft');
    store = AircraftPhotoStore(() async => root);
    repo = AircraftRepository(db, store);
  });

  tearDown(() async {
    await db.close();
    await root.delete(recursive: true);
  });

  Future<int> addType(IcaoAircraftsCompanion type) =>
      db.into(db.icaoAircrafts).insert(type);

  Future<String> storePhoto() async {
    final source = File('${root.path}/picked.jpg')..writeAsBytesSync([1, 2, 3]);
    return store.save(source);
  }

  bool stored(String name) =>
      File('${root.path}/aircraft_photos/$name').existsSync();

  const online = AircraftPhoto.online(
    url: 'https://cdn.jetphotos.com/full/6/1.jpg',
    thumbnailUrl: 'https://cdn.jetphotos.com/400/6/1.jpg',
    link: 'https://www.jetphotos.com/photo/1',
    credit: 'Anna Rossi',
  );

  test('an aircraft keeps its class and the links of its photo', () async {
    final c172 = await addType(_type('C172'));
    final id = await repo.addAircraft(
      icaoAircraftId: c172,
      tailNumber: 'I-ABCD',
      aircraftClass: AircraftClass.sepLand,
      // Means nothing next to a class rating.
      typeRating: 'A320',
      photo: online,
    );

    final aircraft = (await repo.watchAircraftWithStats(id).first)!;
    expect(aircraft.aircraftClass, AircraftClass.sepLand);
    expect(aircraft.typeRating, isNull);
    expect(aircraft.photo, online);
    expect(aircraft.photoFile, isNull);
    // Nothing was downloaded.
    expect(Directory('${root.path}/aircraft_photos').existsSync(), isFalse);
  });

  test('the form gets the type of the aircraft, not the aircraft id', () async {
    // Make aircraft ids and type ids differ.
    await addType(_type('PA28'));
    await addType(_type('DR40'));
    final c172 = await addType(_type('C172'));
    final id = await repo.addAircraft(icaoAircraftId: c172, tailNumber: 'I-A');

    final aircraft = (await repo.watchAircraftWithStats(id).first)!;
    expect(aircraft.id, isNot(c172));
    expect(aircraft.toIcaoAircraft().id, c172);
    expect(aircraft.toIcaoAircraft().designator, 'C172');
  });

  test('updating rewrites tail number, type, class and type rating', () async {
    final c172 = await addType(_type('C172'));
    final a320 = await addType(
      _type('A320', engines: 2, engine: EngineType.jet),
    );
    final id = await repo.addAircraft(
      icaoAircraftId: c172,
      tailNumber: 'I-ABCD',
      notes: 'old',
      aircraftClass: AircraftClass.sepLand,
      photo: online,
    );

    await repo.updateAircraft(
      id,
      icaoAircraftId: a320,
      tailNumber: 'EI-DSA',
      aircraftClass: AircraftClass.type,
      typeRating: ' A320 ',
    );

    final aircraft = (await repo.watchAircraftWithStats(id).first)!;
    expect(aircraft.tailNumber, 'EI-DSA');
    expect(aircraft.designator, 'A320');
    expect(aircraft.notes, isNull);
    expect(aircraft.aircraftClass, AircraftClass.type);
    expect(aircraft.typeRating, 'A320');
    // The photo was not part of the update.
    expect(aircraft.photo, online);
    expect(await repo.getTypeRatings(), ['A320']);
  });

  test('replacing or removing a picked photo deletes its file', () async {
    final c172 = await addType(_type('C172'));
    final first = await storePhoto();
    final id = await repo.addAircraft(
      icaoAircraftId: c172,
      tailNumber: 'I-ABCD',
      photo: AircraftPhoto.file(first),
    );
    expect(stored(first), isTrue);

    Future<void> setPhoto(AircraftPhoto? photo) => repo.updateAircraft(
      id,
      icaoAircraftId: c172,
      tailNumber: 'I-ABCD',
      photo: Value(photo),
    );

    final second = await storePhoto();
    await setPhoto(AircraftPhoto.file(second));
    expect(stored(first), isFalse);
    expect(stored(second), isTrue);

    await setPhoto(online);
    expect(stored(second), isFalse);
    var aircraft = (await repo.watchAircraftWithStats(id).first)!;
    expect(aircraft.photo, online);

    await setPhoto(null);
    aircraft = (await repo.watchAircraftWithStats(id).first)!;
    expect(aircraft.photo, isNull);
    expect(aircraft.photoLink, isNull);
  });

  test('deleting an aircraft deletes its picked photo', () async {
    final c172 = await addType(_type('C172'));
    final photo = await storePhoto();
    final id = await repo.addAircraft(
      icaoAircraftId: c172,
      tailNumber: 'I-ABCD',
      photo: AircraftPhoto.file(photo),
    );

    await repo.deleteAircraft(id);

    expect(stored(photo), isFalse);
    expect(await db.select(db.aircrafts).get(), isEmpty);
  });

  test('v4 → v5 migration adds class and photo, and deduces classes', () async {
    final dir = await Directory.systemTemp.createTemp('zenith_migration_v5');
    final file = File('${dir.path}/db.sqlite');
    addTearDown(() => dir.delete(recursive: true));

    // Build a current database, then take it back to what version 4 had.
    final v5 = LogbookDatabase(NativeDatabase(file));
    Future<void> add(String tail, IcaoAircraftsCompanion type) async {
      final typeId = await v5.into(v5.icaoAircrafts).insert(type);
      await v5
          .into(v5.aircrafts)
          .insert(
            AircraftsCompanion.insert(icaoAircraft: typeId, tailNumber: tail),
          );
    }

    await add('I-SEPL', _type('C172'));
    await add('I-MEPL', _type('PA34', engines: 2));
    await add('I-SETL', _type('PC12', engine: EngineType.turboprop));
    await add(
      'I-AMPH',
      _type('LA4', description: AircraftDescription.amphibian),
    );
    await add('I-JETS', _type('A320', engines: 2, engine: EngineType.jet));

    final views = [
      for (final row
          in await v5
              .customSelect(
                "SELECT name FROM sqlite_master WHERE type = 'view'",
              )
              .get())
        row.read<String>('name'),
    ];
    expect(views, isNotEmpty);
    for (final view in views) {
      await v5.customStatement('DROP VIEW "$view"');
    }
    for (final column in [
      'aircraft_class',
      'type_rating',
      'photo_file',
      'photo_url',
      'photo_thumbnail_url',
      'photo_link',
      'photo_credit',
    ]) {
      await v5.customStatement('ALTER TABLE aircrafts DROP COLUMN $column');
    }
    // Old views know nothing of the new columns.
    for (final view in views) {
      await v5.customStatement(
        'CREATE VIEW "$view" AS SELECT id FROM aircrafts',
      );
    }
    await v5.customStatement('PRAGMA user_version = 4');
    await v5.close();

    final db = LogbookDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final aircraft = {
      for (final a in await AircraftRepository(
        db,
      ).watchAircraftsWithStats().first)
        a.tailNumber: a,
    };

    expect(aircraft['I-SEPL']!.aircraftClass, AircraftClass.sepLand);
    expect(aircraft['I-MEPL']!.aircraftClass, AircraftClass.mepLand);
    expect(aircraft['I-SETL']!.aircraftClass, AircraftClass.setLand);
    // Land or sea: the pilot has to say.
    expect(aircraft['I-AMPH']!.aircraftClass, isNull);
    // A type rating has a name only the pilot knows.
    expect(aircraft['I-JETS']!.aircraftClass, isNull);
    expect(aircraft['I-SEPL']!.photo, isNull);
    expect(aircraft['I-SEPL']!.designator, 'C172');
  });

  test('deduced classes never replace a class that is already set', () async {
    final c172 = await addType(_type('C172'));
    final id = await repo.addAircraft(
      icaoAircraftId: c172,
      tailNumber: 'I-FLOT',
      aircraftClass: AircraftClass.sepSea,
    );
    await repo.addAircraft(icaoAircraftId: c172, tailNumber: 'I-NONE');

    expect(await db.assignDeducedAircraftClasses(), 1);

    final aircraft = (await repo.watchAircraftWithStats(id).first)!;
    expect(aircraft.aircraftClass, AircraftClass.sepSea);
  });
}
