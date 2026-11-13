import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../core/theme.dart';
import '../providers/aircraft_providers.dart';
import '../providers/flight_providers.dart';
import '../providers/gps_tracking_provider.dart';
import '../providers/unit_provider.dart';
import '../repositories/flight_repository.dart';
import '../services/database.dart';
import '../utils/duration_formatter.dart';
import '../widgets/info_chip.dart';
import '../widgets/info_row.dart';
import '../widgets/pulsing_dot.dart';
import 'aircraft_form_page.dart';

class RecordingPage extends ConsumerStatefulWidget {
  const RecordingPage({super.key});

  @override
  ConsumerState<RecordingPage> createState() => _RecordingPageState();
}

class _RecordingPageState extends ConsumerState<RecordingPage> {
  final _titleController = TextEditingController();
  final _departureController = TextEditingController();
  final _arrivalController = TextEditingController();
  AircraftWithStats? _selectedAircraft;

  Timer? _timer;
  DateTime? _startTime;
  Duration _elapsed = Duration.zero;

  bool get _isRecording => _startTime != null;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _titleController.text =
        'Flight ${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resumeExistingRecording();
    });
  }

  Future<void> _resumeExistingRecording() async {
    final repository = ref.read(flightRepositoryProvider);
    final gpsController = ref.read(gpsTrackingControllerProvider.notifier);

    // Check for active session via repository stream
    final activeFlights = await repository.watchActiveFlight().first;
    final activeSession = activeFlights;

    if (activeSession == null) return;

    setState(() {
      _startTime = activeSession.flight.departureTime;
      _elapsed = DateTime.now().difference(_startTime!);
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(_startTime!);
        });
      }
    });

    await gpsController.startTracking(activeSession.flight.id, repository);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _departureController.dispose();
    _arrivalController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final repository = ref.read(flightRepositoryProvider);
    final gpsController = ref.read(gpsTrackingControllerProvider.notifier);

    if (mounted) {
      await _ensureBackgroundPermission();
    }

    final flightId = await repository.startSession(
      title: _titleController.text.trim().isEmpty
          ? 'Flight ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}'
          : _titleController.text.trim(),
      aircraftId: _selectedAircraft?.id,
      departureId: _departureController.text.trim().isEmpty
          ? null
          : int.tryParse(_departureController.text.trim()),
      arrivalId: _arrivalController.text.trim().isEmpty
          ? null
          : int.tryParse(_arrivalController.text.trim()),
    );

    setState(() {
      _startTime = DateTime.now();
      _elapsed = Duration.zero;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(_startTime!);
        });
      }
    });

    await gpsController.startTracking(flightId, repository);
  }

  Future<void> _ensureBackgroundPermission() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always) return;

    if (!mounted) return;
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Background Location'),
        content: const Text(
          'To record flights when your screen is off, '
          'enable "Allow all the time" location access in system settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Skip'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'settings'),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
    if (action == 'settings') {
      await Geolocator.openAppSettings();
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _timer = null;

    final gpsController = ref.read(gpsTrackingControllerProvider.notifier);
    await gpsController.stopTracking();

    final repository = ref.read(flightRepositoryProvider);
    final activeFlight = await repository.watchActiveFlight().first;
    if (activeFlight != null) {
      await repository.endSession(activeFlight.flight.id);
    }

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _addNewAircraft() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const AircraftFormPage()),
    );
    // Stream provider automatically updates, no manual refresh needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isRecording ? 'Recording' : 'New Flight'),
        centerTitle: true,
      ),
      body: _isRecording
          ? _RecordingView(elapsed: _elapsed, onStop: _stopRecording)
          : _RecordingSetupForm(
              titleController: _titleController,
              departureController: _departureController,
              arrivalController: _arrivalController,
              selectedAircraft: _selectedAircraft,
              onAircraftChanged: (value) =>
                  setState(() => _selectedAircraft = value),
              onAddAircraft: _addNewAircraft,
              onStart: _startRecording,
            ),
    );
  }
}

class _RecordingSetupForm extends ConsumerWidget {
  const _RecordingSetupForm({
    required this.titleController,
    required this.departureController,
    required this.arrivalController,
    required this.selectedAircraft,
    required this.onAircraftChanged,
    required this.onAddAircraft,
    required this.onStart,
  });

  final TextEditingController titleController;
  final TextEditingController departureController;
  final TextEditingController arrivalController;
  final AircraftWithStats? selectedAircraft;
  final ValueChanged<AircraftWithStats?> onAircraftChanged;
  final VoidCallback onAddAircraft;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final aircraftListAsync = ref.watch(aircraftListStreamProvider);

