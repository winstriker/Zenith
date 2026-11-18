import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../core/app_page_route.dart';
import '../core/fab_hero_tags.dart';
import '../providers/airport_providers.dart';
import '../providers/navigation_provider.dart';
import '../services/airport_service.dart';
import '../services/database.dart';
import '../widgets/airport_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/hiding_chrome.dart';
import '../widgets/load_more.dart';
import '../widgets/page_title.dart';
import '../widgets/picker_sheet.dart';
import '../widgets/sync_progress_indicator.dart';
import 'airport_detail_page.dart';
import 'airport_form_page.dart';

/// Top-level tab: the airports nearest to the user, or those matching a
/// search and filters, and an "Add airport" FAB for airports missing from
/// OurAirports. More airports load as the list is scrolled to its end.
class AirportsPage extends ConsumerStatefulWidget {
  const AirportsPage({super.key});

  @override
  ConsumerState<AirportsPage> createState() => _AirportsPageState();
}

class _AirportsPageState extends ConsumerState<AirportsPage> {
  final _searchController = TextEditingController();
  final _scroll = ScrollController();
  String _query = '';
  String? _country;
  AirportType? _type;
  bool _customOnly = false;

  /// Whether the user asked for the airports nearest to them; the most
  /// recently used ones are listed until they do.
  bool _nearest = false;

  /// How many airports the list asks for; grows as it is scrolled.
  int _limit = loadMorePageSize;

  /// The last airports loaded, shown while a bigger page or another search
  /// loads.
  List<AirportWithDistance>? _airports;

  bool get _isFiltering =>
      _query.isNotEmpty || _country != null || _type != null || _customOnly;

