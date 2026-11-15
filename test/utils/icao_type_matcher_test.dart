import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/services/database.dart';
import 'package:zenith/utils/icao_type_matcher.dart';

/// A slice of ICAO Doc 8643, spelled the way ICAO spells it.
const _doc8643 = [
  ('C172', 'CESSNA', '172'),
  ('C172', 'CESSNA', '172 Skyhawk'),
  ('C172', 'CESSNA', 'R172 Hawk XP'),
  ('C172', 'REIMS', 'F172 Skyhawk'),
  ('C152', 'CESSNA', '152'),
  ('C182', 'CESSNA', '182 Skylane'),
  ('C82R', 'CESSNA', 'R182 Skylane RG'),
  ('M20P', 'MOONEY', 'M-20F Executive'),
  ('M20P', 'MOONEY', 'M-20J Allegro'),
  ('M20T', 'MOONEY', 'M-20M Bravo'),
  ('P28A', 'PIPER', 'PA-28-161 Cherokee Warrior 2'),
  ('P28A', 'PIPER', 'PA-28-161 Cadet'),
  ('P28R', 'PIPER', 'PA-28R-201 Arrow 3'),
  ('DR40', 'ROBIN', 'DR-400 Regent'),
  ('PC12', 'PILATUS', 'PC-12'),
  ('A320', 'AIRBUS', 'A-320'),
  ('A20N', 'AIRBUS', 'A-320neo'),
  ('A321', 'AIRBUS', 'A-321'),
  ('A21N', 'AIRBUS', 'A-321neo'),
  ('A332', 'AIRBUS', 'A-330-200'),
  ('A333', 'AIRBUS', 'A-330-300'),
  ('B737', 'BOEING', '737-700'),
  ('B738', 'BOEING', '737-800'),
  ('B38M', 'BOEING', '737-8'),
  ('B38M', 'BOEING', '737 MAX 8'),
  ('B37M', 'BOEING', '737 MAX 7'),
  ('B744', 'BOEING', '747-400'),
  ('E195', 'EMBRAER', 'ERJ-190-200'),
  ('E190', 'EMBRAER', 'ERJ-190-100'),
  ('A139', 'AGUSTAWESTLAND', 'AW-139'),
  ('A139', 'AGUSTA', 'AW-139'),
  ('BE20', 'BEECH', '200 Super King Air'),
  ('PRM1', 'RAYTHEON', '390 Premier 1'),
  ('F2TH', 'DASSAULT', 'Falcon 2000'),
  ('FA20', 'DASSAULT', 'Falcon 200'),
  ('LGEZ', 'RUTAN', '61 Long-EZ'),
  ('DH8A', 'BOMBARDIER', 'DHC-8-100 Dash 8'),
  ('DH8D', 'BOMBARDIER', 'DHC-8-400 Dash 8'),
  ('PIVI', 'PIPISTREL', 'Virus (piston)'),
  ('PIVE', 'PIPISTREL', 'Virus (electric)'),
  ('M10', 'AEROSTAR (1)', '90'),
];

final _types = [
  for (final (index, (designator, manufacturer, model)) in _doc8643.indexed)
    IcaoAircraft(
      id: index + 1,
      modelFullName: model,
      designator: designator,
      wakeTurbolenceCategory: WakeTurbulenceCategory.Z,
      wakeTurbolenceGroup: WakeTurbulenceGroup.Z,
      manufacturer: manufacturer,
      description: AircraftDescription.landplane,
      engineCount: 1,
      engineType: EngineType.piston,
      userInserted: false,
    ),
];

String? _best(String name) =>
    IcaoTypeMatcher.match(name, _types).best?.designator;

List<String> _suggested(String name) => [
  for (final t in IcaoTypeMatcher.match(name, _types).suggestions) t.designator,
];