    return aircraftListAsync.when(
      data: (aircraftList) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.flight,
                size: 64,
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Configure Flight',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Set up your flight details before starting the recording.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Flight Title',
                  prefixIcon: Icon(Icons.label_outline),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<AircraftWithStats>(
                      initialValue: selectedAircraft,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Aircraft (optional)',
                        prefixIcon: Icon(Icons.airplanemode_active),
                      ),
                      items: [
                        for (final aws in aircraftList)
                          DropdownMenuItem(
                            value: aws,
                            child: Text(aws.modelFullName),
                          ),
                      ],
                      onChanged: onAircraftChanged,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: IconButton.filled(
                      onPressed: onAddAircraft,
                      icon: const Icon(Icons.add, size: 20),
                      tooltip: 'Add new aircraft',
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        foregroundColor: theme.colorScheme.onPrimaryContainer,
                        minimumSize: const Size(48, 48),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: departureController,
                      decoration: const InputDecoration(
                        labelText: 'Departure (optional)',
                        prefixIcon: Icon(Icons.flight_takeoff),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: arrivalController,
                      decoration: const InputDecoration(
                        labelText: 'Arrival (optional)',
                        prefixIcon: Icon(Icons.flight_land),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.fiber_manual_record, size: 22),
                label: const Text('Start Recording'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _RecordingView extends ConsumerWidget {
  const _RecordingView({required this.elapsed, required this.onStop});

  final Duration elapsed;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sessionAsync = ref.watch(activeFlightStreamProvider);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: cs.errorContainer,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const PulsingDot(),
              const SizedBox(width: 10),
              Text(
                'RECORDING',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: cs.onErrorContainer,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Text(
                  DurationFormatter.hms(elapsed),
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.w200,
                    fontFamily: 'monospace',
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'elapsed time',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                sessionAsync.when(
                  data: (session) => session == null
                      ? const SizedBox.shrink()
                      : _SessionSummaryCard(session: session),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),
                _GpsCard(refreshTick: elapsed),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FilledButton.icon(
              onPressed: onStop,
              icon: const Icon(Icons.stop, size: 22),
              label: const Text('Stop Recording'),
              style: FilledButton.styleFrom(
                backgroundColor: cs.error,
                foregroundColor: cs.onError,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SessionSummaryCard extends StatelessWidget {
  const _SessionSummaryCard({required this.session});
  final FlightWithStats session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final departure = session.departure?.ident;
    final arrival = session.arrival?.ident;
    final aircraft = session.aircraftWithStats;
    final hasRoute = departure != null || arrival != null;

    if (aircraft == null && !hasRoute) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (aircraft != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.airplanemode_active,
                      size: 18,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      aircraft.modelFullName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            if (hasRoute)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (departure != null)
                    InfoChip(
                      label: departure,
                      icon: Icons.flight_takeoff,
                      backgroundColor: cs.tertiaryContainer,
                      textColor: cs.onTertiaryContainer,
                    ),
                  if (departure != null && arrival != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  if (arrival != null)
                    InfoChip(
                      label: arrival,
                      icon: Icons.flight_land,
                      backgroundColor: cs.tertiaryContainer,
                      textColor: cs.onTertiaryContainer,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _GpsCard extends ConsumerWidget {
  const _GpsCard({required this.refreshTick});

  /// The latest location isn't reactive, so the parent passes its 1s ticker
  /// to force a rebuild with fresh data.
  final Duration refreshTick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final gpsState = ref.watch(gpsTrackingControllerProvider);
    final isMetric = ref.watch(unitProvider) == MeasurementUnit.metric;

    // Latest (non-debounced) fix, see [refreshTick].
    final latestLocation = ref
        .read(gpsTrackingControllerProvider.notifier)
        .latestLocation;

    final lat = latestLocation?['latitude'] ?? 0.0;
    final lon = latestLocation?['longitude'] ?? 0.0;
    final alt = latestLocation?['altitude'] ?? 0.0;
    final speed = latestLocation?['speed'] ?? 0.0;
    final heading = latestLocation?['heading'] ?? 0.0;

    final altValue = isMetric ? alt : alt * 3.28084;
    final altUnit = isMetric ? 'm' : 'ft';

    final speedValue = isMetric ? speed : speed * 0.539957;
    final speedUnit = isMetric ? 'km/h' : 'kts';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.satellite_alt,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Live GPS Data',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (gpsState.isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (gpsState.hasError)
                  Icon(Icons.gps_off, color: theme.colorScheme.error, size: 20)
                else
                  Icon(
                    Icons.gps_fixed,
                    color: context.appColors.success,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            InfoRow(
              label: 'Latitude',
              value: lat.toStringAsFixed(6),
              labelWidth: 90,
              isMonospace: true,
            ),
            InfoRow(
              label: 'Longitude',
              value: lon.toStringAsFixed(6),
              labelWidth: 90,
              isMonospace: true,
            ),
            InfoRow(
              label: 'Altitude',
              value: '${altValue.toStringAsFixed(1)} $altUnit',
              labelWidth: 90,
              isMonospace: true,
            ),
            InfoRow(
              label: 'Speed',
              value: '${speedValue.toStringAsFixed(1)} $speedUnit',
              labelWidth: 90,
              isMonospace: true,
            ),
            InfoRow(
              label: 'Heading',
              value: '${heading.toStringAsFixed(1)}\u00B0',
              labelWidth: 90,
              isMonospace: true,
            ),
          ],
        ),
      ),
    );
  }
}