  @override
  void dispose() {
    _searchController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  static bool _isGranted(LocationPermission status) =>
      status == LocationPermission.always ||
      status == LocationPermission.whileInUse;

  /// Changes the search or the filters in [change], and starts the list over
  /// from its first page.
  void _filter(VoidCallback change) {
    // The new list may be too short to scroll the bar back into view.
    ref.read(bottomChromeVisibleProvider.notifier).show();
    setState(() {
      change();
      _limit = loadMorePageSize;
    });
  }

  void _search(String query) {
    if (query != _query) _filter(() => _query = query);
  }

  /// Looks the user's position up again and lists the airports near it.
  void _relocate() {
    ref.read(airportServiceProvider).forgetPosition();
    ref.invalidate(airportsPageProvider);
    _filter(() {});
  }

  /// Lists the airports nearest to the user, asking for location access
  /// first when needed.
  Future<void> _showNearest() async {
    var status = await Geolocator.checkPermission();
    if (!_isGranted(status)) status = await Geolocator.requestPermission();
    if (!mounted) return;
    if (!_isGranted(status)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text(
              'Allow location access to see the nearest airports.',
            ),
            action: status == LocationPermission.deniedForever
                ? const SnackBarAction(
                    label: 'Settings',
                    onPressed: Geolocator.openAppSettings,
                  )
                : null,
          ),
        );
      return;
    }
    // Asked again after the position couldn't be found: look again.
    if (_nearest) {
      _relocate();
    } else {
      _filter(() => _nearest = true);
    }
  }

  void _refreshData() {
    _searchController.clear();
    _filter(() {
      _query = '';
      _country = null;
      _type = null;
      _customOnly = false;
    });
    ref.read(airportLoadProvider.notifier).refresh();
  }

  Future<void> _pickCountry(List<Country> countries) async {
    final current = countries.where((c) => c.code == _country).firstOrNull;
    final picked = await showPickerSheet<Country>(
      context,
      title: 'Country',
      items: countries,
      label: (c) => c.name,
      subtitle: (c) => c.code,
      selected: current,
      searchHint: 'Search countries...',
    );
    if (picked != null && mounted) _filter(() => _country = picked.code);
  }

  Future<void> _pickType() async {
    final picked = await showPickerSheet<AirportType>(
      context,
      title: 'Type',
      items: [
        for (final t in AirportType.values)
          if (t != AirportType.undefined) t,
      ],
      label: AirportType.getDisplayName,
      selected: _type,
    );
    if (picked != null && mounted) _filter(() => _type = picked);
  }

  Future<void> _addAirport() async {
    final id = await Navigator.push<Object?>(
      context,
      AppPageRoute(
        builder: (_) => AirportFormPage(
          // A search with no result is often the code being looked for.
          initialIdent: _query.contains(' ') ? null : _query,
        ),
      ),
    );
    if (id is! int || !mounted) return;
    await Navigator.push(
      context,
      AppPageRoute<void>(builder: (_) => AirportDetailPage(airportId: id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tapping Airports in the navigation bar again goes back to the top.
    ref.listen(tabReselectProvider, (_, next) {
      if (next?.tab == MainTab.airports) scrollTabToTop(ref, _scroll);
    });
    final sync = ref.watch(airportLoadProvider);
    // Drift tells streams about writes from the sync isolate too; this
    // makes sure the list shows the new data even if it didn't.
    ref.listen(airportLoadProvider, (prev, next) {
      if (next.phase == SyncPhase.done && prev?.phase != SyncPhase.done) {
        ref.invalidate(airportsPageProvider);
        ref.invalidate(countriesStreamProvider);
      }
    });
    final service = ref.watch(airportServiceProvider);
    final page = ref.watch(
      airportsPageProvider((
        limit: _limit,
        query: _query,
        country: _country,
        type: _type,
        customOnly: _customOnly,
        nearest: _nearest,
      )),
    );
    if (page.hasValue) _airports = page.value;
    final airports = _airports;
    final loading = !page.hasValue;
    final hasMore = airports != null && airports.length >= _limit;
    final countries = ref.watch(countriesStreamProvider).value ?? const [];
    final flightCounts =
        ref.watch(airportFlightCountsProvider).value ?? const <int, int>{};
    final countryName = _country == null
        ? null
        : countries.where((c) => c.code == _country).firstOrNull?.name ??
              _country;
    final isFiltering = _isFiltering;
    // Without the user's position, the list holds the airports they used
    // most recently instead.
    final showingNearest =
        _nearest && (service.position != null || service.isLocating);

    return Scaffold(
      floatingActionButton: HidingFabs(
        child: FloatingActionButton.extended(
          heroTag: primaryFabHeroTag,
          icon: const Icon(Icons.add),
          label: const Text('Add airport'),
          onPressed: _addAirport,
        ),
      ),
      body: HideChromeOnScroll(
        child: LoadMoreScrollView(
          controller: _scroll,
          hasMore: hasMore,
          loading: loading,
          onLoadMore: () => setState(() => _limit += loadMorePageSize),
          builder: (context, controller) => CustomScrollView(
            controller: controller,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(
                child: PageTitle(
                  'Airports',
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Download airport data again',
                    onPressed: sync.isRunning ? null : _refreshData,
                  ),
                ),
              ),
              if (sync.isRunning || sync.phase == SyncPhase.error)
                SliverToBoxAdapter(
                  child: _SyncBanner(
                    progress: sync,
                    onRetry: () =>
                        ref.read(airportLoadProvider.notifier).refresh(),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search name, code or city...',
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
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    spacing: 8,
                    children: [
                      FilterChip(
                        avatar: _customOnly
                            ? null
                            : const Icon(Icons.edit_location_alt_outlined),
                        label: const Text('My airports'),
                        selected: _customOnly,
                        onSelected: (v) => _filter(() => _customOnly = v),
                      ),
                      _FilterChoiceChip(
                        icon: Icons.public,
                        label: countryName ?? 'Country',
                        selected: _country != null,
                        onPressed: countries.isEmpty
                            ? null
                            : () => _pickCountry(countries),
                        onCleared: () => _filter(() => _country = null),
                      ),
                      _FilterChoiceChip(
                        icon: Icons.category_outlined,
                        label: _type == null
                            ? 'Type'
                            : AirportType.getDisplayName(_type!),
                        selected: _type != null,
                        onPressed: _pickType,
                        onCleared: () => _filter(() => _type = null),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isFiltering)
                SliverToBoxAdapter(
                  child: _NearbyHeader(
                    nearest: showingNearest,
                    locating: _nearest && service.isLocating,
                    onRelocate: _relocate,
                    onShowNearest: _showNearest,
                    onShowRecent: () => _filter(() => _nearest = false),
                  ),
                )
              else
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
              ...switch (airports) {
                null when page.hasError => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.error_outline,
                      title: 'Error while loading airports',
                      action: FilledButton.tonal(
                        onPressed: () => ref.invalidate(airportsPageProvider),
                        child: const Text('Retry'),
                      ),
                    ),
                  ),
                ],
                null => const [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
                [] when _customOnly && _query.isEmpty => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.edit_location_alt_outlined,
                      title: 'No airports of your own',
                      subtitle:
                          'Add an airstrip or a field missing from the '
                          'airport database, to log flights from it.',
                      action: FilledButton.tonalIcon(
                        onPressed: _addAirport,
                        icon: const Icon(Icons.add),
                        label: const Text('Add airport'),
                      ),
                    ),
                  ),
                ],
                [] when isFiltering => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.search_off,
                      iconSize: 48,
                      iconOpacity: 0.4,
                      title: _query.isEmpty
                          ? 'No airports match your filters'
                          : 'No airports match "$_query"',
                      subtitle: 'Missing one? Add it with "Add airport".',
                    ),
                  ),
                ],
                [] when !showingNearest => const [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.history,
                      title: 'No recent airports',
                      subtitle:
                          'The airports you fly from and to show up here. '
                          'Search for one above, or show the nearest.',
                    ),
                  ),
                ],
                [] => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.local_airport,
                      title: 'No airports found',
                      subtitle: sync.isRunning
                          ? 'Airport data is still downloading.'
                          : 'Download the airport data with the refresh '
                                'button.',
                    ),
                  ),
                ],
                _ => [
                  SliverList.builder(
                    itemCount: airports.length,
                    itemBuilder: (context, index) {
                      final item = airports[index];
                      return AirportCard(
                        airport: item.airport,
                        distanceKm: item.distance >= 0 ? item.distance : null,
                        flightCount: flightCounts[item.airport.id],
                        onTap: () => Navigator.push(
                          context,
                          AppPageRoute<void>(
                            builder: (_) =>
                                AirportDetailPage(airportId: item.airport.id),
                          ),
                        ),
                      );
                    },
                  ),
                  if (hasMore)
                    const SliverToBoxAdapter(child: LoadMoreIndicator()),
                ],
              },
              // Clear of the FAB and the navigation bar.
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 88 + MediaQuery.paddingOf(context).bottom,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A filter chip that opens a picker; once a value is picked, it shows it
/// and can be cleared.
class _FilterChoiceChip extends StatelessWidget {
  const _FilterChoiceChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
    required this.onCleared,
  });

  final IconData icon;
  final String label;
  final bool selected;

  /// Null disables the chip.
  final VoidCallback? onPressed;
  final VoidCallback onCleared;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      avatar: Icon(icon),
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      isEnabled: onPressed != null,
      onPressed: onPressed,
      onDeleted: selected ? onCleared : null,
      deleteIcon: const Icon(Icons.close, size: 18),
      deleteButtonTooltipMessage: 'Clear',
    );
  }
}

