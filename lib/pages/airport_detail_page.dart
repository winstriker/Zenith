import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../core/app_page_route.dart';
import '../core/fab_hero_tags.dart';
import '../providers/airport_providers.dart';
import '../services/database.dart';
import '../widgets/base_map_layer.dart';
import '../widgets/empty_state.dart';
import '../widgets/flight_card.dart';
import '../widgets/info_row.dart';
import '../widgets/load_more.dart';
import '../widgets/map_attribution.dart';
import '../widgets/page_title.dart';
import '../widgets/speed_dial_fab.dart';
import 'airport_form_page.dart';
import 'airport_logbook_page.dart';
import 'airport_map_page.dart';
import 'flight_detail_page.dart';

/// An airport: where it is, its runways and frequencies, and the flights
/// that used it, older ones loading as the page is scrolled to its end.
/// Airports the user added can be edited from here.
class AirportDetailPage extends ConsumerStatefulWidget {
  const AirportDetailPage({super.key, required this.airportId});
  final int airportId;

  @override
  ConsumerState<AirportDetailPage> createState() => _AirportDetailPageState();
}

class _AirportDetailPageState extends ConsumerState<AirportDetailPage> {
  /// How many flights the list asks for; grows as it is scrolled.
  int _limit = loadMorePageSize;

  /// The last flights loaded, shown while older ones load.
  List<FlightWithStats>? _flights;

  @override
  Widget build(BuildContext context) {
    final airportId = widget.airportId;
    final details = ref.watch(airportDetailsProvider(airportId));
    final page = ref.watch(
      airportFlightsPageProvider((airportId: airportId, limit: _limit)),
    );
    if (page.hasValue) _flights = page.value;
    final flights = _flights;
    final hasMore = flights != null && flights.length >= _limit;
    final data = details.value;
    final airport = data?.airport;

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: FloatingActionButton(
        heroTag: closeFabHeroTag,
        tooltip: 'Close',
        onPressed: () => Navigator.pop(context),
        child: const Icon(Icons.close),
      ),
      body: Scaffold(
        floatingActionButton: switch (airport) {
          null => null,
          // Only the user's own airports can be edited.
          Airport(isCustom: false) => FloatingActionButton.extended(
            heroTag: primaryFabHeroTag,
            label: const Text('Logbook overrides'),
            icon: const Icon(Icons.edit_note),
            onPressed: () => _editLogbook(airport),
          ),
          _ => SpeedDialFab(
            actions: [
              SpeedDialAction(
                heroTag: 'airportLogbookOverridesFab',
                icon: Icons.edit_note,
                label: 'Logbook overrides',
                onPressed: () => _editLogbook(airport),
              ),
            ],
            primaryIcon: Icons.edit,
            primaryLabel: 'Edit',
            onPrimaryPressed: () async {
              final deleted = await Navigator.push<Object?>(
                context,
                AppPageRoute(builder: (_) => AirportFormPage(airport: airport)),
              );
              // Nothing left to show once the airport is gone.
              if (deleted == true && context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
        },
        body: switch (details) {
          AsyncValue(hasValue: false, hasError: true) => EmptyState(
            icon: Icons.error_outline,
            title: 'Error while loading airport',
            action: FilledButton.tonal(
              onPressed: () =>
                  ref.invalidate(airportDetailsProvider(airportId)),
              child: const Text('Retry'),
            ),
          ),
          AsyncValue(hasValue: false) => const Center(
            child: CircularProgressIndicator(),
          ),
          _ when data == null => const EmptyState(
            icon: Icons.search_off,
            title: 'Airport not found',
          ),
          _ => LoadMoreScrollView(
            hasMore: hasMore,
            loading: !page.hasValue,
            onLoadMore: () => setState(() => _limit += loadMorePageSize),
            builder: (context, controller) => CustomScrollView(
              controller: controller,
              slivers: [
                SliverToBoxAdapter(
                  child: PageTitle(
                    data.airport.name ?? data.airport.ident ?? 'Airport',
                    belowCloseButton: true,
                  ),
                ),
                _Section(
                  title: 'Information',
                  child: _InfoCard(
                    airport: data.airport,
                    country: data.country,
                    region: data.region,
                  ),
                ),
                if (data.runways.isNotEmpty)
                  _Section(
                    title: 'Runways',
                    count: data.runways.length,
                    child: _ListCard(
                      children: [
                        for (final runway in data.runways)
                          _RunwayRow(runway: runway),
                      ],
                    ),
                  ),
                if (data.frequencies.isNotEmpty)
                  _Section(
                    title: 'Frequencies',
                    count: data.frequencies.length,
                    child: _ListCard(
                      children: [
                        for (final freq in data.frequencies)
                          _FrequencyRow(frequency: freq),
                      ],
                    ),
                  ),
                SliverToBoxAdapter(child: _MapCard(airport: data.airport)),
                const _SectionTitle(title: 'Flights'),
                ..._flightSlivers(context, page, flights),
                if (hasMore)
                  const SliverToBoxAdapter(child: LoadMoreIndicator()),
                const SliverToBoxAdapter(child: SizedBox(height: 96)),
              ],
            ),
          ),
        },
      ),
    );
  }

  Future<void> _editLogbook(Airport airport) async {
    final saved = await Navigator.push<bool>(
      context,
      AppPageRoute(builder: (_) => AirportLogbookPage(airport: airport)),
    );
    // The details are read once: read them again to show the change.
    if (saved == true) ref.invalidate(airportDetailsProvider(airport.id));
  }

  List<Widget> _flightSlivers(
    BuildContext context,
    AsyncValue<List<FlightWithStats>> page,
    List<FlightWithStats>? flights,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return switch (flights) {
      null when page.hasError => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Text(
              'Error while loading flights',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: cs.error),
            ),
          ),
        ),
      ],
      null => const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
      [] => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Icon(
                  Icons.flight_land,
                  size: 48,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No flights at this airport yet',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      final list => [
        SliverList.builder(
          itemCount: list.length,
          itemBuilder: (context, index) => FlightCard(
            flight: list[index],
            onTap: () => Navigator.push(
              context,
              AppPageRoute<void>(
                builder: (_) =>
                    FlightDetailPage(flightId: list[index].flight.id),
              ),
            ),
          ),
        ),
      ],
    };
  }
}

