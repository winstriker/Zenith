import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/database_provider.dart';
import '../services/database.dart';
import '../services/person_photo_store.dart';

class PersonRepository {
  PersonRepository(this._database, [this._photos]);
  final LogbookDatabase _database;
  final PersonPhotoStore? _photos;

  /// People matching [query] (on name and surname), most recently flown with
  /// first. People never assigned to a flight come last, alphabetically.
  Stream<List<PersonWithLastFlight>> watchPeople({String query = ''}) {
    final terms = query.trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
    final db = _database;
    Expression<bool> where = const Constant(true);
    for (final term in terms) {
      final like = '%$term%';
      where &= db.people.name.like(like) | db.people.surname.like(like);
    }
    return _watch(where);
  }

  /// One person with their flight stats; emits null once they're deleted.
  Stream<PersonWithLastFlight?> watchPerson(int id) {
    return _watch(
      _database.people.id.equals(id),
    ).map((list) => list.isEmpty ? null : list.first);
  }

  /// Role the person had on each of their flights, keyed by flight id.
  Stream<Map<int, CrewRole>> watchRoles(int personId) {
    final query = _database.select(_database.flightCrew)
      ..where((c) => c.person.equals(personId));
    return query.watch().map(
      (rows) => {for (final r in rows) r.flight: r.role},
    );
  }

  Stream<List<PersonWithLastFlight>> _watch(Expression<bool> where) {
    final db = _database;
    final lastFlight = db.flights.departureTime.max();
    final flightCount = db.flightCrew.flight.count();

    final select =
        db.select(db.people).join([
            leftOuterJoin(
              db.flightCrew,
              db.flightCrew.person.equalsExp(db.people.id),
            ),
            leftOuterJoin(
              db.flights,
              db.flights.id.equalsExp(db.flightCrew.flight),
            ),
          ])
          ..addColumns([lastFlight, flightCount])
          ..where(where)
          ..groupBy([db.people.id])
          ..orderBy([
            OrderingTerm(
              expression: lastFlight,
              mode: OrderingMode.desc,
              nulls: NullsOrder.last,
            ),
            OrderingTerm.asc(db.people.surname),
            OrderingTerm.asc(db.people.name),
          ]);

    return select.watch().map(
      (rows) => [
        for (final row in rows)
          PersonWithLastFlight(
            person: row.readTable(db.people),
            lastFlight: row.read(lastFlight),
            flightCount: row.read(flightCount) ?? 0,
          ),
      ],
    );
  }

  Future<Person> addPerson({
    required String name,
    required String surname,
    String? photo,
  }) {
    return _database
        .into(_database.people)
        .insertReturning(
          PeopleCompanion.insert(
            name: name.trim(),
            surname: surname.trim(),
            photo: Value(photo),
          ),
        );
  }

  /// Renames the person. When [photo] is given, its value (a stored file
  /// name, or null to remove) replaces the current photo, whose file is
  /// deleted.
  Future<void> updatePerson(
    int id, {
    required String name,
    required String surname,
    Value<String?> photo = const Value.absent(),
  }) async {
    final old = await _get(id);
    await (_database.update(
      _database.people,
    )..where((p) => p.id.equals(id))).write(
      PeopleCompanion(
        name: Value(name.trim()),
        surname: Value(surname.trim()),
        photo: photo,
      ),
    );
    if (photo.present && old?.photo != photo.value) {
      await _photos?.delete(old?.photo);
    }
  }

  /// Deletes a person and their photo, and removes them from every flight's
  /// crew.
  Future<void> deletePerson(int id) async {
    final old = await _get(id);
    await _database.transaction(() async {
      await (_database.delete(
        _database.flightCrew,
      )..where((c) => c.person.equals(id))).go();
      await (_database.delete(
        _database.people,
      )..where((p) => p.id.equals(id))).go();
    });
    await _photos?.delete(old?.photo);
  }

  /// Moves every flight of [sourceId] onto [targetId], then deletes the
  /// source person. Where both were on the same flight, the target's role
  /// is kept.
  Future<void> mergePeople({
    required int sourceId,
    required int targetId,
  }) async {
    assert(sourceId != targetId);
    await _database.transaction(() async {
      await _database.customUpdate(
        'UPDATE OR IGNORE flight_crew SET person = ? WHERE person = ?',
        variables: [Variable.withInt(targetId), Variable.withInt(sourceId)],
        updates: {_database.flightCrew},
      );
    });
    await deletePerson(sourceId);
  }

  Future<Person?> _get(int id) => (_database.select(
    _database.people,
  )..where((p) => p.id.equals(id))).getSingleOrNull();
}

final personRepositoryProvider = Provider<PersonRepository>((ref) {
  return PersonRepository(
    ref.watch(databaseProvider),
    ref.watch(personPhotoStoreProvider),
  );
});
