import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database.dart';
import '../repositories/aircraft_repository.dart';

class AircraftFormPage extends ConsumerStatefulWidget {
  const AircraftFormPage({super.key, this.aircraft});
  final AircraftWithStats? aircraft;

  @override
  ConsumerState<AircraftFormPage> createState() => _AircraftFormPageState();
}

class _AircraftFormPageState extends ConsumerState<AircraftFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _tailController = TextEditingController();
  final _searchController = TextEditingController();
  final _notesController = TextEditingController();

  List<IcaoAircraft> _searchResults = [];
  IcaoAircraft? _selectedIcaoAircraft;
  bool _isSearching = false;
  bool _showAddCustom = false;

  // Custom aircraft form controllers
  final _customDesignatorController = TextEditingController();
  final _customModelController = TextEditingController();
  final _customManufacturerController = TextEditingController();
  WakeTurbolenceCategory _customWakeCategory = WakeTurbolenceCategory.Z;
  WakeTurbolenceGroup _customWakeGroup = WakeTurbolenceGroup.Z;
  AircraftDescription _customDescription = AircraftDescription.landplane;
  int _customEngineCount = 1;
  EngineType _customEngineType = EngineType.piston;

  @override
  void initState() {
    super.initState();
    _notesController.text = widget.aircraft?.aircraft.notes ?? '';

    if (widget.aircraft != null) {
      _selectedIcaoAircraft = widget.aircraft!.icaoAircraft;
      _searchController.text = widget.aircraft!.modelFullName;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    _customModelController.dispose();
    _customManufacturerController.dispose();
    super.dispose();
  }

  Future<void> _searchIcaoAircrafts(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final repository = ref.read(aircraftRepositoryProvider);
      final results = await repository.searchIcaoAircrafts(query.trim());
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _addCustomIcaoAircraft() async {
    if (_customModelController.text.trim().isEmpty ||
        _customManufacturerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Model and Manufacturer are required')),
      );
      return;
    }

    try {
      final repository = ref.read(aircraftRepositoryProvider);
      final icaoId = await repository.addIcaoAircraft(
        modelFullName: _customModelController.text.trim(),
        manufacturer: _customManufacturerController.text.trim(),
        designator: _customDesignatorController.text.trim(),
        wakeTurbolenceCategory: _customWakeCategory,
        wakeTurbolenceGroup: _customWakeGroup,
        description: _customDescription,
        engineCount: _customEngineCount,
        engineType: _customEngineType,
      );

      final icaoAircraft = IcaoAircraft(
        id: icaoId,
        designator: _customDesignatorController.text.trim(),
        modelFullName: _customModelController.text.trim(),
        wakeTurbolenceCategory: _customWakeCategory,
        wakeTurbolenceGroup: _customWakeGroup,
        manufacturer: _customManufacturerController.text.trim(),
        description: _customDescription,
        engineCount: _customEngineCount,
        engineType: _customEngineType,
        userInserted: true,
      );

      if (mounted) {
        setState(() {
          _selectedIcaoAircraft = icaoAircraft;
          _searchController.text = icaoAircraft.modelFullName;
          _searchResults = [];
          _showAddCustom = false;
          _customModelController.clear();
          _customManufacturerController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add aircraft type: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedIcaoAircraft == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an aircraft type')),
      );
      return;
    }

    try {
      final repository = ref.read(aircraftRepositoryProvider);

      if (widget.aircraft != null) {
        await repository.updateAircraft(
          widget.aircraft!.aircraft.id,
          icaoAircraftId: _selectedIcaoAircraft!.id,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
      } else {
        await repository.addAircraft(
          tailNumber: _tailController.text.trim(),
          icaoAircraftId: _selectedIcaoAircraft!.id,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  Future<void> _deleteAircraft() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Aircraft'),
        content: Text(
          'Delete "${widget.aircraft!.modelFullName}"? Flights using this aircraft will be unlinked.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final repository = ref.read(aircraftRepositoryProvider);
      await repository.deleteAircraft(widget.aircraft!.aircraft.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isEditing = widget.aircraft != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Aircraft' : 'Add Aircraft')),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
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
                        isEditing
                            ? widget.aircraft!.modelFullName
                            : 'New Aircraft',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isEditing
                            ? 'Edit the details below'
                            : 'Select an aircraft type and enter details',
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
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _tailController,
                    decoration: const InputDecoration(
                      labelText: 'Tail Number *',
                      hintText: 'e.g. I-ABCD',
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Tail number is required.'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Model *',
                      hintText: 'e.g. Cessna 172 Skyhawk, Boeing 737...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      _searchIcaoAircrafts(value);
                      // Clear selection when user types
                      if (_selectedIcaoAircraft?.modelFullName != value) {
                        setState(() => _selectedIcaoAircraft = null);
                      }
                    },
                    validator: (value) {
                      if (_selectedIcaoAircraft == null) {
                        return 'Please select an aircraft type';
                      }
                      return null;
                    },
                  ),

                  // Search Results
                  if (_searchResults.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        border: Border.all(color: cs.outlineVariant),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, _) =>
                            Divider(height: 1, color: cs.outlineVariant),
                        itemBuilder: (context, index) {
                          final icao = _searchResults[index];
                          final isSelected =
                              _selectedIcaoAircraft?.id == icao.id;
                          return ListTile(
                            selected: isSelected,
                            selectedTileColor: cs.primaryContainer.withValues(
                              alpha: 0.3,
                            ),
                            title: Text(icao.modelFullName),
                            subtitle: Text(
                              '${icao.manufacturer} • ${icao.wakeTurbolenceCategory.name}/${icao.wakeTurbolenceGroup.name}',
                            ),
                            trailing: icao.userInserted
                                ? Chip(
                                    label: const Text(
                                      'Custom',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                    backgroundColor: cs.secondaryContainer,
                                  )
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedIcaoAircraft = icao;
                                _searchController.text = icao.modelFullName;
                                _searchResults = [];
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],

                  // Add Custom Option
                  if (_searchResults.isEmpty &&
                      _searchController.text.isNotEmpty &&
                      !_showAddCustom) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => setState(() => _showAddCustom = true),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Aircraft not found? Add custom type'),
                    ),
                  ],

                  // Custom Aircraft Form
                  if (_showAddCustom) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add Custom Aircraft Type',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _customModelController,
                              decoration: const InputDecoration(
                                labelText: 'Model Full Name *',
                                hintText: 'e.g. Custom Experimental',
                                prefixIcon: Icon(Icons.model_training),
                              ),
                              validator: (value) =>
                                  (value == null || value.trim().isEmpty)
                                  ? 'Model name is required.'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _customManufacturerController,
                              decoration: const InputDecoration(
                                labelText: 'Manufacturer *',
                                hintText: 'e.g. Custom Builder',
                                prefixIcon: Icon(Icons.factory),
                              ),
                              validator: (value) =>
                                  (value == null || value.trim().isEmpty)
                                  ? 'Manufacturer is required.'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<WakeTurbolenceCategory>(
                              value: _customWakeCategory,
                              decoration: const InputDecoration(
                                labelText: 'Wake Turbulence Category',
                                prefixIcon: Icon(Icons.waves),
                              ),
                              items: WakeTurbolenceCategory.values.map((e) {
                                return DropdownMenuItem(
                                  value: e,
                                  child: Text(e.name),
                                );
                              }).toList(),
                              onChanged: (v) =>
                                  setState(() => _customWakeCategory = v!),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<WakeTurbolenceGroup>(
                              value: _customWakeGroup,
                              decoration: const InputDecoration(
                                labelText: 'Wake Turbulence Group',
                                prefixIcon: Icon(Icons.groups),
                              ),
                              items: WakeTurbolenceGroup.values.map((e) {
                                return DropdownMenuItem(
                                  value: e,
                                  child: Text(e.name),
                                );
                              }).toList(),
                              onChanged: (v) =>
                                  setState(() => _customWakeGroup = v!),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<AircraftDescription>(
                              value: _customDescription,
                              decoration: const InputDecoration(
                                labelText: 'Aircraft Description',
                                prefixIcon: Icon(Icons.description),
                              ),
                              items: AircraftDescription.values.map((e) {
                                return DropdownMenuItem(
                                  value: e,
                                  child: Text(e.name),
                                );
                              }).toList(),
                              onChanged: (v) =>
                                  setState(() => _customDescription = v!),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              initialValue: _customEngineCount.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Engine Count',
                                prefixIcon: Icon(Icons.power),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (v) =>
                                  _customEngineCount = int.tryParse(v) ?? 1,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<EngineType>(
                              value: _customEngineType,
                              decoration: const InputDecoration(
                                labelText: 'Engine Type',
                                prefixIcon: Icon(Icons.settings),
                              ),
                              items: EngineType.values.map((e) {
                                return DropdownMenuItem(
                                  value: e,
                                  child: Text(e.name),
                                );
                              }).toList(),
                              onChanged: (v) =>
                                  setState(() => _customEngineType = v!),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _addCustomIcaoAircraft,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Aircraft Type'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Selected Aircraft Preview
                  if (_selectedIcaoAircraft != null) ...[
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selected Aircraft Type',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedIcaoAircraft!.modelFullName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manufacturer: ${_selectedIcaoAircraft!.manufacturer}',
                              style: theme.textTheme.bodyMedium,
                            ),
                            Text(
                              'Wake: ${_selectedIcaoAircraft!.wakeTurbolenceCategory.name}/${_selectedIcaoAircraft!.wakeTurbolenceGroup.name} • '
                              'Engines: ${_selectedIcaoAircraft!.engineCount} (${_selectedIcaoAircraft!.engineType.name})',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            if (_selectedIcaoAircraft!.userInserted) ...[
                              const SizedBox(height: 4),
                              Chip(
                                label: const Text(
                                  'Custom Type',
                                  style: TextStyle(fontSize: 10),
                                ),
                                backgroundColor: cs.secondaryContainer,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
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
                      style: TextButton.styleFrom(foregroundColor: cs.error),
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
}
