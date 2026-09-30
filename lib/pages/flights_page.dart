import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/flight_providers.dart';
import '../services/database.dart';
import '../widgets/empty_state.dart';
import '../widgets/flight_card.dart';
import 'flight_detail_page.dart';

class FlightsPage extends ConsumerStatefulWidget {
  const FlightsPage({super.key});

  @override
  ConsumerState<FlightsPage> createState() => _FlightsPageState();
}

class _FlightsPageState extends ConsumerState<FlightsPage> {
  DateTime? _selectedDate;

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

  Future<void> _confirmDelete(FlightWithStats flight) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Flight'),
        content: Text(
          'Are you sure you want to delete "${flight.flight.title}"?',
        ),
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
      await ref.read(flightServiceProvider).deleteSession(flight.flight.id);
      // Stream provider automatically updates
    }
  }

  @override
  Widget build(BuildContext context) {
    final flightsAsync = ref.watch(flightListStreamProvider);

    return flightsAsync.when(
      data: (allFlights) {
        final flights = _selectedDate == null
            ? allFlights
            : ref.read(flightServiceProvider).searchByDate(_selectedDate!);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              _selectedDate != null
                  ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                  : 'Flights',
            ),
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
              ? EmptyState(
                  icon: _selectedDate != null ? Icons.search_off : Icons.flight,
                  title: _selectedDate != null
                      ? 'No flights on this date'
                      : 'No flights yet',
                  subtitle: _selectedDate != null
                      ? 'Try selecting a different date'
                      : 'Start recording your first flight!',
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: flights.length,
                  itemBuilder: (context, index) {
                    final flight = flights[index];
                    return FlightCard(
                      flight: flight,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              FlightDetailPage(flightId: flight.flight.id),
                        ),
                      ),
                      onLongPress: () => _confirmDelete(flight),
                    );
                  },
                ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
