import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/currency.dart';
import 'package:zenith/repositories/licence_repository.dart';
import 'package:zenith/services/database.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late LogbookDatabase db;
  late LicenceRepository repo;

  setUp(() {
    db = LogbookDatabase(NativeDatabase.memory());
    repo = LicenceRepository(db);
  });
  tearDown(() => db.close());

  Future<int> addAircraft({
    required AircraftClass cls,
    String? typeRating,
  }) async {
    final type = await db.addIcaoAircraft(
      modelFullName: 'Test',
      manufacturer: 'Test',
      designator: 'TEST',
      wakeTurbolenceCategory: WakeTurbulenceCategory.values.first,
      wakeTurbolenceGroup: WakeTurbulenceGroup.values.first,
      description: AircraftDescription.landplane,
      engineCount: 1,
      engineType: EngineType.piston,
    );
    return db
        .into(db.aircrafts)
        .insert(
          AircraftsCompanion.insert(
            icaoAircraft: type,
            tailNumber: 'I-TEST',
            aircraftClass: Value(cls),
            typeRating: Value(typeRating),
          ),
        );
  }

  Future<int> addFlight({
    required DateTime dep,
    int? aircraft,
    String role = 'pic',
    bool recording = false,
    bool check = false,
    LogbookOverrides? overrides,
  }) => db
      .into(db.flights)
      .insert(
        FlightsCompanion.insert(
          title: 'Flight',
          departureTime: dep,
          arrivalTime: Value(dep.add(const Duration(hours: 1, minutes: 30))),
          isRecording: recording,
          aircraftId: Value(aircraft),
          pilotRole: Value(role),
          dayLandings: const Value(2),
          nightLandings: const Value(1),
          logbookOverrides: Value(overrides),
          proficiencyCheck: Value(check),
        ),
      );

  Future<void> addExaminer(int flight) async {
    final person = await db
        .into(db.people)
        .insert(PeopleCompanion.insert(name: 'Exa', surname: 'Miner'));
    await db
        .into(db.flightCrew)
        .insert(
          FlightCrewCompanion.insert(
            flight: flight,
            person: person,
            role: CrewRole.exm,
          ),
        );
  }

  test('licences come with their ratings, sorted by kind', () async {
    final ppl = await repo.addLicence(
      const LicencesCompanion(
        kind: Value(LicenceKind.ppl),
        category: Value(AircraftCategory.aeroplane),
      ),
    );
    await repo.addLicence(
      const LicencesCompanion(
        kind: Value(LicenceKind.spl),
        category: Value(AircraftCategory.sailplane),
      ),
    );
    await repo.addRating(
      LicenceRatingsCompanion(
        licence: Value(ppl),
        kind: const Value(RatingKind.night),
      ),
    );
    await repo.addRating(
      LicenceRatingsCompanion(
        licence: Value(ppl),
        kind: const Value(RatingKind.classRating),
        aircraftClass: const Value(AircraftClass.sepLand),
        expiryDate: Value(DateTime(2027, 3, 31)),
      ),
    );

    final licences = await repo.watchLicences().first;
    expect(licences, hasLength(2));
    expect(licences[0].ratings.map((r) => r.title), [
      'SEP (L)',
      'Night rating',
    ]);
    expect(licences[1].licence.title, 'SPL(S)');
    expect(licences[1].ratings, isEmpty);

    await repo.deleteLicence(ppl);
    expect(await repo.watchLicences().first, hasLength(1));
    expect(await db.select(db.licenceRatings).get(), isEmpty);
  });

  test('type rating suggestions include the aircraft ones', () async {
    await addAircraft(cls: AircraftClass.type, typeRating: 'A320');
    final licence = await repo.addLicence(
      const LicencesCompanion(
        kind: Value(LicenceKind.atpl),
        category: Value(AircraftCategory.aeroplane),
      ),
    );
    await repo.addRating(
      LicenceRatingsCompanion(
        licence: Value(licence),
        kind: const Value(RatingKind.typeRating),
        name: const Value('B737 300-900'),
      ),
    );
    await repo.addRating(
      LicenceRatingsCompanion(
        licence: Value(licence),
        kind: const Value(RatingKind.typeRating),
        name: const Value('a320'),
      ),
    );
    final names = await repo.ratingNameSuggestions(RatingKind.typeRating);
    expect(names, hasLength(2));
    expect(names.last, 'B737 300-900');
  });

  test('flights are read as logged, overrides included', () async {
    final sep = await addAircraft(cls: AircraftClass.sepLand);
    final since = DateTime(2026);
    await addFlight(dep: DateTime(2026, 5, 1, 10), aircraft: sep);
    await addFlight(dep: DateTime(2026, 5, 2, 10), aircraft: sep, role: 'dual');
    await addFlight(
      dep: DateTime(2026, 5, 3, 10),
      aircraft: sep,
      overrides: const LogbookOverrides(
        times: {LogbookTimeField.pic: Duration(minutes: 30)},
      ),
    );
    await addFlight(dep: DateTime(2026, 5, 4, 10), recording: true);
    await addFlight(dep: DateTime(2025, 5, 4, 10)); // before `since`

    final flights = await repo.currencyFlights(since: since);
    flights.sort((a, b) => a.date.compareTo(b.date));
    expect(flights, hasLength(3));
    expect(flights[0].pic, const Duration(minutes: 90));
    expect(flights[0].dual, Duration.zero);
    expect(flights[0].aircraftClass, AircraftClass.sepLand);
    expect(flights[0].landings, 3);
    expect(flights[0].nightLandings, 1);
    expect(flights[1].pic, Duration.zero);
    expect(flights[1].dual, const Duration(minutes: 90));
    expect(flights[2].pic, const Duration(minutes: 30));
  });

  test('the logbook stream follows flight changes', () async {
    final stream = repo.watchCurrencyFlights(since: DateTime(2026));
    final seen = <int>[];
    final sub = stream.listen((f) => seen.add(f.length));
    await pumpEventQueue();
    await addFlight(dep: DateTime(2026, 6, 1, 10));
    await pumpEventQueue();
    await sub.cancel();

    expect(seen.first, 0);
    expect(seen.last, 1);
  });

  test('medicals: the one expiring last first', () async {
    await repo.addMedical(
      MedicalCertificatesCompanion.insert(
        medicalClass: MedicalClass.class2,
        expiryDate: DateTime(2027),
      ),
    );
    await repo.addMedical(
      MedicalCertificatesCompanion.insert(
        medicalClass: MedicalClass.class1,
        expiryDate: DateTime(2026, 12),
      ),
    );
    final medicals = await repo.watchMedicals().first;
    expect(medicals.map((m) => m.medicalClass), [
      MedicalClass.class2,
      MedicalClass.class1,
    ]);
  });

  test('a flight is a proficiency check only with an examiner', () async {
    final dep = DateTime(2026, 5, 3, 10);
    final withExaminer = await addFlight(dep: dep, check: true);
    await addExaminer(withExaminer);
    // The examiner was removed after it was ticked.
    await addFlight(dep: dep.add(const Duration(days: 1)), check: true);

    final flights = await repo.currencyFlights(since: DateTime(2026));
    flights.sort((a, b) => a.date.compareTo(b.date));
    expect(flights.map((f) => f.proficiencyCheck), [true, false]);
  });
}
