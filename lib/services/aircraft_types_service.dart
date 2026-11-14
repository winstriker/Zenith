import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'database.dart';

class AircraftTypesService {
  AircraftTypesService(this.database);
  final logger = Logger("Aircraft Types Service");
  final LogbookDatabase database;
  final String icaoTypesUrl = const String.fromEnvironment("ICAO_TYPES_URL");
  final List<Function> _callbacks = [];

  void addListener(Function fun) {
    _callbacks.add(fun);
  }

  void removeListener(Function fun) {
    _callbacks.remove(fun);
  }

  void _notify() {
    for (final fun in _callbacks) {
      fun();
    }
  }

  Future<void> loadData({bool forceDownload = false}) async {
    await repairOrphanedAircraft(database);
    final stat = database.select(database.icaoAircrafts);
    stat.where((val) => val.userInserted.equals(false));
    stat.limit(1);
    final result = await stat.getSingleOrNull();
    if (!forceDownload && result != null) {
      logger.log(
        Level.INFO,
        "Types Database is already populated, not downloading again.",
      );
      return;
    }
    return _loadData(
      database,
      icaoTypesUrl,
      logger,
      forceDownload: forceDownload,
      notify: _notify,
    );
  }

  static Future<void> _loadData(
    LogbookDatabase database,
    String icaoTypesUrl,
    Logger logger, {
    bool forceDownload = false,
    Function? notify,
  }) async {
    final client = http.Client();
    final url = icaoTypesUrl;

    try {
      final response = await client.post(Uri.parse(url));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw http.ClientException(
          'ICAO types download failed (${response.statusCode})',
          Uri.parse(url),
        );
      }
      // Decoding and mapping run in the background isolate too: the list
      // is large and runs at startup, while the UI is animating.
      final json = response.body;
      final count = await database.computeWithDatabase(
        computation: (db) => _parseAndSync(db, json),
        connect: LogbookDatabase.new,
      );
      logger.log(
        Level.INFO,
        "Successfully synced $count aircraft types in the database.",
      );
      if (notify != null) {
        notify();
      }
    } catch (e) {
      logger.log(Level.SEVERE, "Error while loading aircraft types. $e");
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Runs in a background isolate: decodes the downloaded ICAO list and
  /// merges it into the table. Returns how many types were synced.
  static Future<int> _parseAndSync(LogbookDatabase db, String json) async {
    final List<dynamic> icaoAircrafts = jsonDecode(json) as List<dynamic>;

    final companions = icaoAircrafts.map((val) {
      return IcaoAircraftsCompanion.insert(
        modelFullName: val["ModelFullName"] as String,
        designator: val["Designator"] as String,
        wakeTurbolenceCategory: _mapWakeTurbulenceCategory(
          val['WTC'] as String?,
        ),
        wakeTurbolenceGroup: _mapWakeTurbulenceGroup(val['WTG'] as String?),
        manufacturer: val["ManufacturerCode"] as String,
        description: _mapAircraftDescription(
          val['AircraftDescription'] as String?,
        ),
        engineCount: int.tryParse(val["EngineCount"] as String) ?? 0,
        engineType: _mapEngineType(val["EngineType"] as String?),
        userInserted: const Value(false),
      );
    }).toList();
    if (companions.isEmpty) {
      // Never wipe the local list because of an empty response.
      throw StateError('ICAO types download returned no aircraft types');
    }

    await syncTypes(db, companions);
    return companions.length;
  }

  /// Merges a freshly downloaded ICAO list into the table without changing
  /// the id of any type that is still listed, because aircraft point to
  /// types by id. Types are matched on designator, model and manufacturer:
  /// matches are updated in place, new types are added, and types that left
  /// the list are deleted unless an aircraft still uses them.
  /// User-inserted types are never touched.
  static Future<void> syncTypes(
    LogbookDatabase db,
    List<IcaoAircraftsCompanion> types,
  ) {
    String key(String designator, String model, String manufacturer) =>
        '$designator\u0000$model\u0000$manufacturer';

    return db.transaction(() async {
      final existing =
          await (db.select(db.icaoAircrafts)
                ..where((t) => t.userInserted.equals(false))
                ..orderBy([(t) => OrderingTerm.asc(t.id)]))
              .get();
      // A list per key, in case ICAO lists the same type twice.
      final idsByKey = <String, List<int>>{};
      for (final row in existing) {
        idsByKey
            .putIfAbsent(
              key(row.designator, row.modelFullName, row.manufacturer),
              () => [],
            )
            .add(row.id);
      }

      final matched = <int>{};
      final updates = <(int, IcaoAircraftsCompanion)>[];
      final inserts = <IcaoAircraftsCompanion>[];
      for (final type in types) {
        final ids =
            idsByKey[key(
              type.designator.value,
              type.modelFullName.value,
              type.manufacturer.value,
            )];
        if (ids != null && ids.isNotEmpty) {
          final id = ids.removeAt(0);
          matched.add(id);
          updates.add((id, type));
        } else {
          inserts.add(type);
        }
      }

      final used = {
        for (final row
            in await db
                .customSelect('SELECT DISTINCT icao_aircraft FROM aircrafts')
                .get())
          row.read<int>('icao_aircraft'),
      };
      final stale = [
        for (final row in existing)
          if (!matched.contains(row.id) && !used.contains(row.id)) row.id,
      ];

      await db.batch((batch) {
        for (final (id, type) in updates) {
          batch.update(db.icaoAircrafts, type, where: (t) => t.id.equals(id));
        }
        batch.insertAll(db.icaoAircrafts, inserts);
        for (final id in stale) {
          batch.deleteWhere(db.icaoAircrafts, (t) => t.id.equals(id));
        }
      });
    });
  }

  /// Older versions replaced every ICAO type with new ids on reload, leaving
  /// aircraft pointing at types that no longer exist (and so hidden from
  /// every aircraft list). Gives each such aircraft an "Unknown type" at the
  /// missing id so it shows up again and its type can be picked anew.
  /// Returns how many types were recreated.
  static Future<int> repairOrphanedAircraft(LogbookDatabase db) async {
    final missing = await db
        .customSelect(
          'SELECT DISTINCT icao_aircraft FROM aircrafts '
          'WHERE icao_aircraft NOT IN (SELECT id FROM icao_aircrafts)',
        )
        .get();
    for (final row in missing) {
      await db
          .into(db.icaoAircrafts)
          .insert(
            IcaoAircraftsCompanion.insert(
              id: Value(row.read<int>('icao_aircraft')),
              modelFullName: 'Unknown type',
              designator: 'ZZZZ',
              manufacturer: 'Unknown',
              wakeTurbolenceCategory: WakeTurbulenceCategory.Z,
              wakeTurbolenceGroup: WakeTurbulenceGroup.Z,
              description: AircraftDescription.unsupported,
              engineCount: 0,
              engineType: EngineType.none,
              // Kept out of syncTypes, which only manages downloaded types.
              userInserted: const Value(true),
            ),
          );
    }
    return missing.length;
  }

  static WakeTurbulenceCategory _mapWakeTurbulenceCategory(String? str) {
    switch (str) {
      case "J":
        return WakeTurbulenceCategory.J;
      case "H":
        return WakeTurbulenceCategory.H;
      case "M":
        return WakeTurbulenceCategory.M;
      case "L":
        return WakeTurbulenceCategory.L;
      default:
        return WakeTurbulenceCategory.Z;
    }
  }

  static WakeTurbulenceGroup _mapWakeTurbulenceGroup(String? str) {
    switch (str) {
      case "A":
        return WakeTurbulenceGroup.A;
      case "B":
        return WakeTurbulenceGroup.B;
      case "C":
        return WakeTurbulenceGroup.C;
      case "D":
        return WakeTurbulenceGroup.D;
      case "E":
        return WakeTurbulenceGroup.E;
      case "F":
        return WakeTurbulenceGroup.F;
      case "G":
        return WakeTurbulenceGroup.G;
      default:
        return WakeTurbulenceGroup.Z;
    }
  }

  static AircraftDescription _mapAircraftDescription(String? str) {
    switch (str) {
      case "Amphibian":
        return AircraftDescription.amphibian;
      case "LandPlane":
        return AircraftDescription.landplane;
      case "SeaPlane":
        return AircraftDescription.seaplane;
      case "Helicopter":
        return AircraftDescription.helicopter;
      case "Gyrocopter":
        return AircraftDescription.gyrocopter;
      case "Tiltrotor":
        return AircraftDescription.tiltrotor;
      default:
        return AircraftDescription.unsupported;
    }
  }

  static EngineType _mapEngineType(String? str) {
    switch (str) {
      case 'Jet':
        return EngineType.jet;
      case 'Piston':
        return EngineType.piston;
      case 'Turboprop/Turboshaft':
        return EngineType.turboprop;
      case 'Electric':
        return EngineType.electric;
      case 'Rocket':
        return EngineType.rocket;
      default:
        return EngineType.none;
    }
  }
}
