import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/repositories/flight_repository.dart';
import 'package:zenith/repositories/person_repository.dart';
import 'package:zenith/services/database.dart';
import 'package:zenith/services/person_photo_store.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  Future<int> addFlight(LogbookDatabase db, DateTime departure) {
    return db
        .into(db.flights)
        .insert(
          FlightsCompanion.insert(
            title: 'A → B',
            departureTime: departure,
            isRecording: false,
          ),
        );
  }

  group('crew', () {
    late LogbookDatabase db;
    setUp(() => db = LogbookDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('setFlightCrew replaces the crew of a flight', () async {
      final repo = PersonRepository(db);
      final anna = await repo.addPerson(name: 'Anna', surname: 'Rossi');
      final marco = await repo.addPerson(name: 'Marco', surname: 'Bianchi');
      final flight = await addFlight(db, DateTime(2026, 1, 2));

      await db.setFlightCrew(flight, [
        CrewMember(person: anna, role: CrewRole.ins),
        CrewMember(person: marco, role: CrewRole.sic),
      ]);
      await db.setFlightCrew(flight, [
        CrewMember(person: marco, role: CrewRole.exm),
      ]);

      final crew = await db.getFlightCrew(flight);
      expect(crew, hasLength(1));
      expect(crew.single.person.fullName, 'Marco Bianchi');
      expect(crew.single.role, CrewRole.exm);
    });

    test('people are sorted by most recent flight, then never flown', () async {
      final repo = PersonRepository(db);
      final old = await repo.addPerson(name: 'Old', surname: 'Pilot');
      final recent = await repo.addPerson(name: 'Recent', surname: 'Pilot');
      await repo.addPerson(name: 'Never', surname: 'Flown');

      final f1 = await addFlight(db, DateTime(2024, 5, 2));
      final f2 = await addFlight(db, DateTime(2026, 5, 2));
      final f3 = await addFlight(db, DateTime(2023, 5, 2));
      await db.setFlightCrew(f1, [CrewMember(person: old, role: CrewRole.ins)]);
      await db.setFlightCrew(f3, [CrewMember(person: old, role: CrewRole.ins)]);
      await db.setFlightCrew(f2, [
        CrewMember(person: recent, role: CrewRole.sic),
      ]);

      final people = await repo.watchPeople().first;
      expect(people.map((p) => p.person.name), ['Recent', 'Old', 'Never']);
      expect(people[1].flightCount, 2);
      expect(people[1].lastFlight, DateTime(2024, 5, 2));
      expect(people[2].lastFlight, isNull);

      final search = await repo.watchPeople(query: 'old pil').first;
      expect(search.map((p) => p.person.name), ['Old']);
    });

    test('updatePerson renames', () async {
      final repo = PersonRepository(db);
      final p = await repo.addPerson(name: 'Ana', surname: 'Rosi');
      await repo.updatePerson(p.id, name: ' Anna ', surname: 'Rossi');
      final people = await repo.watchPeople().first;
      expect(people.single.person.fullName, 'Anna Rossi');
    });

    test('deletePerson removes them from every crew', () async {
      final repo = PersonRepository(db);
      final anna = await repo.addPerson(name: 'Anna', surname: 'Rossi');
      final marco = await repo.addPerson(name: 'Marco', surname: 'Bianchi');
      final flight = await addFlight(db, DateTime(2026, 2, 2));
      await db.setFlightCrew(flight, [
        CrewMember(person: anna, role: CrewRole.ins),
        CrewMember(person: marco, role: CrewRole.sic),
      ]);

      await repo.deletePerson(anna.id);

      final crew = await db.getFlightCrew(flight);
      expect(crew.map((c) => c.person.id), [marco.id]);
      final people = await repo.watchPeople().first;
      expect(people.map((p) => p.person.id), [marco.id]);
    });

    test(
      'mergePeople moves flights and keeps target role on overlap',
      () async {
        final repo = PersonRepository(db);
        final dup = await repo.addPerson(name: 'Ana', surname: 'Rossi');
        final anna = await repo.addPerson(name: 'Anna', surname: 'Rossi');
        final shared = await addFlight(db, DateTime(2026, 3, 3));
        final onlyDup = await addFlight(db, DateTime(2026, 4, 4));
        await db.setFlightCrew(shared, [
          CrewMember(person: dup, role: CrewRole.sic),
          CrewMember(person: anna, role: CrewRole.ins),
        ]);
        await db.setFlightCrew(onlyDup, [
          CrewMember(person: dup, role: CrewRole.exm),
        ]);

        await repo.mergePeople(sourceId: dup.id, targetId: anna.id);

        final sharedCrew = await db.getFlightCrew(shared);
        expect(sharedCrew.map((c) => (c.person.id, c.role)), [
          (anna.id, CrewRole.ins),
        ]);
        final dupCrew = await db.getFlightCrew(onlyDup);
        expect(dupCrew.map((c) => (c.person.id, c.role)), [
          (anna.id, CrewRole.exm),
        ]);
        final people = await repo.watchPeople().first;
        expect(people.single.person.id, anna.id);
        expect(people.single.flightCount, 2);
      },
    );
  });

  group('photos', () {
    late LogbookDatabase db;
    late Directory root;
    late PersonPhotoStore store;
    late PersonRepository repo;

    setUp(() async {
      db = LogbookDatabase(NativeDatabase.memory());
      root = await Directory.systemTemp.createTemp('zenith_photos');
      store = PersonPhotoStore(() async => root);
      repo = PersonRepository(db, store);
    });
    tearDown(() async {
      await db.close();
      await root.delete(recursive: true);
    });

    Future<String> storePhoto() async {
      final src = File('${root.path}/src.png')..writeAsBytesSync([1, 2, 3]);
      return store.save(src);
    }

    bool exists(String name) =>
        File('${root.path}/people_photos/$name').existsSync();

    test('replacing a photo deletes the old file', () async {
      final first = await storePhoto();
      final p = await repo.addPerson(name: 'A', surname: 'B', photo: first);
      final second = await storePhoto();

      await repo.updatePerson(
        p.id,
        name: 'A',
        surname: 'B',
        photo: Value(second),
      );
      expect(exists(first), isFalse);
      expect(exists(second), isTrue);

      // Renaming without touching the photo keeps it.
      await repo.updatePerson(p.id, name: 'A', surname: 'C');
      expect(exists(second), isTrue);

      await repo.updatePerson(
        p.id,
        name: 'A',
        surname: 'C',
        photo: const Value(null),
      );
      expect(exists(second), isFalse);
    });

    test('deleting and merging remove the photo file', () async {
      final photo = await storePhoto();
      final dup = await repo.addPerson(name: 'A', surname: 'B', photo: photo);
      final keep = await repo.addPerson(name: 'A', surname: 'Bee');
      await repo.mergePeople(sourceId: dup.id, targetId: keep.id);
      expect(exists(photo), isFalse);
    });
  });

  test('watchPerson, watchRoles and flights for a person', () async {
    final db = LogbookDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = PersonRepository(db);
    final anna = await repo.addPerson(name: 'Anna', surname: 'Rossi');
    final f1 = await addFlight(db, DateTime(2026, 1, 2));
    final f2 = await addFlight(db, DateTime(2026, 2, 3));
    await addFlight(db, DateTime(2026, 3, 4));
    await db.setFlightCrew(f1, [CrewMember(person: anna, role: CrewRole.ins)]);
    await db.setFlightCrew(f2, [CrewMember(person: anna, role: CrewRole.exm)]);

    final entry = await repo.watchPerson(anna.id).first;
    expect(entry!.flightCount, 2);
    expect(await repo.watchRoles(anna.id).first, {
      f1: CrewRole.ins,
      f2: CrewRole.exm,
    });
    final flights = await FlightRepository(
      db,
    ).watchFlightsForPerson(anna.id).first;
    expect(flights.map((f) => f.flight.id), [f2, f1]);

    await repo.deletePerson(anna.id);
    expect(await repo.watchPerson(anna.id).first, isNull);
  });
}
