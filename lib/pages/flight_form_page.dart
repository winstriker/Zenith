import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import '../core/fab_hero_tags.dart';

import '../providers/database_provider.dart';
import '../providers/flight_form_provider.dart';
import '../providers/flight_providers.dart';
import '../repositories/aircraft_repository.dart';
import '../repositories/flight_repository.dart';
import '../services/adsb_flight_importer.dart';
import '../services/database.dart';
import '../utils/tz_datetime.dart';
import '../widgets/aircraft_card.dart';
import '../widgets/airport_search_dialog.dart';
import '../widgets/crew_card.dart';
import '../widgets/flight_form_card.dart';
import '../widgets/flight_rules_card.dart';
import '../widgets/landings_card.dart';
import '../widgets/page_title.dart';
import '../widgets/remarks_card.dart';
import '../widgets/timezone_picker.dart';
import 'aircraft_form_page.dart';
import 'aircraft_select_page.dart';

class FlightFormPage extends ConsumerStatefulWidget {
  const FlightFormPage({super.key, this.flightToEdit, this.adsbImport})
    : assert(flightToEdit == null || adsbImport == null);
  final FlightWithStats? flightToEdit;

  /// A flight found on ADS-B to log: fills the form in, and its track is
  /// saved with the new flight.
  final AdsbImportDraft? adsbImport;

  bool get isEditing => flightToEdit != null;

  @override
  ConsumerState<FlightFormPage> createState() => _FlightFormPageState();
}

