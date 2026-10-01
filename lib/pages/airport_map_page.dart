import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart'
    hide Theme;

import '../services/database.dart';
import '../providers/airport_providers.dart';
import '../providers/carto_provider.dart';
import 'airport_detail_page.dart';

class AirportMapPage extends ConsumerStatefulWidget {
  final double latitude;
  final double longitude;
  final String airportName;

  const AirportMapPage({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.airportName,
  });

  @override
  ConsumerState<AirportMapPage> createState() => _AirportMapPageState();
}

class _AirportMapPageState extends ConsumerState<AirportMapPage> {
  final MapController _mapController = MapController();
  List<Airport> _airports = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAirports();
    });
  }

  Future<void> _refreshAirports() async {
    setState(() => _loading = true);
    try {
      final service = ref.read(airportServiceProvider);
      final camera = _mapController.camera;
      final bounds = camera.visibleBounds;
      final center = camera.center;

      const minDelta = 0.5;
      final latDelta = max((bounds.north - bounds.south) / 2, minDelta);
      final lngDelta = max((bounds.east - bounds.west) / 2, minDelta);
      final delta = max(latDelta, lngDelta);

      final candidates = await service.database.getAirportsWithinSquare(
        center.latitude,
        center.longitude,
        delta: delta,
      );

      if (candidates == null) {
        if (mounted) setState(() => _airports = []);
        return;
      }

      _airports = candidates.where((a) {
        if (a.latitudeDeg == null || a.longitudeDeg == null) return false;
        final d = _haversine(
          center.latitude,
          center.longitude,
          a.latitudeDeg!,
          a.longitudeDeg!,
        );
        if (d > 50) return false;
        return a.latitudeDeg! >= bounds.south - 0.02 &&
            a.latitudeDeg! <= bounds.north + 0.02 &&
            a.longitudeDeg! >= bounds.west - 0.02 &&
            a.longitudeDeg! <= bounds.east + 0.02;
      }).toList();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const radius = 6371;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return radius * 2 * asin(sqrt(a));
  }

  double _toRad(double deg) => deg * pi / 180;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final cartoStyle = ref.watch(cartoStyleProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Airports Near ${widget.airportName}'),
        actions: [
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          if (!_loading && _airports.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${_airports.length} airport${_airports.length == 1 ? '' : 's'}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
        ],
      ),
      body: cartoStyle.when(
        data: (style) => FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(widget.latitude, widget.longitude),
            initialZoom: 11.0,
            onMapEvent: (MapEvent event) {
              if (event is MapEventMoveEnd ||
                  event is MapEventFlingAnimationEnd) {
                _refreshAirports();
              }
            },
          ),
          children: [
            VectorTileLayer(
              tileProviders: style!.providers,
              theme: style.theme,
              tileOffset: TileOffset.maplibre,
              concurrency: 4,
              diskCacheTtl: const Duration(days: 30),
              diskCacheMaximumSizeInBytes: 50 * 1024 * 1024,
            ),
            if (kReleaseMode) ...[
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.6),
                    ),
                    child: Text(
                      '© OpenStreetMap contributors,© CARTO',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            MarkerLayer(
              markers: _airports.map((airport) {
                final isCenter =
                    airport.latitudeDeg == widget.latitude &&
                    airport.longitudeDeg == widget.longitude;
                return Marker(
                  point: LatLng(airport.latitudeDeg!, airport.longitudeDeg!),
                  width: 140,
                  height: 48,
                  alignment: Alignment.topCenter,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AirportDetailPage(airportId: airport.id),
                        ),
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isCenter ? cs.primary : cs.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isCenter ? cs.onPrimary : cs.primary,
                            ),
                          ),
                          child: Text(
                            airport.ident ?? airport.name ?? '',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isCenter
                                  ? cs.onPrimary
                                  : cs.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Icon(
                          isCenter ? Icons.flight : Icons.location_on,
                          color: cs.primary,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Failed to load map style',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
