import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_page_route.dart';
import '../core/fab_hero_tags.dart';
import '../models/sync_progress.dart';
import '../pages/aircraft_type_form_page.dart';
import '../providers/aircraft_providers.dart';
import '../services/database.dart';
import '../utils/icao_type_matcher.dart';
import 'empty_state.dart';
import 'model_card.dart';
import 'page_title.dart';
import 'sync_progress_indicator.dart';

/// Searchable list of ICAO aircraft types, framed like the detail pages: a
/// close FAB at the top-left and an "Add" FAB at the bottom-right.
///
/// Shared by the aircraft types list and the type picker so the two stay
/// identical apart from what tapping a type does.
class AircraftTypeListScaffold extends ConsumerStatefulWidget {
  const AircraftTypeListScaffold({
    super.key,
    required this.title,
    required this.onTap,
    this.onCreated,
    this.autofocusSearch = false,
    this.suggestFor,
    this.suggestDesignator,
    this.suggestNames = const [],
  });

  final String title;
  final void Function(IcaoAircraft type) onTap;

  /// Called with the type just created through the "Add" FAB.
  final void Function(IcaoAircraft type)? onCreated;

  final bool autofocusSearch;

  /// An aircraft name found elsewhere (e.g. "Cessna 172R Skyhawk II"), shown
  /// above the types that best fit it. Those are listed first, until the
  /// user searches.
  final String? suggestFor;

  /// What else is known about that aircraft, to find the fitting types: its
  /// ICAO designator and other names it goes by.
  final String? suggestDesignator;
  final List<String> suggestNames;

  @override
  ConsumerState<AircraftTypeListScaffold> createState() =>
      _AircraftTypeListScaffoldState();
}

class _AircraftTypeListScaffoldState
    extends ConsumerState<AircraftTypeListScaffold> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _customOnly = false;

  // Suggestions are only recomputed when the list of types changes.
  List<IcaoAircraft>? _suggestedFrom;
  List<IcaoAircraft> _suggestions = const [];

  List<IcaoAircraft> _suggestionsFrom(List<IcaoAircraft> types) {
    final name = widget.suggestFor;
    if (name == null) return const [];
    if (!identical(_suggestedFrom, types)) {
      _suggestedFrom = types;
      _suggestions = IcaoTypeMatcher.resolve(
        designator: widget.suggestDesignator,
        names: {name, ...widget.suggestNames}.toList(),
        types: types,
      ).suggestions;
    }
    return _suggestions;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(icaoAircraftsStreamProvider);
    final sync = ref.watch(aircraftTypesLoadProvider);

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
          tooltip: 'Add custom aircraft type',
          icon: const Icon(Icons.add),
          label: const Text('Add'),
          onPressed: _addType,
        ),
        body: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
              child: PageTitle(
                widget.title,
                belowCloseButton: true,
                trailing: IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Reload aircraft types',
                  onPressed: sync.isRunning ? null : _reload,
                ),
              ),
            ),
            if (sync.isRunning || sync.phase == SyncPhase.error)
              SliverToBoxAdapter(
                child: SyncBanner(progress: sync, onRetry: _reload),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  controller: _searchController,
                  // The keyboard would hide the suggestions.
                  autofocus:
                      widget.autofocusSearch && widget.suggestFor == null,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search aircraft type...',
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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FilterChip(
                    label: const Text('Custom types only'),
                    selected: _customOnly,
                    onSelected: (v) => setState(() => _customOnly = v),
                  ),
                ),
              ),
            ),
            ...typesAsync.when(
              data: (all) => _typeSlivers(all, reloading: sync.isRunning),
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

  List<Widget> _typeSlivers(List<IcaoAircraft> all, {required bool reloading}) {
    if (all.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.airplanemode_active,
            title: 'No aircraft types loaded',
            action: FilledButton.icon(
              onPressed: reloading ? null : _reload,
              icon: const Icon(Icons.refresh),
              label: const Text('Reload Types'),
            ),
          ),
        ),
      ];
    }
    final types = filterIcaoTypes(
      _customOnly ? all.where((t) => t.userInserted).toList() : all,
      _query,
    );
    if (types.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _query.isEmpty
              ? const EmptyState(
                  icon: Icons.airplanemode_active,
                  title: 'No custom types yet',
                  subtitle: 'Types you add appear here.',
                )
              : EmptyState(
                  icon: Icons.search_off,
                  iconSize: 48,
                  iconOpacity: 0.4,
                  title: 'No type matches "$_query"',
                  subtitle: 'Try a different search or add a custom type.',
                ),
        ),
      ];
    }
    final suggestions = _query.isEmpty && !_customOnly
        ? _suggestionsFrom(all)
        : const <IcaoAircraft>[];
    Widget card(IcaoAircraft t) =>
        ModelCard(aircraft: t, onTap: () => widget.onTap(t));
    return [
      if (suggestions.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: _ListHeader('Suggested for “${widget.suggestFor}”'),
        ),
        SliverList.builder(
          itemCount: suggestions.length,
          itemBuilder: (_, i) => card(suggestions[i]),
        ),
        const SliverToBoxAdapter(child: _ListHeader('All types')),
      ],
      SliverPadding(
        padding: const EdgeInsets.only(top: 4, bottom: 88),
        sliver: SliverList.builder(
          itemCount: types.length,
          itemBuilder: (_, i) => card(types[i]),
        ),
      ),
    ];
  }

  Future<void> _reload() =>
      ref.read(aircraftTypesLoadProvider.notifier).refresh();

  Future<void> _addType() async {
    final type = await Navigator.push(
      context,
      AppPageRoute<IcaoAircraft>(builder: (_) => const AircraftTypeFormPage()),
    );
    if (type != null && mounted) widget.onCreated?.call(type);
  }
}

/// Splits [query] into words; a type matches when every word is found in
/// its designator, model name or manufacturer (so "Cessna C150" works).
/// Results with a word equal to the designator come first, then those with
/// a word that prefixes it, then everything else, preserving the original
/// order within each group.
List<IcaoAircraft> filterIcaoTypes(List<IcaoAircraft> types, String query) {
  final tokens = query
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList();
  if (tokens.isEmpty) return types;
  final exact = <IcaoAircraft>[];
  final prefix = <IcaoAircraft>[];
  final other = <IcaoAircraft>[];
  for (final type in types) {
    final d = type.designator.toLowerCase();
    final haystack =
        '$d ${type.modelFullName.toLowerCase()} '
        '${type.manufacturer.toLowerCase()}';
    if (!tokens.every(haystack.contains)) continue;
    if (tokens.contains(d)) {
      exact.add(type);
    } else if (tokens.any(d.startsWith)) {
      prefix.add(type);
    } else {
      other.add(type);
    }
  }
  return [...exact, ...prefix, ...other];
}

class _ListHeader extends StatelessWidget {
  const _ListHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
