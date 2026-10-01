import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/aircraft_providers.dart';
import '../repositories/aircraft_repository.dart';
import '../services/database.dart';
import '../widgets/empty_state.dart';
import '../widgets/model_card.dart';

class IcaoAircraftSelectPage extends ConsumerStatefulWidget {
  const IcaoAircraftSelectPage({super.key});

  @override
  ConsumerState<IcaoAircraftSelectPage> createState() =>
      _IcaoAircraftSelectPageState();
}

class _IcaoAircraftSelectPageState
    extends ConsumerState<IcaoAircraftSelectPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icaoAsync = ref.watch(icaoAircraftsStreamProvider);

    return icaoAsync.when(
      data: (icaoList) {
        final filtered = _query.isEmpty
            ? icaoList
            : icaoList.where((icao) {
                final q = _query.toLowerCase();
                return icao.modelFullName.toLowerCase().contains(q) ||
                    icao.manufacturer.toLowerCase().contains(q);
              }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Select Aircraft Type'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Add custom aircraft type',
                onPressed: _showAddCustomDialog,
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search aircraft type...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ),
              Expanded(
                child: icaoList.isEmpty
                    ? EmptyState(
                        icon: Icons.airplanemode_active,
                        title: 'No aircraft types loaded',
                        subtitle: 'Reload aircraft types from settings.',
                        action: FilledButton.icon(
                          onPressed: () {
                            ref
                                .read(aircraftTypesLoadProvider.notifier)
                                .refresh();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reload Types'),
                        ),
                      )
                    : filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.search_off,
                        iconSize: 48,
                        iconOpacity: 0.4,
                        title: 'No type matches "$_query"',
                        subtitle:
                            'Try a different search or add a custom type.',
                        action: OutlinedButton.icon(
                          onPressed: _showAddCustomDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Custom Type'),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 4, bottom: 80),
                        itemCount: filtered.length,

                        itemBuilder: (context, index) {
                          final icao = filtered[index];
                          return ModelCard(
                            aircraft: icao,
                            onTap: () => Navigator.pop(context, icao),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  Future<void> _showAddCustomDialog() async {
    final modelCtrl = TextEditingController();
    final manufacturerCtrl = TextEditingController();
    WakeTurbolenceCategory wakeCategory = WakeTurbolenceCategory.Z;
    WakeTurbolenceGroup wakeGroup = WakeTurbolenceGroup.Z;
    AircraftDescription description = AircraftDescription.landplane;
    int engineCount = 1;
    EngineType engineType = EngineType.piston;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Custom Aircraft Type'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: modelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Model Full Name *',
                    hintText: 'e.g. Custom Experimental',
                    prefixIcon: Icon(Icons.model_training),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: manufacturerCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Manufacturer *',
                    hintText: 'e.g. Custom Builder',
                    prefixIcon: Icon(Icons.factory),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<WakeTurbolenceCategory>(
                  initialValue: wakeCategory,
                  decoration: const InputDecoration(
                    labelText: 'Wake Turbulence Category',
                    prefixIcon: Icon(Icons.waves),
                  ),
                  items: WakeTurbolenceCategory.values.map((e) {
                    return DropdownMenuItem(value: e, child: Text(e.name));
                  }).toList(),
                  onChanged: (v) => setState(() => wakeCategory = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<WakeTurbolenceGroup>(
                  initialValue: wakeGroup,
                  decoration: const InputDecoration(
                    labelText: 'Wake Turbulence Group',
                    prefixIcon: Icon(Icons.groups),
                  ),
                  items: WakeTurbolenceGroup.values.map((e) {
                    return DropdownMenuItem(value: e, child: Text(e.name));
                  }).toList(),
                  onChanged: (v) => setState(() => wakeGroup = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<AircraftDescription>(
                  initialValue: description,
                  decoration: const InputDecoration(
                    labelText: 'Aircraft Description',
                    prefixIcon: Icon(Icons.description),
                  ),
                  items: AircraftDescription.values.map((e) {
                    return DropdownMenuItem(value: e, child: Text(e.name));
                  }).toList(),
                  onChanged: (v) => setState(() => description = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: engineCount.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Engine Count',
                    prefixIcon: Icon(Icons.power),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => engineCount = int.tryParse(v) ?? 1,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<EngineType>(
                  initialValue: engineType,
                  decoration: const InputDecoration(
                    labelText: 'Engine Type',
                    prefixIcon: Icon(Icons.settings),
                  ),
                  items: EngineType.values.map((e) {
                    return DropdownMenuItem(value: e, child: Text(e.name));
                  }).toList(),
                  onChanged: (v) => setState(() => engineType = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (modelCtrl.text.trim().isEmpty ||
                    manufacturerCtrl.text.trim().isEmpty) {
                  return;
                }
                final repository = ref.read(aircraftRepositoryProvider);
                await repository.addIcaoAircraft(
                  modelFullName: modelCtrl.text.trim(),
                  manufacturer: manufacturerCtrl.text.trim(),
                  designator: modelCtrl.text
                      .trim()
                      .substring(0, 4)
                      .toUpperCase(),
                  wakeTurbolenceCategory: wakeCategory,
                  wakeTurbolenceGroup: wakeGroup,
                  description: description,
                  engineCount: engineCount,
                  engineType: engineType,
                );
                if (ctx.mounted) Navigator.pop(ctx, true);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }
}

/// Stream provider for ICAO aircrafts
final icaoAircraftsStreamProvider = StreamProvider<List<IcaoAircraft>>((ref) {
  final repository = ref.watch(aircraftRepositoryProvider);
  return repository.watchAllIcaoAircrafts();
});
