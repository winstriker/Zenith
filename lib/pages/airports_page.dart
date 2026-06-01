import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  String? _selectedType;
  final _searchController = TextEditingController();
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncLoad = ref.watch(airportDataLoadProvider);
    final service = ref.read(airportServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Airports'),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_alt_off : Icons.filter_alt),
            tooltip: 'Filters',
            onPressed: () => setState(() => _showFilters = !_showFilters),
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
              ref.invalidate(airportDataLoadProvider);
            },
          ),
        ],
      ),
      body: asyncLoad.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Downloading airport data...'),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_off,
                  size: 64,
                  color: Theme.of(context)
                      .colorScheme
                      .error
                      .withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load airport data',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Check your internet connection and try again.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(airportDataLoadProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (_) => _buildContent(context, service),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AirportService service) {
    final airports = service.searchAirports(
      query: _searchQuery,
      countryCode: _selectedCountry,
      type: _selectedType,
    );
    final theme = Theme.of(context);

    return Column(
      children: [
        _buildSearchBar(context, service),
        if (_showFilters) _buildFilters(context, service),
        Expanded(
          child: airports.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty ||
                                  _selectedCountry != null ||
                                  _selectedType != null
                              ? Icons.search_off
                              : Icons.flight,
                          size: 64,
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty ||
                                  _selectedCountry != null ||
                                  _selectedType != null
                              ? 'No airports match your filters'
                              : 'No airports found',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty ||
                                  _selectedCountry != null ||
                                  _selectedType != null
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
                    return AirportCard(
                      airport: airport,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AirportDetailPage(airportRef: airport.id),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, AirportService service) {
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