/// A section's heading, like "Flights" on the aircraft page.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.count});
  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = this.count;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Text.rich(
          TextSpan(
            text: title,
            children: [
              if (count != null)
                TextSpan(
                  text: '  $count',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
            ],
          ),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// A [_SectionTitle] over its content.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.count});
  final String title;
  final int? count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        _SectionTitle(title: title, count: count),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(child: child),
        ),
      ],
    );
  }
}

/// A card holding rows.
class _ListCard extends StatelessWidget {
  const _ListCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.airport,
    required this.country,
    required this.region,
  });

  final Airport airport;
  final Country? country;
  final Region? region;

  @override
  Widget build(BuildContext context) {
    String? orNull(String? v) => v == null || v.trim().isEmpty ? null : v;
    final rows = <(String, String?)>[
      ('Ident', orNull(airport.ident)),
      ('Type', AirportType.getDisplayName(airport.type)),
      ('ICAO', orNull(airport.icaoCode)),
      ('IATA', orNull(airport.iataCode)),
      ('GPS code', orNull(airport.gpsCode)),
      ('Local code', orNull(airport.localCode)),
      ('City', orNull(airport.municipality)),
      ('Region', region?.name),
      ('Country', country?.name ?? airport.isoCountry),
      ('Latitude', airport.latitudeDeg?.toStringAsFixed(6)),
      ('Longitude', airport.longitudeDeg?.toStringAsFixed(6)),
      (
        'Elevation',
        airport.elevationFt == null ? null : '${airport.elevationFt} ft',
      ),
      ('Website', orNull(airport.homeLink)),
      if (airport.isCustom) ('Source', 'Added by you'),
    ];

    return _ListCard(
      children: [
        for (final (label, value) in rows)
          if (value != null) InfoRow(label: label, value: value),
      ],
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({required this.airport});
  final Airport airport;

  @override
  Widget build(BuildContext context) {
    final lat = airport.latitudeDeg;
    final lng = airport.longitudeDeg;
    if (lat == null || lng == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;

    void openMap() => Navigator.push(
      context,
      AppPageRoute<void>(builder: (_) => AirportMapPage(airport: airport)),
    );

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 200,
        child: FlutterMap(
          // Keyed so a moved custom airport recenters the map.
          key: ValueKey((lat, lng)),
          options: MapOptions(
            initialCenter: LatLng(lat, lng),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
            onTap: (_, _) => openMap(),
          ),
          children: [
            const BaseMapLayer(),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(lat, lng),
                  width: 36,
                  height: 36,
                  alignment: Alignment.topCenter,
                  child: Icon(Icons.location_on, size: 36, color: cs.primary),
                ),
              ],
            ),
            const MapAttribution(),
          ],
        ),
      ),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
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

class _RunwayRow extends StatelessWidget {
  const _RunwayRow({required this.runway});
  final Runway runway;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final surface = runway.surface;
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
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (surface != null && surface.isNotEmpty)
                _DetailChip(label: surface),
              if (runway.lengthFt != null)
                _DetailChip(label: '${runway.lengthFt} ft'),
              if (runway.widthFt != null)
                _DetailChip(label: '${runway.widthFt} ft wide'),
              if (runway.lighted ?? false)
                Icon(Icons.light, size: 14, color: cs.tertiary),
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
