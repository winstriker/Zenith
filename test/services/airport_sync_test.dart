import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/services/airport_service.dart';
import 'package:zenith/services/database.dart';

const _countries =
    'id,code,name,continent,wikipedia_link,keywords\n'
    '1,IT,Italy,EU,,\n';
const _regions =
    'id,code,local_code,name,continent,iso_country,wikipedia_link,keywords\n'
    '1,IT-25,25,Lombardy,EU,IT,,\n';
const _airportsHeader =
    'id,ident,type,name,latitude_deg,longitude_deg,elevation_ft,continent,'
    'iso_country,iso_region,municipality,scheduled_service,icao_code,'
    'iata_code,gps_code,local_code,home_link,wikipedia_link,keywords\n';
const _runwaysHeader =
    'id,airport_ref,airport_ident,length_ft,width_ft,surface,lighted,closed,'
    'le_ident,le_latitude_deg,le_longitude_deg,le_elevation_ft,'
    'le_heading_degT,le_displaced_threshold_ft,he_ident,he_latitude_deg,'
    'he_longitude_deg,he_elevation_ft,he_heading_degT,'
    'he_displaced_threshold_ft\n';
const _frequenciesHeader =
    'id,airport_ref,airport_ident,type,description,frequency_mhz\n';

String _airport(int id, String ident, String name) =>
    '$id,$ident,small_airport,"$name",45.1,9.2,300,EU,IT,IT-25,Milan,no,'
    '$ident,,$ident,,,,\n';

String _runway(int id, int airport) =>
    '$id,$airport,X,3000,45,ASP,1,0,18,,,,,,36,,,,,\n';

ParsedAirportData _parse(String airports, {String runways = ''}) =>
    AirportsService.parseAirportData(
      countriesCsv: _countries,
      regionsCsv: _regions,
      airportsCsv: _airportsHeader + airports,
      runwaysCsv: _runwaysHeader + runways,
      frequenciesCsv: _frequenciesHeader,
    );

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late LogbookDatabase db;
  setUp(() => db = LogbookDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> addFlight({int? departure, int? arrival}) => db
      .into(db.flights)
      .insert(
        FlightsCompanion.insert(
          title: 'flight',
          departureTime: DateTime(2026),
          isRecording: false,
          departure: Value(departure),
          arrival: Value(arrival),
        ),
      );

  Future<Map<int, Airport>> airports() async => {
    for (final a in await db.select(db.airports).get()) a.id: a,
  };

  test('first sync inserts everything and reports progress', () async {
    final fractions = <double>[];
    final summary = await AirportsService.syncAirportData(
      db,
      _parse(
        _airport(1, 'LIMC', 'Malpensa') + _airport(2, 'LIML', 'Linate'),
        runways: _runway(10, 1) + _runway(11, 99),
      ),
      onProgress: (f, _) => fractions.add(f),
    );

    expect(summary.added, 2);
    expect((await airports()).keys, unorderedEquals([1, 2]));
    // Runway 11 points at an unknown airport and is skipped.
    final runways = await db.select(db.runways).get();
    expect(runways.map((r) => r.id), [10]);
    expect(fractions, isNotEmpty);
    expect(fractions.last, closeTo(1, 1e-9));
    for (var i = 1; i < fractions.length; i++) {
      expect(fractions[i], greaterThanOrEqualTo(fractions[i - 1]));
    }
  });

  test('removed airports are deleted unless used by a flight', () async {
    await AirportsService.syncAirportData(
      db,
      _parse(
        _airport(1, 'LIMC', 'Malpensa') +
            _airport(2, 'LIML', 'Linate') +
            _airport(3, 'LIME', 'Orio'),
      ),
    );
    await addFlight(departure: 2);

    final summary = await AirportsService.syncAirportData(
      db,
      _parse(_airport(1, 'LIMC', 'Malpensa')),
    );

    expect((await airports()).keys, unorderedEquals([1, 2]));
    expect(summary.deleted, 1);
    expect(summary.kept, 1);
  });

  test('used airports are updated in place with the same id', () async {
    await AirportsService.syncAirportData(
      db,
      _parse(_airport(1, 'LIMC', 'Malpensa')),
    );
    await addFlight(arrival: 1);

    final summary = await AirportsService.syncAirportData(
      db,
      _parse(_airport(1, 'LIMC', 'Milano Malpensa')),
    );

    final all = await airports();
    expect(all.length, 1);
    expect(all[1]!.name, 'Milano Malpensa');
    expect(summary.updated, 1);
  });

  test('ident moving between airports does not violate UNIQUE', () async {
    await AirportsService.syncAirportData(
      db,
      _parse(_airport(1, 'AAAA', 'One') + _airport(2, 'BBBB', 'Two')),
    );
    await addFlight(departure: 2);

    // Idents swap, and a new airport takes the ident of a kept one.
    await AirportsService.syncAirportData(
      db,
      _parse(_airport(1, 'BBBB', 'One') + _airport(3, 'AAAA', 'Three')),
    );

    final all = await airports();
    expect(all[1]!.ident, 'BBBB');
    expect(all[3]!.ident, 'AAAA');
    // Kept (used, removed from OurAirports) airport lost its clashing ident.
    expect(all[2], isNotNull);
    expect(all[2]!.ident, isNull);
  });

  test('custom airports survive the sync and keep their ident', () async {
    await AirportsService.syncAirportData(
      db,
      _parse(_airport(1, 'LIMC', 'Malpensa')),
    );
    await db
        .into(db.airports)
        .insert(
          AirportsCompanion.insert(
            id: const Value(-1),
            ident: const Value('LI99'),
            name: const Value('My strip'),
            type: AirportType.smallAirport,
            continent: 'EU',
            isoCountry: 'IT',
            isoRegion: 'IT-U-A',
          ),
        );

    // OurAirports later lists an airport with the custom airport's ident.
    final summary = await AirportsService.syncAirportData(
      db,
      _parse(_airport(1, 'LIMC', 'Malpensa') + _airport(2, 'LI99', 'Other')),
    );

    final all = await airports();
    expect(all.keys, unorderedEquals([-1, 1, 2]));
    expect(all[-1]!.ident, 'LI99');
    expect(all[-1]!.name, 'My strip');
    expect(all[2]!.ident, isNull);
    expect(summary.deleted, 0);

    // Stable: syncing the same data again changes nothing.
    final again = await AirportsService.syncAirportData(
      db,
      _parse(_airport(1, 'LIMC', 'Malpensa') + _airport(2, 'LI99', 'Other')),
    );
    expect(again.updated, 0);
    expect((await airports())[-1]!.ident, 'LI99');
  });

  test('a failing sync leaves the previous data intact', () async {
    await AirportsService.syncAirportData(
      db,
      _parse(_airport(1, 'LIMC', 'Malpensa'), runways: _runway(10, 1)),
    );

    final bad = _parse(_airport(2, 'LIML', 'Linate'));
    final broken = ParsedAirportData(
      countries: bad.countries,
      regions: bad.regions,
      airports: bad.airports,
      // Duplicate primary keys make the runway insert fail mid-transaction.
      runways: [
        RunwaysCompanion.insert(id: const Value(1), airport: 2),
        RunwaysCompanion.insert(id: const Value(1), airport: 2),
      ],
      frequencies: bad.frequencies,
    );
    await expectLater(
      AirportsService.syncAirportData(db, broken),
      throwsA(anything),
    );

    expect((await airports()).keys, [1]);
    expect((await db.select(db.runways).get()).map((r) => r.id), [10]);
  });
}
