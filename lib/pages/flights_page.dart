import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/flight_providers.dart';
import '../services/flight_service.dart';
import '../models/flight_session.dart';
import '../widgets/flight_card.dart';
import 'flight_detail_page.dart';

class FlightsPage extends ConsumerStatefulWidget {
  const FlightsPage({super.key});

  @override
  ConsumerState<FlightsPage> createState() => _FlightsPageState();
}

class _FlightsPageState extends ConsumerState<FlightsPage> {
  DateTime? _selectedDate;
  final _flightService = FlightService();

  List<FlightSession> get _filteredFlights {
    final allFlights = ref.watch(flightListProvider);
    if (_selectedDate == null) return allFlights;
    return _flightService.searchByDate(_selectedDate!);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _clearFilter() {
    setState(() => _selectedDate = null);
  }

  Future<void> _confirmDelete(FlightSession flight) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Flight'),
        content: Text('Are you sure you want to delete "${flight.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _flightService.deleteSession(flight.sessionId);
      ref.read(flightListProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final flights = _filteredFlights;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedDate != null
            ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
            : 'Flights'),
        actions: [
          if (_selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear filter',
              onPressed: _clearFilter,
            ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Search by date',
            onPressed: _pickDate,
          ),
        ],
      ),
      body: flights.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _selectedDate != null ? Icons.search_off : Icons.flight,
                      size: 64,
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _selectedDate != null
                          ? 'No flights on this date'
                          : 'No flights yet',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedDate != null
                          ? 'Try selecting a different date'
                          : 'Start recording your first flight!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: flights.length,
              itemBuilder: (context, index) {
                final flight = flights[index];
                return GestureDetector(
                  onLongPress: () => _confirmDelete(flight),
                  child: FlightCard(
                    flight: flight,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FlightDetailPage(flight: flight),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
