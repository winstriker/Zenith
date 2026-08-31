import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logbook/main.dart';
import '../services/database.dart';
import '../widgets/flight_card.dart';
import '../widgets/info_chip.dart';
import 'aircraft_form_page.dart';
import 'flight_detail_page.dart';

class AircraftDetailPage extends ConsumerStatefulWidget {
  final AircraftWithStats aircraft;
  const AircraftDetailPage({super.key, required this.aircraft});

  @override
  ConsumerState<AircraftDetailPage> createState() => _AircraftDetailPageState();
}

class _AircraftDetailPageState extends ConsumerState<AircraftDetailPage> {
  static const _pageSize = 5;

  late AircraftWithStats _aircraft;
  final List<FlightWithStats> _flights = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _aircraft = widget.aircraft;
    _loadFlights();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadFlights();
    }
  }

  Future<void> _loadFlights() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);
    final db = ref.read(databaseProvider);
    final flights = await db.getFlightsForAircraft(
      _aircraft.aircraft.id,
      limit: _pageSize,
      offset: _offset,
    );
    if (!mounted) return;
    setState(() {
      _flights.addAll(flights);
      _offset += flights.length;
      _hasMore = flights.length >= _pageSize;
      _isLoading = false;
    });
  }

  Future<void> _onEdit() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AircraftFormPage(aircraft: _aircraft.aircraft),
      ),
    );
    if (result == true && mounted) {
      final db = ref.read(databaseProvider);
      final updated = await db.getAircraft(_aircraft.aircraft.id);
      final stats = await db.getAircraftsWithStats();
      final match =
          stats.where((s) => s.aircraft.id == _aircraft.aircraft.id).firstOrNull;
      if (updated != null && match != null) {
        setState(() {
          _aircraft = AircraftWithStats(
            updated,
            match.flightCount,
            match.totalFlightTime,
          );
        });
      }
      _flights.clear();
      _offset = 0;
      _hasMore = true;
      _loadFlights();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ac = _aircraft.aircraft;
    final hours = _aircraft.totalFlightTime != null
        ? '${(_aircraft.totalFlightTime!.inMinutes / 60).toStringAsFixed(1)}h'
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aircraft Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit aircraft',
            onPressed: _onEdit,
          ),
        ],
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.secondaryContainer,
                    cs.secondaryContainer.withValues(alpha: 0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cs.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.flight,
                          size: 40,
                          color: cs.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ac.type,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onSecondaryContainer,
                              ),
                            ),
                            if (ac.model != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                ac.model!,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: cs.onSecondaryContainer
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      InfoChip(
                        icon: Icons.flight,
                        label: '${_aircraft.flightCount} flights',
                        backgroundColor: cs.primaryContainer,
                        textColor: cs.onPrimaryContainer,
                      ),
                      if (hours != null) ...[
                        const SizedBox(width: 12),
                        InfoChip(
                          icon: Icons.schedule,
                          label: hours,
                          backgroundColor: cs.tertiaryContainer,
                          textColor: cs.onTertiaryContainer,
                        ),
                      ],
                    ],
                  ),
                  if (ac.tailNumber != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.tag, size: 16, color: cs.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Text(
                            ac.tailNumber!,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Text(
                'Flights',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (_flights.isEmpty && !_isLoading)
            SliverToBoxAdapter(
              child: Center(
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
                        'No flights with this aircraft yet',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= _flights.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return FlightCard(
                    flight: _flights[index],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              FlightDetailPage(flight: _flights[index]),
                        ),
                      );
                    },
                  );
                },
                childCount: _flights.length + (_isLoading ? 1 : 0),
              ),
            ),
        ],
      ),
    );
  }
}
