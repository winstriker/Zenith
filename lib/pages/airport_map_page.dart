import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../core/app_page_route.dart';
import '../core/theme.dart';
import '../repositories/airport_repository.dart';
import '../services/database.dart';
import '../widgets/base_map_layer.dart';
import '../widgets/map_attribution.dart';
import '../widgets/map_overlay.dart';
import '../widgets/picker_sheet.dart';
import 'airport_detail_page.dart';

/// Full-screen map of the airports around [airport], with a search and
/// filters. The bars fade out while the user moves the map.
class AirportMapPage extends ConsumerStatefulWidget {
  const AirportMapPage({super.key, required this.airport});
  final Airport airport;

  @override
  ConsumerState<AirportMapPage> createState() => _AirportMapPageState();
}

class _AirportMapPageState extends ConsumerState<AirportMapPage> {
  final _mapController = MapController();
  final _searchController = TextEditingController();

  // shortcut: past this many markers the map gets sluggish, so the biggest
  // airports are shown and the rest wait for a closer zoom; clustering
  // would show them all.
  static const _maxMarkers = 300;

  List<Airport> _airports = const [];

  /// Whether more airports than [_maxMarkers] match in view.
  bool _truncated = false;
  bool _loading = false;

  /// Bumped by every query, so a slow one can't overwrite a newer answer.
  int _request = 0;
  Timer? _queryTimer;

  String _query = '';
  AirportType? _type;
  bool _usedOnly = false;
  bool _customOnly = false;
  bool _icaoOnly = true;

  bool _overlayVisible = true;
  Timer? _overlayTimer;

