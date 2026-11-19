import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/repositories/airport_repository.dart';
import 'package:zenith/services/database.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late LogbookDatabase db;
  late AirportRepository repo;
  setUp(() async {
    db = LogbookDatabase(NativeDatabase.memory());
    repo = AirportRepository(db);
    await db
        .into(db.countries)
        .insert(
          CountriesCompanion.insert(code: 'IT', name: 'Italy', continent: 'EU'),
        );
    await db
        .into(db.regions)
        .insert(
          RegionsCompanion.insert(
            code: 'IT-25',
            localCode: const Value('25'),
            name: 'Lombardy',
            continent: 'EU',
            isoCountry: 'IT',
          ),
        );
  });
  tearDown(() => db.close());

  Future<void> addAirport(String ident, double lat, double lon) => db
      .into(db.airports)
      .insert(
        AirportsCompanion.insert(
          ident: Value(ident),
          name: Value(ident),
          type: AirportType.smallAirport,
          latitudeDeg: Value(lat),
          longitudeDeg: Value(lon),
          continent: 'EU',
          isoCountry: 'IT',
          isoRegion: 'IT-25',
        ),
      );

  test('nearest airports come nearest first, before the limit', () async {
    // Inserted far to near, so table order would be wrong.
    await addAirport('FAR', 46.5, 9.0);
    await addAirport('MID', 45.0, 10.0);
    await addAirport('NEAR', 45.1, 9.0);
    await addAirport('OUT', 48.0, 9.0);

    Future<List<String?>> near(int limit) async => [
      for (final a in await repo.watchAirportsNear(45, 9, limit: limit).first)
        a.ident,
    ];

    expect(await near(1), ['NEAR']);
    // Longitude degrees are shorter than latitude ones up here.
    expect(await near(2), ['NEAR', 'MID']);
    expect(await near(10), ['NEAR', 'MID', 'FAR']);
  });

  test('recent airports come most recently used first, in pages', () async {
    await addAirport('AAAA', 45, 9);
    await addAirport('BBBB', 45, 9);
    await addAirport('CCCC', 45, 9);
    await addAirport('UNUSED', 45, 9);
    final ids = {
      for (final a in await db.select(db.airports).get()) a.ident: a.id,
    };
    Future<void> fly(int day, String from, String to) => db
        .into(db.flights)
        .insert(
          FlightsCompanion.insert(
            title: '$from-$to',
            departureTime: DateTime(2026, 3, day),
            isRecording: false,
            departure: Value(ids[from]),
            arrival: Value(ids[to]),
          ),
        );
    await fly(1, 'CCCC', 'AAAA');
    await fly(2, 'AAAA', 'BBBB');
    await fly(3, 'BBBB', 'BBBB');

    Future<List<String?>> recent(int limit) async => [
      for (final a in await repo.watchRecentAirports(limit: limit).first)
        a.ident,
    ];
    expect(await recent(20), ['BBBB', 'AAAA', 'CCCC']);
    expect(await recent(2), ['BBBB', 'AAAA']);
  });

  test('flight counts count each flight once per airport', () async {
    await addAirport('AAAA', 45, 9);
    await addAirport('BBBB', 45, 9);
    await addAirport('UNUSED', 45, 9);
    final ids = {
      for (final a in await db.select(db.airports).get()) a.ident: a.id,
    };
    Future<void> fly(String from, String? to) => db
        .into(db.flights)
        .insert(
          FlightsCompanion.insert(
            title: '$from-$to',
            departureTime: DateTime(2026, 3, 1),
            isRecording: false,
            departure: Value(ids[from]),
            arrival: Value(ids[to]),
          ),
        );
    await fly('AAAA', 'BBBB');
    await fly('BBBB', 'BBBB'); // Local flight: once for BBBB.
    await fly('AAAA', null);

    expect(await repo.watchFlightCounts().first, {
      ids['AAAA']!: 2,
      ids['BBBB']!: 2,
    });
  });

  test('map airports: filters, bounds, biggest first', () async {
    Future<int> add(String ident, AirportType type, double lat, String icao) =>
        db
            .into(db.airports)
            .insert(
              AirportsCompanion.insert(
                ident: Value(ident),
                name: Value('$ident field'),
                type: type,
                latitudeDeg: Value(lat),
                longitudeDeg: const Value(9),
                continent: 'EU',
                isoCountry: 'IT',
                isoRegion: 'IT-25',
                icaoCode: Value(icao),
              ),
            );
    await add('SMAL', AirportType.smallAirport, 45, '');
    await add('HELI', AirportType.heliport, 45, '');
    final large = await add('LARG', AirportType.largeAirport, 45, 'LARG');
    await add('AWAY', AirportType.largeAirport, 50, 'AWAY');
    await db
        .into(db.flights)
        .insert(
          FlightsCompanion.insert(
            title: 'f',
            departureTime: DateTime(2026),
            isRecording: false,
            arrival: Value(large),
          ),
        );

    Future<List<String?>> map({
      bool bounded = true,
      String query = '',
      AirportType? type,
      bool usedOnly = false,
      bool icaoOnly = false,
      int limit = 10,
    }) async => [
      for (final a in await repo.getMapAirports(
        bounds: bounded ? (south: 44, west: 8, north: 46, east: 10) : null,
        query: query,
        type: type,
        usedOnly: usedOnly,
        icaoOnly: icaoOnly,
        limit: limit,
      ))
        a.ident,
    ];

    expect(await map(), ['LARG', 'SMAL', 'HELI']);
    expect(await map(limit: 1), ['LARG']);
    expect(await map(bounded: false, icaoOnly: true), ['LARG', 'AWAY']);
    expect(await map(usedOnly: true), ['LARG']);
    expect(await map(type: AirportType.heliport), ['HELI']);
    expect(await map(bounded: false, query: 'away'), ['AWAY']);
  });

  group('custom airports', () {
    AirportsCompanion custom(String ident) => AirportsCompanion.insert(
      ident: Value(ident),
      name: Value('$ident strip'),
      type: AirportType.smallAirport,
      latitudeDeg: const Value(45.0),
      longitudeDeg: const Value(9.0),
      continent: 'EU',
      isoCountry: 'IT',
      isoRegion: 'IT-U-A',
    );

    test('get negative, decreasing ids', () async {
      await addAirport('LIMC', 45.6, 8.7);
      final first = await repo.addCustomAirport(custom('XA01'));
      final second = await repo.addCustomAirport(custom('XA02'));
      expect(first, -1);
      expect(second, -2);
      expect((await repo.getAirport(first))!.isCustom, isTrue);
    });

    test(
      'idents are checked case-insensitively, but not against itself',
      () async {
        final id = await repo.addCustomAirport(custom('XA01'));
        expect(await repo.isIdentTaken('xa01'), isTrue);
        expect(await repo.isIdentTaken('XA01', exceptId: id), isFalse);
        expect(await repo.isIdentTaken('XA02'), isFalse);
      },
    );

    test('update changes the row; OurAirports airports are refused', () async {
      final id = await repo.addCustomAirport(custom('XA01'));
      await repo.updateCustomAirport(
        id,
        custom('XA01').copyWith(name: const Value('Renamed')),
      );
      expect((await repo.getAirport(id))!.name, 'Renamed');
      expect(
        () => repo.updateCustomAirport(1, custom('XA01')),
        throwsArgumentError,
      );
    });

    test('are not deleted while a flight uses them', () async {
      final id = await repo.addCustomAirport(custom('XA01'));
      final flight = await db
          .into(db.flights)
          .insert(
            FlightsCompanion.insert(
              title: 'flight',
              departureTime: DateTime(2026),
              isRecording: false,
              departure: Value(id),
            ),
          );
      expect(await repo.deleteCustomAirport(id), isFalse);
      expect(await repo.getAirport(id), isNotNull);

      await (db.delete(db.flights)..where((f) => f.id.equals(flight))).go();
      expect(await repo.deleteCustomAirport(id), isTrue);
      expect(await repo.getAirport(id), isNull);
    });

    test('customOnly search lists only them, newest first', () async {
      await addAirport('LIMC', 45.6, 8.7);
      await repo.addCustomAirport(custom('XA01'));
      await repo.addCustomAirport(custom('XA02'));
      final found = await repo.searchAirports(customOnly: true).first;
      expect(found.map((a) => a.ident), ['XA02', 'XA01']);
    });
  });
}
