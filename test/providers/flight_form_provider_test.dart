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
      person: Person(id: 1, name: 'Anna', surname: 'Verdi'),
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
      simulator: Simulator(id: 1, kind: SimulatorKind.ffs),
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
}
