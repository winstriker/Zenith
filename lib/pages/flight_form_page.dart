import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logbook/providers/flight_form_provider.dart';
import 'package:logbook/providers/flight_providers.dart';
import 'package:logbook/widgets/aircraft_card.dart';
import 'package:logbook/widgets/airport_search_dialog.dart';
import 'package:logbook/widgets/flight_details_card.dart';
import 'package:logbook/widgets/flight_rules_card.dart';
import 'package:logbook/widgets/landings_card.dart';
import 'package:logbook/widgets/remarks_card.dart';
import 'package:logbook/widgets/timezone_picker.dart';
import '../services/database.dart';
import '../utils/tz_datetime.dart';
import 'aircraft_select_page.dart';

class FlightFormPage extends ConsumerStatefulWidget {
  const FlightFormPage({super.key});

  @override
  ConsumerState<FlightFormPage> createState() => _FlightFormPageState();
}

class _FlightFormPageState extends ConsumerState<FlightFormPage> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(flightFormProvider);
    final notifier = ref.read(flightFormProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Log Flight'), centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: form.isValid ? () => _save(notifier) : null,
        icon: const Icon(Icons.save),
        label: const Text('Save'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FlightDetailsCard(
              departureDate: form.departureDate,
              arrivalDate: form.arrivalDate,
              departureCode: form.departureCode,
              arrivalCode: form.arrivalCode,
              depTime: form.depTime,
              arrTime: form.arrTime,
              selectedDeparture: form.selectedDeparture,
              selectedArrival: form.selectedArrival,
              depTzLabel: form.depTzLabel,
              arrTzLabel: form.arrTzLabel,
              blockTime: form.blockTimeFormatted,
              onDepartureDateTap: () => _pickDate(notifier, isDeparture: true),
              onArrivalDateTap: () => _pickDate(notifier, isDeparture: false),
              onDepartureTzTap: () =>
                  _showTzPicker(notifier, isDeparture: true),
              onArrivalTzTap: () => _showTzPicker(notifier, isDeparture: false),
              onDepartureAirportTap: () =>
                  _pickAirport(notifier, isDeparture: true),
              onArrivalAirportTap: () =>
                  _pickAirport(notifier, isDeparture: false),
              onDepTimeChanged: notifier.setDepTime,
              onArrTimeChanged: notifier.setArrTime,
              parseDateTime: TZDateTimeParser.parseDateTimeFromText,
              depIanaLocation: form.depIanaLocation,
              arrIanaLocation: form.arrIanaLocation,
            ),
            const SizedBox(height: 16),
            AircraftCard(
              aircraft: form.selectedAircraft,
              onTap: () => _pickAircraft(notifier),
              useOuterPadding: false,
            ),
            const SizedBox(height: 16),
            LandingsCard(
              approachType: form.approachType,
              onApproachTypeChanged: notifier.setApproachType,
              nightLandings: form.nightLandings,
              onNightLandingsChanged: notifier.setNightLandings,
              dayLandings: form.dayLandings,
              onDayLandingsChanged: notifier.setDayLandings,
            ),
            const SizedBox(height: 16),
            FlightRulesCard(
              flightRules: form.flightRules,
              onFlightRulesChanged: notifier.setFlightRules,
            ),
            const SizedBox(height: 16),
            RemarksCard(
              initialValue: form.remarks,
              onChanged: notifier.setRemarks,
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAirport(
    FlightFormNotifier notifier, {
    required bool isDeparture,
  }) async {
    final airport = await showDialog<Airport>(
      context: context,
      builder: (_) => AirportSearchDialog(
        title: isDeparture ? 'Select Departure' : 'Select Arrival',
      ),
    );
    if (airport != null) {
      if (isDeparture) {
        notifier.setSelectedDeparture(airport);
      } else {
        notifier.setSelectedArrival(airport);
      }
    }
  }

  Future<void> _pickDate(
    FlightFormNotifier notifier, {
    required bool isDeparture,
  }) async {
    final form = ref.read(flightFormProvider);
    final current = isDeparture
        ? form.departureDate
        : (form.arrivalDate ?? form.departureDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      if (isDeparture) {
        notifier.setDepartureDate(picked);
      } else {
        notifier.setArrivalDate(picked);
      }
    }
  }

  void _showTzPicker(FlightFormNotifier notifier, {required bool isDeparture}) {
    final form = ref.read(flightFormProvider);
    final referenceDate = isDeparture
        ? form.departureDate
        : (form.arrivalDate ?? form.departureDate);
    TimezonePicker.show(
      context: context,
      currentMode: isDeparture ? form.depTzMode : form.arrTzMode,
      currentIanaLocation: isDeparture
          ? form.depIanaLocation
          : form.arrIanaLocation,
      onModeChanged: (mode) {
        if (isDeparture) {
          notifier.setDepTzMode(mode);
        } else {
          notifier.setArrTzMode(mode);
        }
      },
      onIanaLocationChanged: (location) {
        if (isDeparture) {
          notifier.setDepIanaLocation(location);
        } else {
          notifier.setArrIanaLocation(location);
        }
      },
      isDeparture: isDeparture,
      referenceDate: referenceDate,
    );
  }

  Future<void> _pickAircraft(FlightFormNotifier notifier) async {
    final aircraft = await Navigator.push<Aircraft>(
      context,
      MaterialPageRoute(builder: (_) => const AircraftSelectPage()),
    );
    if (aircraft != null) {
      notifier.setSelectedAircraft(aircraft);
    }
  }

  Future<void> _save(FlightFormNotifier notifier) async {
    if (!_formKey.currentState!.validate()) return;

    final form = ref.read(flightFormProvider);
    final flightService = ref.read(flightServiceProvider);

    final depCode = form.selectedDeparture?.ident ?? form.departureCode.trim();
    final arrCode = form.selectedArrival?.ident ?? form.arrivalCode.trim();

    // Use the TZDateTime directly - it stores the correct instant in UTC
    final depDateTime = form.depTZDateTime;
    final arrDateTime = form.arrTZDateTime;

    await flightService.addFlight(
      departureId: form.selectedDeparture?.id,
      arrivalId: form.selectedArrival?.id,
      title: '$depCode → $arrCode',
      departureTime: depDateTime,
      arrivalTime: arrDateTime,
      aircraftId: form.selectedAircraft?.id,
      approachType: form.approachType,
      nightLandings: form.nightLandings,
      dayLandings: form.dayLandings,
      flightRules: form.flightRules,
      remarks: form.remarks.trim().isEmpty ? null : form.remarks.trim(),
      departureIanaLocation: form.depIanaLocation,
      arrivalIanaLocation: form.arrIanaLocation,
    );

    ref.read(flightListProvider.notifier).refresh();
    notifier.reset();

    if (mounted) Navigator.pop(context, true);
  }
}
