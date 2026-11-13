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
      final List<dynamic> icaoAircrafts =
          jsonDecode(response.body) as List<dynamic>;

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

      await database.computeWithDatabase(
        computation: (db) async {
          final stat = db.icaoAircrafts.delete();
          stat.where((ac) => ac.userInserted.equals(false));
          await stat.go();
          await db.batch((batch) {
            batch.insertAll(db.icaoAircrafts, companions);
          });
        },
        connect: LogbookDatabase.new,
      );
      logger.log(
        Level.INFO,
        "Successfully inserted ${companions.length} aircraft types in the database.",
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
