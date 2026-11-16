import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:zenith/providers/flight_form_provider.dart';

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
}
