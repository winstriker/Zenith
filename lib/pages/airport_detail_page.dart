import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:logbook/services/database.dart';
import '../providers/airport_providers.dart';
import '../widgets/info_row.dart';
import 'airport_map_page.dart';

class _FrequenciesSection extends ConsumerWidget {
  final List<Frequency>? frequencies;
  const _FrequenciesSection({required this.frequencies});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (frequencies == null || frequencies!.isEmpty) {
      return const SizedBox.shrink();
    }
    return _buildFrequenciesSection(
      context,
      frequencies ?? List<Frequency>.empty(),
    );
  }

  Widget _buildFrequenciesSection(
    BuildContext context,
    List<Frequency> frequencies,
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
            ...frequencies.map((freq) => _frequencyRow(context, freq)),
          ],
        ),
      ),
    );
  }

  Widget _frequencyRow(BuildContext context, Frequency freq) {
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
              freq.type ?? "",
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              freq.description ?? "",
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${freq.frequencyMhz} MHz',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _RunwaysSection extends ConsumerWidget {
  final List<Runway>? runways;
  const _RunwaysSection({required this.runways});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (runways == null || runways!.isEmpty) return const SizedBox.shrink();
    return _buildRunwaysSection(context, runways!);
  }

  Widget _buildRunwaysSection(BuildContext context, List<Runway> runways) {
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
            ...runways.map((runway) => _runwayRow(context, runway)),
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
              if (runway.lighted ?? false) ...[
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
        style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}

class AirportDetailPage extends ConsumerWidget {
  final int airportId;

  const AirportDetailPage({super.key, required this.airportId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(airportServiceProvider);
    final airport = service.getCompleteAirportData(airportId);
    return Scaffold(
      appBar: AppBar(title: Text('Airport Details')),
      body: FutureBuilder(
        future: airport,
        builder: ((context, snapshot) {
          if (snapshot.hasError) {
            return ErrorWidget("Error while loading airport");
          }
          if (!snapshot.hasData) {
            return const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return ListView(
            children: [
              _buildHeroSection(context, snapshot.data!.airport),
              _buildInfoSection(
                context,
                snapshot.data!.airport,
                snapshot.data!.country,
                snapshot.data!.region,
              ),
              _buildMapSection(context, snapshot.data!.airport),
              _FrequenciesSection(frequencies: snapshot.data!.frequencies),
              _RunwaysSection(runways: snapshot.data!.runways),
              const SizedBox(height: 32),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, Airport airport) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
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
                      airport.name ?? "NO NAME FOUND",
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
              if (airport.ident != null)
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
                    airport.ident!,
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
              AirportType.getDisplayName(airport.type),
              style: theme.textTheme.labelMedium?.copyWith(color: cs.onPrimary),
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
    Region? region,
  ) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Information', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            if (airport.ident != null)
              InfoRow(label: 'Ident', value: airport.ident!, labelWidth: 120),
            if (airport.icaoCode != null)
              InfoRow(label: 'ICAO', value: airport.icaoCode!, labelWidth: 120),
            if (airport.iataCode != null)
              InfoRow(label: 'IATA', value: airport.iataCode!, labelWidth: 120),
            if (airport.municipality != null)
              InfoRow(label: 'Municipality', value: airport.municipality!, labelWidth: 120),
            if (country != null)
              InfoRow(label: 'Country', value: country.name, labelWidth: 120),
            if (region != null)
              InfoRow(label: 'Region', value: region.name, labelWidth: 120),
            InfoRow(label: 'Continent', value: airport.continent, labelWidth: 120),
            if (airport.latitudeDeg != null)
              InfoRow(
                label: 'Latitude',
                value: airport.latitudeDeg!.toStringAsFixed(6),
                labelWidth: 120,
              ),
            if (airport.longitudeDeg != null)
              InfoRow(
                label: 'Longitude',
                value: airport.longitudeDeg!.toStringAsFixed(6),
                labelWidth: 120,
              ),
            if (airport.elevationFt != null)
              InfoRow(
                label: 'Elevation',
                value: '${airport.elevationFt!.toStringAsFixed(0)} ft',
                labelWidth: 120,
              ),
            if (airport.gpsCode != null)
              InfoRow(label: 'GPS Code', value: airport.gpsCode!, labelWidth: 120),
            if (airport.localCode != null)
              InfoRow(label: 'Local Code', value: airport.localCode!, labelWidth: 120),
            if (airport.homeLink != null)
              InfoRow(label: 'Website', value: airport.homeLink!, labelWidth: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildMapSection(BuildContext context, Airport airport) {
    final lat = airport.latitudeDeg;
    final lng = airport.longitudeDeg;
    if (lat == null || lng == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 200,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(lat, lng),
            initialZoom: 13.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
            onTap: (tap, point) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AirportMapPage(
                    latitude: lat,
                    longitude: lng,
                    airportName: airport.name ?? '',
                  ),
                ),
              );
            },
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.logbook.app',
            ),
          ],
        ),
      ),
    );
  }
}