/// Says what the unfiltered list shows (the airports the user used most
/// recently, or those nearest to them), with the buttons to switch between
/// the two and to find the user's position again.
class _NearbyHeader extends StatelessWidget {
  const _NearbyHeader({
    required this.nearest,
    required this.locating,
    required this.onRelocate,
    required this.onShowNearest,
    required this.onShowRecent,
  });

  /// Whether the list shows the nearest airports, rather than the most
  /// recently used ones.
  final bool nearest;
  final bool locating;
  final VoidCallback onRelocate;
  final VoidCallback onShowNearest;
  final VoidCallback onShowRecent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              (nearest ? 'Nearest to you' : 'Recently used').toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (locating)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (nearest) ...[
            IconButton(
              icon: const Icon(Icons.my_location, size: 20),
              tooltip: 'Find my position again',
              onPressed: onRelocate,
            ),
            TextButton.icon(
              icon: const Icon(Icons.history, size: 18),
              label: const Text('Show recent'),
              onPressed: onShowRecent,
            ),
          ] else
            TextButton.icon(
              icon: const Icon(Icons.near_me_outlined, size: 18),
              label: const Text('Show nearest'),
              onPressed: onShowNearest,
            ),
        ],
      ),
    );
  }
}

/// Shown under the title while airport data is syncing, or after it failed.
class _SyncBanner extends StatelessWidget {
  const _SyncBanner({required this.progress, required this.onRetry});

  final SyncProgress progress;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isError = progress.phase == SyncPhase.error;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: SyncProgressIndicator(progress: progress, compact: true),
          ),
          if (isError)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
