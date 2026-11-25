import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_page_route.dart';
import '../core/fab_hero_tags.dart';
import '../providers/airport_providers.dart';
import '../providers/database_provider.dart';
import '../providers/flight_form_provider.dart';
import '../providers/flight_providers.dart';
import '../providers/licence_providers.dart';
import '../repositories/aircraft_repository.dart';
import '../repositories/flight_repository.dart';
import '../services/adsb_flight_importer.dart';
import '../services/database.dart';
import '../services/pdf_export_service.dart';
import '../services/person_photo_store.dart';
import '../widgets/aircraft_card.dart';
import '../widgets/airport_search_dialog.dart';
import '../widgets/crew_card.dart';
import '../widgets/flight_form_card.dart';
import '../widgets/flight_rules_card.dart';
import '../widgets/landings_card.dart';
import '../widgets/page_title.dart';
import '../widgets/remarks_card.dart';
import '../widgets/session_times_card.dart';
import '../widgets/simulator_card.dart';
import '../widgets/timezone_picker.dart';
import 'aircraft_form_page.dart';
import 'aircraft_select_page.dart';
import 'image_crop_page.dart';
import 'signature_pad_page.dart';
import 'simulator_select_page.dart';

enum _SignatureAction { draw, upload, photo, remove }

class FlightFormPage extends ConsumerStatefulWidget {
  const FlightFormPage({
    super.key,
    this.flightToEdit,
    this.adsbImport,
    this.simulator = false,
  }) : assert(flightToEdit == null || adsbImport == null),
       assert(!simulator || adsbImport == null);
  final FlightWithStats? flightToEdit;

  /// For a new entry: start with a simulator session rather than a flight.
  final bool simulator;

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

  /// Newly made signature, not yet copied into the store.
  File? _pickedSignature;
  bool _signatureRemoved = false;

  /// Whether a simulator session is being logged. Set before the shared
  /// form state follows, so the first frame already has the right layout.
  late bool _simulator =
      widget.simulator || (widget.flightToEdit?.isSimulatorSession ?? false);

  /// Bumped once the entry is loaded: rebuilds the time fields, which only
  /// read their value when created.
  int _loaded = 0;

  /// Whether the airport dialogs search every airport, ignoring the search
  /// settings; only for this form, never saved.
  final _searchAll = ValueNotifier(false);

  /// The signature the flight was saved with, unless removed here.
  String? get _storedSignature =>
      _signatureRemoved ? null : widget.flightToEdit?.flight.signatureFile;

