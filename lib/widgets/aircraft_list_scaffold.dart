import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/search.dart';
import '../pages/aircraft_form_page.dart';
import '../providers/aircraft_providers.dart';
import '../services/database.dart';
import 'aircraft_card.dart';
import 'empty_state.dart';

/// Searchable list of the user's aircraft, framed like the detail pages:
/// a close FAB at the top-left and an "Add" FAB at the bottom-right.
///
/// Shared by the aircraft list and the aircraft picker of the flight form so
/// the two stay identical apart from what tapping an aircraft does.
class AircraftListScaffold extends ConsumerStatefulWidget {
  const AircraftListScaffold({
    super.key,
    required this.title,
    required this.onTap,
    this.onLongPress,
    this.autofocusSearch = false,
    this.showStats = false,
  });

  final String title;
  final void Function(AircraftWithStats aircraft) onTap;
  final void Function(AircraftWithStats aircraft)? onLongPress;
  final bool autofocusSearch;
  final bool showStats;

  @override
  ConsumerState<AircraftListScaffold> createState() =>
      _AircraftListScaffoldState();
}

class _AircraftListScaffoldState extends ConsumerState<AircraftListScaffold> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(AircraftWithStats aws, List<String> tokens) =>
      matchesAllTokens(tokens, [
        aws.tailNumber,
        aws.modelFullName,
        aws.manufacturer,
        aws.designator,
        aws.notes,
      ]);

  @override
  Widget build(BuildContext context) {
    final aircraftAsync = ref.watch(aircraftListStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: FloatingActionButton(
        heroTag: 'closeFab',
        tooltip: 'Close',
        onPressed: () => Navigator.pop(context),
        child: const Icon(Icons.close),
      ),
      body: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'addFab',
          icon: const Icon(Icons.add),
          label: const Text('Add'),
          onPressed: _addAircraft,
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
                  widget.title,
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
                  autofocus: widget.autofocusSearch,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search aircraft...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            tooltip: 'Clear',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
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
            ...aircraftAsync.when(
              data: (aircraftList) {
                if (aircraftList.isEmpty) {
                  return const [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.airplanemode_active,
                        title: 'No aircraft yet',
                        subtitle:
                            'Add your first aircraft to start tracking flights.',
                      ),
                    ),
                  ];
                }
                final tokens = searchTokens(_query);
                final filtered = tokens.isEmpty
                    ? aircraftList
                    : aircraftList
                          .where((aws) => _matches(aws, tokens))
                          .toList();
                if (filtered.isEmpty) {
                  return [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.search_off,
                        iconSize: 48,
                        iconOpacity: 0.4,
                        title: 'No aircraft match "$_query"',
                      ),
                    ),
                  ];
                }
                return [
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 88),
                    sliver: SliverList.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final aws = filtered[index];
                        final onLongPress = widget.onLongPress;
                        return AircraftCard(
                          aircraft: aws,
                          showStats: widget.showStats,
                          onTap: () => widget.onTap(aws),
                          onLongPress: onLongPress == null
                              ? null
                              : () => onLongPress(aws),
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

  Future<void> _addAircraft() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const AircraftFormPage()),
    );
    // Stream provider picks up the new aircraft automatically.
  }
}
