import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../main.dart';
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
      aircraftId: _selectedAircraft?.aircraft.id,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gpsState = ref.watch(gpsTrackingControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isRecording ? 'Recording' : 'New Flight'),
        centerTitle: true,
      ),
      body: _isRecording
          ? _buildRecordingView(theme, gpsState)
          : _buildSetupForm(theme),
    );
  }

  Widget _buildSetupForm(ThemeData theme) {
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
                controller: _titleController,
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
                      initialValue: _selectedAircraft,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Aircraft (optional)',
                        prefixIcon: Icon(Icons.airplanemode_active),
                      ),
                      items: aircraftList
                          .map(
                            (aws) => DropdownMenuItem(
                              value: aws,
                              child: Text('${aws.modelFullName}'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedAircraft = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: IconButton.filled(
                      onPressed: _addNewAircraft,
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
                      controller: _departureController,
                      decoration: const InputDecoration(
                        labelText: 'Departure (optional)',
                        prefixIcon: Icon(Icons.flight_takeoff),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _arrivalController,
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
                onPressed: _startRecording,
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

  Future<void> _addNewAircraft() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AircraftFormPage()),
    );
    // Stream provider automatically updates, no manual refresh needed
  }

  Widget _buildRecordingView(ThemeData theme, AsyncValue<void> gpsState) {
    final sessionAsync = ref.watch(activeFlightStreamProvider);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: Colors.red.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const PulsingDot(),
              const SizedBox(width: 10),
              Text(
                'RECORDING',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.red.shade800,
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
                  DurationFormatter.hms(_elapsed),
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.w200,
                    fontFamily: 'monospace',
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'elapsed time',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                sessionAsync.when(
                  data: (session) {
                    if (session == null) return const SizedBox.shrink();
                    final hasRoute =
                        session.departure?.ident != null ||
                        session.arrival?.ident != null;
                    final hasAircraft = session.aircraft != null;

                    if (!hasAircraft && !hasRoute) {
                      return const SizedBox.shrink();
                    }

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            if (hasAircraft)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.airplanemode_active,
                                      size: 18,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      session.aircraft!.modelFullName,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
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
                                  if (session.departure?.ident != null)
                                    InfoChip(
                                      label: session.departure!.ident!,
                                      icon: Icons.flight_takeoff,
                                      backgroundColor:
                                          theme.colorScheme.tertiaryContainer,
                                      textColor:
                                          theme.colorScheme.onTertiaryContainer,
                                    ),
                                  if (session.departure?.ident != null &&
                                      session.arrival?.ident != null)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Icon(
                                        Icons.arrow_forward,
                                        size: 16,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  if (session.arrival?.ident != null)
                                    InfoChip(
                                      label: session.arrival!.ident!,
                                      icon: Icons.flight_land,
                                      backgroundColor:
                                          theme.colorScheme.tertiaryContainer,
                                      textColor:
                                          theme.colorScheme.onTertiaryContainer,
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),
                _buildGpsCard(theme, gpsState),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FilledButton.icon(
              onPressed: _stopRecording,
              icon: const Icon(Icons.stop, size: 22),
              label: const Text('Stop Recording'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
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

  Widget _buildGpsCard(ThemeData theme, AsyncValue<void> gpsState) {
    final unitMode = ref.watch(unitProvider);
    final isMetric = unitMode == MeasurementUnit.metric;

    // Get latest GPS data from the controller
    final gpsController = ref.read(gpsTrackingControllerProvider.notifier);
    final latestLocation = gpsController.latestLocation;

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
                  const Icon(Icons.gps_fixed, color: Colors.green, size: 20),
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
