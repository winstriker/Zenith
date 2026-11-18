import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/fab_hero_tags.dart';
import '../repositories/aircraft_repository.dart';
import '../services/database.dart';
import '../utils/icao_designator.dart';
import '../widgets/page_title.dart';

/// Full-page form that adds a custom aircraft type, or edits [type] when
/// given. Pops the saved [IcaoAircraft].
class AircraftTypeFormPage extends ConsumerStatefulWidget {
  const AircraftTypeFormPage({super.key, this.type});

  /// When set, the page edits this custom type instead of adding one.
  final IcaoAircraft? type;

  @override
  ConsumerState<AircraftTypeFormPage> createState() =>
      _AircraftTypeFormPageState();
}

class _AircraftTypeFormPageState extends ConsumerState<AircraftTypeFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _designatorCtrl = TextEditingController(
    text: widget.type?.designator,
  );
  late final _modelCtrl = TextEditingController(
    text: widget.type?.modelFullName,
  );
  late final _manufacturerCtrl = TextEditingController(
    text: widget.type?.manufacturer,
  );
  late WakeTurbulenceCategory _wakeCategory =
      widget.type?.wakeTurbolenceCategory ?? WakeTurbulenceCategory.Z;
  late WakeTurbulenceGroup _wakeGroup =
      widget.type?.wakeTurbolenceGroup ?? WakeTurbulenceGroup.Z;
  late AircraftDescription _description =
      widget.type?.description ?? AircraftDescription.landplane;
  late int _engineCount = widget.type?.engineCount ?? 1;
  late EngineType _engineType = widget.type?.engineType ?? EngineType.piston;
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
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final modelFullName = _modelCtrl.text.trim();
    final manufacturer = _manufacturerCtrl.text.trim();
    final designator = _designatorCtrl.text.trim().toUpperCase();
    final repo = ref.read(aircraftRepositoryProvider);
    final existing = widget.type;
    final int id;
    if (existing == null) {
      id = await repo.addIcaoAircraft(
        modelFullName: modelFullName,
        manufacturer: manufacturer,
        designator: designator,
        wakeTurbolenceCategory: _wakeCategory,
        wakeTurbolenceGroup: _wakeGroup,
        description: _description,
        engineCount: _engineCount,
        engineType: _engineType,
      );
    } else {
      id = existing.id;
      await repo.updateIcaoAircraft(
        id,
        modelFullName: modelFullName,
        manufacturer: manufacturer,
        designator: designator,
        wakeTurbolenceCategory: _wakeCategory,
        wakeTurbolenceGroup: _wakeGroup,
        description: _description,
        engineCount: _engineCount,
        engineType: _engineType,
      );
    }
    if (!mounted) return;
    Navigator.pop(
      context,
      IcaoAircraft(
        id: id,
        modelFullName: modelFullName,
        designator: designator,
        wakeTurbolenceCategory: _wakeCategory,
        wakeTurbolenceGroup: _wakeGroup,
        manufacturer: manufacturer,
        description: _description,
        engineCount: _engineCount,
        engineType: _engineType,
        userInserted: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.type != null;
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: FloatingActionButton(
        heroTag: closeFabHeroTag,
        tooltip: 'Close',
        onPressed: () => Navigator.pop(context),
        child: const Icon(Icons.close),
      ),
      body: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          heroTag: primaryFabHeroTag,
          onPressed: _saving ? null : _save,
          icon: Icon(isEditing ? Icons.save : Icons.add),
          label: Text(isEditing ? 'Save' : 'Add'),
        ),
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            PageTitle(
              isEditing ? 'Edit Aircraft Type' : 'New Aircraft Type',
              belowCloseButton: true,
            ),
            Padding(
              // Bottom padding keeps the last field clear of the save button.
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _designatorCtrl,
                      autofocus: !isEditing,
                      decoration: const InputDecoration(
                        labelText: 'ICAO Type Designator *',
                        hintText: 'e.g. C172',
                        prefixIcon: Icon(Icons.tag),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.next,
                      inputFormatters: icaoDesignatorInputFormatters,
                      maxLength: icaoDesignatorLength,
                      validator: validateIcaoDesignator,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _modelCtrl,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
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
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Manufacturer *',
                        hintText: 'e.g. Custom Builder',
                        prefixIcon: Icon(Icons.factory),
                      ),
                      validator: _required,
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
