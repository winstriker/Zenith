import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../models/sync_progress.dart';
import 'database.dart';

class AircraftTypesService {
  AircraftTypesService(this.database);
  final logger = Logger("Aircraft Types Service");
  final LogbookDatabase database;
  final String icaoTypesUrl = const String.fromEnvironment("ICAO_TYPES_URL");

  // Share of the progress bar given to the download; saving gets the rest.
  static const _downloadEnd = 0.8;

  /// Live progress of the ICAO types download.
  final progress = ValueNotifier<SyncProgress>(
    const SyncProgress(SyncPhase.idle),
  );

  bool get isBusy => progress.value.isRunning;

  void dispose() => progress.dispose();

  void _setProgress(
    SyncPhase phase, {
    double? fraction,
    String message = '',
    Object? error,
  }) {
    progress.value = SyncProgress(
      phase,
      fraction: fraction,
      message: message,
      error: error,
    );
  }

  /// Downloads the ICAO types, unless already there and not [forceDownload].
  /// Failures end in [SyncPhase.error] rather than throwing.
  Future<void> loadData({bool forceDownload = false}) async {
    if (isBusy) return;
    // Mark as running synchronously so concurrent calls bail out above.
    _setProgress(
      SyncPhase.downloading,
      fraction: 0,
      message: 'Preparing download…',
    );
    try {
      await repairOrphanedAircraft(database);
      final stat = database.select(database.icaoAircrafts);
      stat.where((val) => val.userInserted.equals(false));
      stat.limit(1);
      if (!forceDownload && await stat.getSingleOrNull() != null) {
        logger.info("Types Database is already populated, not downloading.");
        _setProgress(SyncPhase.idle);
        return;
      }
      final json = await _download();
      _setProgress(
        SyncPhase.saving,
        fraction: _downloadEnd,
        message: 'Saving aircraft types…',
      );
      // Decoding and mapping run in the background isolate too: the list
      // is large and runs at startup, while the UI is animating.
      final count = await database.computeWithDatabase(
        computation: (db) => _parseAndSync(db, json),
        connect: LogbookDatabase.new,
      );
      logger.info("Successfully synced $count aircraft types.");
      _setProgress(
        SyncPhase.done,
        fraction: 1,
        message: 'Aircraft types updated',
      );
    } catch (e, st) {
      logger.severe("Error while loading aircraft types", e, st);
      _setProgress(
        SyncPhase.error,
        message: 'Could not download aircraft types',
        error: e,
      );
    }
  }

  /// Downloads the ICAO list, reporting byte-level progress.
  Future<String> _download() async {
    final client = http.Client();
    try {
      final uri = Uri.parse(icaoTypesUrl);
      final response = await client.send(http.Request('POST', uri));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw http.ClientException(
          'ICAO types download failed (${response.statusCode})',
          uri,
        );
      }
      final total = response.contentLength;
      final bytes = BytesBuilder(copy: false);
      final throttle = Stopwatch()..start();
      await for (final chunk in response.stream) {
        bytes.add(chunk);
        if (throttle.elapsedMilliseconds < 100) continue;
        throttle.reset();
        final received = bytes.length;
        _setProgress(
          SyncPhase.downloading,
          // Unknown size: an indeterminate bar.
          fraction: total == null || total == 0
              ? null
              : (received / total).clamp(0, 1) * _downloadEnd,
          message:
              'Downloading aircraft types — ${_mb(received)}'
              '${total == null ? '' : ' / ${_mb(total)}'} MB',
        );
      }
      return utf8.decode(bytes.takeBytes());
    } finally {
      client.close();
    }
  }

  static String _mb(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);

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
  /// the list are deleted unless an aircraft or simulator still uses them.
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
        for (final row in await db.customSelect(_usedTypesSql).get())
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

  /// Ids of the types an aircraft or simulator points to.
  static const _usedTypesSql =
      'SELECT icao_aircraft FROM aircrafts '
      'UNION SELECT icao_aircraft FROM simulators '
      'WHERE icao_aircraft IS NOT NULL';

  /// Older versions replaced every ICAO type with new ids on reload, leaving
  /// aircraft and simulators pointing at types that no longer exist (and so
  /// hidden from every aircraft list). Gives each such id an "Unknown type"
  /// so they show up again and their type can be picked anew.
  /// Returns how many types were recreated.
  static Future<int> repairOrphanedAircraft(LogbookDatabase db) async {
    final missing = await db
        .customSelect(
          'SELECT icao_aircraft FROM ($_usedTypesSql) '
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
