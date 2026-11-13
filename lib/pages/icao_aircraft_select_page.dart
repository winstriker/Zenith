import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/aircraft_providers.dart';
import '../repositories/aircraft_repository.dart';
import '../services/database.dart';
import '../utils/icao_designator.dart';
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
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const _AddCustomIcaoDialog(),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }
}

class _AddCustomIcaoDialog extends ConsumerStatefulWidget {
  const _AddCustomIcaoDialog();

  @override
  ConsumerState<_AddCustomIcaoDialog> createState() =>
      _AddCustomIcaoDialogState();
}

class _AddCustomIcaoDialogState extends ConsumerState<_AddCustomIcaoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _designatorCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _manufacturerCtrl = TextEditingController();
  WakeTurbulenceCategory _wakeCategory = WakeTurbulenceCategory.Z;
  WakeTurbulenceGroup _wakeGroup = WakeTurbulenceGroup.Z;
  AircraftDescription _description = AircraftDescription.landplane;
  int _engineCount = 1;
  EngineType _engineType = EngineType.piston;
  bool _saving = false;

  @override
  void dispose() {
    _designatorCtrl.dispose();
    _modelCtrl.dispose();
    _manufacturerCtrl.dispose();
    super.dispose();
  }

  static String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await ref
        .read(aircraftRepositoryProvider)
        .addIcaoAircraft(
          modelFullName: _modelCtrl.text.trim(),
          manufacturer: _manufacturerCtrl.text.trim(),
          designator: _designatorCtrl.text.trim().toUpperCase(),
          wakeTurbolenceCategory: _wakeCategory,
          wakeTurbolenceGroup: _wakeGroup,
          description: _description,
          engineCount: _engineCount,
          engineType: _engineType,
        );
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Custom Aircraft Type'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _designatorCtrl,
                decoration: const InputDecoration(
                  labelText: 'ICAO Type Designator *',
                  hintText: 'e.g. C172',
                  prefixIcon: Icon(Icons.tag),
                ),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: icaoDesignatorInputFormatters,
                maxLength: icaoDesignatorLength,
                validator: validateIcaoDesignator,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _modelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Model Full Name *',
                  hintText: 'e.g. Custom Experimental',
                  prefixIcon: Icon(Icons.model_training),
                ),
                validator: _required,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _manufacturerCtrl,
                decoration: const InputDecoration(
                  labelText: 'Manufacturer *',
                  hintText: 'e.g. Custom Builder',
                  prefixIcon: Icon(Icons.factory),
                ),
                validator: _required,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<WakeTurbulenceCategory>(
                initialValue: _wakeCategory,
                decoration: const InputDecoration(
                  labelText: 'Wake Turbulence Category',
                  prefixIcon: Icon(Icons.waves),
                ),
                items: [
                  for (final e in WakeTurbulenceCategory.values)
                    DropdownMenuItem(value: e, child: Text(e.name)),
                ],
                onChanged: (v) => setState(() => _wakeCategory = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<WakeTurbulenceGroup>(
                initialValue: _wakeGroup,
                decoration: const InputDecoration(
                  labelText: 'Wake Turbulence Group',
                  prefixIcon: Icon(Icons.groups),
                ),
                items: [
                  for (final e in WakeTurbulenceGroup.values)
                    DropdownMenuItem(value: e, child: Text(e.name)),
                ],
                onChanged: (v) => setState(() => _wakeGroup = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AircraftDescription>(
                initialValue: _description,
                decoration: const InputDecoration(
                  labelText: 'Aircraft Description',
                  prefixIcon: Icon(Icons.description),
                ),
                items: [
                  for (final e in AircraftDescription.values)
                    DropdownMenuItem(value: e, child: Text(e.name)),
                ],
                onChanged: (v) => setState(() => _description = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _engineCount.toString(),
                decoration: const InputDecoration(
                  labelText: 'Engine Count',
                  prefixIcon: Icon(Icons.power),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1
                    ? 'Must be at least 1'
                    : null,
                onChanged: (v) => _engineCount = int.tryParse(v) ?? 1,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<EngineType>(
                initialValue: _engineType,
                decoration: const InputDecoration(
                  labelText: 'Engine Type',
                  prefixIcon: Icon(Icons.settings),
                ),
                items: [
                  for (final e in EngineType.values)
                    DropdownMenuItem(value: e, child: Text(e.name)),
                ],
                onChanged: (v) => setState(() => _engineType = v!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: const Text('Add'),
        ),
      ],
    );
  }
}

/// Stream provider for ICAO aircrafts
final icaoAircraftsStreamProvider = StreamProvider<List<IcaoAircraft>>((ref) {
  final repository = ref.watch(aircraftRepositoryProvider);
  return repository.watchAllIcaoAircrafts();
});
