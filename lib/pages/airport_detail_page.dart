import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../providers/airport_providers.dart';
import '../services/database.dart';
import '../widgets/base_map_layer.dart';
import '../widgets/empty_state.dart';
import '../widgets/info_row.dart';
import '../widgets/map_attribution.dart';
import 'airport_map_page.dart';

class AirportDetailPage extends ConsumerWidget {
  const AirportDetailPage({super.key, required this.airportId});
  final int airportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(airportDetailsProvider(airportId));
    return Scaffold(
      appBar: AppBar(title: const Text('Airport Details')),
      body: details.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Error while loading airport',
          action: FilledButton.tonal(
            onPressed: () => ref.invalidate(airportDetailsProvider(airportId)),
            child: const Text('Retry'),
          ),
        ),
        data: (data) {
          if (data == null) {
            return const EmptyState(
              icon: Icons.search_off,
              title: 'Airport not found',
            );
          }
          return ListView(
            children: [
              _HeroSection(airport: data.airport),
              _InfoSection(
                airport: data.airport,
                country: data.country,
                region: data.region,
              ),
              _MapSection(airport: data.airport),
              _FrequenciesSection(frequencies: data.frequencies),
              _RunwaysSection(runways: data.runways),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

/// Card with a title and a list of rows, used by all detail sections.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.airport});
  final Airport airport;

  @override
  Widget build(BuildContext context) {
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
                      airport.name ?? 'NO NAME FOUND',
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
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.airport,
    required this.country,
    required this.region,
  });

  final Airport airport;
  final Country? country;
  final Region? region;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String?)>[
      ('Ident', airport.ident),
      ('ICAO', airport.icaoCode),
      ('IATA', airport.iataCode),
      ('Municipality', airport.municipality),
      ('Country', country?.name),
      ('Region', region?.name),
      ('Continent', airport.continent),
      ('Latitude', airport.latitudeDeg?.toStringAsFixed(6)),
      ('Longitude', airport.longitudeDeg?.toStringAsFixed(6)),
      (
        'Elevation',
        airport.elevationFt == null ? null : '${airport.elevationFt} ft',
      ),
      ('GPS Code', airport.gpsCode),
      ('Local Code', airport.localCode),
      ('Website', airport.homeLink),
    ];

    return _SectionCard(
      title: 'Information',
      children: [
        const SizedBox(height: 4),
        for (final (label, value) in rows)
          if (value != null)
            InfoRow(label: label, value: value, labelWidth: 120),
      ],
    );
  }
}

class _MapSection extends StatelessWidget {
  const _MapSection({required this.airport});
  final Airport airport;

  @override
  Widget build(BuildContext context) {
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
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
            onTap: (tap, point) {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => AirportMapPage(
                    latitude: lat,
                    longitude: lng,
                    airportName: airport.name ?? '',
                  ),
                ),
              );
            },
          ),
          children: const [BaseMapLayer(), MapAttribution()],
        ),
      ),
    );
  }
}

class _FrequenciesSection extends StatelessWidget {
  const _FrequenciesSection({required this.frequencies});
  final List<Frequency>? frequencies;

  @override
  Widget build(BuildContext context) {
    final list = frequencies;
    if (list == null || list.isEmpty) return const SizedBox.shrink();
    return _SectionCard(
      title: 'Frequencies (${list.length})',
      children: [for (final freq in list) _FrequencyRow(frequency: freq)],
    );
  }
}

class _FrequencyRow extends StatelessWidget {
  const _FrequencyRow({required this.frequency});
  final Frequency frequency;

  @override
  Widget build(BuildContext context) {
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
              frequency.type ?? '',
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              frequency.description ?? '',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${frequency.frequencyMhz} MHz',
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

class _RunwaysSection extends StatelessWidget {
  const _RunwaysSection({required this.runways});
  final List<Runway>? runways;

  @override
  Widget build(BuildContext context) {
    final list = runways;
    if (list == null || list.isEmpty) return const SizedBox.shrink();
    return _SectionCard(
      title: 'Runways (${list.length})',
      children: [for (final runway in list) _RunwayRow(runway: runway)],
    );
  }
}

class _RunwayRow extends StatelessWidget {
  const _RunwayRow({required this.runway});
  final Runway runway;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (runway.leIdent != null)
                _RunwayEndChip(ident: runway.leIdent!),
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
                _RunwayEndChip(ident: runway.heIdent!),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (runway.surface != null && runway.surface!.isNotEmpty)
                _DetailChip(label: runway.surface!),
              if (runway.lengthFt != null) ...[
                const SizedBox(width: 8),
                _DetailChip(label: '${runway.lengthFt} ft'),
              ],
              if (runway.widthFt != null) ...[
                const SizedBox(width: 8),
                _DetailChip(label: '${runway.widthFt} ft wide'),
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
}

class _RunwayEndChip extends StatelessWidget {
  const _RunwayEndChip({required this.ident});
  final String ident;

  @override
  Widget build(BuildContext context) {
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
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
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
