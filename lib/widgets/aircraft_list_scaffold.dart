import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/fab_hero_tags.dart';

import '../pages/aircraft_form_page.dart';
import '../providers/aircraft_providers.dart';
import '../services/database.dart';
import 'aircraft_card.dart';
import 'empty_state.dart';
import 'load_more.dart';
import 'page_title.dart';

/// Searchable list of the user's aircraft, framed like the detail pages:
/// a close FAB at the top-left and an "Add" FAB at the bottom-right. More
/// aircraft load as the list is scrolled to its end.
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

  /// How many aircraft the list asks for; grows as it is scrolled.
  int _limit = loadMorePageSize;

  /// The last aircraft loaded, shown while a bigger page or another search
  /// loads.
  List<AircraftWithStats>? _aircraft;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    final page = ref.watch(
      aircraftPageProvider((limit: _limit, query: _query)),
    );
    if (page.hasValue) _aircraft = page.value;
    final aircraft = _aircraft;
    final loading = !page.hasValue;
    final hasMore = aircraft != null && aircraft.length >= _limit;

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
          onPressed: _addAircraft,
        ),
        body: LoadMoreScrollView(
          hasMore: hasMore,
          loading: loading,
          onLoadMore: () => setState(() => _limit += loadMorePageSize),
          builder: (context, controller) => CustomScrollView(
            controller: controller,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(
                child: PageTitle(widget.title, belowCloseButton: true),
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
                                _search('');
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
                    onChanged: (v) => _search(v.trim()),
                  ),
                ),
              ),
              ...switch (aircraft) {
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
                [] when _query.isEmpty => const [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.airplanemode_active,
                      title: 'No aircraft yet',
                      subtitle:
                          'Add your first aircraft to start tracking flights.',
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
                      title: 'No aircraft match "$_query"',
                    ),
                  ),
                ],
                _ => [
                  SliverList.builder(
                    itemCount: aircraft.length,
                    itemBuilder: (context, index) {
                      final aws = aircraft[index];
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

  Future<void> _addAircraft() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const AircraftFormPage()),
    );
    // Stream provider picks up the new aircraft automatically.
  }
}