class _FlightFormPageState extends ConsumerState<FlightFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final FlightFormNotifier _formNotifier;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _formNotifier = ref.read(flightFormProvider.notifier);
    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _populateFromFlight(widget.flightToEdit!);
      });
    } else if (widget.adsbImport != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _populateFromImport(widget.adsbImport!);
      });
    }
  }

  @override
  void dispose() {
    // Always clear the shared form state, otherwise an abandoned edit leaks
    // into the next form (and crew gets re-added on top of the old one).
    Future.microtask(() => _formNotifier.reset());
    super.dispose();
  }

  void _populateFromFlight(FlightWithStats flight) async {
    final notifier = _formNotifier;
    final f = flight.flight;

    // Start from a clean state so nothing from a previous form survives.
    notifier.reset();

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
    if (f.pilotRole != null) {
      notifier.setPilotRole(CrewRole.fromString(f.pilotRole!));
    }
    final crew = await ref.read(databaseProvider).getFlightCrew(f.id);
    final track = await ref.read(flightRepositoryProvider).getTrack(f.id);
    if (!mounted) return;
    notifier.setTrack([for (final p in track) p.timedPosition]);
    for (final member in crew) {
      notifier.addCrewMember(member);
    }
    notifier.setProficiencyCheck(f.proficiencyCheck);
    notifier.setNightLandings(f.nightLandings ?? 0);
    notifier.setDayLandings(f.dayLandings ?? 1);
    notifier.setFlightRules(f.flightRules ?? 'VFR');
    if (f.instrumentMinutes != null) {
      notifier.setInstrumentTime(Duration(minutes: f.instrumentMinutes!));
    }

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

  /// Fills the form in with what ADS-B saw of the flight. The times are in
  /// the airports' time zones, or UTC where there is no airport.
  void _populateFromImport(AdsbImportDraft draft) {
    final notifier = _formNotifier;
    notifier.reset();

    void side({
      required ImportedAirport? airport,
      required DateTime? time,
      required DateTime day,
      required void Function(Airport) select,
      required void Function(String?) setIana,
      required String? Function() iana,
      required void Function(DateTime) setDate,
      required void Function(String) setTime,
    }) {
      if (airport != null) {
        select(airport.airport);
      } else {
        // Without an airport there is no local time to speak of.
        setIana('UTC');
      }
      final location = switch (iana()) {
        final name? => tz.getLocation(name),
        null => tz.local,
      };
      final local = tz.TZDateTime.from(time ?? day, location);
      setDate(DateTime(local.year, local.month, local.day));
      if (time != null) {
        setTime(TZDateTimeParser.formatHHmm(TimeOfDay.fromDateTime(local)));
      }
    }

    side(
      airport: draft.departure,
      time: draft.departureTime,
      day: draft.departureTime,
      select: notifier.setSelectedDeparture,
      setIana: notifier.setDepIanaLocation,
      iana: () => ref.read(flightFormProvider).depIanaLocation,
      setDate: notifier.setDepartureDate,
      setTime: notifier.setDepTime,
    );
    side(
      airport: draft.arrival,
      time: draft.arrivalTime,
      // Without a landing time, the day it was last heard: a fair guess at
      // the day it landed, so a typed time is all it takes.
      day: draft.flight.end,
      select: notifier.setSelectedArrival,
      setIana: notifier.setArrIanaLocation,
      iana: () => ref.read(flightFormProvider).arrIanaLocation,
      setDate: notifier.setArrivalDate,
      setTime: notifier.setArrTime,
    );
    if (draft.aircraft != null) notifier.setSelectedAircraft(draft.aircraft);
    notifier.setTrack([
      for (final p in draft.points)
        (time: p.time, latitude: p.latitude, longitude: p.longitude),
    ]);
  }

  /// Adds the aircraft of the imported flight, which the user doesn't have
  /// yet, and selects it.
  Future<void> _addImportedAircraft(String registration) async {
    final id = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(
        builder: (_) => AircraftFormPage(initialTailNumber: registration),
      ),
    );
    if (id is! int || !mounted) return;
    final aircraft = await ref
        .read(aircraftRepositoryProvider)
        .watchAircraftWithStats(id)
        .first;
    if (aircraft != null && mounted) {
      _formNotifier.setSelectedAircraft(aircraft);
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(flightFormProvider);
    final notifier = _formNotifier;
    final draft = widget.adsbImport;
    final missingRegistration =
        draft?.registration != null && form.selectedAircraft == null
        ? draft!.registration
        : null;

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: FloatingActionButton(
        heroTag: closeFabHeroTag,
        tooltip: 'Close',
        onPressed: () => Navigator.pop(context),
        child: const Icon(Icons.close),
      ),
      body: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          heroTag: primaryFabHeroTag,
          onPressed: form.isValid && !_saving ? () => _save(notifier) : null,
          icon: const Icon(Icons.save),
          label: const Text('Save'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              PageTitle(
                widget.isEditing ? 'Edit Flight' : 'Log Flight',
                belowCloseButton: true,
                horizontalPadding: 0,
                bottomPadding: 16,
              ),
              if (draft != null) ...[
                _ImportSummary(draft: draft),
                const SizedBox(height: 16),
              ],
              FlightFormCard(
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
                onDepartureDateTap: () =>
                    _pickDate(notifier, isDeparture: true),
                onArrivalDateTap: () => _pickDate(notifier, isDeparture: false),
                onDepartureTzTap: () =>
                    _showTzPicker(notifier, isDeparture: true),
                onArrivalTzTap: () =>
                    _showTzPicker(notifier, isDeparture: false),
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
              if (missingRegistration != null) ...[
                const SizedBox(height: 8),
                _NewAircraftBanner(
                  registration: missingRegistration,
                  onAdd: () => _addImportedAircraft(missingRegistration),
                ),
              ],
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
                instrumentTime: form.instrumentTime,
                visualTime: form.visualTime,
                nightTime: form.nightTime,
                onInstrumentTimeChanged: notifier.setInstrumentTime,
                onVisualTimeChanged: notifier.setVisualTime,
                blockTimeKnown:
                    form.blockTime != null && !form.blockTime!.isNegative,
                timeError: form.instrumentError,
              ),
              const SizedBox(height: 16),
              CrewCard(
                pilotRole: form.pilotRole,
                crewMembers: form.crewMembers,
                errorText: form.crewError,
                onPilotRoleChanged: notifier.setPilotRole,
                onCrewMemberAdded: notifier.addCrewMember,
                onCrewMemberRemoved: notifier.removeCrewMember,
                onCrewMemberChanged: notifier.updateCrewMember,
                proficiencyCheck: form.proficiencyCheck,
                onProficiencyCheckChanged: notifier.setProficiencyCheck,
              ),
              const SizedBox(height: 16),
              RemarksCard(
                initialValue:
                    widget.flightToEdit?.flight.remarks ?? form.remarks,
                onChanged: notifier.setRemarks,
              ),
              const SizedBox(height: 80),
            ],
          ),
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
    if (form.crewError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(form.crewError!)));
      return;
    }
    final flightService = ref.read(flightServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final depCode =
          form.selectedDeparture?.ident ?? form.departureCode.trim();
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
          pilotRole: form.pilotRole.name,
          instrumentMinutes: form.instrumentTime?.inMinutes,
          nightMinutes: form.nightTime?.inMinutes,
          proficiencyCheck: form.isProficiencyCheck,
          crew: form.crewMembers,
        );
      } else {
        final flightId = await flightService.addFlight(
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
          pilotRole: form.pilotRole.name,
          instrumentMinutes: form.instrumentTime?.inMinutes,
          nightMinutes: form.nightTime?.inMinutes,
          proficiencyCheck: form.isProficiencyCheck,
          crew: form.crewMembers,
        );
        final draft = widget.adsbImport;
        if (draft != null) {
          try {
            await ref
                .read(flightRepositoryProvider)
                .replaceTrack(
                  flightId,
                  draft.points,
                  source: draft.flight.provider.id,
                );
          } catch (e) {
            // The flight is saved: the track can be fetched again from its
            // page.
            messenger.showSnackBar(
              SnackBar(
                content: Text('The flight was saved without its track ($e).'),
              ),
            );
          }
        }
      }

      notifier.reset();

      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

