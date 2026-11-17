import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../core/theme.dart';
import '../providers/airport_providers.dart';
import '../services/airport_service.dart';
import '../services/database.dart';
import '../widgets/airport_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/load_more.dart';
import '../widgets/sync_progress_indicator.dart';
import 'airport_detail_page.dart';

class AirportsPage extends ConsumerStatefulWidget {
  const AirportsPage({super.key});

  @override
  ConsumerState<AirportsPage> createState() => _AirportsPageState();
}

class _AirportsPageState extends ConsumerState<AirportsPage> {
  String _searchQuery = '';
  String? _selectedCountry;
  AirportType? _selectedType;
  final _searchController = TextEditingController();
  bool _showFilters = false;

  /// How many airports the list asks for; grows as it is scrolled.
  int _limit = loadMorePageSize;

  /// The last airports loaded, shown while a bigger page or another search
  /// loads.
  List<AirportWithDistance>? _airports;

  late Future<bool> _permissionFuture;

  bool get _isFiltering =>
      _searchQuery.isNotEmpty ||
      _selectedCountry != null ||
      _selectedType != null;

  @override
  void initState() {
    super.initState();
    _permissionFuture = _checkLocationPermission();
  }

  /// Starts the list over from its first page. Call (inside setState)
  /// whenever the search or filters change.
  void _reloadAirports() => _limit = loadMorePageSize;

  /// Looks the user's position up again and lists the airports near it.
  void _relocate() {
    ref.read(airportServiceProvider).forgetPosition();
    ref.invalidate(airportsPageProvider);
    setState(_reloadAirports);
  }

  Future<bool> _checkLocationPermission() async {
    final status = await Geolocator.checkPermission();
    return status == LocationPermission.always ||
        status == LocationPermission.whileInUse;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
    final isFiltering = _isFiltering;
    final page = ref.watch(
      airportsPageProvider((
        limit: _limit,
        query: _searchQuery,
        country: _selectedCountry,
        type: _selectedType,
      )),
    );
    if (page.hasValue) _airports = page.value;
    final airports = _airports;
    final countries = ref.watch(countriesStreamProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<bool>(
          future: _permissionFuture,
          builder: (context, snapshot) {
            final hasPermission = snapshot.data ?? false;
            if (isFiltering) return const Text('Search Results');
            return Text(hasPermission ? 'Nearest Airports' : 'Airports');
          },
        ),
        actions: [
          if (service.isLocating)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.appColors.success,
                ),
              ),
            ),

