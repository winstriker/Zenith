import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/repositories/aircraft_repository.dart';
import 'package:zenith/services/aircraft_types_service.dart';
import 'package:zenith/services/database.dart';

IcaoAircraftsCompanion _type(
  String designator, {
  String model = 'Model',
  int engines = 1,
  bool user = false,
}) => IcaoAircraftsCompanion.insert(
  modelFullName: '$model $designator',
  designator: designator,
  wakeTurbolenceCategory: WakeTurbulenceCategory.L,
  wakeTurbolenceGroup: WakeTurbulenceGroup.Z,
  manufacturer: 'ACME',
  description: AircraftDescription.landplane,
  engineCount: engines,
  engineType: EngineType.piston,
  userInserted: Value(user),
);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late LogbookDatabase db;
  setUp(() => db = LogbookDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<int> idOf(String designator) async => (await (db.select(
    db.icaoAircrafts,
  )..where((t) => t.designator.equals(designator))).getSingle()).id;

  Future<int> addSimulator(int? typeId) => db
      .into(db.simulators)
      .insert(
        SimulatorsCompanion.insert(
          kind: SimulatorKind.ffs,
          icaoAircraft: Value(typeId),
        ),
      );

  Future<int> addAircraft(int typeId) => db
      .into(db.aircrafts)
      .insert(
        AircraftsCompanion.insert(icaoAircraft: typeId, tailNumber: 'I-TEST'),
      );

  test('reload keeps ids, so aircraft keep their type', () async {
    await AircraftTypesService.syncTypes(db, [_type('C172'), _type('PA28')]);
    final c172 = await idOf('C172');
    final aircraft = await addAircraft(c172);

    // A second download with changed details and a new type.
    await AircraftTypesService.syncTypes(db, [
      _type('PA28'),
      _type('C172', engines: 2),
      _type('SR22'),
    ]);

    expect(await idOf('C172'), c172);
    final listed = await db.select(db.aircraftWithIcaos).get();
    expect(listed.single.id, aircraft);
    expect(listed.single.designator, 'C172');
    expect(listed.single.engineCount, 2);
    expect(await db.select(db.icaoAircrafts).get(), hasLength(3));
  });

  test('types that left the list go, unless something uses them', () async {
    await AircraftTypesService.syncTypes(db, [
      _type('C172'),
      _type('OLD1'),
      _type('OLD2'),
      _type('OLD3'),
    ]);
    await addAircraft(await idOf('OLD1'));
    await addSimulator(await idOf('OLD3'));
    // A generic device, with no type.
    await addSimulator(null);

    await AircraftTypesService.syncTypes(db, [_type('C172')]);

    final designators = (await db.select(db.icaoAircrafts).get()).map(
      (t) => t.designator,
    );
    expect(designators, unorderedEquals(['C172', 'OLD1', 'OLD3']));
  });

  test('user-inserted types are never touched', () async {
    await db.into(db.icaoAircrafts).insert(_type('MINE', user: true));
    await AircraftTypesService.syncTypes(db, [_type('C172')]);
    await AircraftTypesService.syncTypes(db, [_type('PA28')]);
    final mine = await (db.select(
      db.icaoAircrafts,
    )..where((t) => t.designator.equals('MINE'))).getSingle();
    expect(mine.userInserted, isTrue);
  });

  test('duplicate entries in the download are kept apart', () async {
    await AircraftTypesService.syncTypes(db, [_type('DUP'), _type('DUP')]);
    final first = await db.select(db.icaoAircrafts).get();
    await AircraftTypesService.syncTypes(db, [_type('DUP'), _type('DUP')]);
    final second = await db.select(db.icaoAircrafts).get();
    expect(second.map((t) => t.id), first.map((t) => t.id));
  });

  test('aircraft orphaned by old reloads become visible again', () async {
    await addAircraft(999);
    await addSimulator(998);
    await addSimulator(null);
    expect(await db.select(db.aircraftWithIcaos).get(), isEmpty);

    expect(await AircraftTypesService.repairOrphanedAircraft(db), 2);
    final placeholder = await (db.select(
      db.icaoAircrafts,
    )..where((t) => t.id.equals(998))).getSingle();
    expect(placeholder.modelFullName, 'Unknown type');
    final listed = await db.select(db.aircraftWithIcaos).get();
    expect(listed.single.modelFullName, 'Unknown type');

    // Idempotent, and the placeholder survives a sync.
    expect(await AircraftTypesService.repairOrphanedAircraft(db), 0);
    await AircraftTypesService.syncTypes(db, [_type('C172')]);
    expect(await db.select(db.aircraftWithIcaos).get(), hasLength(1));
  });

  test('only unused custom types can be deleted', () async {
    final repo = AircraftRepository(db);
    final stock = await db.into(db.icaoAircrafts).insert(_type('C172'));
    final custom = await db
        .into(db.icaoAircrafts)
        .insert(_type('HOME', user: true));
    final used = await db
        .into(db.icaoAircrafts)
        .insert(_type('USED', user: true));
    await addAircraft(used);

    expect(await repo.deleteIcaoAircraft(stock), isFalse);
    expect(await repo.countTypeUsage(used), 1);
    expect(await repo.deleteIcaoAircraft(used), isFalse);
    expect(await repo.deleteIcaoAircraft(custom), isTrue);
    final left = await db.select(db.icaoAircrafts).get();
    expect(left.map((t) => t.designator), unorderedEquals(['C172', 'USED']));
  });

  test('editing leaves downloaded types alone', () async {
    final repo = AircraftRepository(db);
    final stock = await db.into(db.icaoAircrafts).insert(_type('C172'));
    final custom = await db
        .into(db.icaoAircrafts)
        .insert(_type('HOME', user: true));
    for (final id in [stock, custom]) {
      await repo.updateIcaoAircraft(
        id,
        modelFullName: 'Renamed',
        manufacturer: 'Me',
        designator: 'NEWD',
        wakeTurbolenceCategory: WakeTurbulenceCategory.L,
        wakeTurbolenceGroup: WakeTurbulenceGroup.Z,
        description: AircraftDescription.landplane,
        engineCount: 2,
        engineType: EngineType.piston,
      );
    }
    final rows = await db.select(db.icaoAircrafts).get();
    expect(rows.firstWhere((t) => t.id == stock).designator, 'C172');
    expect(rows.firstWhere((t) => t.id == custom).designator, 'NEWD');
  });
}
