import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/currency.dart';
import '../models/logbook_entry.dart';
import '../providers/database_provider.dart';
import '../services/database.dart';

/// Licences, their ratings and medical certificates, plus the logbook as
/// the currency rules read it.
class LicenceRepository {
  LicenceRepository(this._db);
  final LogbookDatabase _db;

  // Licences -----------------------------------------------------------------

  /// Every licence with its ratings, oldest first.
  Stream<List<LicenceWithRatings>> watchLicences() {
    final query = _db.select(_db.licences).join([
      leftOuterJoin(
        _db.licenceRatings,
        _db.licenceRatings.licence.equalsExp(_db.licences.id),
      ),
    ])..orderBy([OrderingTerm.asc(_db.licences.id)]);
    return query.watch().map((rows) {
      final licences = <int, Licence>{};
      final ratings = <int, List<LicenceRating>>{};
      for (final row in rows) {
        final licence = row.readTable(_db.licences);
        licences[licence.id] = licence;
        final list = ratings.putIfAbsent(licence.id, () => []);
        final rating = row.readTableOrNull(_db.licenceRatings);
        if (rating != null) list.add(rating);
      }
      return [
        for (final MapEntry(:key, :value) in licences.entries)
          LicenceWithRatings(value, ratings[key]!..sort(_byKindThenTitle)),
      ];
    });
  }

  Stream<LicenceWithRatings?> watchLicence(int id) => watchLicences().map(
    (all) => all.where((l) => l.licence.id == id).firstOrNull,
  );

  static int _byKindThenTitle(LicenceRating a, LicenceRating b) {
    final kind = a.kind.index.compareTo(b.kind.index);
    if (kind != 0) return kind;
    final cls = (a.aircraftClass?.index ?? -1).compareTo(
      b.aircraftClass?.index ?? -1,
    );
    return cls != 0 ? cls : a.title.compareTo(b.title);
  }

  Future<int> addLicence(LicencesCompanion licence) =>
      _db.into(_db.licences).insert(licence);

  Future<void> updateLicence(int id, LicencesCompanion licence) =>
      (_db.update(_db.licences)..where((l) => l.id.equals(id))).write(licence);

  /// Deletes the licence and its ratings.
  Future<void> deleteLicence(int id) => _db.transaction(() async {
    await (_db.delete(
      _db.licenceRatings,
    )..where((r) => r.licence.equals(id))).go();
    await (_db.delete(_db.licences)..where((l) => l.id.equals(id))).go();
  });

  // Ratings ------------------------------------------------------------------

  Future<int> addRating(LicenceRatingsCompanion rating) =>
      _db.into(_db.licenceRatings).insert(rating);

  Future<void> updateRating(int id, LicenceRatingsCompanion rating) =>
      (_db.update(
        _db.licenceRatings,
      )..where((r) => r.id.equals(id))).write(rating);

  Future<void> deleteRating(int id) =>
      (_db.delete(_db.licenceRatings)..where((r) => r.id.equals(id))).go();

  /// Names already given to ratings of [kind], and for type ratings the ones
  /// given to aircraft too, alphabetically: suggestions for the name field.
  Future<List<String>> ratingNameSuggestions(RatingKind kind) async {
    final name = _db.licenceRatings.name;
    final own = _db.selectOnly(_db.licenceRatings, distinct: true)
      ..addColumns([name])
      ..where(_db.licenceRatings.kind.equalsValue(kind) & name.isNotNull());
    final names = {for (final row in await own.get()) row.read(name)!};
    if (kind == RatingKind.typeRating) {
      final rating = _db.aircrafts.typeRating;
      final fromAircraft = _db.selectOnly(_db.aircrafts, distinct: true)
        ..addColumns([rating])
        ..where(rating.isNotNull());
      names.addAll([
        for (final row in await fromAircraft.get()) row.read(rating)!,
      ]);
    }
    // One spelling per rating.
    final unique = <String, String>{
      for (final n in names) normalizeTypeRating(n): n.trim(),
    };
    return unique.values.where((n) => n.isNotEmpty).toList()..sort();
  }

