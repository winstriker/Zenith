import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/flight_form_provider.dart';
import '../providers/flight_providers.dart';
import '../services/database.dart';
import '../utils/tz_datetime.dart';
import '../widgets/aircraft_card.dart';
import '../widgets/airport_search_dialog.dart';
import '../widgets/flight_details_card.dart';
import '../widgets/flight_rules_card.dart';
import '../widgets/landings_card.dart';
import '../widgets/remarks_card.dart';
import '../widgets/timezone_picker.dart';
import 'aircraft_select_page.dart';

class FlightFormPage extends ConsumerStatefulWidget {
  final FlightWithStats? flightToEdit;

  const FlightFormPage({super.key, this.flightToEdit});

  bool get isEditing => flightToEdit != null;

  @override
  ConsumerState<FlightFormPage> createState() => _FlightFormPageState();
}

class _FlightFormPageState extends ConsumerState<FlightFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final FlightFormNotifier _formNotifier;

  @override
  void initState() {
    super.initState();
    _formNotifier = ref.read(flightFormProvider.notifier);
    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _populateFromFlight(widget.flightToEdit!);
      });
    }
  }

  @override
  void dispose() {
    if (!widget.isEditing) {
      Future.microtask(() => _formNotifier.reset());
    }
    super.dispose();
  }

  void _populateFromFlight(FlightWithStats flight) async {
    final notifier = _formNotifier;
    final f = flight.flight;

    // Fetch airports from the database
    final depAirport = flight.departure;
    final arrAirport = flight.arrival;
    notifier.setDepartureDate(f.departureTime);
    notifier.setArrivalDate(f.arrivalTime);
    notifier.setDepTime(
      TZDateTimeParser.formatHHmmInTimezone(
        f.departureTime,
        f.departureIanaLocation,
      ),
    );
    notifier.setArrTime(
      f.arrivalTime != null
          ? TZDateTimeParser.formatHHmmInTimezone(
              f.arrivalTime!,
              f.arrivalIanaLocation,
            )
          : '',
    );
    notifier.setRemarks(f.remarks ?? '');
    notifier.setApproachType(f.approachType ?? 'VISUAL');
    notifier.setNightLandings(f.nightLandings ?? 0);
    notifier.setDayLandings(f.dayLandings ?? 1);
    notifier.setFlightRules(f.flightRules ?? 'VFR');

    if (depAirport != null) {
      notifier.setSelectedDeparture(depAirport);
    } else if (f.departureIanaLocation != null) {
      notifier.setDepartureCode(f.departureIanaLocation!);
      notifier.setDepIanaLocation(f.departureIanaLocation);
    }
    if (arrAirport != null) {
      notifier.setSelectedArrival(arrAirport);
    } else if (f.arrivalIanaLocation != null) {
      notifier.setArrivalCode(f.arrivalIanaLocation!);
      notifier.setArrIanaLocation(f.arrivalIanaLocation);
    }
    if (flight.aircraftWithStats != null) {
      notifier.setSelectedAircraft(flight.aircraftWithStats);
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(flightFormProvider);
    final notifier = _formNotifier;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Flight' : 'Log Flight'),
        centerTitle: true,
      ),
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
              initialValue: widget.flightToEdit?.flight.remarks ?? form.remarks,
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
    final aws = await Navigator.push<AircraftWithStats>(
      context,
      MaterialPageRoute(builder: (_) => const AircraftSelectPage()),
    );
    if (aws != null) {
      notifier.setSelectedAircraft(aws);
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

    if (widget.isEditing) {
      await flightService.updateFlight(
        flightId: widget.flightToEdit!.flight.id,
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
    } else {
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
    }

    notifier.reset();

    if (mounted) Navigator.pop(context, true);
  }
}
