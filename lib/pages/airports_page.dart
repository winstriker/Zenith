import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logbook/services/database.dart';
import '../providers/airport_providers.dart';
import '../services/airport_service.dart';
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
  AirportType? _selectedType;
  final _searchController = TextEditingController();
  bool _showFilters = false;
  bool _shouldRelocate = false;

  String _lastQuery = '';
  String? _lastCountry;
  AirportType? _lastType;
  List<Airport> _cachedResults = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Airport> _searchAirportsCached(AirportsService service) {
    if (_searchQuery != _lastQuery ||
        _selectedCountry != _lastCountry ||
        _selectedType != _lastType) {
      _lastQuery = _searchQuery;
      _lastCountry = _selectedCountry;
      _lastType = _selectedType;
      _cachedResults = []; /*TODO: service.searchAirports(
        query: _searchQuery,
        countryCode: _selectedCountry,
        type: _selectedType,
        limit: 100,
      );*/
    }
    return _cachedResults;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(airportLoadProvider);
    final service = ref.read(airportServiceProvider);
    final theme = Theme.of(context);

    final isFiltering =
        _searchQuery.isNotEmpty ||
        _selectedCountry != null ||
        _selectedType != null;

    final nearAirports = service.getNearAirports(
      limit: 20,
      relocate: _shouldRelocate,
    );
    _shouldRelocate = false;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isFiltering
              ? 'Airports (3)' //TODO: Add matching search result number
              : 'Nearest Airports',
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
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Recenter location',
            onPressed: () {
              setState(() => _shouldRelocate = true);
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
        future: nearAirports,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorWidget("Error while loading airport");
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
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isFiltering ? Icons.search_off : Icons.flight,
                                size: 64,
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.3,
                                ),
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
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final airportWithDistance = snapshot.data![index];
                          return AirportCard(
                            airport: airportWithDistance.airport,
                            distanceKm: airportWithDistance.distance,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AirportDetailPage(
                                  airportId: airportWithDistance.airport.id,
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
    final List<Country> countries = []; //TODO: service.getCountriesList();
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
              Expanded(
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
                    ...countries.map(
                      (c) => DropdownMenuItem(
                        value: c.code,
                        child: Text(c.name, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedCountry = value),
                ),
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
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Types'),
                    ),
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
