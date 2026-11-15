import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/aircraft_class.dart';
import 'package:zenith/models/aircraft_type_enums.dart';

void main() {
  List<AircraftClass> candidates(
    AircraftDescription description,
    int engines,
    EngineType engine,
  ) => AircraftClass.candidatesFor(
    description: description,
    engineCount: engines,
    engineType: engine,
  );

  AircraftClass? deduce(
    AircraftDescription description,
    int engines,
    EngineType engine,
  ) => AircraftClass.deduce(
    description: description,
    engineCount: engines,
    engineType: engine,
  );

  const land = AircraftDescription.landplane;
  const sea = AircraftDescription.seaplane;

  test('piston aeroplanes are SEP or MEP, land or sea', () {
    expect(deduce(land, 1, EngineType.piston), AircraftClass.sepLand);
    expect(deduce(sea, 1, EngineType.piston), AircraftClass.sepSea);
    expect(deduce(land, 2, EngineType.piston), AircraftClass.mepLand);
    expect(deduce(sea, 2, EngineType.piston), AircraftClass.mepSea);
    expect(deduce(land, 4, EngineType.piston), AircraftClass.mepLand);
  });

  test('single-engine turboprops are SET, the others need a type rating', () {
    expect(deduce(land, 1, EngineType.turboprop), AircraftClass.setLand);
    expect(deduce(sea, 1, EngineType.turboprop), AircraftClass.setSea);
    expect(deduce(land, 2, EngineType.turboprop), AircraftClass.type);
  });

  test('every jet needs a type rating', () {
    expect(deduce(land, 1, EngineType.jet), AircraftClass.type);
    expect(deduce(land, 2, EngineType.jet), AircraftClass.type);
    expect(deduce(sea, 2, EngineType.jet), AircraftClass.type);
  });

  test('a single electric engine is still SEP', () {
    expect(deduce(land, 1, EngineType.electric), AircraftClass.sepLand);
    expect(deduce(land, 2, EngineType.electric), isNull);
  });

  test('amphibians can be land or sea, so nothing is deduced', () {
    expect(candidates(AircraftDescription.amphibian, 1, EngineType.piston), [
      AircraftClass.sepLand,
      AircraftClass.sepSea,
    ]);
    expect(deduce(AircraftDescription.amphibian, 1, EngineType.piston), isNull);
    expect(candidates(AircraftDescription.amphibian, 1, EngineType.turboprop), [
      AircraftClass.setLand,
      AircraftClass.setSea,
    ]);
    // No such doubt when the answer is a type rating either way.
    expect(
      deduce(AircraftDescription.amphibian, 2, EngineType.turboprop),
      AircraftClass.type,
    );
  });

  test('helicopters and tiltrotors always need a type rating', () {
    for (final engine in [EngineType.piston, EngineType.turboprop]) {
      expect(
        deduce(AircraftDescription.helicopter, 1, engine),
        AircraftClass.type,
      );
    }
    expect(
      deduce(AircraftDescription.tiltrotor, 2, EngineType.turboprop),
      AircraftClass.type,
    );
  });

  test('gliders, balloons and national-rules aircraft', () {
    expect(
      deduce(AircraftDescription.sailplane, 0, EngineType.none),
      AircraftClass.sailplane,
    );
    expect(candidates(AircraftDescription.motorglider, 1, EngineType.piston), [
      AircraftClass.tmg,
      AircraftClass.sailplane,
    ]);
    expect(
      deduce(AircraftDescription.balloon, 0, EngineType.none),
      AircraftClass.balloon,
    );
    expect(
      deduce(AircraftDescription.gyrocopter, 1, EngineType.piston),
      AircraftClass.other,
    );
    expect(
      deduce(AircraftDescription.ultralightAircraft, 1, EngineType.piston),
      AircraftClass.other,
    );
  });

  test('unknown types and missing engine data give nothing', () {
    expect(
      candidates(AircraftDescription.unsupported, 0, EngineType.none),
      isEmpty,
    );
    expect(candidates(land, 0, EngineType.piston), isEmpty);
    expect(candidates(land, 1, EngineType.none), isEmpty);
  });

  test('class ratings are told apart from the rest', () {
    expect(AircraftClass.sepLand.isClassRating, isTrue);
    expect(AircraftClass.tmg.isClassRating, isTrue);
    expect(AircraftClass.type.isClassRating, isFalse);
    expect(AircraftClass.sailplane.isClassRating, isFalse);
  });
}
