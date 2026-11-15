import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/fab_hero_tags.dart';
import '../core/search.dart';
import '../providers/flight_providers.dart';
import '../services/database.dart';
import '../widgets/empty_state.dart';
import '../widgets/flight_card.dart';
import 'flight_detail_page.dart';
import 'flight_form_page.dart';

/// Searchable logbook, framed like the aircraft and people lists: a close FAB
/// at the top-left and an "Add" FAB at the bottom-right. Flights can be
/// filtered by text and, through the calendar button, by departure date.
class FlightsPage extends ConsumerStatefulWidget {
  const FlightsPage({super.key});

  @override
  ConsumerState<FlightsPage> createState() => _FlightsPageState();
}

class _FlightsPageState extends ConsumerState<FlightsPage> {
  final _searchController = TextEditingController();
  String _query = '';
  DateTime? _selectedDate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _clearDate() {
    setState(() => _selectedDate = null);
  }

  Future<void> _addFlight() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const FlightFormPage()),
    );
    // Stream provider picks up the new flight automatically.
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

  bool _onSelectedDate(FlightWithStats f) {
    final d = _selectedDate!;
    final t = f.flight.departureTime;
    return t.year == d.year && t.month == d.month && t.day == d.day;
  }

  /// Every word must hit some field, so "LIMC D-KBFF" matches a flight out
  /// of LIMC flown with D-KBFF.
  bool _matchesQuery(FlightWithStats f, List<String> tokens) {
    Iterable<String?> airport(Airport? a) => [
      a?.ident,
      a?.icaoCode,
      a?.iataCode,
      a?.name,
      a?.municipality,
    ];
    final aircraft = f.aircraftWithStats;
    return matchesAllTokens(tokens, [
      f.flight.title,
      f.flight.remarks,
      ...airport(f.departure),
      ...airport(f.arrival),
      aircraft?.tailNumber,
      aircraft?.modelFullName,
      aircraft?.designator,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final flightsAsync = ref.watch(flightListStreamProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final selectedDate = _selectedDate;

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
          icon: const Icon(Icons.add),
          label: const Text('Add'),
          onPressed: _addFlight,
        ),
        body: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            // Leaves room for the close FAB pinned at the top-left.
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.paddingOf(context).top + 80,
                  16,
                  8,
                ),
                child: Text(
                  'Flights',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search flights...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_query.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            tooltip: 'Clear',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                        IconButton(
                          icon: Icon(
                            Icons.calendar_month,
                            size: 20,
                            color: selectedDate != null ? cs.primary : null,
                          ),
                          tooltip: 'Search by date',
                          onPressed: _pickDate,
                        ),
                      ],
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ),
            ),
            if (selectedDate != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: InputChip(
                      avatar: const Icon(Icons.calendar_month, size: 18),
                      label: Text(
                        DateFormat('MMM dd, yyyy').format(selectedDate),
                      ),
                      tooltip: 'Change date',
                      onPressed: _pickDate,
                      onDeleted: _clearDate,
                      deleteButtonTooltipMessage: 'Clear date',
                    ),
                  ),
                ),
              ),
            ...flightsAsync.when(
              data: (allFlights) {
                if (allFlights.isEmpty) {
                  return const [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.flight,
                        title: 'No flights yet',
                        subtitle: 'Start recording your first flight!',
                      ),
                    ),
                  ];
                }
                final tokens = searchTokens(_query);
                final flights = allFlights
                    .where(
                      (f) =>
                          (selectedDate == null || _onSelectedDate(f)) &&
                          (tokens.isEmpty || _matchesQuery(f, tokens)),
                    )
                    .toList();
                if (flights.isEmpty) {
                  return [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.search_off,
                        iconSize: 48,
                        iconOpacity: 0.4,
                        title: _query.isEmpty
                            ? 'No flights on this date'
                            : 'No flights match "$_query"',
                        subtitle: selectedDate != null
                            ? 'Try selecting a different date'
                            : null,
                      ),
                    ),
                  ];
                }
                return [
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 88),
                    sliver: SliverList.builder(
                      itemCount: flights.length,
                      itemBuilder: (context, index) {
                        final flight = flights[index];
                        return FlightCard(
                          flight: flight,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  FlightDetailPage(flightId: flight.flight.id),
                            ),
                          ),
                          onLongPress: () => _confirmDelete(flight),
                        );
                      },
                    ),
                  ),
                ];
              },
              loading: () => const [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (e, _) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('Error: $e')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
