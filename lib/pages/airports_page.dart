import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../core/theme.dart';
import '../providers/airport_providers.dart';
import '../services/airport_service.dart';
import '../services/database.dart';
import '../widgets/airport_card.dart';
import '../widgets/airport_sync_progress.dart';
import '../widgets/empty_state.dart';
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
  bool _shouldRelocate = false;

  String _lastQuery = '';
  String? _lastCountry;
  AirportType? _lastType;
  List<Airport> _cachedResults = [];

  late Future<bool> _permissionFuture;
  late Future<List<AirportWithDistance>> _airportsFuture;
  late Future<List<Country>> _countriesFuture;

  bool get _isFiltering =>
      _searchQuery.isNotEmpty ||
      _selectedCountry != null ||
      _selectedType != null;

  @override
  void initState() {
    super.initState();
    final service = ref.read(airportServiceProvider);
    _permissionFuture = _checkLocationPermission();
    _countriesFuture = service.getCountriesList();
    _airportsFuture = _loadAirports(service);
  }

  /// Rebuilds the airports future. Call (inside setState) whenever the
  /// search, filters, permission or relocate flag change.
  void _reloadAirports() {
    _airportsFuture = _loadAirports(ref.read(airportServiceProvider));
  }

  Future<List<AirportWithDistance>> _loadAirports(AirportsService service) {
    final future = _isFiltering
        ? _searchAirportsCached(
            service,
          ).then((list) => list.map((a) => AirportWithDistance(a, -1)).toList())
        : _loadAirportsWithFallback(service);
    _shouldRelocate = false;
    return future;
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

  Future<List<Airport>> _searchAirportsCached(AirportsService service) async {
    if (_searchQuery == _lastQuery &&
        _selectedCountry == _lastCountry &&
        _selectedType == _lastType &&
        _cachedResults.isNotEmpty) {
      return _cachedResults;
    }
    _lastQuery = _searchQuery;
    _lastCountry = _selectedCountry;
    _lastType = _selectedType;
    _cachedResults = await service.searchAirports(
      query: _searchQuery,
      countryCode: _selectedCountry,
      type: _selectedType,
    );
    return _cachedResults;
  }

  Future<List<AirportWithDistance>> _loadAirportsWithFallback(
    AirportsService service,
  ) async {
    final hasPermission = await _checkLocationPermission();
    if (hasPermission) {
      return service.getNearAirportsWithFallback(relocate: _shouldRelocate);
    } else {
      return service.getAirportsAlphabetical(limit: 20);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sync = ref.watch(airportLoadProvider);
    // Reload the list once a sync has written new data.
    ref.listen(airportLoadProvider, (prev, next) {
      if (next.phase == AirportSyncPhase.done &&
          prev?.phase != AirportSyncPhase.done) {
        setState(() {
          _countriesFuture = ref
              .read(airportServiceProvider)
              .getCountriesList();
          _cachedResults = [];
          _reloadAirports();
        });
      }
    });
    final service = ref.watch(airportServiceProvider);
    final isFiltering = _isFiltering;

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
                      setState(() {
                        _permissionFuture = Future.value(true);
                        _shouldRelocate = true;
                        _reloadAirports();
                      });
                    }
                  },
                );
              }
              return IconButton(
                icon: const Icon(Icons.my_location),
                tooltip: 'Recenter location',
                onPressed: () {
                  setState(() {
                    _shouldRelocate = true;
                    _reloadAirports();
                  });
                },
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
        bottom: sync.isRunning || sync.phase == AirportSyncPhase.error
            ? _SyncBanner(
                progress: sync,
                onRetry: () => ref.read(airportLoadProvider.notifier).refresh(),
              )
            : null,
      ),
      body: FutureBuilder(
        future: _airportsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Error while loading airports',
              action: FilledButton.tonal(
                onPressed: () => setState(_reloadAirports),
                child: const Text('Retry'),
              ),
            );
          }
          if (!snapshot.hasData) {
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
                  countries: _countriesFuture,
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
                child: snapshot.data == null || snapshot.data!.isEmpty
                    ? EmptyState(
                        icon: isFiltering ? Icons.search_off : Icons.flight,
                        title: isFiltering
                            ? 'No airports match your filters'
                            : 'No airports found',
                        subtitle: isFiltering
                            ? 'Try adjusting your search or filters'
                            : 'Data may still be loading',
                      )
                    : ListView.builder(
                        padding: EdgeInsets.only(
                          top: 8,
                          bottom: 80 + MediaQuery.paddingOf(context).bottom,
                        ),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final item = snapshot.data![index];
                          return AirportCard(
                            airport: item.airport,
                            distanceKm: item.distance >= 0
                                ? item.distance
                                : null,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => AirportDetailPage(
                                  airportId: item.airport.id,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Shown under the app bar while airport data is syncing, or after it failed.
class _SyncBanner extends StatelessWidget implements PreferredSizeWidget {
  const _SyncBanner({required this.progress, required this.onRetry});

  final AirportSyncProgress progress;
  final VoidCallback onRetry;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    final isError = progress.phase == AirportSyncPhase.error;
    return SizedBox(
      height: preferredSize.height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 8, 6),
        child: Row(
          children: [
            Expanded(
              child: AirportSyncProgressIndicator(
                progress: progress,
                compact: true,
              ),
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

  final Future<List<Country>> countries;
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
                child: FutureBuilder<List<Country>>(
                  future: countries,
                  builder: (context, snapshot) {
                    final countryList = snapshot.data ?? [];
                    return DropdownButtonFormField<String>(
                      initialValue: selectedCountry,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        contentPadding: _fieldPadding,
                      ),
                      items: [
                        const DropdownMenuItem(child: Text('All Countries')),
                        for (final c in countryList)
                          DropdownMenuItem(
                            value: c.code,
                            child: Text(
                              c.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: onCountryChanged,
                    );
                  },
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
