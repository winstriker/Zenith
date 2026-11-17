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
}