  bool get _hasSignature =>
      _pickedSignature != null || _storedSignature != null;

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
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Starts now: the shared state dates from when the last form closed.
        _formNotifier.reset();
        _formNotifier.setSimulator(_simulator);
        setState(() => _loaded++);
      });
    }
  }

  void _setSimulator(bool simulator) {
    setState(() => _simulator = simulator);
    _formNotifier.setSimulator(simulator);
  }

  @override
  void dispose() {
    // Always clear the shared form state, otherwise an abandoned edit leaks
    // into the next form (and crew gets re-added on top of the old one).
    Future.microtask(() => _formNotifier.reset());
    _searchAll.dispose();
    super.dispose();
  }

  void _populateFromFlight(FlightWithStats flight) async {
    final notifier = _formNotifier;
    final f = flight.flight;

    final depAirport = flight.departure;
    final arrAirport = flight.arrival;
    final crew = await ref.read(databaseProvider).getFlightCrew(f.id);
    final track = await ref.read(flightRepositoryProvider).getTrack(f.id);
    // A temporary flight has no airports yet: guess them from where the
    // track starts and ends, as an ADS-B import does.
    Future<Airport?> nearest(FlightDataPoint p) async =>
        AdsbFlightImporter.pickNearest(
          await ref
              .read(airportServiceProvider)
              .getAirportsNearCoordinates(p.latitude, p.longitude, limit: 50),
        )?.airport;
    final guess = f.isRecording && track.isNotEmpty;
    final (depGuess, arrGuess) = await (
      guess && depAirport == null
          ? nearest(track.first)
          : Future<Airport?>.value(),
      guess && arrAirport == null && f.arrivalTime != null
          ? nearest(track.last)
          : Future<Airport?>.value(),
    ).wait;
    if (!mounted) return;

    // Start from a clean state so nothing from a previous form survives.
    notifier.reset();
    if (flight.isSimulatorSession) {
      notifier.setSimulator(true);
      notifier.setSelectedSimulator(flight.simulator);
    }
    notifier.setRemarks(f.remarks ?? '');
    notifier.setApproachType(f.approachType ?? 'VISUAL');
    if (f.pilotRole != null) {
      notifier.setPilotRole(CrewRole.fromString(f.pilotRole!));
    }
    notifier.setTrack([for (final p in track) p.timedPosition]);
    for (final member in crew) {
      notifier.addCrewMember(member);
    }
    notifier.setProficiencyCheck(f.proficiencyCheck);
    notifier.setNightLandings(f.nightLandings ?? 0);
    notifier.setDayLandings(f.dayLandings ?? 1);
    notifier.setMountainLandings(f.mountainLandings ?? 0);
    notifier.setFlightRules(f.flightRules ?? 'VFR');
    if (f.instrumentMinutes != null) {
      notifier.setInstrumentTime(Duration(minutes: f.instrumentMinutes!));
    }

    // An airport that is gone leaves its code in the title.
    final codes = f.title.split(' → ');
    if (codes.length == 2) {
      notifier.setDepartureCode(codes.first);
      notifier.setArrivalCode(codes.last);
    }
    notifier.setSelectedDeparture(depAirport ?? depGuess);
    notifier.setSelectedArrival(arrAirport ?? arrGuess);

    // The zones it was saved in (none is UTC), then the times in them. A
    // guessed airport has its own.
    final depZone = f.departureIanaLocation ?? 'UTC';
    if (depGuess == null && depZone != ref.read(flightFormProvider).depZone) {
      notifier.setDepIanaLocation(depZone);
    }
    notifier.setDepInstant(f.departureTime);
    final arrival = f.arrivalTime;
    if (arrGuess == null &&
        (arrival != null || f.arrivalIanaLocation != null)) {
      final arrZone = f.arrivalIanaLocation ?? 'UTC';
      if (arrZone != ref.read(flightFormProvider).arrZone) {
        notifier.setArrIanaLocation(arrZone);
      }
    }
    if (arrival != null) notifier.setArrInstant(arrival);

    if (flight.aircraftWithStats != null) {
      notifier.setSelectedAircraft(flight.aircraftWithStats);
    }
    setState(() => _loaded++);
  }

  /// Fills the form in with what ADS-B saw of the flight. The times are in
  /// the airports' time zones, or UTC where there is no airport.
  void _populateFromImport(AdsbImportDraft draft) {
    final notifier = _formNotifier;
    notifier.reset();

    final departure = draft.departure;
    if (departure != null) {
      notifier.setSelectedDeparture(departure.airport);
    } else {
      notifier.setDepTzMode(TimezoneMode.utc);
    }
    notifier.setDepInstant(draft.departureTime);

    final arrival = draft.arrival;
    if (arrival != null) {
      notifier.setSelectedArrival(arrival.airport);
    } else {
      notifier.setArrTzMode(TimezoneMode.utc);
    }
    // Without a landing time, a typed one is the first after departure.
    final arrivalTime = draft.arrivalTime;
    if (arrivalTime != null) notifier.setArrInstant(arrivalTime);

    if (draft.aircraft != null) notifier.setSelectedAircraft(draft.aircraft);
    notifier.setTrack([
      for (final p in draft.points)
        (time: p.time, latitude: p.latitude, longitude: p.longitude),
    ]);
    setState(() => _loaded++);
  }

  /// Adds the aircraft of the imported flight, which the user doesn't have
  /// yet, and selects it.
  Future<void> _addImportedAircraft(String registration) async {
    final id = await Navigator.push<Object?>(
      context,
      AppPageRoute(
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
    final holdsMountainRating =
        ref
            .watch(licencesStreamProvider)
            .value
            ?.any((l) => l.ratings.any((r) => r.kind == RatingKind.mountain)) ??
        false;
    final timeError = form.timeError == null
        ? null
        : Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
            child: Text(
              form.timeError!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          );
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
                switch ((widget.isEditing, _simulator)) {
                  (true, true) => 'Edit Session',
                  // A recorded flight is saved into the logbook from here.
                  (true, false) when widget.flightToEdit!.flight.isRecording =>
                    'Complete Flight',
                  (true, false) => 'Edit Flight',
                  (false, true) => 'Log Session',
                  (false, false) => 'Log Flight',
                },
                belowCloseButton: true,
                horizontalPadding: 0,
                bottomPadding: 16,
              ),
              if (!widget.isEditing && draft == null) ...[
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      label: Text('Aircraft'),
                      icon: Icon(Icons.airplanemode_active),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('Simulator'),
                      icon: Icon(simulatorIcon),
                    ),
                  ],
                  selected: {_simulator},
                  onSelectionChanged: (s) => _setSimulator(s.single),
                ),
                const SizedBox(height: 16),
              ],
              if (draft != null) ...[
                _ImportSummary(draft: draft),
                const SizedBox(height: 16),
              ],
              if (_simulator) ...[
                SessionTimesCard(
                  key: ValueKey(_loaded),
                  date: form.departureDate,
                  startTime: form.depTime,
                  endTime: form.arrTime,
                  start: form.depTZDateTime,
                  end: form.arrTZDateTime,
                  onDateTap: () => _pickDate(notifier, isDeparture: true),
                  onStartChanged: notifier.setDepTime,
                  onEndChanged: notifier.setArrTime,
                ),
                ?timeError,
                const SizedBox(height: 16),
                SimulatorCard(
                  simulator: form.selectedSimulator,
                  onTap: () => _pickSimulator(notifier),
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
                if (form.selectedSimulator?.kind.countsForRecency == false)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                    child: Text(
                      'Only landings in a full flight simulator count for '
                      'recent experience (FCL.060).',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ] else ...[
                FlightFormCard(
                  key: ValueKey(_loaded),
                  departureDate: form.departureDate,
                  arrivalDate: form.arrivalDate ?? form.arrTZDateTime,
                  departureCode: form.departureCode,
                  arrivalCode: form.arrivalCode,
                  depTime: form.depTime,
                  arrTime: form.arrTime,
                  selectedDeparture: form.selectedDeparture,
                  selectedArrival: form.selectedArrival,
                  depTzLabel: form.depTzLabel,
                  arrTzLabel: form.arrTzLabel,
                  onDepartureDateTap: () =>
                      _pickDate(notifier, isDeparture: true),
                  onArrivalDateTap: () =>
                      _pickDate(notifier, isDeparture: false),
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
                  departure: form.depTime.isEmpty ? null : form.depTZDateTime,
                  arrival: form.arrTZDateTime,
                ),
                ?timeError,
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
                  // Asked of mountain rating holders only (FCL.815(d)).
                  mountainLandings:
                      holdsMountainRating || form.mountainLandings > 0
                      ? form.mountainLandings
                      : null,
                  onMountainLandingsChanged: notifier.setMountainLandings,
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
              ],
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
                signature: _signatureFile(),
                onSignatureTap: _pickSignature,
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  /// The signature to show: the new one, else the saved one.
  File? _signatureFile() {
    if (_pickedSignature != null) return _pickedSignature;
    final stored = _storedSignature;
    final dir = ref.watch(signatureDirectoryProvider).value;
    if (stored == null || dir == null) return null;
    return File('${dir.path}/$stored');
  }

  Future<void> _pickSignature() async {
    final action = await showModalBottomSheet<_SignatureAction>(
      context: context,
      builder: (ctx) {
        final error = Theme.of(ctx).colorScheme.error;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.draw_outlined),
                title: const Text('Draw signature'),
                onTap: () => Navigator.pop(ctx, _SignatureAction.draw),
              ),
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const Text('Upload PNG'),
                onTap: () => Navigator.pop(ctx, _SignatureAction.upload),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Photograph paper logbook'),
                subtitle: const Text('Crop it to the remarks of this flight'),
                onTap: () => Navigator.pop(ctx, _SignatureAction.photo),
              ),
              if (_hasSignature)
                ListTile(
                  leading: Icon(Icons.delete_outline, color: error),
                  title: Text(
                    'Remove signature',
                    style: TextStyle(color: error),
                  ),
                  onTap: () => Navigator.pop(ctx, _SignatureAction.remove),
                ),
            ],
          ),
        );
      },
    );
    if (action == null || !mounted) return;
    final File? picked;
    switch (action) {
      case _SignatureAction.remove:
        setState(() {
          _pickedSignature = null;
          _signatureRemoved = true;
        });
        return;
      case _SignatureAction.draw:
        picked = await Navigator.push<File>(
          context,
          AppPageRoute(builder: (_) => const SignaturePadPage()),
        );
      case _SignatureAction.upload:
        picked = await _pickAndCrop(ImageSource.gallery);
      case _SignatureAction.photo:
        picked = await _pickAndCrop(ImageSource.camera);
    }
    if (picked == null || !mounted) return;
    setState(() {
      _pickedSignature = picked;
      // Replaced: the saved one goes.
      _signatureRemoved = true;
    });
  }

  /// Fits a picture into the remarks cell. It may be smaller than the cell
  /// or off to a side: the rest is left transparent.
  Future<File?> _pickAndCrop(ImageSource source) {
    final (:x, :y) = PdfExportService.remarksCellRatio;
    final isPhoto = source == ImageSource.camera;
    return pickAndCropImage(
      context,
      source: source,
      // An upload keeps its original file, and so its transparency.
      maxPickSize: isPhoto ? 3000 : null,
      spec: CropSpec(
        title: isPhoto ? 'Crop remarks' : 'Fit signature',
        aspectRatio: x / y,
        // About 400 dpi in a 37 mm wide cell.
        outputWidth: 600,
        allowOutside: true,
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
        searchAll: _searchAll,
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

  Future<void> _pickSimulator(FlightFormNotifier notifier) async {
    final sim = await Navigator.push<SimulatorWithStats>(
      context,
      AppPageRoute(builder: (_) => const SimulatorSelectPage()),
    );
    if (sim != null) notifier.setSelectedSimulator(sim);
  }

  Future<void> _pickAircraft(FlightFormNotifier notifier) async {
    final aws = await Navigator.push<AircraftWithStats>(
      context,
      AppPageRoute(builder: (_) => const AircraftSelectPage()),
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
    final signatures = ref.read(signatureStoreProvider);
    setState(() => _saving = true);
    String? storedSignature;
    try {
      if (_pickedSignature != null) {
        storedSignature = await signatures.save(_pickedSignature!);
      }
      // Value.absent() = signature unchanged.
      final signature = _pickedSignature != null
          ? Value(storedSignature)
          : _signatureRemoved
          ? const Value<String?>(null)
          : const Value<String?>.absent();
      final depCode =
          form.selectedDeparture?.ident ?? form.departureCode.trim();
      final arrCode = form.selectedArrival?.ident ?? form.arrivalCode.trim();

      // Use the TZDateTime directly - it stores the correct instant in UTC
      final depDateTime = form.depTZDateTime;
      final arrDateTime = form.arrTZDateTime;
      final remarks = form.remarks.trim().isEmpty ? null : form.remarks.trim();

      if (form.isSimulator) {
        // A session keeps none of a flight's route, aircraft or rules.
        final sim = form.selectedSimulator!;
        final flightId = widget.flightToEdit?.flight.id;
        if (flightId != null) {
          await flightService.updateFlight(
            flightId: flightId,
            departureId: null,
            arrivalId: null,
            title: sim.title,
            departureTime: depDateTime,
            arrivalTime: arrDateTime,
            departureIanaLocation: form.depZone,
            arrivalIanaLocation: form.arrZone,
            simulatorId: sim.id,
            approachType: form.approachType,
            nightLandings: form.nightLandings,
            dayLandings: form.dayLandings,
            remarks: remarks,
            pilotRole: form.pilotRole.name,
            proficiencyCheck: form.isProficiencyCheck,
            crew: form.crewMembers,
            signatureFile: signature,
          );
        } else {
          await flightService.addFlight(
            departureId: null,
            arrivalId: null,
            title: sim.title,
            departureTime: depDateTime,
            arrivalTime: arrDateTime,
            departureIanaLocation: form.depZone,
            arrivalIanaLocation: form.arrZone,
            simulatorId: sim.id,
            approachType: form.approachType,
            nightLandings: form.nightLandings,
            dayLandings: form.dayLandings,
            remarks: remarks,
            pilotRole: form.pilotRole.name,
            proficiencyCheck: form.isProficiencyCheck,
            crew: form.crewMembers,
            signatureFile: storedSignature,
          );
        }
      } else if (widget.isEditing) {
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
          // Never more than the landings flown.
          mountainLandings: form.mountainLandings.clamp(
            0,
            form.dayLandings + form.nightLandings,
          ),
          flightRules: form.flightRules,
          remarks: form.remarks.trim().isEmpty ? null : form.remarks.trim(),
          departureIanaLocation: form.depZone,
          arrivalIanaLocation: form.arrZone,
          pilotRole: form.pilotRole.name,
          instrumentMinutes: form.instrumentTime?.inMinutes,
          nightMinutes: form.nightTime?.inMinutes,
          proficiencyCheck: form.isProficiencyCheck,
          crew: form.crewMembers,
          signatureFile: signature,
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
          // Never more than the landings flown.
          mountainLandings: form.mountainLandings.clamp(
            0,
            form.dayLandings + form.nightLandings,
          ),
          flightRules: form.flightRules,
          remarks: form.remarks.trim().isEmpty ? null : form.remarks.trim(),
          departureIanaLocation: form.depZone,
          arrivalIanaLocation: form.arrZone,
          pilotRole: form.pilotRole.name,
          instrumentMinutes: form.instrumentTime?.inMinutes,
          nightMinutes: form.nightTime?.inMinutes,
          proficiencyCheck: form.isProficiencyCheck,
          crew: form.crewMembers,
          signatureFile: storedSignature,
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
    } catch (_) {
      // Don't leave a signature behind that no flight points to.
      await signatures.delete(storedSignature);
      rethrow;
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
