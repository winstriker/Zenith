import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/fab_hero_tags.dart';
import '../pages/simulator_form_page.dart';
import '../repositories/simulator_repository.dart';
import '../services/database.dart';
import 'empty_state.dart';
import 'load_more.dart';
import 'page_title.dart';
import 'simulator_card.dart';

/// Searchable list of the user's simulators, framed like the aircraft list:
/// a close FAB at the top-left and an "Add" FAB at the bottom-right. More
/// load as the list is scrolled to its end.
///
/// Shared by the simulator list and the simulator picker of the flight form.
class SimulatorListScaffold extends ConsumerStatefulWidget {
  const SimulatorListScaffold({
    super.key,
    required this.title,
    required this.onTap,
    this.onLongPress,
    this.header,
    this.autofocusSearch = false,
    this.showStats = false,
  });

  final String title;
  final void Function(SimulatorWithStats simulator) onTap;
  final void Function(SimulatorWithStats simulator)? onLongPress;

  /// Shown between the title and the search field.
  final Widget? header;
  final bool autofocusSearch;
  final bool showStats;

  @override
  ConsumerState<SimulatorListScaffold> createState() =>
      _SimulatorListScaffoldState();
}

class _SimulatorListScaffoldState extends ConsumerState<SimulatorListScaffold> {
  final _searchController = TextEditingController();
  String _query = '';
  int _limit = loadMorePageSize;

  /// The last simulators loaded, shown while a bigger page or another
  /// search loads.
  List<SimulatorWithStats>? _simulators;

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
      simulatorPageProvider((limit: _limit, query: _query)),
    );
    if (page.hasValue) _simulators = page.value;
    final simulators = _simulators;
    final loading = !page.hasValue;
    final hasMore = simulators != null && simulators.length >= _limit;

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
          onPressed: _addSimulator,
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
              if (widget.header != null)
                SliverToBoxAdapter(child: widget.header),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    autofocus: widget.autofocusSearch,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search simulators...',
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
              ...switch (simulators) {
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
                      icon: simulatorIcon,
                      title: 'No simulators yet',
                      subtitle:
                          'Add the simulators you train in to log sessions.',
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
                      title: 'No simulators match "$_query"',
                    ),
                  ),
                ],
                _ => [
                  SliverList.builder(
                    itemCount: simulators.length,
                    itemBuilder: (context, index) {
                      final sim = simulators[index];
                      final onLongPress = widget.onLongPress;
                      return SimulatorCard(
                        simulator: sim,
                        showStats: widget.showStats,
                        onTap: () => widget.onTap(sim),
                        onLongPress: onLongPress == null
                            ? null
                            : () => onLongPress(sim),
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

  Future<void> _addSimulator() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const SimulatorFormPage()),
    );
  }
}
