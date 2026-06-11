import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logbook/main.dart';
import '../services/database.dart';
import '../providers/aircraft_providers.dart';
import '../widgets/aircraft_card.dart';
import '../widgets/flight_card.dart';
import 'flight_detail_page.dart';

class AircraftsPage extends ConsumerStatefulWidget {
  const AircraftsPage({super.key});

  @override
  ConsumerState<AircraftsPage> createState() => _AircraftsPageState();
}

class _AircraftsPageState extends ConsumerState<AircraftsPage> {
  @override
  Widget build(BuildContext context) {
    final aircraftList = ref.watch(aircraftListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Aircraft'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add aircraft',
            onPressed: () => _showAddDialog(),
          ),
        ],
      ),
      body: aircraftList.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.airplanemode_active,
                      size: 64,
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No aircraft yet',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your first aircraft to start tracking flights.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => _showAddDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Aircraft'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: aircraftList.length,
              itemBuilder: (context, index) {
                final aws = aircraftList[index];
                return AircraftCard(
                  aircraft: aws,
                  onTap: () => _showDetailPage(aws),
                );
              },
            ),
    );
  }

  Future<void> _showAddDialog() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const _AircraftFormPage()),
    );
    if (result == true) {
      ref.read(aircraftListProvider.notifier).refresh();
    }
  }

  Future<void> _showDetailPage(AircraftWithStats aws) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AircraftDetailPage(aircraft: aws)),
    );
    if (result == true) {
      ref.read(aircraftListProvider.notifier).refresh();
    }
  }
}

class _AircraftFormPage extends ConsumerStatefulWidget {
  final Aircraft? aircraft;
  const _AircraftFormPage({this.aircraft});

  @override
  ConsumerState<_AircraftFormPage> createState() => _AircraftFormPageState();
}

class _AircraftFormPageState extends ConsumerState<_AircraftFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _typeController;
  late final TextEditingController _modelController;
  late final TextEditingController _tailController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _typeController = TextEditingController(text: widget.aircraft?.type ?? '');
    _modelController = TextEditingController(text: widget.aircraft?.model ?? '');
    _tailController = TextEditingController(text: widget.aircraft?.tailNumber ?? '');
    _notesController = TextEditingController(text: widget.aircraft?.notes ?? '');
  }

  @override
  void dispose() {
    _typeController.dispose();
    _modelController.dispose();
    _tailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isEditing = widget.aircraft != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Aircraft' : 'Add Aircraft'),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
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
            child: Row(
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
                        isEditing ? widget.aircraft!.type : 'New Aircraft',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isEditing
                            ? 'Edit the details below'
                            : 'Enter the details of your aircraft',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSecondaryContainer.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _typeController,
                    decoration: const InputDecoration(
                      labelText: 'Type *',
                      hintText: 'e.g. C172',
                      prefixIcon: Icon(Icons.airplanemode_active),
                    ),
                    validator: (value) => (value == null || value.trim().isEmpty)
                        ? 'Type is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _modelController,
                    decoration: const InputDecoration(
                      labelText: 'Model',
                      hintText: 'e.g. Cessna 172S Skyhawk',
                      prefixIcon: Icon(Icons.model_training),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tailController,
                    decoration: const InputDecoration(
                      labelText: 'Tail Number',
                      hintText: 'e.g. N123AB',
                      prefixIcon: Icon(Icons.numbers),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Any additional info...',
                      prefixIcon: Icon(Icons.notes),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _save,
                    child: Text(isEditing ? 'Save Changes' : 'Add Aircraft'),
                  ),
                  if (isEditing) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _deleteAircraft,
                      style: TextButton.styleFrom(
                        foregroundColor: cs.error,
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete Aircraft'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final db = ref.read(databaseProvider);
    if (widget.aircraft != null) {
      await db.updateAircraft(
        widget.aircraft!.id,
        type: _typeController.text.trim(),
        model: _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
        tailNumber: _tailController.text.trim().isEmpty ? null : _tailController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
    } else {
      await db.addAircraft(
        type: _typeController.text.trim(),
        model: _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
        tailNumber: _tailController.text.trim().isEmpty ? null : _tailController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
    }
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _deleteAircraft() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Aircraft'),
        content: Text('Delete "${widget.aircraft!.type}"? Flights using this aircraft will be unlinked.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final db = ref.read(databaseProvider);
      await db.deleteAircraft(widget.aircraft!.id);
      if (mounted) Navigator.pop(context, true);
    }
  }
}

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
        builder: (_) => _AircraftFormPage(aircraft: _aircraft.aircraft),
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
                      _StatChip(
                        icon: Icons.flight,
                        label: '${_aircraft.flightCount} flights',
                        color: cs.primaryContainer,
                        textColor: cs.onPrimaryContainer,
                      ),
                      if (hours != null) ...[
                        const SizedBox(width: 12),
                        _StatChip(
                          icon: Icons.schedule,
                          label: hours,
                          color: cs.tertiaryContainer,
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

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