  // Medicals -----------------------------------------------------------------

  /// Medical certificates, the one expiring last first.
  Stream<List<MedicalCertificate>> watchMedicals() => (_db.select(
    _db.medicalCertificates,
  )..orderBy([(m) => OrderingTerm.desc(m.expiryDate)])).watch();

  /// The medical certificate [id], null once deleted.
  Stream<MedicalCertificate?> watchMedical(int id) => (_db.select(
    _db.medicalCertificates,
  )..where((m) => m.id.equals(id))).watchSingleOrNull();

  Future<int> addMedical(MedicalCertificatesCompanion medical) =>
      _db.into(_db.medicalCertificates).insert(medical);

  Future<void> updateMedical(int id, MedicalCertificatesCompanion medical) =>
      (_db.update(
        _db.medicalCertificates,
      )..where((m) => m.id.equals(id))).write(medical);

  Future<void> deleteMedical(int id) =>
      (_db.delete(_db.medicalCertificates)..where((m) => m.id.equals(id))).go();

  // Logbook ------------------------------------------------------------------

  /// The flights since [since] as the currency rules see them, again
  /// whenever a flight, its crew or an aircraft changes.
  Stream<List<CurrencyFlight>> watchCurrencyFlights({required DateTime since}) {
    final updates = _db.tableUpdates(
      TableUpdateQuery.onAllTables([
        _db.flights,
        _db.flightCrew,
        _db.aircrafts,
      ]),
    );
    // Not an async* generator: cancelling one that waits in an `await for`
    // only completes once the next update comes.
    return Stream<void>.multi((controller) {
      controller.add(null);
      final sub = updates.listen(
        (_) => controller.add(null),
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = sub.cancel;
    }).asyncMap((_) => currencyFlights(since: since));
  }

  /// The logged flights since [since], with each time worked out as in the
  /// logbook (overrides included).
  Future<List<CurrencyFlight>> currencyFlights({
    required DateTime since,
  }) async {
    final rows =
        await (_db.select(_db.flights).join([
              leftOuterJoin(
                _db.aircrafts,
                _db.aircrafts.id.equalsExp(_db.flights.aircraftId),
              ),
            ])..where(
              _db.flights.isRecording.equals(false) &
                  _db.flights.departureTime.isBiggerOrEqualValue(since),
            ))
            .get();
    final crew = await _db.getCrewForFlights(
      rows.map((r) => r.readTable(_db.flights).id),
    );
    return [for (final row in rows) _toCurrencyFlight(row, crew)];
  }

  CurrencyFlight _toCurrencyFlight(
    TypedResult row,
    Map<int, List<CrewMember>> crew,
  ) {
    final flight = row.readTable(_db.flights);
    final aircraft = row.readTableOrNull(_db.aircrafts);
    final members = crew[flight.id] ?? const <CrewMember>[];
    final entry = LogbookEntry.of(
      FlightWithStats(flight: flight, dataPoints: const []),
      crew: members,
    );
    final pic = entry.time(LogbookTimeField.pic);
    final ifr = entry.time(LogbookTimeField.ifr);
    return CurrencyFlight(
      date: flight.departureTime,
      total: entry.time(LogbookTimeField.total),
      pic: pic,
      dual: entry.time(LogbookTimeField.dual),
      instructor: entry.time(LogbookTimeField.instructor),
      ifr: ifr,
      picIfr: ifr < pic ? ifr : pic,
      dayLandings: entry.dayLandings,
      nightLandings: entry.nightLandings,
      aircraftClass: aircraft?.aircraftClass,
      typeRating: aircraft?.typeRating,
      // Not without the examiner, should they have been removed since.
      proficiencyCheck:
          flight.proficiencyCheck && members.any((m) => m.role == CrewRole.exm),
    );
  }
}

final licenceRepositoryProvider = Provider<LicenceRepository>(
  (ref) => LicenceRepository(ref.watch(databaseProvider)),
);