void main() {
  test('names as JetPhotos writes them find their ICAO type', () {
    const expected = {
      'Cessna 172R Skyhawk II': 'C172',
      'Reims-Cessna F172N Skyhawk': 'C172',
      'Cessna 152': 'C152',
      'Cessna 182Q Skylane': 'C182',
      'Mooney M20F Executive 21': 'M20P',
      'Mooney M20M Bravo': 'M20T',
      'Piper PA-28-161 Cherokee Warrior II': 'P28A',
      'Piper PA-28R-201 Arrow III': 'P28R',
      'Robin DR400/180 Régent': 'DR40',
      'Pilatus PC-12/47E NG': 'PC12',
      'Airbus A321-231': 'A321',
      'Airbus A330-243': 'A332',
      'Embraer ERJ-190-200LR': 'E195',
      'Agusta-Westland AW-139': 'A139',
      'Beechcraft 200 King Air': 'BE20',
      'Raytheon 390 Premier I': 'PRM1',
      'Rutan LongEZ': 'LGEZ',
    };
    for (final MapEntry(key: name, value: designator) in expected.entries) {
      expect(_best(name), designator, reason: name);
    }
  });

  test('picks the best fitting variant of a type', () {
    final match = IcaoTypeMatcher.match('Reims-Cessna F172N Skyhawk', _types);
    expect(match.best?.manufacturer, 'REIMS');
    expect(match.best?.modelFullName, 'F172 Skyhawk');
  });

  test('Boeing customer codes stand for the base model', () {
    expect(_best('Boeing 737-8K2'), 'B738');
    expect(_best('Boeing 737-7H4'), 'B737');
    expect(_best('Boeing 747-436'), 'B744');
  });

  test('Airbus engine codes ending in N are neos', () {
    expect(_best('Airbus A320-271N'), 'A20N');
    expect(_best('Airbus A321-271NX'), 'A21N');
    expect(_best('Airbus A320-214'), 'A320');
  });

  test('a number is never cut in two', () {
    expect(_best('Dassault Falcon 2000LX'), 'F2TH');
  });

  test('does not choose between types that fit equally well', () {
    final dash8 = IcaoTypeMatcher.match('Bombardier Dash 8-Q402', _types);
    expect(dash8.best, isNull);
    expect(
      dash8.suggestions.map((t) => t.designator),
      containsAll(['DH8A', 'DH8D']),
    );

    expect(_best('Pipistrel Virus SW121'), isNull);
    expect(
      _suggested('Pipistrel Virus SW121'),
      unorderedEquals(['PIVI', 'PIVE']),
    );
  });

  group('with what lookup services say', () {
    IcaoTypeMatch resolve(String? designator, List<String> names) =>
        IcaoTypeMatcher.resolve(
          designator: designator,
          names: names,
          types: _types,
        );

    test('a designator settles the type, names pick the entry', () {
      final reims = resolve('C172', ['Reims/Cessna F172N']);
      expect(reims.best?.designator, 'C172');
      expect(reims.best?.manufacturer, 'REIMS');
      // Every entry of the designator is offered, and nothing else.
      expect(reims.suggestions.map((t) => t.designator).toSet(), {'C172'});
      expect(reims.suggestions, hasLength(4));

      final skyhawk = resolve('c172', ['Cessna 172R Skyhawk']);
      expect(skyhawk.best?.modelFullName, '172 Skyhawk');
    });

    test('a designator beats a name that would say otherwise', () {
      // By name alone this is an A320; the services know it is a neo.
      expect(resolve('A20N', ['Airbus A320-214']).best?.designator, 'A20N');
      // And names nobody could match don't matter.
      expect(resolve('B738', ['Boeing 737NG 8AS/W']).best?.designator, 'B738');
      expect(resolve('PC12', []).best?.designator, 'PC12');
    });

    test('without a name that fits, the plainest entry is taken', () {
      expect(resolve('C172', ['Something else']).best?.modelFullName, '172');
    });

    test('a designator ICAO does not list falls back to the names', () {
      expect(resolve('ZZZZ', ['Cessna 152']).best?.designator, 'C152');
      expect(resolve(null, ['Cessna 152']).best?.designator, 'C152');
      // The first name that gives a sure answer wins.
      expect(
        resolve(null, ['Cameron N-90', 'Pilatus PC-12/47E']).best?.designator,
        'PC12',
      );
    });

    test('nothing known gives nothing', () {
      expect(resolve(null, []).best, isNull);
      expect(resolve('ZZZZ', ['Cameron N-90']).suggestions, isEmpty);
      // Unsure names still give suggestions.
      final dash8 = resolve(null, ['Bombardier Dash 8-Q402']);
      expect(dash8.best, isNull);
      expect(dash8.suggestions, isNotEmpty);
    });
  });

  test('finds nothing for aircraft ICAO does not list', () {
    for (final name in ['Cameron N-90', 'Schleicher Ka-2b Rhonschwalbe', '']) {
      final match = IcaoTypeMatcher.match(name, _types);
      expect(match.best, isNull, reason: name);
      expect(match.suggestions, isEmpty, reason: name);
    }
  });
}
