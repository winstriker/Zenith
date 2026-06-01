import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/airport_providers.dart';
import '../services/airport_service.dart';
import '../models/airport.dart';
import '../widgets/airport_card.dart';
import 'airport_detail_page.dart';

class AirportsPage extends ConsumerStatefulWidget {
  const AirportsPage({super.key});

  @override
  ConsumerState<AirportsPage> createState() => _AirportsPageState();
}

class _AirportsPageState extends ConsumerState<AirportsPage> {
  String _searchQuery = '';
  String? _selectedCountry;
  String? _selectedType;
  final _searchController = TextEditingController();
  bool _showFilters = false;

  double? _lat;
  double? _lng;
  bool _locating = true;

  static const _radius = 6371;

  @override
  void initState() {
    super.initState();
    _locate();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
      if (!mounted) return;
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _locating = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _locating = false);
    }
  }

  double _distance(double lat1, double lon1, double lat2, double lon2) {
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return _radius * 2 * asin(sqrt(a));
  }

  double _toRad(double deg) => deg * pi / 180;

  @override
  Widget build(BuildContext context) {
    final loadState = ref.watch(airportLoadProvider);
    final service = ref.read(airportServiceProvider);
    final theme = Theme.of(context);

    final isFiltering = _searchQuery.isNotEmpty ||
        _selectedCountry != null ||
        _selectedType != null;

    final allAirports = loadState.isLoaded
        ? service.searchAirports(
            query: _searchQuery,
            countryCode: _selectedCountry,
            type: _selectedType,
          )
        : <Airport>[];

    final airports = isFiltering
        ? allAirports
        : _nearest(allAirports);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isFiltering
              ? 'Airports (${airports.length})'
              : _lat != null
                  ? 'Nearest Airports'
                  : 'Airports',
        ),
        actions: [
          if (loadState.isRefreshing)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          if (_locating)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_alt_off : Icons.filter_alt),
            tooltip: 'Filters',
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Recenter location',
            onPressed: () {
              setState(() => _locating = true);
              _locate();
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
              ref.read(airportLoadProvider).refresh();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(context),
          if (_showFilters) _buildFilters(context, service),
          Expanded(
            child: !loadState.isLoaded
                ? (loadState.error != null
                    ? _buildErrorState(context, loadState.error!)
                    : _buildLoadingState(context))
                : airports.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isFiltering
                                    ? Icons.search_off
                                    : Icons.flight,
                                size: 64,
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                isFiltering
                                    ? 'No airports match your filters'
                                    : 'No airports found',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isFiltering
                                    ? 'Try adjusting your search or filters'
                                    : 'Data may still be loading',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 80),
                        itemCount: airports.length,
                        itemBuilder: (context, index) {
                          final airport = airports[index];
                          final dist = _lat != null && airport.latitudeDeg != null
                              ? _distance(
                                  _lat!,
                                  _lng!,
                                  airport.latitudeDeg!,
                                  airport.longitudeDeg!,
                                )
                              : null;
                          return AirportCard(
                            airport: airport,
                            distanceKm: dist,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AirportDetailPage(
                                    airportRef: airport.id),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  List<Airport> _nearest(List<Airport> airports) {
    if (_lat == null || _lng == null) return airports;
    final withDist = airports.where((a) => a.latitudeDeg != null).toList();
    withDist.sort((a, b) {
      final da = _distance(_lat!, _lng!, a.latitudeDeg!, a.longitudeDeg!);
      final db = _distance(_lat!, _lng!, b.latitudeDeg!, b.longitudeDeg!);
      return da.compareTo(db);
    });
    return withDist.take(20).toList();
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flight,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading airports...',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Downloading and parsing data in background',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: theme.colorScheme.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load airport data',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref.read(airportLoadProvider).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
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

  Widget _buildFilters(BuildContext context, AirportService service) {
    final countries = service.countries;
    final types = service.airportTypes.where((t) => t != 'closed').toList();
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
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCountry,
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
                    ...countries.map((c) => DropdownMenuItem(
                          value: c.code,
                          child: Text(
                            c.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedCountry = value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Types'),
                    ),
                    ...types.map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(
                            t.replaceAll('_', ' '),
                          ),
                        )),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedType = value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
