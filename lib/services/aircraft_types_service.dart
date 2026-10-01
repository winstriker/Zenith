import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'database.dart';

class AircraftTypesService {
  AircraftTypesService(this.database);
  final logger = Logger("Aircraft Types Service");
  final LogbookDatabase database;
  final String icaoTypesUrl = const String.fromEnvironment("ICAO_TYPES_URL");

  Future<void> loadData() async {
    final client = http.Client();

    final response = await client.post(Uri.parse(icaoTypesUrl));
    final List<dynamic> icaoAircrafts =
        jsonDecode(response.body) as List<dynamic>;

    int counter = 0;
    icaoAircrafts.map((val) {
      return IcaoAircraft(
        id: counter++,
        modelFullName: val["ModelFullName"] as String,
        wakeTurbolenceCategory: switch (val['WTC'] as String) {
          "J" => WakeTurbolenceCategory.J,
          "H" => WakeTurbolenceCategory.H,
          "M" => WakeTurbolenceCategory.M,
          "L" => WakeTurbolenceCategory.L,
          _ => WakeTurbolenceCategory.Z,
        },
        wakeTurbolenceGroup: switch (val['WTG'] as String) {
          "A" => WakeTurbolenceGroup.A,
          "B" => WakeTurbolenceGroup.B,
          "C" => WakeTurbolenceGroup.C,
          "D" => WakeTurbolenceGroup.D,
          "E" => WakeTurbolenceGroup.E,
          "F" => WakeTurbolenceGroup.F,
          "G" => WakeTurbolenceGroup.G,
          _ => WakeTurbolenceGroup.Z,
        },
        manufacturer: val["ManufacturerCode"] as String,
        description: switch (val['AircraftDescription'] as String) {
          "Amphibian" => AircraftDescription.amphibian,
          "LandPlane" => AircraftDescription.landplane,
          "SeaPlane" => AircraftDescription.seaplane,
          "Helicopter" => AircraftDescription.helicopter,
          "Gyrocopter" => AircraftDescription.gyrocopter,
          "Tiltrotor" => AircraftDescription.tiltrotor,
          _ => AircraftDescription.unsupported,
        },
        engineCount: val["EngineCount"] as int,
        engineType: switch (val["EngineType"] as String) {
          'Jet' => EngineType.jet,
          'Piston' => EngineType.piston,
          'Turboprop/Turboshaft' => EngineType.turboprop,
          'Electric' => EngineType.electric,
          'Rocket' => EngineType.rocket,
          _ => EngineType.none,
        },
      );
    });
  }
}
