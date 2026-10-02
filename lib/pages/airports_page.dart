import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/database.dart';
import '../providers/airport_providers.dart';
import '../services/airport_service.dart';
import '../widgets/airport_card.dart';
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
      limit: 100,
    );
    return _cachedResults;
  }

  Future<List<AirportWithDistance>> _loadAirportsWithFallback(
    AirportsService service,
  ) async {
    final hasPermission = await _checkLocationPermission();
    if (hasPermission) {
      return service.getNearAirportsWithFallback(
        limit: 20,
        relocate: _shouldRelocate,
      );
    } else {
      return service.getAirportsAlphabetical(limit: 20);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(airportLoadProvider);
    final service = ref.read(airportServiceProvider);

    final isFiltering =
        _searchQuery.isNotEmpty ||
        _selectedCountry != null ||
        _selectedType != null;

    final airportsFuture = isFiltering
        ? _searchAirportsCached(
            service,
          ).then((list) => list.map((a) => AirportWithDistance(a, -1)).toList())
        : _loadAirportsWithFallback(service);
    _shouldRelocate = false;

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<bool>(
          future: _checkLocationPermission(),
          builder: (context, snapshot) {
            final hasPermission = snapshot.data ?? false;
            if (isFiltering) return const Text('Search Results');
            return Text(hasPermission ? 'Nearest Airports' : 'Airports');
          },
        ),
        actions: [
          if (service.status.type == StatusType.downloading)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          if (service.isLocating)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color.fromRGBO(0, 255, 0, 1),
                ),
              ),
            ),

          IconButton(
            icon: Icon(_showFilters ? Icons.filter_alt_off : Icons.filter_alt),
            tooltip: 'Filters',
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
          FutureBuilder<bool>(
            future: _checkLocationPermission(),
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
                      setState(() => _shouldRelocate = true);
                    }
                  },
                );
              }
              return IconButton(
                icon: const Icon(Icons.my_location),
                tooltip: 'Recenter location',
                onPressed: () {
                  setState(() => _shouldRelocate = true);
                },
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh data',
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _selectedCountry = null;
                _selectedType = null;
                _searchController.clear();
              });
              ref.read(airportLoadProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: airportsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorWidget("Error while loading airports");
          }
          if (!snapshot.hasData) {
            return const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return Column(
            children: [
              _buildSearchBar(context),
              if (_showFilters) _buildFilters(context, service),
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
                        padding: const EdgeInsets.only(top: 8, bottom: 80),
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

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search airports by name, code, or city...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildFilters(BuildContext context, AirportsService service) {
    final countries = service.getCountriesList();
    final types = AirportType.values;
    final theme = Theme.of(context);

    return Container(
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
              if (_selectedCountry != null || _selectedType != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => setState(() {
                    _selectedCountry = null;
                    _selectedType = null;
                  }),
                  child: const Text('Clear all'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FutureBuilder<List<Country>>(
                future: countries,
                builder: (context, snapshot) {
                  final countryList = snapshot.data ?? [];
                  return Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCountry,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Countries'),
                        ),
                        ...countryList.map(
                          (c) => DropdownMenuItem(
                            value: c.code,
                            child: Text(
                              c.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedCountry = value),
                    ),
                  );
                },
              ),

              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<AirportType>(
                  initialValue: _selectedType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(child: Text('All Types')),
                    ...types.map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(AirportType.getDisplayName(t)),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _selectedType = value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
