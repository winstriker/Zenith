import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logbook/main.dart';
import '../providers/flight_providers.dart';
import '../providers/aircraft_providers.dart';
import '../providers/unit_provider.dart';
import '../services/database.dart';
import '../services/location_service.dart';
import '../widgets/pulsing_dot.dart';
import '../widgets/info_chip.dart';
import '../widgets/info_row.dart';
import '../utils/duration_formatter.dart';

class RecordingPage extends ConsumerStatefulWidget {
  const RecordingPage({super.key});

  @override
  ConsumerState<RecordingPage> createState() => _RecordingPageState();
}

class _RecordingPageState extends ConsumerState<RecordingPage> {
  final _titleController = TextEditingController();
  final _departureController = TextEditingController();
  final _arrivalController = TextEditingController();
  Aircraft? _selectedAircraft;

  StreamSubscription<Map<String, double>>? _locationSubscription;
  Timer? _timer;
  DateTime? _startTime;
  Duration _elapsed = Duration.zero;

  double _latitude = 0;
  double _longitude = 0;
  double _altitude = 0;
  double _speed = 0;
  double _heading = 0;

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
    final flightService = ref.read(flightServiceProvider);
    final activeSession = flightService.activeSession;
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

    final locationService = LocationService();
    await locationService.startTracking();

    _locationSubscription = locationService.locationStream.listen((location) {
      final lat = location['latitude']!;
      final lon = location['longitude']!;
      final alt = location['altitude']!;
      final speed = location['speed']!;
      final heading = location['heading']!;

      ref
          .read(flightServiceProvider)
          .addPoint(lat, lon, alt, speed: speed, heading: heading);

      if (mounted) {
        setState(() {
          _latitude = lat;
          _longitude = lon;
          _altitude = alt;
          _speed = speed;
          _heading = heading;
        });
      }
    });

    ref.read(recordingStateProvider.notifier).refresh();
    ref.read(flightListProvider.notifier).refresh();
    ref.read(activeFlightProvider.notifier).refresh();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _departureController.dispose();
    _arrivalController.dispose();
    _locationSubscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final flightService = ref.read(flightServiceProvider);
    final locationService = LocationService();

    if (mounted) {
      await _ensureBackgroundPermission();
    }

    await flightService.startSession(
      title: _titleController.text.trim().isEmpty
          ? 'Flight ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}'
          : _titleController.text.trim(),
      aircraftId: _selectedAircraft?.id,
      aircraft: _selectedAircraft,
      departure: _departureController.text.trim().isEmpty
          ? null
          : _departureController.text.trim(),
      arrival: _arrivalController.text.trim().isEmpty
          ? null
          : _arrivalController.text.trim(),
    );

    await locationService.startTracking();

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

    _locationSubscription = locationService.locationStream.listen((location) {
      final lat = location['latitude']!;
      final lon = location['longitude']!;
      final alt = location['altitude']!;
      final speed = location['speed']!;
      final heading = location['heading']!;

      ref
          .read(flightServiceProvider)
          .addPoint(lat, lon, alt, speed: speed, heading: heading);

      if (mounted) {
        setState(() {
          _latitude = lat;
          _longitude = lon;
          _altitude = alt;
          _speed = speed;
          _heading = heading;
        });
      }
    });

    ref.read(recordingStateProvider.notifier).refresh();
    ref.read(flightListProvider.notifier).refresh();
    ref.read(activeFlightProvider.notifier).refresh();
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
    _locationSubscription?.cancel();
    _locationSubscription = null;

    LocationService().stopTracking();
    await ref.read(flightServiceProvider).endSession();

    ref.read(recordingStateProvider.notifier).refresh();
    ref.read(flightListProvider.notifier).refresh();
    ref.read(activeFlightProvider.notifier).refresh();

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isRecording ? 'Recording' : 'New Flight'),
        centerTitle: true,
      ),
      body: _isRecording ? _buildRecordingView(theme) : _buildSetupForm(theme),
    );
  }

  Widget _buildSetupForm(ThemeData theme) {
    final aircraftList = ref.watch(aircraftListProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
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
                child: DropdownButtonFormField<Aircraft>(
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
                          child: Text(
                            aws.tailNumber != null
                                ? '${aws.type} (${aws.tailNumber})'
                                : aws.type,
                          ),
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
                  onPressed: () => _addNewAircraft(),
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
  }

  Future<void> _addNewAircraft() async {
    final db = ref.read(databaseProvider);
    final typeCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final tailCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Aircraft'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: typeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Type *',
                  hintText: 'e.g. C172',
                  prefixIcon: Icon(Icons.airplanemode_active),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: modelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Model',
                  hintText: 'e.g. Cessna 172S',
                  prefixIcon: Icon(Icons.model_training),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tail Number',
                  hintText: 'e.g. N123AB',
                  prefixIcon: Icon(Icons.numbers),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (typeCtrl.text.trim().isEmpty) return;
              await db.addAircraft(
                type: typeCtrl.text.trim(),
                model: modelCtrl.text.trim().isEmpty
                    ? null
                    : modelCtrl.text.trim(),
                tailNumber: tailCtrl.text.trim().isEmpty
                    ? null
                    : tailCtrl.text.trim(),
                notes: notesCtrl.text.trim().isEmpty
                    ? null
                    : notesCtrl.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    typeCtrl.dispose();
    modelCtrl.dispose();
    tailCtrl.dispose();
    notesCtrl.dispose();

    if (saved == true) {
      ref.read(aircraftListProvider.notifier).refresh();
    }
  }

  Widget _buildRecordingView(ThemeData theme) {
    final session = ref.watch(flightServiceProvider).activeSession;
    final hasRoute =
        session?.departure?.ident != null || session?.arrival?.ident != null;
    final hasAircraft = session?.aircraft != null;

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
            padding: const EdgeInsets.all(20),
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
                if (hasAircraft || hasRoute)
                  Card(
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
                                    session!.aircraft!.type,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          if (hasRoute)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (session!.departure?.ident != null)
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
                                      color: theme.colorScheme.onSurfaceVariant,
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
                  ),
                const SizedBox(height: 24),
                _buildGpsCard(theme),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
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

  Widget _buildGpsCard(ThemeData theme) {
    final unitMode = ref.watch(unitProvider);
    final isMetric = unitMode == MeasurementUnit.metric;

    final altValue = isMetric ? _altitude : _altitude * 3.28084;
    final altUnit = isMetric ? 'm' : 'ft';

    final speedValue = isMetric ? _speed : _speed * 0.539957;
    final speedUnit = isMetric ? 'km/h' : 'kts'; // Knots mode shows kts

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
              ],
            ),
            const SizedBox(height: 16),
            InfoRow(
              label: 'Latitude',
              value: _latitude.toStringAsFixed(6),
              labelWidth: 90,
              isMonospace: true,
            ),
            InfoRow(
              label: 'Longitude',
              value: _longitude.toStringAsFixed(6),
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
              value: '${_heading.toStringAsFixed(1)}\u00B0',
              labelWidth: 90,
              isMonospace: true,
            ),
          ],
        ),
      ),
    );
  }
}
