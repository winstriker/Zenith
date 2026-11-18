import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/search.dart';
import '../providers/database_provider.dart';
import '../services/database.dart';
import '../services/person_photo_store.dart';

/// Repository for aircraft data access using Drift's reactive queries
class AircraftRepository {
  AircraftRepository(this._database, [this._photos]);
  final LogbookDatabase _database;

  /// Where photos picked by the user live. Their files are deleted along
  /// with the aircraft or when the photo is replaced.
  final AircraftPhotoStore? _photos;

  /// Stream of a specific aircraft with stats
  Stream<AircraftWithStats?> watchAircraftWithStats(int id) {
    final stmt = _database.aircraftWithStatss.select();
    stmt.where((acws) => acws.id.equals(id));
    stmt.limit(1);
    return stmt.watchSingle();
  }

  /// Stream of the aircraft with stats, in the order they were added.
  ///
  /// Only those matching [query] (see `sqlMatchesAllTokens`), and only the
  /// first [limit] of them when given: a list grows by asking a bigger one.
  Stream<List<AircraftWithStats>> watchAircraftsWithStats({
    int? limit,
    String query = '',
  }) {
    final view = _database.aircraftWithStatss;
    final stmt = _database.select(view)
      ..where(
        (a) => sqlMatchesAllTokens(searchTokens(query), [
          a.tailNumber,
          a.modelFullName,
          a.manufacturer,
          a.designator,
          a.notes,
        ]),
      )
      ..orderBy([(a) => OrderingTerm.asc(a.id)]);
    if (limit != null) stmt.limit(limit);
    return stmt.watch();
  }

  /// Stream of a single aircraft with ICAO data
  Stream<AircraftWithIcao?> watchAircraftWithIcao(int id) {
    return (_database.select(
      _database.aircraftWithIcaos,
    )..where((a) => a.id.equals(id))).watchSingleOrNull();
  }

  /// Stream of a specific aircraft
  Stream<Aircraft?> watchAircraft(int id) {
    return (_database.select(
      _database.aircrafts,
    )..where((a) => a.id.equals(id))).watchSingleOrNull();
  }

  /// Search ICAO aircrafts by model name, manufacturer, or type
  Future<List<IcaoAircraft>> searchIcaoAircrafts(
    String query, {
    int limit = 50,
  }) async {
    final term = '%$query%';
    return (_database.select(_database.icaoAircrafts)
          ..where(
            (a) =>
                a.modelFullName.like(term) |
                a.manufacturer.like(term) |
                a.designator.like(term),
          )
          ..orderBy([
            (a) => OrderingTerm.asc(a.manufacturer),
            (a) => OrderingTerm.asc(a.modelFullName),
          ])
          ..limit(limit))
        .get();
  }

  /// Stream of all ICAO aircrafts
  Stream<List<IcaoAircraft>> watchAllIcaoAircrafts() {
    return (_database.select(_database.icaoAircrafts)..orderBy([
          (a) => OrderingTerm.asc(a.manufacturer),
          (a) => OrderingTerm.asc(a.modelFullName),
        ]))
        .watch();
  }

  /// The user's aircraft of the ICAO type [icaoAircraftId].
  Stream<List<AircraftWithStats>> watchAircraftsOfType(int icaoAircraftId) {
    return (_database.select(_database.aircraftWithStatss)
          ..where((a) => a.icaoAircraft.equals(icaoAircraftId))
          ..orderBy([(a) => OrderingTerm.asc(a.tailNumber)]))
        .watch();
  }

  /// Every ICAO type, for matching a type by name.
  Future<List<IcaoAircraft>> getAllIcaoAircrafts() {
    return _database.select(_database.icaoAircrafts).get();
  }

  /// The type ratings already given to aircraft, alphabetically.
  Future<List<String>> getTypeRatings() async {
    final rating = _database.aircrafts.typeRating;
    final query = _database.selectOnly(_database.aircrafts, distinct: true)
      ..addColumns([rating])
      ..where(rating.isNotNull())
      ..orderBy([OrderingTerm.asc(rating)]);
    final rows = await query.get();
    return [for (final row in rows) row.read(rating)!];
  }

  // Mutating operations
  Future<int> addAircraft({
    required int icaoAircraftId,
    required String tailNumber,
    String? notes,
    AircraftClass? aircraftClass,
    String? typeRating,
    AircraftPhoto? photo,
  }) async {
    return _database
        .into(_database.aircrafts)
        .insert(
          AircraftsCompanion.insert(
            icaoAircraft: icaoAircraftId,
            tailNumber: tailNumber,
            notes: Value(notes),
            aircraftClass: Value(aircraftClass),
            typeRating: Value(_typeRatingFor(aircraftClass, typeRating)),
            photoFile: Value(photo?.file),
            photoUrl: Value(photo?.url),
            photoThumbnailUrl: Value(photo?.thumbnailUrl),
            photoLink: Value(photo?.link),
            photoCredit: Value(photo?.credit),
          ),
        );
  }

  /// A type rating only means something next to [AircraftClass.type].
  static String? _typeRatingFor(AircraftClass? aircraftClass, String? rating) {
    final trimmed = rating?.trim() ?? '';
    return aircraftClass == AircraftClass.type && trimmed.isNotEmpty
        ? trimmed
        : null;
  }

