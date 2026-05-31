import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/flight_providers.dart';
import '../services/flight_service.dart';
import '../services/location_service.dart';

class RecordingPage extends ConsumerStatefulWidget {
  const RecordingPage({super.key});

  @override
  ConsumerState<RecordingPage> createState() => _RecordingPageState();
}

class _RecordingPageState extends ConsumerState<RecordingPage> {
  final _titleController = TextEditingController();
  final _aircraftController = TextEditingController();
  final _departureController = TextEditingController();
  final _arrivalController = TextEditingController();

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
  }

  @override
  void dispose() {
    _titleController.dispose();
    _aircraftController.dispose();
    _departureController.dispose();
    _arrivalController.dispose();
    _locationSubscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  void _startRecording() {
    final flightService = FlightService();
    final locationService = LocationService();

    flightService.startSession(
      title: _titleController.text.trim().isEmpty
          ? 'Flight ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}'
          : _titleController.text.trim(),
      aircraftType:
          _aircraftController.text.trim().isEmpty ? null : _aircraftController.text.trim(),
      departure:
          _departureController.text.trim().isEmpty ? null : _departureController.text.trim(),
      arrival:
          _arrivalController.text.trim().isEmpty ? null : _arrivalController.text.trim(),
    );

    locationService.startTracking();

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

      FlightService().addPoint(lat, lon, alt, speed: speed, heading: heading);

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

    ref.read(recordingStateProvider.notifier).state = true;
    ref.read(flightListProvider.notifier).refresh();
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _timer = null;
    _locationSubscription?.cancel();
    _locationSubscription = null;

    LocationService().stopTracking();
    await FlightService().endSession();

    ref.read(recordingStateProvider.notifier).state = false;
    ref.read(flightListProvider.notifier).refresh();

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.flight, size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('Configure Flight',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
              'Set up your flight details before starting the recording.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center),
          const SizedBox(height: 32),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Flight Title',
              prefixIcon: Icon(Icons.label_outline),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _aircraftController,
            decoration: const InputDecoration(
              labelText: 'Aircraft Type (optional)',
              prefixIcon: Icon(Icons.airplanemode_active),
            ),
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
                  borderRadius: BorderRadius.circular(16)),
              textStyle: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingView(ThemeData theme) {
    final session = FlightService().activeSession;
    final hasRoute =
        session?.departure != null || session?.arrival != null;
    final hasAircraft = session?.aircraftType != null;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: Colors.red.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _PulsingRecordingDot(),
              const SizedBox(width: 10),
              Text('RECORDING',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.red.shade800,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  )),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Text(_formatDuration(_elapsed),
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w200,
                      fontFamily: 'monospace',
                      color: theme.colorScheme.onSurface,
                    )),
                const SizedBox(height: 8),
                Text('elapsed time',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
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
                                  Icon(Icons.airplanemode_active, size: 18,
                                      color: theme.colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Text(session!.aircraftType!,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          if (hasRoute)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (session!.departure != null)
                                  _RouteChip(
                                      label: session.departure!,
                                      icon: Icons.flight_takeoff),
                                if (session.departure != null &&
                                    session.arrival != null)
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 8),
                                    child: Icon(Icons.arrow_forward, size: 16,
                                        color: theme
                                            .colorScheme.onSurfaceVariant),
                                  ),
                                if (session.arrival != null)
                                  _RouteChip(
                                      label: session.arrival!,
                                      icon: Icons.flight_land),
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
                    borderRadius: BorderRadius.circular(16)),
                textStyle: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGpsCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.satellite_alt, size: 18,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Live GPS Data',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),
            _GpsRow(
                label: 'Latitude',
                value: _latitude.toStringAsFixed(6),
                icon: Icons.explore),
            const SizedBox(height: 12),
            _GpsRow(
                label: 'Longitude',
                value: _longitude.toStringAsFixed(6),
                icon: Icons.explore),
            const SizedBox(height: 12),
            _GpsRow(
                label: 'Altitude',
                value: '${_altitude.toStringAsFixed(1)} m',
                icon: Icons.height),
            const SizedBox(height: 12),
            _GpsRow(
                label: 'Speed',
                value: '${_speed.toStringAsFixed(1)} km/h',
                icon: Icons.speed),
            const SizedBox(height: 12),
            _GpsRow(
                label: 'Heading',
                value: '${_heading.toStringAsFixed(1)}\u00B0',
                icon: Icons.navigation),
          ],
        ),
      ),
    );
  }
}

class _PulsingRecordingDot extends StatefulWidget {
  const _PulsingRecordingDot();

  @override
  State<_PulsingRecordingDot> createState() => _PulsingRecordingDotState();
}

class _PulsingRecordingDotState extends State<_PulsingRecordingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: 1));
    _animation = Tween<double>(begin: 1.0, end: 0.3)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _GpsRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _GpsRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
        Expanded(
          child: Text(value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              )),
        ),
      ],
    );
  }
}

class _RouteChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _RouteChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onTertiaryContainer),
          const SizedBox(width: 4),
          Text(label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }
}
