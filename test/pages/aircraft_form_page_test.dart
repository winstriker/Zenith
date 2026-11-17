import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zenith/pages/aircraft_form_page.dart';
import 'package:zenith/providers/database_provider.dart';
import 'package:zenith/repositories/aircraft_repository.dart';
import 'package:zenith/services/aircraft_lookup_service.dart';
import 'package:zenith/services/database.dart';
import 'package:zenith/services/person_photo_store.dart';

String _jetApi(String reg, String model, int photos) => jsonEncode({
  'Reg': reg,
  'Images': [
    for (var i = 1; i <= photos; i++)
      {
        'Image': 'https://cdn.jetphotos.com/full/1/$i.jpg',
        'Thumbnail': 'https://cdn.jetphotos.com/400/1/$i.jpg',
        'Link': 'https://www.jetphotos.com/photo/$i',
        'Photographer': 'Photographer $i',
        'Aircraft': model,
      },
  ],
});

void main() {
  late LogbookDatabase db;
  late Directory root;
  late int c172;
  late int a320;

  /// Registrations JetAPI knows in this test.
  final known = {
    'I-ABCD': _jetApi('I-ABCD', 'Cessna 172R Skyhawk II', 2),
    'I-PIPE': _jetApi('I-PIPE', 'Cessna 172R Skyhawk II', 1),
    'EI-DSA': _jetApi('EI-DSA', 'Airbus A320-216', 1),
    'I-SEAL': _jetApi('I-SEAL', 'Lake LA-4-200 Buccaneer', 1),
    'I-ODDS': _jetApi('I-ODDS', 'Cameron N-90', 1),
  };

  /// Registrations adsbdb knows in this test: no photo, but a designator.
  final adsbdb = {
    'OE-DVK': jsonEncode({
      'response': {
        'aircraft': {
          'type': 'F172N',
          'icao_type': 'C172',
          'manufacturer': 'Reims/Cessna',
          'registration': 'OE-DVK',
          'url_photo': null,
        },
      },
    }),
    // The services know better than the name on JetPhotos.
    'I-PIPE': jsonEncode({
      'response': {
        'aircraft': {
          'type': 'PA-28-161',
          'icao_type': 'P28A',
          'manufacturer': 'Piper',
          'registration': 'I-PIPE',
        },
      },
    }),
  };

  setUp(() async {
    db = LogbookDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    root = Directory.systemTemp.createTempSync('zenith_form');

    IcaoAircraftsCompanion type(
      String designator,
      String manufacturer,
      String model, {
      AircraftDescription description = AircraftDescription.landplane,
      int engines = 1,
      EngineType engine = EngineType.piston,
    }) => IcaoAircraftsCompanion.insert(
      modelFullName: model,
      designator: designator,
      wakeTurbolenceCategory: WakeTurbulenceCategory.L,
      wakeTurbolenceGroup: WakeTurbulenceGroup.Z,
      manufacturer: manufacturer,
      description: description,
      engineCount: engines,
      engineType: engine,
    );

    // Type ids must not line up with aircraft ids.
    await db.into(db.icaoAircrafts).insert(type('P28A', 'PIPER', 'PA-28-161'));
    c172 = await db
        .into(db.icaoAircrafts)
        .insert(type('C172', 'CESSNA', '172 Skyhawk'));
    a320 = await db
        .into(db.icaoAircrafts)
        .insert(
          type('A320', 'AIRBUS', 'A-320', engines: 2, engine: EngineType.jet),
        );
    await db
        .into(db.icaoAircrafts)
        .insert(
          type(
            'LA4',
            'LAKE',
            'LA-4-200 Buccaneer',
            description: AircraftDescription.amphibian,
          ),
        );
  });

  tearDown(() async {
    await db.close();
    root.deleteSync(recursive: true);
  });

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openForm(WidgetTester tester, {AircraftWithStats? edit}) async {
    // The 3:2 photo header follows the width: on the default 800x600 test
    // surface it is 533 high, and with the photo strip it pushes the form
    // below the fold, where finders don't look. A taller surface keeps the
    // form on screen.
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          aircraftPhotoStoreProvider.overrideWithValue(
            AircraftPhotoStore(() async => root),
          ),
          aircraftLookupServiceProvider.overrideWithValue(
            AircraftLookupService(
              AircraftLookupService.defaultSources(
                appVersion: 'test',
                planespottersContact: 'https://example.com/contact',
              ),
              MockClient((request) async {
                final url = request.url;
                final body = switch (url.host) {
                  'www.jetapi.dev' => known[url.queryParameters['reg']],
                  'api.adsbdb.com' => adsbdb[url.pathSegments.last],
                  _ => null,
                };
                return body == null
                    ? http.Response('Not Found', 404)
                    : http.Response(body, 200);
              }),
            ),
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<bool>(
                    builder: (_) => AircraftFormPage(aircraft: edit),
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
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Future<void> lookUp(WidgetTester tester, String registration) async {
    await tester.enterText(field('Tail Number'), registration);
    await tester.tap(find.byTooltip('Look up registration'));
    await tester.pump();
    await settle(tester);
  }

  Future<void> save(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(FloatingActionButton, label));
    await tester.pump();
    await settle(tester);
  }

  Future<List<Aircraft>> aircraft(WidgetTester tester) async =>
      (await tester.runAsync(() => db.select(db.aircrafts).get()))!;

  testWidgets('a registration fills in type, class and photo', (tester) async {
    await openForm(tester);
    await lookUp(tester, 'i-abcd');

    expect(field('Tail Number'), findsOneWidget);
    expect(find.text('I-ABCD'), findsOneWidget);
    expect(find.text('172 Skyhawk'), findsOneWidget);
    expect(find.text('SEP (L)'), findsOneWidget);
    expect(find.text('2 photos found online · tap to choose'), findsOneWidget);
    expect(find.text('© Photographer 1 · JetPhotos'), findsOneWidget);
    // The photos to choose from carry no credit: the chosen one does.
    expect(find.text('© Photographer 2 · JetPhotos'), findsNothing);
    expect(find.text('JetPhotos'), findsNothing);
    // A class rating has no type rating to name.
    expect(field('Type rating *'), findsNothing);

    await save(tester, 'Add');

    final saved = (await aircraft(tester)).single;
    expect(saved.tailNumber, 'I-ABCD');
    expect(saved.icaoAircraft, c172);
    expect(saved.aircraftClass, AircraftClass.sepLand);
    expect(saved.typeRating, isNull);
    // Only links are kept, nothing is downloaded.
    expect(saved.photoUrl, 'https://cdn.jetphotos.com/full/1/1.jpg');
    expect(saved.photoThumbnailUrl, 'https://cdn.jetphotos.com/400/1/1.jpg');
    expect(saved.photoLink, 'https://www.jetphotos.com/photo/1');
    expect(saved.photoCredit, 'Photographer 1');
    expect(saved.photoFile, isNull);
    expect(root.listSync(), isEmpty);
  });

  testWidgets('another JetPhotos photo can be chosen, or none', (tester) async {
    await openForm(tester);
    await lookUp(tester, 'I-ABCD');

    await tester.tap(
      find.bySemanticsLabel('Photo 2, by Photographer 2, from JetPhotos'),
    );
    await tester.pumpAndSettle();
    expect(find.text('© Photographer 2 · JetPhotos'), findsOneWidget);

    await tester.tap(find.byTooltip('Change photo'));
    await tester.pumpAndSettle();
    expect(find.text('Choose from gallery'), findsOneWidget);
    expect(find.text('Take a photo'), findsOneWidget);
    await tester.tap(find.text('Remove photo'));
    await tester.pumpAndSettle();
    expect(find.textContaining('· JetPhotos'), findsNothing);
    expect(find.byTooltip('Add photo'), findsOneWidget);

    await tester.tap(
      find.bySemanticsLabel('Photo 2, by Photographer 2, from JetPhotos'),
    );
    await tester.pumpAndSettle();
    await save(tester, 'Add');

    expect(
      (await aircraft(tester)).single.photoLink,
      'https://www.jetphotos.com/photo/2',
    );
  });

  testWidgets('a jet is a type rating, named after its designator to start', (
    tester,
  ) async {
    await openForm(tester);
    await lookUp(tester, 'EI-DSA');

    expect(find.text('A-320'), findsOneWidget);
    expect(find.text('Type rating'), findsOneWidget);
    final rating = tester.widget<TextFormField>(field('Type rating *'));
    expect(rating.controller!.text, 'A320');

    await tester.enterText(field('Type rating *'), 'A320 family');
    await save(tester, 'Add');

    final saved = (await aircraft(tester)).single;
    expect(saved.icaoAircraft, a320);
    expect(saved.aircraftClass, AircraftClass.type);
    expect(saved.typeRating, 'A320 family');
  });

  testWidgets('an amphibian asks for land or sea', (tester) async {
    await openForm(tester);
    await lookUp(tester, 'I-SEAL');

    expect(find.text('LA-4-200 Buccaneer'), findsOneWidget);
    expect(find.text('Select class'), findsOneWidget);
    expect(find.textContaining('SEP (L) or SEP (S)'), findsOneWidget);

    await tester.ensureVisible(find.text('Select class'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select class'));
    await tester.pumpAndSettle();
    expect(find.text('Matches type'), findsNWidgets(2));
    await tester.tap(find.text('SEP (S)'));
    await tester.pumpAndSettle();
    await save(tester, 'Add');

    expect((await aircraft(tester)).single.aircraftClass, AircraftClass.sepSea);
  });

  testWidgets('no matching type leaves the type to the user', (tester) async {
    await openForm(tester);
    await lookUp(tester, 'I-ODDS');

    expect(find.text('Select aircraft model'), findsOneWidget);
    // The photo is still offered.
    expect(find.text('1 photo found online'), findsOneWidget);

    await save(tester, 'Add');
    expect(find.text('Please select an aircraft type'), findsOneWidget);
    expect(await aircraft(tester), isEmpty);
  });

  testWidgets('a designator from a service decides the type', (tester) async {
    await openForm(tester);
    // JetPhotos calls it a Cessna 172; adsbdb knows it is a P28A.
    await lookUp(tester, 'I-PIPE');

    expect(find.text('PA-28-161'), findsOneWidget);
    expect(find.text('172 Skyhawk'), findsNothing);
    expect(find.text('1 photo found online'), findsOneWidget);
  });

  testWidgets('an aircraft without photos still gets its type and class', (
    tester,
  ) async {
    await openForm(tester);
    await lookUp(tester, 'OE-DVK');

    expect(find.text('172 Skyhawk'), findsOneWidget);
    expect(find.text('SEP (L)'), findsOneWidget);
    expect(find.text('No photos found for this aircraft.'), findsOneWidget);
    expect(find.textContaining('found online'), findsNothing);

    await save(tester, 'Add');

    final saved = (await aircraft(tester)).single;
    expect(saved.icaoAircraft, c172);
    expect(saved.aircraftClass, AircraftClass.sepLand);
    expect(saved.photoUrl, isNull);
  });

  testWidgets('an unknown registration says so and changes nothing', (
    tester,
  ) async {
    await openForm(tester);
    await lookUp(tester, 'I-ZZZZ');

    expect(find.textContaining('Nothing found for "I-ZZZZ"'), findsOneWidget);
    expect(find.text('Select aircraft model'), findsOneWidget);
    expect(find.textContaining('found online'), findsNothing);
  });

  testWidgets('editing keeps the type and saves the new tail number', (
    tester,
  ) async {
    final repo = AircraftRepository(db);
    final existing = (await tester.runAsync(() async {
      final id = await repo.addAircraft(
        icaoAircraftId: c172,
        tailNumber: 'I-OLDE',
        aircraftClass: AircraftClass.sepSea,
      );
      return repo.watchAircraftWithStats(id).first;
    }))!;
    expect(existing.id, isNot(c172));

    await openForm(tester, edit: existing);
    // The class the user chose is kept, even though the type says "land".
    expect(find.text('SEP (S)'), findsOneWidget);

    await tester.enterText(field('Tail Number'), 'I-NEWE');
    await tester.enterText(field('Notes'), 'On floats');
    await save(tester, 'Save');

    final saved = (await aircraft(tester)).single;
    expect(saved.tailNumber, 'I-NEWE');
    expect(saved.notes, 'On floats');
    expect(saved.icaoAircraft, c172);
    expect(saved.aircraftClass, AircraftClass.sepSea);
  });

  testWidgets('deleting from the form removes the aircraft', (tester) async {
    final repo = AircraftRepository(db);
    final existing = (await tester.runAsync(() async {
      final id = await repo.addAircraft(
        icaoAircraftId: c172,
        tailNumber: 'I-GONE',
      );
      return repo.watchAircraftWithStats(id).first;
    }))!;

    await openForm(tester, edit: existing);
    await tester.ensureVisible(find.text('Delete Aircraft'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Aircraft'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pump();
    await settle(tester);

    expect(await aircraft(tester), isEmpty);
    expect(find.text('open'), findsOneWidget);
  });
}
