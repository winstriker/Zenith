import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/repositories/flight_repository.dart';
import 'package:zenith/repositories/licence_repository.dart';
import 'package:zenith/repositories/simulator_repository.dart';
import 'package:zenith/services/database.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late LogbookDatabase db;
  late SimulatorRepository repo;

  setUp(() {
    db = LogbookDatabase(NativeDatabase.memory());
    repo = SimulatorRepository(db);
  });

  tearDown(() => db.close());

  Future<int> a320Type() => db
      .into(db.icaoAircrafts)
      .insert(
        IcaoAircraftsCompanion.insert(
          modelFullName: 'A-320',
          designator: 'A320',
          wakeTurbolenceCategory: WakeTurbulenceCategory.M,
          wakeTurbolenceGroup: WakeTurbulenceGroup.D,
          manufacturer: 'AIRBUS',
          description: AircraftDescription.landplane,
          engineCount: 2,
          engineType: EngineType.jet,
        ),
      );

  Future<int> session(
    int simulatorId,
    DateTime start, {
    Duration length = const Duration(hours: 4),
    int landings = 0,
  }) => db
      .into(db.flights)
      .insert(
        FlightsCompanion.insert(
          title: 'Session',
          departureTime: start,
          arrivalTime: Value(start.add(length)),
          isRecording: false,
          simulatorId: Value(simulatorId),
          dayLandings: Value(landings),
        ),
      );

  test('an FFS is logged by type and qualification number', () async {
    final id = await repo.addSimulator(
      SimulatorsCompanion(
        kind: const Value(SimulatorKind.ffs),
        level: const Value('D'),
        icaoAircraft: Value(await a320Type()),
        aircraftClass: const Value(AircraftClass.type),
        typeRating: const Value(' A320 '),
        qualificationNumber: const Value('Q1234'),
      ),
    );
    final sim = (await repo.watchSimulator(id).first)!;
    expect(sim.simulator.typeRating, 'A320');
    expect(sim.title, 'A320 FFS D');
    expect(sim.logbookType, 'A320 (Q1234)');
  });

  test('other devices are logged by kind (AMC1 FCL.050(i)(9)(i))', () async {
    final id = await repo.addSimulator(
      const SimulatorsCompanion(
        kind: Value(SimulatorKind.fnpt),
        level: Value('II'),
        aircraftClass: Value(AircraftClass.mepLand),
        // Only kept next to a type rating.
        typeRating: Value('A320'),
      ),
    );
    final sim = (await repo.watchSimulator(id).first)!;
    expect(sim.simulator.typeRating, isNull);
    expect(sim.represents, 'MEP (L)');
    expect(sim.logbookType, 'FNPT II');
  });

  test('counts sessions and their time, and searches', () async {
    final id = await repo.addSimulator(
      const SimulatorsCompanion(
        kind: Value(SimulatorKind.ffs),
        organisation: Value('CAE Madrid'),
      ),
    );
    await repo.addSimulator(
      const SimulatorsCompanion(kind: Value(SimulatorKind.bitd)),
    );
    await session(id, DateTime(2026, 11, 1, 8));
    await session(
      id,
      DateTime(2026, 11, 2, 8),
      length: const Duration(hours: 2),
    );

    final all = await repo.watchSimulators().first;
    expect(all, hasLength(2));
    expect(all.first.sessionCount, 2);
    expect(all.first.totalMinutes, 360);
    expect(all.last.sessionCount, 0);

    final found = await repo.watchSimulators(query: 'madrid').first;
    expect(found.single.id, id);
  });

  test("can't be deleted while sessions are logged in it", () async {
    final id = await repo.addSimulator(
      const SimulatorsCompanion(kind: Value(SimulatorKind.ftd)),
    );
    final flight = await session(id, DateTime(2026, 11, 1, 8));
    expect(await repo.deleteSimulator(id), isFalse);
    expect(await repo.watchSimulator(id).first, isNotNull);

    await (db.delete(db.flights)..where((f) => f.id.equals(flight))).go();
    expect(await repo.deleteSimulator(id), isTrue);
    expect(await repo.watchSimulator(id).first, isNull);
  });

  test(
    'sessions are listed with their device, apart from flight time',
    () async {
      final id = await repo.addSimulator(
        SimulatorsCompanion(
          kind: const Value(SimulatorKind.ffs),
          icaoAircraft: Value(await a320Type()),
          aircraftClass: const Value(AircraftClass.type),
          typeRating: const Value('A320'),
        ),
      );
      await session(id, DateTime(2026, 11, 1, 8), landings: 3);
      final flights = FlightRepository(db);

      final listed = await flights.watchRecordedFlightsPage(limit: 10).first;
      expect(listed.single.isSimulatorSession, isTrue);
      expect(listed.single.simulator?.type?.designator, 'A320');
      final searched = await flights
          .watchRecordedFlightsPage(limit: 10, query: 'a320')
          .first;
      expect(searched, hasLength(1));
      expect(await flights.watchRecordedFlightCount().first, 0);
      expect(await flights.watchTotalFlightTime().first, 0);

      final currency = await LicenceRepository(
        db,
      ).currencyFlights(since: DateTime(2026));
      final s = currency.single;
      expect(s.simulator, SimulatorKind.ffs);
      expect(s.aircraftClass, AircraftClass.type);
      expect(s.typeRating, 'A320');
      expect(s.landings, 3);
      expect(s.total, Duration.zero);
    },
  );

  test('v10 → v11 adds simulators to an existing logbook', () async {
    final dir = await Directory.systemTemp.createTemp('zenith_migration_v11');
    final file = File('${dir.path}/db.sqlite');
    addTearDown(() => dir.delete(recursive: true));

    final v10 = LogbookDatabase(NativeDatabase(file));
    await v10
        .into(v10.flights)
        .insert(
          FlightsCompanion.insert(
            title: 'Flight',
            departureTime: DateTime(2026, 5, 3),
            isRecording: false,
          ),
        );
    await v10.customStatement('DROP INDEX flights_simulator_id_idx');
    await v10.customStatement('ALTER TABLE flights DROP COLUMN simulator_id');
    await v10.customStatement('DROP TABLE simulators');
    await v10.customStatement('PRAGMA user_version = 10');
    await v10.close();

    final v11 = LogbookDatabase(NativeDatabase(file));
    addTearDown(v11.close);
    final flight = await v11.select(v11.flights).getSingle();
    expect(flight.simulatorId, isNull);
    final id = await SimulatorRepository(
      v11,
    ).addSimulator(const SimulatorsCompanion(kind: Value(SimulatorKind.ffs)));
    expect(await SimulatorRepository(v11).watchSimulator(id).first, isNotNull);
  });
}
