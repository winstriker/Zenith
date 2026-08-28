import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logbook/main.dart';
import '../providers/flight_providers.dart';
import '../services/database.dart';

class FlightFormPage extends ConsumerStatefulWidget {
  const FlightFormPage({super.key});

  @override
  ConsumerState<FlightFormPage> createState() => _FlightFormPageState();
}

class _FlightFormPageState extends ConsumerState<FlightFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _departureController = TextEditingController();
  final _arrivalController = TextEditingController();

  Airport? _selectedDeparture;
  Airport? _selectedArrival;
  DateTime _departureTime = DateTime.now();
  TimeOfDay _departureHour = TimeOfDay.now();
  DateTime? _arrivalTime;
  TimeOfDay? _arrivalHour;

  List<Airport> _departureSuggestions = [];
  List<Airport> _arrivalSuggestions = [];
  Timer? _departureDebounce;
  Timer? _arrivalDebounce;
  bool _showDepartureSuggestions = false;
  bool _showArrivalSuggestions = false;

  @override
  void dispose() {
    _departureController.dispose();
    _arrivalController.dispose();
    _departureDebounce?.cancel();
    _arrivalDebounce?.cancel();
    super.dispose();
  }

  void _searchAirports(String query, bool isDeparture) async {
    if (query.trim().length < 2) {
      setState(() {
        if (isDeparture) {
          _departureSuggestions = [];
          _showDepartureSuggestions = false;
        } else {
          _arrivalSuggestions = [];
          _showArrivalSuggestions = false;
        }
      });
      return;
    }

    final db = ref.read(databaseProvider);
    final results = await db.searchAirports(query: query.trim(), limit: 8);

    if (!mounted) return;
    setState(() {
      if (isDeparture) {
        _departureSuggestions = results;
        _showDepartureSuggestions = results.isNotEmpty;
      } else {
        _arrivalSuggestions = results;
        _showArrivalSuggestions = results.isNotEmpty;
      }
    });
  }

  void _onDepartureChanged(String value) {
    _departureDebounce?.cancel();
    _selectedDeparture = null;
    _departureDebounce = Timer(
      const Duration(milliseconds: 400),
      () => _searchAirports(value, true),
    );
  }

  void _onArrivalChanged(String value) {
    _arrivalDebounce?.cancel();
    _selectedArrival = null;
    _arrivalDebounce = Timer(
      const Duration(milliseconds: 400),
      () => _searchAirports(value, false),
    );
  }

  void _selectDeparture(Airport airport) {
    _departureController.text = airport.ident ?? airport.icaoCode ?? airport.iataCode ?? airport.name ?? '';
    _selectedDeparture = airport;
    setState(() {
      _showDepartureSuggestions = false;
      _departureSuggestions = [];
    });
  }

  void _selectArrival(Airport airport) {
    _arrivalController.text = airport.ident ?? airport.icaoCode ?? airport.iataCode ?? airport.name ?? '';
    _selectedArrival = airport;
    setState(() {
      _showArrivalSuggestions = false;
      _arrivalSuggestions = [];
    });
  }

  Future<void> _pickDepartureDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _departureTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _departureTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _departureHour.hour,
          _departureHour.minute,
        );
      });
    }
  }

  Future<void> _pickDepartureHour() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _departureHour,
    );
    if (picked != null) {
      setState(() {
        _departureHour = picked;
        _departureTime = DateTime(
          _departureTime.year,
          _departureTime.month,
          _departureTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _pickArrivalDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _arrivalTime ?? _departureTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        _arrivalTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          (_arrivalHour ?? _departureHour).hour,
          (_arrivalHour ?? _departureHour).minute,
        );
      });
    }
  }

  Future<void> _pickArrivalHour() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _arrivalHour ?? _departureHour,
    );
    if (picked != null) {
      setState(() {
        _arrivalHour = picked;
        _arrivalTime = DateTime(
          (_arrivalTime ?? _departureTime).year,
          (_arrivalTime ?? _departureTime).month,
          (_arrivalTime ?? _departureTime).day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final flightService = ref.read(flightServiceProvider);
    final departureTime = _departureTime;
    final arrivalTime = _arrivalTime;

    final depCode = _selectedDeparture?.ident ?? _departureController.text.trim();
    final arrCode = _selectedArrival?.ident ?? _arrivalController.text.trim();

    await flightService.addFlight(
      departureId: _selectedDeparture?.id,
      arrivalId: _selectedArrival?.id,
      title: '$depCode → $arrCode',
      departureTime: departureTime,
      arrivalTime: arrivalTime,
    );

    ref.read(flightListProvider.notifier).refresh();

    if (mounted) Navigator.pop(context, true);
  }

  Widget _buildAirportField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required List<Airport> suggestions,
    required bool showSuggestions,
    required ValueChanged<String> onChanged,
    required ValueChanged<Airport> onSelected,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            hintText: 'Search airport...',
            prefixIcon: Icon(icon),
          ),
          onChanged: onChanged,
          validator: validator,
          onTap: () {
            if (suggestions.isNotEmpty) {
              setState(() {
                if (label == 'Departure Airport') {
                  _showDepartureSuggestions = true;
                } else {
                  _showArrivalSuggestions = true;
                }
              });
            }
          },
        ),
        if (showSuggestions && suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 250),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: suggestions.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final airport = suggestions[index];
                final code = airport.ident ?? airport.icaoCode ?? airport.iataCode ?? '';
                final name = airport.name ?? '';
                final city = airport.municipality ?? '';
                return ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.local_airport,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  title: Row(
                    children: [
                      Text(
                        code,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  subtitle: city.isNotEmpty
                      ? Text(
                          city,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        )
                      : null,
                  onTap: () => onSelected(airport),
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Flight'),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.primaryContainer,
                  cs.primaryContainer.withValues(alpha: 0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.flight_takeoff,
                    size: 40,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New Flight',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enter the details of your flight',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildAirportField(
                    label: 'Departure Airport',
                    icon: Icons.flight_takeoff,
                    controller: _departureController,
                    suggestions: _departureSuggestions,
                    showSuggestions: _showDepartureSuggestions,
                    onChanged: _onDepartureChanged,
                    onSelected: _selectDeparture,
                  ),
                  const SizedBox(height: 16),
                  _buildAirportField(
                    label: 'Arrival Airport',
                    icon: Icons.flight_land,
                    controller: _arrivalController,
                    suggestions: _arrivalSuggestions,
                    showSuggestions: _showArrivalSuggestions,
                    onChanged: _onArrivalChanged,
                    onSelected: _selectArrival,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Departure',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDepartureDate,
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(_formatDate(_departureTime)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDepartureHour,
                          icon: const Icon(Icons.access_time, size: 18),
                          label: Text(_formatTime(_departureHour)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Arrival (optional)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickArrivalDate,
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(
                            _arrivalTime != null
                                ? _formatDate(_arrivalTime!)
                                : 'Select date',
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickArrivalHour,
                          icon: const Icon(Icons.access_time, size: 18),
                          label: Text(
                            _arrivalHour != null
                                ? _formatTime(_arrivalHour!)
                                : 'Select time',
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _save,
                    child: const Text('Add Flight'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
