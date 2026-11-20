import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/app_page_route.dart';
import '../core/theme.dart';
import '../pages/airport_detail_page.dart';
import '../services/database.dart';
import '../utils/night_time.dart';

/// The departure and arrival markers of a flight on a map, and, when it has
/// no track, the great circle between them. Tapping a marker opens its
/// airport.
class FlightRouteLayer extends StatelessWidget {
  const FlightRouteLayer({super.key, required this.flight, required this.path});

  final FlightWithStats flight;

  /// The track as the map draws it: empty when there is none.
  final List<LatLng> path;

  static LatLng? _position(Airport? airport) {
    final lat = airport?.latitudeDeg;
    final lon = airport?.longitudeDeg;
    return lat == null || lon == null ? null : LatLng(lat, lon);
  }

  /// Where the flight starts and ends: its airports, or the ends of its track
  /// for a recorded flight without them.
  static (LatLng?, LatLng?) _ends(FlightWithStats flight, List<LatLng> path) {
    final hasTrack = path.length >= 2;
    return (
      _position(flight.departure) ?? (hasTrack ? path.first : null),
      _position(flight.arrival) ?? (hasTrack ? path.last : null),
    );
  }

  /// The great circle between the airports, drawn instead of a track. A
  /// straight line on the map would be a rhumb line.
  static List<LatLng> _orthodromic(FlightWithStats flight, List<LatLng> path) {
    if (path.length >= 2) return const [];
    final (start, end) = _ends(flight, path);
    if (start == null || end == null || start == end) return const [];
    final circle = GreatCircle(
      (latitude: start.latitude, longitude: start.longitude),
      (latitude: end.latitude, longitude: end.longitude),
    );
    const segments = 64;
    return List.generate(segments + 1, (i) {
      final p = circle.at(i / segments);
      return LatLng(p.latitude, p.longitude);
    });
  }

  /// Everything the map must show for the whole route to be seen: empty when
  /// there is nothing to draw.
  static List<LatLng> extent(FlightWithStats flight, List<LatLng> path) {
    final (start, end) = _ends(flight, path);
    return [...path, ..._orthodromic(flight, path), ?start, ?end];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (start, end) = _ends(flight, path);
    final line = _orthodromic(flight, path);

    Marker marker(LatLng point, Airport? airport, Widget icon) => Marker(
      point: point,
      // Larger than the icon, to be easy to tap.
      width: 40,
      height: 40,
      alignment: Alignment.center,
      child: airport == null
          ? Center(child: icon)
          : Semantics(
              button: true,
              label: airport.ident,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).push(
                  AppPageRoute<void>(
                    builder: (_) => AirportDetailPage(airportId: airport.id),
                  ),
                ),
                child: Center(child: icon),
              ),
            ),
    );

    return Stack(
      children: [
        if (line.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(points: line, strokeWidth: 3, color: cs.primary),
            ],
          ),
        MarkerLayer(
          markers: [
            if (start != null)
              marker(
                start,
                flight.departure,
                RouteMarker(
                  icon: Icons.flight_takeoff,
                  color: cs.primary,
                  foreground: cs.onPrimary,
                ),
              ),
            if (end != null)
              marker(
                end,
                flight.arrival,
                RouteMarker(
                  icon: Icons.flight_land,
                  color: cs.error,
                  foreground: cs.onError,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class RouteMarker extends StatelessWidget {
  const RouteMarker({
    super.key,
    required this.icon,
    required this.color,
    required this.foreground,
  });

  final IconData icon;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: colors.onOverlay, width: 2),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, size: 12, color: foreground),
    );
  }
}

/// The aircraft on a map, pointing where it is heading.
class PlaneMarker extends StatelessWidget {
  const PlaneMarker({super.key, required this.headingDeg});
  final double headingDeg;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cs.primary,
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.6),
            blurRadius: 12,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Transform.rotate(
        angle: headingDeg * pi / 180,
        child: Icon(Icons.flight, color: cs.onPrimary, size: 28),
      ),
    );
  }
}