/// What was imported from ADS-B and how much of it is a guess.
class _ImportSummary extends StatelessWidget {
  const _ImportSummary({required this.draft});
  final AdsbImportDraft draft;

  static String _airport(String side, ImportedAirport? airport) {
    if (airport == null) return '$side: not known, pick it below';
    final code = airport.airport.ident ?? airport.airport.name ?? '?';
    return switch (airport.origin) {
      ImportedAirportOrigin.route => '$side: $code, from the route',
      ImportedAirportOrigin.usualRoute =>
        '$side: $code, where the callsign usually goes. The landing '
            "wasn't seen: enter the arrival time.",
      ImportedAirportOrigin.nearest =>
        '$side: $code, nearest to where the track '
            '${side == 'Departure' ? 'starts' : 'ends'}'
            '${airport.distanceKm == null ? '' : ' (${airport.distanceKm!.toStringAsFixed(1)} km)'}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final flight = draft.flight;
    final style = theme.textTheme.bodySmall?.copyWith(
      color: cs.onSecondaryContainer,
    );
    return Card(
      margin: EdgeInsets.zero,
      color: cs.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.settings_input_antenna, color: cs.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [
                      'Imported from ${flight.provider.label}',
                      ?flight.callsign,
                    ].join(' · '),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: cs.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Times are when the aircraft was first and last seen, '
                    'not block times. Check them before saving.',
                    style: style,
                  ),
                  const SizedBox(height: 4),
                  Text(_airport('Departure', draft.departure), style: style),
                  Text(_airport('Arrival', draft.arrival), style: style),
                  const SizedBox(height: 4),
                  Text(
                    flight.provider.attribution,
                    style: style?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Offers to add the aircraft of an imported flight, which the user doesn't
/// have yet.
class _NewAircraftBanner extends StatelessWidget {
  const _NewAircraftBanner({required this.registration, required this.onAdd});
  final String registration;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: cs.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: cs.onTertiaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$registration is not among your aircraft.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onTertiaryContainer,
                ),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
