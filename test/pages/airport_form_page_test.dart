import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/pages/airport_form_page.dart';
import 'package:zenith/providers/database_provider.dart';
import 'package:zenith/services/database.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late LogbookDatabase db;

  setUp(() async {
    db = LogbookDatabase(NativeDatabase.memory());
    await db
        .into(db.countries)
        .insert(
          CountriesCompanion.insert(
            id: const Value(1),
            code: 'IT',
            name: 'Italy',
            continent: 'EU',
          ),
        );
    await db
        .into(db.airports)
        .insert(
          AirportsCompanion.insert(
            id: const Value(10),
            ident: const Value('LIMC'),
            name: const Value('Malpensa'),
            type: AirportType.largeAirport,
            continent: 'EU',
            isoCountry: 'IT',
            isoRegion: 'IT-25',
          ),
        );
  });

  tearDown(() => db.close());

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  /// Opens the form and returns what it popped once it closes.
  Future<List<Object?>> openForm(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final popped = <Object?>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async => popped.add(
                  await Navigator.push<Object?>(
                    context,
                    MaterialPageRoute(builder: (_) => const AirportFormPage()),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await settle(tester);
    return popped;
  }

  /// Unmounts the page: drift's stream subscriptions cancel on a timer,
  /// which must run before the test ends.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Future<void> fill(WidgetTester tester, {required String ident}) async {
    await tester.enterText(field('Identifier *'), ident);
    await tester.enterText(field('Name *'), 'My strip');
    await tester.enterText(field('Latitude *'), '45,5');
    await tester.enterText(field('Longitude *'), '9.25');
    await tester.tap(find.text('Country *'));
    await settle(tester);
    await tester.tap(find.text('Italy'));
    await settle(tester);
  }

  testWidgets('adds a custom airport and pops its id', (tester) async {
    final popped = await openForm(tester);
    await fill(tester, ident: 'xa01');
    await tester.tap(find.text('Add'));
    await settle(tester);

    final airports = await (db.select(
      db.airports,
    )..where((a) => a.id.isSmallerThanValue(0))).get();
    expect(airports, hasLength(1));
    final a = airports.single;
    expect(a.id, -1);
    expect(a.ident, 'XA01');
    expect(a.name, 'My strip');
    expect(a.latitudeDeg, 45.5);
    expect(a.longitudeDeg, 9.25);
    expect(a.isoCountry, 'IT');
    expect(a.isoRegion, 'IT-U-A');
    expect(a.continent, 'EU');
    expect(popped, [-1]);
    await unmount(tester);
  });

  testWidgets('refuses an identifier another airport uses', (tester) async {
    final popped = await openForm(tester);
    await fill(tester, ident: 'limc');
    await tester.tap(find.text('Add'));
    await settle(tester);

    expect(find.text('Another airport already uses LIMC'), findsOneWidget);
    expect(popped, isEmpty);
    final custom = await (db.select(
      db.airports,
    )..where((a) => a.id.isSmallerThanValue(0))).get();
    expect(custom, isEmpty);
    await unmount(tester);
  });

  testWidgets('requires a country and coordinates', (tester) async {
    final popped = await openForm(tester);
    await tester.enterText(field('Identifier *'), 'XA01');
    await tester.enterText(field('Name *'), 'My strip');
    await tester.tap(find.text('Add'));
    await settle(tester);

    expect(find.text('Country is required.'), findsOneWidget);
    expect(find.text('Required'), findsNWidgets(2));
    expect(popped, isEmpty);
    await unmount(tester);
  });
}
