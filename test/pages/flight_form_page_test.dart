import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:zenith/pages/flight_form_page.dart';
import 'package:zenith/providers/database_provider.dart';
import 'package:zenith/providers/flight_form_provider.dart';
import 'package:zenith/services/adsb_flight_importer.dart';
import 'package:zenith/services/adsb_track_source.dart';
import 'package:zenith/services/database.dart';
import 'package:zenith/widgets/flight_card.dart';
import 'package:zenith/widgets/time_input.dart';
import 'package:zenith/widgets/time_pill.dart';

const _rome = Airport(
  id: 1,
  ident: 'LIRF',
  type: AirportType.largeAirport,
  latitudeDeg: 41.8,
  longitudeDeg: 12.25,
  continent: 'EU',
  isoCountry: 'IT',
  isoRegion: 'IT-62',
);
const _tokyo = Airport(
  id: 2,
  ident: 'RJTT',
  type: AirportType.largeAirport,
  latitudeDeg: 35.55,
  longitudeDeg: 139.78,
  continent: 'AS',
  isoCountry: 'JP',
  isoRegion: 'JP-13',
);

void main() {
  setUpAll(tzdata.initializeTimeZones);

  late LogbookDatabase db;
  late ProviderContainer container;
  FlightFormState form() => container.read(flightFormProvider);

  setUp(() {
    db = LogbookDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  FlightWithStats flight({
    required DateTime departure,
    DateTime? arrival,
    String? departureZone,
    String? arrivalZone,
    Airport? from = _rome,
    Airport? to = _rome,
    int? simulator,
  }) => FlightWithStats(
    flight: Flight(
      id: 1,
      syncId: 'test',
      title: 'LIRF → LIRA',
      // As the database returns them.
      departureTime: departure.toLocal(),
      arrivalTime: arrival?.toLocal(),
      departureIanaLocation: departureZone,
      arrivalIanaLocation: arrivalZone,
      isRecording: false,
      simulatorId: simulator,
      proficiencyCheck: false,
    ),
    dataPoints: const [],
    departure: from,
    arrival: to,
  );

  Future<void> open(WidgetTester tester, FlightFormPage page) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: page),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    expect(tester.takeException(), isNull);
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  List<String> times(WidgetTester tester) => [
    for (final e
        in find
            .descendant(
              of: find.byType(TimeInput),
              matching: find.byType(EditableText),
            )
            .evaluate())
      (e.widget as EditableText).controller.text,
  ];

  /// Opens [f] to edit it: the form must stand for the times it has.
  Future<void> expectUnchanged(WidgetTester tester, FlightWithStats f) async {
    await open(tester, FlightFormPage(flightToEdit: f));
    expect(
      form().depTZDateTime.toUtc(),
      f.flight.departureTime.toUtc(),
      reason: 'departure',
    );
    expect(
      form().arrTZDateTime?.toUtc(),
      f.flight.arrivalTime?.toUtc(),
      reason: 'arrival',
    );
    expect(times(tester), [form().depTime, form().arrTime]);
  }

  testWidgets('editing shows the times of the flight', (tester) async {
    await expectUnchanged(
      tester,
      flight(
        departure: DateTime.utc(2026, 7, 10, 6, 5),
        arrival: DateTime.utc(2026, 7, 10, 7, 35),
        departureZone: 'Europe/Rome',
        arrivalZone: 'Europe/Rome',
      ),
    );
    expect(times(tester), ['08:05', '09:35']);
    expect(form().depTzMode, TimezoneMode.local);
    // The arrival follows a new departure date.
    container
        .read(flightFormProvider.notifier)
        .setDepartureDate(DateTime(2026, 6, 10));
    expect(form().blockTime, const Duration(minutes: 90));
    await close(tester);
  });

  testWidgets('editing a flight of another day than here', (tester) async {
    for (final hour in [1, 22]) {
      await expectUnchanged(
        tester,
        flight(
          departure: DateTime.utc(2026, 7, 9, hour),
          arrival: DateTime.utc(2026, 7, 9, hour + 1),
          departureZone: 'Asia/Tokyo',
          arrivalZone: 'Asia/Tokyo',
          from: _tokyo,
          to: _tokyo,
        ),
      );
      await close(tester);
    }
  });

  testWidgets('editing a flight that took more than a day', (tester) async {
    await expectUnchanged(
      tester,
      flight(
        departure: DateTime.utc(2026, 7, 10, 6),
        arrival: DateTime.utc(2026, 7, 11, 7),
        departureZone: 'Europe/Rome',
        arrivalZone: 'Europe/Rome',
      ),
    );
    await close(tester);
  });

  testWidgets('editing a flight saved in UTC', (tester) async {
    await expectUnchanged(
      tester,
      flight(
        departure: DateTime.utc(2026, 7, 10, 12),
        arrival: DateTime.utc(2026, 7, 10, 13),
      ),
    );
    expect(times(tester), ['12:00', '13:00']);
    expect(find.text('1:00'), findsOneWidget);
    await close(tester);
  });

  testWidgets('editing a flight saved in a zone picked by hand', (
    tester,
  ) async {
    await expectUnchanged(
      tester,
      flight(
        departure: DateTime.utc(2026, 7, 10, 12),
        departureZone: 'Asia/Tokyo',
        arrivalZone: 'Europe/Rome',
      ),
    );
    await close(tester);
  });

  testWidgets('editing a flight at the hour that comes twice', (tester) async {
    for (final hour in [0, 1]) {
      await expectUnchanged(
        tester,
        flight(
          departure: DateTime.utc(2026, 10, 25, hour, 30),
          arrival: DateTime.utc(2026, 10, 25, 5),
          departureZone: 'Europe/Rome',
          arrivalZone: 'Europe/Rome',
        ),
      );
      await close(tester);
    }
  });

  testWidgets('editing a session logged before zones were kept', (
    tester,
  ) async {
    await expectUnchanged(
      tester,
      flight(
        departure: DateTime.utc(2026, 7, 10, 22),
        arrival: DateTime.utc(2026, 7, 11, 1),
        simulator: 1,
        from: null,
        to: null,
      ),
    );
    await close(tester);
  });

  testWidgets('an airport that is gone keeps its code', (tester) async {
    await expectUnchanged(
      tester,
      flight(
        departure: DateTime.utc(2026, 7, 10, 12),
        departureZone: 'Europe/Rome',
        arrivalZone: 'Europe/Rome',
        from: null,
        to: null,
      ),
    );
    expect(form().departureCode, 'LIRF');
    expect(form().arrivalCode, 'LIRA');
    await close(tester);
  });

  testWidgets('an import shows the times it found', (tester) async {
    await open(
      tester,
      FlightFormPage(
        adsbImport: AdsbImportDraft(
          flight: AdsbFlight(
            provider: AdsbProvider.openSky,
            icao24: '4ca242',
            start: DateTime.utc(2026, 7, 10, 6, 5),
            end: DateTime.utc(2026, 7, 10, 7, 35),
          ),
          points: const [],
          departure: const ImportedAirport(_rome, ImportedAirportOrigin.route),
        ),
      ),
    );
    // No arrival airport: in UTC.
    expect(times(tester), ['08:05', '07:35']);
    expect(form().blockTime, const Duration(minutes: 90));
    await close(tester);
  });

  testWidgets('the block time is shown in UTC too', (tester) async {
    await open(tester, const FlightFormPage());
    container.read(flightFormProvider.notifier)
      ..setDepTzMode(TimezoneMode.utc)
      ..setArrTzMode(TimezoneMode.utc)
      ..setDepartureDate(DateTime(2026, 7, 10))
      ..setArrivalDate(DateTime(2026, 7, 10))
      ..setDepTime('08:00')
      ..setArrTime('09:30');
    await tester.pump();
    expect(
      find.descendant(of: find.byType(TimePill), matching: find.text('1:30')),
      findsOneWidget,
    );
    await close(tester);
  });

  testWidgets('a new form starts now, not when the last one closed', (
    tester,
  ) async {
    container.read(flightFormProvider.notifier)
      ..setDepartureDate(DateTime(2020))
      ..setRemarks('old');
    await open(tester, const FlightFormPage());
    expect(form().departureDate.year, isNot(2020));
    expect(times(tester).first, form().depTime);
    await close(tester);
  });

  testWidgets('a card without arrival time shows none', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlightCard(
            flight: flight(
              departure: DateTime.utc(2026, 7, 10, 12),
              departureZone: 'Mars/Olympus',
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('12:00 UTC'), findsOneWidget);
  });
}