  @override
  void dispose() {
    _queryTimer?.cancel();
    _overlayTimer?.cancel();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<List<Airport>> _find({required bool inView}) {
    final b = _mapController.camera.visibleBounds;
    return ref
        .read(airportRepositoryProvider)
        .getMapAirports(
          bounds: inView
              ? (south: b.south, west: b.west, north: b.north, east: b.east)
              : null,
          query: _query,
          type: _type,
          usedOnly: _usedOnly,
          customOnly: _customOnly,
          icaoOnly: _icaoOnly,
          limit: _maxMarkers + 1,
        );
  }

  /// Loads the airports matching the filters in view.
  Future<void> _refresh() async {
    final request = ++_request;
    setState(() => _loading = true);
    final found = await _find(inView: true);
    if (!mounted || request != _request) return;
    setState(() {
      _loading = false;
      _truncated = found.length > _maxMarkers;
      _airports = found.take(_maxMarkers).toList();
    });
  }

  /// Refreshes once the map or the search has settled for a moment.
  void _scheduleRefresh() {
    _queryTimer?.cancel();
    _queryTimer = Timer(const Duration(milliseconds: 250), _refresh);
  }

  void _filter(VoidCallback change) {
    setState(change);
    _refresh();
  }

  /// Moves the map to every airport matching the search, wherever they are.
  Future<void> _showAllMatches() async {
    if (_query.isEmpty) return;
    final found = await _find(inView: false);
    if (!mounted) return;
    if (found.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('No airports match "$_query"')));
      return;
    }
    final points = [
      for (final a in found.take(_maxMarkers))
        LatLng(a.latitudeDeg!, a.longitudeDeg!),
    ];
    final bounds = LatLngBounds.fromPoints(points);
    if (bounds.southWest == bounds.northEast) {
      _mapController.move(points.first, 12);
    } else {
      final padding = MediaQuery.paddingOf(context);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          maxZoom: 12,
          padding: EdgeInsets.fromLTRB(
            40,
            padding.top + 80,
            40,
            padding.bottom + 220,
          ),
        ),
      );
    }
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventWithMove) _scheduleRefresh();
    if (!mapUserMoves.contains(event.source)) return;
    _overlayTimer?.cancel();
    _overlayTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _overlayVisible = true);
    });
    if (_overlayVisible) setState(() => _overlayVisible = false);
  }

  Future<void> _pickType() async {
    final picked = await showPickerSheet<AirportType>(
      context,
      title: 'Type',
      items: [
        for (final t in AirportType.values)
          if (t != AirportType.undefined) t,
      ],
      label: AirportType.getDisplayName,
      selected: _type,
    );
    if (picked != null && mounted) _filter(() => _type = picked);
  }

  Widget _overlay(Widget child) =>
      FadingOverlay(visible: _overlayVisible, child: child);

  String get _subtitle {
    if (_truncated) return 'Biggest $_maxMarkers shown · zoom in for all';
    final n = _airports.length;
    return n == 1 ? '1 airport in view' : '$n airports in view';
  }

  @override
  Widget build(BuildContext context) {
    final overlay = context.appColors.overlay;
    final padding = MediaQuery.paddingOf(context);
    final airport = widget.airport;
    // The airport the map was opened for stays on it whatever the filters.
    final shown = [
      ..._airports,
      if (airport.latitudeDeg != null &&
          airport.longitudeDeg != null &&
          !_airports.any((a) => a.id == airport.id))
        airport,
    ];

    return Scaffold(
      backgroundColor: overlay,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(
                airport.latitudeDeg ?? 0,
                airport.longitudeDeg ?? 0,
              ),
              initialZoom: 10,
              onMapReady: _refresh,
              onMapEvent: _onMapEvent,
            ),
            children: [
              const BaseMapLayer(),
              MarkerLayer(
                markers: [
                  for (final a in shown)
                    Marker(
                      point: LatLng(a.latitudeDeg!, a.longitudeDeg!),
                      width: 120,
                      child: _AirportMarker(
                        airport: a,
                        highlighted: a.id == airport.id,
                        onTap: () => Navigator.push(
                          context,
                          AppPageRoute<void>(
                            builder: (_) => AirportDetailPage(airportId: a.id),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 140 + padding.top,
            child: _overlay(
              MapScrim(
                colors: [
                  overlay.withValues(alpha: 0.7),
                  overlay.withValues(alpha: 0.3),
                  overlay.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          Positioned(
            top: padding.top + 4,
            left: 4,
            right: 4,
            child: _overlay(
              MapTopBar(
                title: 'Airports near ${airport.ident ?? airport.name ?? ''}',
                subtitle: _subtitle,
                trailing: _loading
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.appColors.onOverlay,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 220 + padding.bottom,
            child: _overlay(
              MapScrim(
                colors: [
                  overlay.withValues(alpha: 0),
                  overlay.withValues(alpha: 0.5),
                  overlay.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: padding.bottom + 4,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _overlay(
                  _FilterPanel(
                    searchController: _searchController,
                    query: _query,
                    type: _type,
                    usedOnly: _usedOnly,
                    customOnly: _customOnly,
                    icaoOnly: _icaoOnly,
                    onSearch: (v) {
                      _query = v.trim();
                      _scheduleRefresh();
                    },
                    onSubmitSearch: _showAllMatches,
                    onPickType: _pickType,
                    onClearType: () => _filter(() => _type = null),
                    onUsedOnly: (v) => _filter(() => _usedOnly = v),
                    onCustomOnly: (v) => _filter(() => _customOnly = v),
                    onIcaoOnly: (v) => _filter(() => _icaoOnly = v),
                  ),
                ),
                const SizedBox(height: 6),
                const MapAttributionLabel(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// An airport's code in a pill; the airport the map was opened for stands
/// out.
class _AirportMarker extends StatelessWidget {
  const _AirportMarker({
    required this.airport,
    required this.highlighted,
    required this.onTap,
  });
  final Airport airport;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final dot = switch (airport.type) {
      AirportType.largeAirport || AirportType.mediumAirport => cs.primary,
      AirportType.smallAirport => colors.onOverlay,
      AirportType.closed ||
      AirportType.undefined => colors.onOverlay.withValues(alpha: 0.38),
      _ => cs.tertiary,
    };
    final background = highlighted
        ? cs.primary
        : colors.overlay.withValues(alpha: 0.75);
    final foreground = highlighted ? cs.onPrimary : colors.onOverlay;
    return Center(
      child: Semantics(
        button: true,
        label: airport.name ?? airport.ident,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(6, 3, 8, 3),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.onOverlay.withValues(alpha: 0.15),
              ),
              boxShadow: [
                if (highlighted)
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.6),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  airport.id < 0 ? Icons.edit_location_alt : Icons.circle,
                  size: airport.id < 0 ? 12 : 8,
                  color: highlighted ? cs.onPrimary : dot,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    airport.ident ?? airport.name ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Search field, filter chips and the ICAO-only switch.
class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.searchController,
    required this.query,
    required this.type,
    required this.usedOnly,
    required this.customOnly,
    required this.icaoOnly,
    required this.onSearch,
    required this.onSubmitSearch,
    required this.onPickType,
    required this.onClearType,
    required this.onUsedOnly,
    required this.onCustomOnly,
    required this.onIcaoOnly,
  });

  final TextEditingController searchController;
  final String query;
  final AirportType? type;
  final bool usedOnly;
  final bool customOnly;
  final bool icaoOnly;
  final ValueChanged<String> onSearch;
  final VoidCallback onSubmitSearch;
  final VoidCallback onPickType;
  final VoidCallback onClearType;
  final ValueChanged<bool> onUsedOnly;
  final ValueChanged<bool> onCustomOnly;
  final ValueChanged<bool> onIcaoOnly;

  @override
  Widget build(BuildContext context) {
    final onOverlay = context.appColors.onOverlay;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: onOverlay.withValues(alpha: 0.12)),
    );
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            style: TextStyle(color: onOverlay),
            cursorColor: onOverlay,
            onChanged: onSearch,
            onSubmitted: (_) => onSubmitSearch(),
            decoration: InputDecoration(
              hintText: 'Name, code or city: search to find anywhere',
              hintStyle: TextStyle(color: onOverlay.withValues(alpha: 0.5)),
              prefixIcon: Icon(
                Icons.search,
                size: 20,
                color: onOverlay.withValues(alpha: 0.6),
              ),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(Icons.clear, size: 20, color: onOverlay),
                      tooltip: 'Clear',
                      onPressed: () {
                        searchController.clear();
                        onSearch('');
                      },
                    ),
              isDense: true,
              filled: true,
              fillColor: onOverlay.withValues(alpha: 0.08),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 12,
              ),
              border: border,
              enabledBorder: border,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 8,
              children: [
                _OverlayChip(
                  icon: Icons.history,
                  label: 'Used',
                  selected: usedOnly,
                  onTap: () => onUsedOnly(!usedOnly),
                ),
                _OverlayChip(
                  icon: Icons.edit_location_alt_outlined,
                  label: 'My airports',
                  selected: customOnly,
                  onTap: () => onCustomOnly(!customOnly),
                ),
                _OverlayChip(
                  icon: Icons.category_outlined,
                  label: type == null
                      ? 'Type'
                      : AirportType.getDisplayName(type!),
                  selected: type != null,
                  onTap: onPickType,
                  onClear: type == null ? null : onClearType,
                ),
              ],
            ),
          ),
          SwitchListTile(
            dense: true,
            contentPadding: const EdgeInsets.only(left: 4),
            title: Text(
              'ICAO airports only',
              style: TextStyle(color: onOverlay, fontWeight: FontWeight.w600),
            ),
            value: icaoOnly,
            onChanged: onIcaoOnly,
          ),
        ],
      ),
    );
  }
}

/// A filter chip styled for the dark panel over the map.
class _OverlayChip extends StatelessWidget {
  const _OverlayChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.onClear,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Shows a clear button when set.
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onOverlay = context.appColors.onOverlay;
    final foreground = selected ? cs.onPrimary : onOverlay;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: selected ? cs.primary : onOverlay.withValues(alpha: 0.12),
      ),
    );
    return Material(
      color: selected ? cs.primary : onOverlay.withValues(alpha: 0.08),
      shape: shape,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: Padding(
          padding: EdgeInsets.fromLTRB(10, 8, onClear == null ? 12 : 4, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              if (onClear != null)
                InkResponse(
                  onTap: onClear,
                  radius: 14,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: foreground,
                      semanticLabel: 'Clear',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
