import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/airport_providers.dart';
import '../models/airport.dart';
import '../models/airport_frequency.dart';
import '../models/runway.dart';
import '../models/country.dart';

class AirportDetailPage extends ConsumerWidget {
  final String airportRef;

  const AirportDetailPage({super.key, required this.airportRef});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(airportServiceProvider);
    final airport = service.getAirportById(airportRef);

    if (airport == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Airport')),
        body: const Center(child: Text('Airport not found')),
      );
    }

    final frequencies = service.getFrequencies(airport.id);
    final runways = service.getRunways(airport.id);
    final country = service.getCountry(airport.isoCountry);

    return Scaffold(
      appBar: AppBar(
        title: Text(airport.displayCode.isNotEmpty
            ? airport.displayCode
            : 'Airport Details'),
      ),
      body: ListView(
        children: [
          _buildHeroSection(context, airport),
          _buildInfoSection(context, airport, country),
          if (frequencies.isNotEmpty)
            _buildFrequenciesSection(context, frequencies),
          if (runways.isNotEmpty) _buildRunwaysSection(context, runways),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, Airport airport) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      airport.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (airport.municipality != null)
                      Text(
                        airport.municipality!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: cs.onPrimary.withValues(alpha: 0.8),
                        ),
                      ),
                  ],
                ),
              ),
              if (airport.displayCode.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cs.onPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    airport.displayCode,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cs.onPrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              airport.typeLabel,
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    Airport airport,
    Country? country,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Information',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (airport.ident.isNotEmpty)
              _infoRow(theme, cs, 'Ident', airport.ident),
            if (airport.icaoCode != null)
              _infoRow(theme, cs, 'ICAO', airport.icaoCode!),
            if (airport.iataCode != null)
              _infoRow(theme, cs, 'IATA', airport.iataCode!),
            if (airport.municipality != null)
              _infoRow(theme, cs, 'Municipality', airport.municipality!),
            if (country != null)
              _infoRow(theme, cs, 'Country', country.name),
            if (airport.isoRegion != null)
              _infoRow(theme, cs, 'Region', airport.isoRegion!),
            if (airport.continent != null)
              _infoRow(theme, cs, 'Continent', airport.continent!),
            if (airport.latitudeDeg != null)
              _infoRow(
                theme,
                cs,
                'Latitude',
                airport.latitudeDeg!.toStringAsFixed(6),
              ),
            if (airport.longitudeDeg != null)
              _infoRow(
                theme,
                cs,
                'Longitude',
                airport.longitudeDeg!.toStringAsFixed(6),
              ),
            if (airport.elevationFt != null)
              _infoRow(
                theme,
                cs,
                'Elevation',
                '${airport.elevationFt!.toStringAsFixed(0)} ft',
              ),
            if (airport.gpsCode != null)
              _infoRow(theme, cs, 'GPS Code', airport.gpsCode!),
            if (airport.localCode != null)
              _infoRow(theme, cs, 'Local Code', airport.localCode!),
            if (airport.homeLink != null)
              _infoRow(theme, cs, 'Website', airport.homeLink!),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    ThemeData theme,
    ColorScheme cs,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequenciesSection(
    BuildContext context,
    List<AirportFrequency> frequencies,
  ) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Frequencies (${frequencies.length})',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...frequencies.map(
              (freq) => _frequencyRow(context, freq),
            ),
          ],
        ),
      ),
    );
  }

  Widget _frequencyRow(BuildContext context, AirportFrequency freq) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              freq.type,
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              freq.description,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${freq.frequencyMhz.toStringAsFixed(3)} MHz',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunwaysSection(
    BuildContext context,
    List<Runway> runways,
  ) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Runways (${runways.length})',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...runways.map(
              (runway) => _runwayRow(context, runway),
            ),
          ],
        ),
      ),
    );
  }

  Widget _runwayRow(BuildContext context, Runway runway) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (runway.leIdent != null)
                _runwayEndChip(context, runway.leIdent!),
              if (runway.leIdent != null && runway.heIdent != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.swap_horiz,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              if (runway.heIdent != null)
                _runwayEndChip(context, runway.heIdent!),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (runway.surface != null && runway.surface!.isNotEmpty)
                _detailChip(context, runway.surface!),
              if (runway.lengthFt != null) ...[
                const SizedBox(width: 8),
                _detailChip(
                  context,
                  '${runway.lengthFt!.toStringAsFixed(0)} ft',
                ),
              ],
              if (runway.widthFt != null) ...[
                const SizedBox(width: 8),
                _detailChip(
                  context,
                  '${runway.widthFt!.toStringAsFixed(0)} ft wide',
                ),
              ],
              if (runway.lighted) ...[
                const SizedBox(width: 8),
                Icon(Icons.light, size: 14, color: cs.tertiary),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _runwayEndChip(BuildContext context, String ident) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        ident,
        style: theme.textTheme.labelMedium?.copyWith(
          color: cs.onSecondaryContainer,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _detailChip(BuildContext context, String label) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}