  Future<int> addIcaoAircraft({
    required String modelFullName,
    required String manufacturer,
    required String designator,
    required WakeTurbulenceCategory wakeTurbolenceCategory,
    required WakeTurbulenceGroup wakeTurbolenceGroup,
    required AircraftDescription description,
    required int engineCount,
    required EngineType engineType,
  }) async {
    return _database.addIcaoAircraft(
      modelFullName: modelFullName,
      manufacturer: manufacturer,
      designator: designator,
      wakeTurbolenceCategory: wakeTurbolenceCategory,
      wakeTurbolenceGroup: wakeTurbolenceGroup,
      description: description,
      engineCount: engineCount,
      engineType: engineType,
    );
  }

  /// Stream of one ICAO type; null once deleted.
  Stream<IcaoAircraft?> watchIcaoAircraft(int id) {
    return (_database.select(
      _database.icaoAircrafts,
    )..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  /// Rewrites a custom type. Downloaded types are left alone: the next
  /// download would undo the change.
  Future<void> updateIcaoAircraft(
    int id, {
    required String modelFullName,
    required String manufacturer,
    required String designator,
    required WakeTurbulenceCategory wakeTurbolenceCategory,
    required WakeTurbulenceGroup wakeTurbolenceGroup,
    required AircraftDescription description,
    required int engineCount,
    required EngineType engineType,
  }) async {
    await (_database.update(
      _database.icaoAircrafts,
    )..where((t) => t.id.equals(id) & t.userInserted.equals(true))).write(
      IcaoAircraftsCompanion(
        modelFullName: Value(modelFullName),
        manufacturer: Value(manufacturer),
        designator: Value(designator),
        wakeTurbolenceCategory: Value(wakeTurbolenceCategory),
        wakeTurbolenceGroup: Value(wakeTurbolenceGroup),
        description: Value(description),
        engineCount: Value(engineCount),
        engineType: Value(engineType),
      ),
    );
  }

  /// How many aircraft and simulators are of the type [id].
  Future<int> countTypeUsage(int id) async {
    final row = await _database
        .customSelect(
          'SELECT (SELECT COUNT(*) FROM aircrafts WHERE icao_aircraft = ?1) '
          '+ (SELECT COUNT(*) FROM simulators WHERE icao_aircraft = ?1) AS n',
          variables: [Variable.withInt(id)],
        )
        .getSingle();
    return row.read<int>('n');
  }

  /// Deletes a custom type, unless an aircraft or simulator still uses it:
  /// foreign keys aren't enforced, so they would point at nothing. Returns
  /// whether it was deleted.
  Future<bool> deleteIcaoAircraft(int id) {
    return _database.transaction(() async {
      if (await countTypeUsage(id) > 0) return false;
      final deleted = await (_database.delete(
        _database.icaoAircrafts,
      )..where((t) => t.id.equals(id) & t.userInserted.equals(true))).go();
      return deleted > 0;
    });
  }

  /// Rewrites an aircraft. When [photo] is given, its value (or null, to
  /// remove the photo) replaces the current one; a replaced photo that was
  /// a file is deleted.
  Future<void> updateAircraft(
    int id, {
    required int icaoAircraftId,
    required String tailNumber,
    String? notes,
    AircraftClass? aircraftClass,
    String? typeRating,
    Value<AircraftPhoto?> photo = const Value.absent(),
  }) async {
    final old = await _get(id);
    final newPhoto = photo.value;
    await (_database.update(
      _database.aircrafts,
    )..where((a) => a.id.equals(id))).write(
      AircraftsCompanion(
        icaoAircraft: Value(icaoAircraftId),
        tailNumber: Value(tailNumber),
        notes: Value(notes),
        aircraftClass: Value(aircraftClass),
        typeRating: Value(_typeRatingFor(aircraftClass, typeRating)),
        photoFile: photo.present ? Value(newPhoto?.file) : const Value.absent(),
        photoUrl: photo.present ? Value(newPhoto?.url) : const Value.absent(),
        photoThumbnailUrl: photo.present
            ? Value(newPhoto?.thumbnailUrl)
            : const Value.absent(),
        photoLink: photo.present ? Value(newPhoto?.link) : const Value.absent(),
        photoCredit: photo.present
            ? Value(newPhoto?.credit)
            : const Value.absent(),
      ),
    );
    if (photo.present && old?.photoFile != newPhoto?.file) {
      await _photos?.delete(old?.photoFile);
    }
  }

  /// How the aircraft is written in the exported logbook: [type] instead of
  /// its ICAO designator, and a [subtitle] line under it. Blank clears
  /// either.
  Future<void> setLogbookEntry(int id, {String? type, String? subtitle}) {
    String? orNull(String? text) =>
        text == null || text.trim().isEmpty ? null : text.trim();
    return (_database.update(
      _database.aircrafts,
    )..where((a) => a.id.equals(id))).write(
      AircraftsCompanion(
        logbookType: Value(orNull(type)),
        logbookSubtitle: Value(orNull(subtitle)),
      ),
    );
  }

  /// Deletes an aircraft (and its photo file) and detaches it from its
  /// flights, atomically.
  Future<void> deleteAircraft(int id) async {
    final old = await _get(id);
    await _database.transaction(() async {
      await (_database.update(_database.flights)
            ..where((f) => f.aircraftId.equals(id)))
          .write(const FlightsCompanion(aircraftId: Value(null)));
      await (_database.delete(
        _database.aircrafts,
      )..where((a) => a.id.equals(id))).go();
    });
    await _photos?.delete(old?.photoFile);
  }

  Future<Aircraft?> _get(int id) => (_database.select(
    _database.aircrafts,
  )..where((a) => a.id.equals(id))).getSingleOrNull();
}

final aircraftRepositoryProvider = Provider<AircraftRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return AircraftRepository(db, ref.watch(aircraftPhotoStoreProvider));
});