          IconButton(
            icon: Icon(_showFilters ? Icons.filter_alt_off : Icons.filter_alt),
            tooltip: 'Filters',
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
          FutureBuilder<bool>(
            future: _permissionFuture,
            builder: (context, snapshot) {
              final hasPermission = snapshot.data ?? false;
              if (!hasPermission) {
                return IconButton(
                  icon: Icon(
                    Icons.location_off,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  tooltip: 'Enable location access',
                  onPressed: () async {
                    final status = await Geolocator.requestPermission();
                    if (!mounted) return;
                    if (status == LocationPermission.always ||
                        status == LocationPermission.whileInUse) {
                      _permissionFuture = Future.value(true);
                      _relocate();
                    }
                  },
                );
              }
              return IconButton(
                icon: const Icon(Icons.my_location),
                tooltip: 'Recenter location',
                onPressed: _relocate,
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh data',
            onPressed: sync.isRunning
                ? null
                : () {
                    setState(() {
                      _searchQuery = '';
                      _selectedCountry = null;
                      _selectedType = null;
                      _searchController.clear();
                      _reloadAirports();
                    });
                    ref.read(airportLoadProvider.notifier).refresh();
                  },
          ),
        ],
        bottom: sync.isRunning || sync.phase == SyncPhase.error
            ? _SyncBanner(
                progress: sync,
                onRetry: () => ref.read(airportLoadProvider.notifier).refresh(),
              )
            : null,
      ),
      body: Builder(
        builder: (context) {
          if (airports == null && page.hasError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Error while loading airports',
              action: FilledButton.tonal(
                onPressed: () => ref.invalidate(airportsPageProvider),
                child: const Text('Retry'),
              ),
            );
          }
          if (airports == null) {
            return const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return Column(
            children: [
              _AirportSearchBar(
                controller: _searchController,
                onChanged: (value) => setState(() {
                  _searchQuery = value;
                  _reloadAirports();
                }),
              ),
              if (_showFilters)
                _AirportFilters(
                  countries: countries,
                  selectedCountry: _selectedCountry,
                  selectedType: _selectedType,
                  onCountryChanged: (value) => setState(() {
                    _selectedCountry = value;
                    _reloadAirports();
                  }),
                  onTypeChanged: (value) => setState(() {
                    _selectedType = value;
                    _reloadAirports();
                  }),
                  onClear: () => setState(() {
                    _selectedCountry = null;
                    _selectedType = null;
                    _reloadAirports();
                  }),
                ),
              Expanded(
                child: airports.isEmpty
                    ? EmptyState(
                        icon: isFiltering ? Icons.search_off : Icons.flight,
                        title: isFiltering
                            ? 'No airports match your filters'
                            : 'No airports found',
                        subtitle: isFiltering
                            ? 'Try adjusting your search or filters'
                            : 'Data may still be loading',
                      )
                    : _AirportList(
                        airports: airports,
                        hasMore: airports.length >= _limit,
                        loading: !page.hasValue,
                        onLoadMore: () =>
                            setState(() => _limit += loadMorePageSize),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The airports found, loading the next page as the list nears its end.
class _AirportList extends StatelessWidget {
  const _AirportList({
    required this.airports,
    required this.hasMore,
    required this.loading,
    required this.onLoadMore,
  });

  final List<AirportWithDistance> airports;
  final bool hasMore;
  final bool loading;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    return LoadMoreScrollView(
      hasMore: hasMore,
      loading: loading,
      onLoadMore: onLoadMore,
      builder: (context, controller) => ListView.builder(
        controller: controller,
        padding: EdgeInsets.only(
          top: 8,
          bottom: 80 + MediaQuery.paddingOf(context).bottom,
        ),
        itemCount: airports.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == airports.length) return const LoadMoreIndicator();
          final item = airports[index];
          return AirportCard(
            airport: item.airport,
            distanceKm: item.distance >= 0 ? item.distance : null,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AirportDetailPage(airportId: item.airport.id),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Shown under the app bar while airport data is syncing, or after it failed.
class _SyncBanner extends StatelessWidget implements PreferredSizeWidget {
  const _SyncBanner({required this.progress, required this.onRetry});

  final SyncProgress progress;
  final VoidCallback onRetry;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    final isError = progress.phase == SyncPhase.error;
    return SizedBox(
      height: preferredSize.height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 8, 6),
        child: Row(
          children: [
            Expanded(
              child: SyncProgressIndicator(progress: progress, compact: true),
            ),
            if (isError)
              TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _AirportSearchBar extends StatelessWidget {
  const _AirportSearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Search airports by name, code, or city...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _AirportFilters extends StatelessWidget {
  const _AirportFilters({
    required this.countries,
    required this.selectedCountry,
    required this.selectedType,
    required this.onCountryChanged,
    required this.onTypeChanged,
    required this.onClear,
  });

  final List<Country> countries;
  final String? selectedCountry;
  final AirportType? selectedType;
  final ValueChanged<String?> onCountryChanged;
  final ValueChanged<AirportType?> onTypeChanged;
  final VoidCallback onClear;

  static const _fieldPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 10,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Filters',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (selectedCountry != null || selectedType != null) ...[
                const SizedBox(width: 8),
                TextButton(onPressed: onClear, child: const Text('Clear all')),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: selectedCountry,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Country',
                    contentPadding: _fieldPadding,
                  ),
                  items: [
                    const DropdownMenuItem(child: Text('All Countries')),
                    for (final c in countries)
                      DropdownMenuItem(
                        value: c.code,
                        child: Text(c.name, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: onCountryChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<AirportType>(
                  initialValue: selectedType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    contentPadding: _fieldPadding,
                  ),
                  items: [
                    const DropdownMenuItem(child: Text('All Types')),
                    for (final t in AirportType.values)
                      DropdownMenuItem(
                        value: t,
                        child: Text(AirportType.getDisplayName(t)),
                      ),
                  ],
                  onChanged: onTypeChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
