import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:zenith/providers/flight_form_provider.dart';
import 'package:zenith/services/database.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  late ProviderContainer container;
  FlightFormNotifier notifier() => container.read(flightFormProvider.notifier);
  FlightFormState state() => container.read(flightFormProvider);

  setUp(() {
    container = ProviderContainer();
    final date = DateTime(2026, 11, 13);
    notifier()
      ..setDepartureCode('LIMC')
      ..setArrivalCode('LIML')
      ..setDepIanaLocation('UTC')
      ..setArrIanaLocation('UTC')
      ..setDepartureDate(date)
      ..setArrivalDate(date)
      ..setDepTime('08:00')
      ..setArrTime('09:30');
  });
  tearDown(() => container.dispose());

  test('VFR flights log no IFR time, IFR flights all of it', () {
    expect(state().instrumentTime, Duration.zero);
    expect(state().visualTime, const Duration(minutes: 90));
    notifier().setFlightRules('IFR');
    expect(state().instrumentTime, const Duration(minutes: 90));
    expect(state().visualTime, Duration.zero);
    expect(state().isValid, isTrue);
  });

  test('mixed rules need the split, and one side gives the other', () {
    notifier().setFlightRules('Y');
    expect(state().instrumentTime, isNull);
    expect(state().isValid, isFalse);

    notifier().setInstrumentTime(const Duration(minutes: 30));
    expect(state().visualTime, const Duration(minutes: 60));
    expect(state().isValid, isTrue);

    notifier().setVisualTime(const Duration(minutes: 70));
    expect(state().instrumentTime, const Duration(minutes: 20));

    // The split follows a new arrival time on the VFR side.
    notifier().setArrTime('10:00');
    expect(state().instrumentTime, const Duration(minutes: 20));
    expect(state().visualTime, const Duration(minutes: 100));
  });

  test('a split longer than the block time is refused', () {
    notifier()
      ..setFlightRules('Z')
      ..setInstrumentTime(const Duration(minutes: 120));
    expect(state().instrumentError, isNotNull);
    expect(state().isValid, isFalse);

    notifier().setVisualTime(const Duration(minutes: 100));
    expect(state().instrumentError, isNotNull);
  });

  test('no night time without airport positions', () {
    expect(state().nightTime, isNull);
  });

  test('a proficiency check needs an examiner, ticked when one joins', () {
    const examiner = CrewMember(
      person: Person(syncId: 'test', id: 1, name: 'Anna', surname: 'Verdi'),
      role: CrewRole.exm,
    );
    expect(state().hasExaminer, isFalse);
    expect(state().isProficiencyCheck, isFalse);

    notifier().addCrewMember(examiner);
    expect(state().isProficiencyCheck, isTrue);
    notifier().setProficiencyCheck(false);
    expect(state().isProficiencyCheck, isFalse);

    // Removed and added again: ticked again.
    notifier().removeCrewMember(0);
    notifier().addCrewMember(examiner);
    expect(state().isProficiencyCheck, isTrue);

    // No longer an examiner: not a check, whatever the box says.
    notifier().updateCrewMember(
      0,
      CrewMember(person: examiner.person, role: CrewRole.ins),
    );
    expect(state().isProficiencyCheck, isFalse);
  });

  group('simulator sessions', () {
    const sim = SimulatorWithStats(
      simulator: Simulator(syncId: 'test', id: 1, kind: SimulatorKind.ffs),
    );

    test('need a simulator, start without landings', () {
      notifier().setSimulator(true);
      expect(state().dayLandings, 0);
      expect(state().isValid, isFalse);
      notifier().setSelectedSimulator(sim);
      expect(state().isValid, isTrue);
      expect(state().blockTime, const Duration(minutes: 90));
    });

    test('end on the next day when the end reads before the start', () {
      notifier()
        ..setSimulator(true)
        ..setSelectedSimulator(sim)
        ..setDepTime('22:00')
        ..setArrTime('02:00');
      expect(state().blockTime, const Duration(hours: 4));
      expect(state().arrTZDateTime!.day, 14);
    });
  });

  group('time zones', () {
    const rome = Airport(
      id: 1,
      ident: 'LIRF',
      type: AirportType.largeAirport,
      latitudeDeg: 41.8,
      longitudeDeg: 12.25,
      continent: 'EU',
      isoCountry: 'IT',
      isoRegion: 'IT-62',
    );
    const tokyo = Airport(
      id: 2,
      ident: 'RJTT',
      type: AirportType.largeAirport,
      latitudeDeg: 35.55,
      longitudeDeg: 139.78,
      continent: 'AS',
      isoCountry: 'JP',
      isoRegion: 'JP-13',
    );
    const losAngeles = Airport(
      id: 3,
      ident: 'KLAX',
      type: AirportType.largeAirport,
      latitudeDeg: 33.94,
      longitudeDeg: -118.4,
      continent: 'NA',
      isoCountry: 'US',
      isoRegion: 'US-CA',
    );
    const noPosition = Airport(
      id: 4,
      ident: 'XXXX',
      type: AirportType.smallAirport,
      continent: 'EU',
      isoCountry: 'IT',
      isoRegion: 'IT-62',
    );

    setUp(() => notifier().reset());

    test('an arrival time without a date is the first one after departure', () {
      notifier()
        ..setSelectedDeparture(rome)
        ..setSelectedArrival(rome)
        ..setDepartureDate(DateTime(2026, 7, 10))
        ..setDepTime('08:00')
        ..setArrTime('09:30');
      expect(state().blockTime, const Duration(minutes: 90));
      // Past midnight.
      notifier().setDepTime('23:00');
      expect(state().arrTZDateTime!.day, 11);
      expect(state().blockTime, const Duration(hours: 10, minutes: 30));
      // Across the date line, both ways.
      notifier()
        ..setSelectedDeparture(losAngeles)
        ..setSelectedArrival(tokyo)
        ..setDepTime('22:00')
        ..setArrTime('02:00');
      expect(state().arrTZDateTime!.day, 12);
      expect(state().blockTime, const Duration(hours: 12));
      notifier()
        ..setSelectedDeparture(tokyo)
        ..setSelectedArrival(losAngeles)
        ..setDepTime('01:00')
        ..setArrTime('19:00');
      expect(state().arrTZDateTime!.day, 9);
      expect(state().blockTime, const Duration(hours: 10));
      // Not known without a departure time to be after.
      notifier().setDepTime('');
      expect(state().arrTZDateTime, isNull);
      expect(state().blockTime, isNull);
    });

    test('an arrival before the departure is refused', () {
      notifier()
        ..setSelectedDeparture(rome)
        ..setSelectedArrival(rome)
        ..setDepartureDate(DateTime(2026, 7, 10))
        ..setArrivalDate(DateTime(2026, 7, 10))
        ..setDepTime('10:00')
        ..setArrTime('09:00');
      expect(state().isValid, isFalse);
      notifier().setArrTime('');
      expect(state().isValid, isTrue);
    });

    test('back in local time, the times follow the airport again', () {
      notifier()
        ..setSelectedDeparture(rome)
        ..setDepartureDate(DateTime(2026, 7, 10))
        ..setDepTime('08:00');
      expect(state().depTZDateTime.toUtc().hour, 6);
      notifier().setDepTzMode(TimezoneMode.utc);
      expect(state().depTZDateTime.toUtc().hour, 8);
      expect(state().depTzLabel, 'UTC');
      notifier().setDepTzMode(TimezoneMode.local);
      expect(state().depTZDateTime.toUtc().hour, 6);
      expect(state().depTzLabel, 'CEST');
    });

    test('the label is the one of the date flown', () {
      notifier()
        ..setSelectedDeparture(rome)
        ..setDepTime('08:00')
        ..setDepartureDate(DateTime(2026, 7, 10));
      expect(state().depTzLabel, 'CEST');
      notifier().setDepartureDate(DateTime(2026, 1, 10));
      expect(state().depTzLabel, 'CET');
    });

    test('a zone picked by hand outlives a change of airport', () {
      notifier()
        ..setDepIanaLocation('Asia/Tokyo')
        ..setSelectedDeparture(rome)
        ..setDepTime('08:00')
        ..setDepartureDate(DateTime(2026, 7, 10));
      expect(state().depTzLabel, 'JST');
    });

    test('an airport without a position has no zone of the one before', () {
      notifier()
        ..setDepTime('08:00')
        ..setDepartureDate(DateTime(2026, 7, 10))
        ..setSelectedDeparture(tokyo)
        ..setSelectedDeparture(noPosition);
      expect(
        state().depTZDateTime.isAtSameMomentAs(DateTime(2026, 7, 10, 8)),
        isTrue,
      );
    });

    test('a time the clocks skip is refused', () {
      notifier()
        ..setSelectedDeparture(rome)
        ..setSelectedArrival(rome)
        ..setDepartureDate(DateTime(2026, 3, 29))
        ..setDepTime('02:30');
      expect(state().isValid, isFalse);
      notifier().setDepTime('03:30');
      expect(state().isValid, isTrue);
    });

    test('an unknown zone does not break the form', () {
      notifier().setDepIanaLocation('Mars/Olympus');
      expect(state().depTZDateTime.timeZoneOffset, Duration.zero);
    });

    test("a session is in the device's zone", () {
      for (final month in [1, 7]) {
        notifier()
          ..setSelectedDeparture(tokyo)
          ..setSimulator(true)
          ..setDepartureDate(DateTime(2026, month, 10))
          ..setDepTime('08:00')
          ..setArrTime('10:00');
        expect(
          state().depTZDateTime.isAtSameMomentAs(DateTime(2026, month, 10, 8)),
          isTrue,
        );
        expect(state().blockTime, const Duration(hours: 2));
      }
    });

    test('a session past midnight when the clocks go back', () {
      notifier()
        ..setSimulator(true)
        ..setDepartureDate(DateTime(2026, 10, 25))
        ..setDepTime('22:00')
        ..setArrTime('01:00');
      expect(state().blockTime, const Duration(hours: 3));
    });
  });
}
