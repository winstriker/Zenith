import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/app_page_route.dart';
import '../core/fab_hero_tags.dart';
import '../providers/flight_providers.dart';
import '../services/database.dart';
import '../widgets/empty_state.dart';
import '../widgets/flight_card.dart';
import '../widgets/load_more.dart';
import '../widgets/page_title.dart';
import 'flight_detail_page.dart';
import 'flight_form_page.dart';

/// Searchable logbook, framed like the aircraft and people lists: a close FAB
/// at the top-left and an "Add" FAB at the bottom-right. Flights can be
/// filtered by text and, through the calendar button, by departure date.
/// Older flights load as the list is scrolled to its end.
class FlightsPage extends ConsumerStatefulWidget {
  const FlightsPage({super.key});

  @override
  ConsumerState<FlightsPage> createState() => _FlightsPageState();
}

class _FlightsPageState extends ConsumerState<FlightsPage> {
  final _searchController = TextEditingController();
  String _query = '';
  DateTime? _selectedDate;

  /// How many flights the list asks for; grows as it is scrolled.
  int _limit = loadMorePageSize;

  /// The last flights loaded, shown while a bigger page or another search
  /// loads.
  List<FlightWithStats>? _flights;

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
      setState(() {
        _selectedDate = picked;
        _limit = loadMorePageSize;
      });
    }
  }

  void _clearDate() {
    setState(() {
      _selectedDate = null;
      _limit = loadMorePageSize;
    });
  }

  Future<void> _addFlight() async {
    await Navigator.push(
      context,
      AppPageRoute<void>(builder: (_) => const FlightFormPage()),
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

  void _search(String query) {
    if (query == _query) return;
    setState(() {
      _query = query;
      _limit = loadMorePageSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final selectedDate = _selectedDate;
    final page = ref.watch(
      recordedFlightsPageProvider((
        limit: _limit,
        query: _query,
        day: selectedDate,
      )),
    );
    if (page.hasValue) _flights = page.value;
    final flights = _flights;
    final loading = !page.hasValue;
    final hasMore = flights != null && flights.length >= _limit;

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
        body: LoadMoreScrollView(
          hasMore: hasMore,
          loading: loading,
          onLoadMore: () => setState(() => _limit += loadMorePageSize),
          builder: (context, controller) => CustomScrollView(
            controller: controller,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              const SliverToBoxAdapter(
                child: PageTitle('Flights', belowCloseButton: true),
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
                                _search('');
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
                    onChanged: (v) => _search(v.trim()),
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
              ...switch (flights) {
                null when page.hasError => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('Error: ${page.error}')),
                  ),
                ],
                null => const [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
                [] when _query.isEmpty && selectedDate == null => const [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.flight,
                      title: 'No flights yet',
                      subtitle: 'Start recording your first flight!',
                    ),
                  ),
                ],
                [] => [
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
                ],
                _ => [
                  SliverList.builder(
                    itemCount: flights.length,
                    itemBuilder: (context, index) {
                      final flight = flights[index];
                      return FlightCard(
                        flight: flight,
                        onTap: () => Navigator.push(
                          context,
                          AppPageRoute<void>(
                            builder: (_) =>
                                FlightDetailPage(flightId: flight.flight.id),
                          ),
                        ),
                        onLongPress: () => _confirmDelete(flight),
                      );
                    },
                  ),
                  if (hasMore)
                    const SliverToBoxAdapter(child: LoadMoreIndicator()),
                  const SliverToBoxAdapter(child: SizedBox(height: 88)),
                ],
              },
            ],
          ),
        ),
      ),
    );
  }
}
