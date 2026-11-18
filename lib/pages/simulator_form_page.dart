import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_page_route.dart';
import '../core/fab_hero_tags.dart';
import '../repositories/aircraft_repository.dart';
import '../repositories/simulator_repository.dart';
import '../services/database.dart';
import '../widgets/aircraft_class_card.dart';
import '../widgets/model_card.dart';
import '../widgets/page_title.dart';
import '../widgets/section_header.dart';
import 'icao_aircraft_select_page.dart';

/// Full-page form that adds a simulator, or edits [simulator] when given.
/// Pops `true` when the simulator was deleted, and the id of the new
/// simulator when one was added.
class SimulatorFormPage extends ConsumerStatefulWidget {
  const SimulatorFormPage({super.key, this.simulator});
  final SimulatorWithStats? simulator;

  @override
  ConsumerState<SimulatorFormPage> createState() => _SimulatorFormPageState();
}

class _SimulatorFormPageState extends ConsumerState<SimulatorFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _typeRating = TextEditingController();
  final _qualificationNumber = TextEditingController();
  final _organisation = TextEditingController();
  final _notes = TextEditingController();

  SimulatorKind _kind = SimulatorKind.ffs;
  String? _level;
  IcaoAircraft? _type;
  AircraftClass? _aircraftClass;

  /// While false, the class and type rating follow the aircraft type.
  bool _classSetByUser = false;
  bool _typeRatingSetByUser = false;

  /// Type ratings already given to aircraft and simulators, as shortcuts.
  List<String> _knownTypeRatings = const [];
  bool _saving = false;

  bool get _isEditing => widget.simulator != null;

  List<AircraftClass> get _candidates {
    final type = _type;
    if (type == null) return const [];
    return AircraftClass.candidatesFor(
      description: type.description,
      engineCount: type.engineCount,
      engineType: type.engineType,
    );
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.simulator;
    if (existing != null) {
      final s = existing.simulator;
      _kind = s.kind;
      _level = s.level;
      _type = existing.type;
      _aircraftClass = s.aircraftClass;
      _classSetByUser = s.aircraftClass != null;
      _typeRating.text = s.typeRating ?? '';
      _typeRatingSetByUser = s.typeRating != null;
      _qualificationNumber.text = s.qualificationNumber ?? '';
      _organisation.text = s.organisation ?? '';
      _notes.text = s.notes ?? '';
    }
    ref.read(aircraftRepositoryProvider).getTypeRatings().then((ratings) {
      if (mounted) setState(() => _knownTypeRatings = ratings);
    });
  }

  @override
  void dispose() {
    _typeRating.dispose();
    _qualificationNumber.dispose();
    _organisation.dispose();
    _notes.dispose();
    super.dispose();
  }

  /// Brings the class and the type rating in line with the selected type,
  /// unless the user chose them. Call inside setState.
  void _followType() {
    if (!_classSetByUser) {
      final candidates = _candidates;
      _aircraftClass = candidates.length == 1 ? candidates.single : null;
    }
    if (!_typeRatingSetByUser) {
      _typeRating.text = _aircraftClass == AircraftClass.type
          ? _type?.designator ?? ''
          : '';
    }
  }

  Future<void> _pickType() async {
    final picked = await Navigator.push<IcaoAircraft>(
      context,
      AppPageRoute(builder: (_) => const IcaoAircraftSelectPage()),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _type = picked;
      _followType();
    });
  }

  Future<void> _pickClass() async {
    final choice = await showAircraftClassPicker(
      context,
      selected: _aircraftClass,
      candidates: _candidates,
    );
    if (choice == null || !mounted) return;
    setState(() {
      _aircraftClass = choice.aircraftClass;
      _classSetByUser = true;
      if (!_typeRatingSetByUser) {
        _typeRating.text = _aircraftClass == AircraftClass.type
            ? _type?.designator ?? ''
            : '';
      }
    });
  }

  static String? _orNull(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repository = ref.read(simulatorRepositoryProvider);
    final row = SimulatorsCompanion(
      kind: Value(_kind),
      level: Value(_kind.levels.contains(_level) ? _level : null),
      icaoAircraft: Value(_type?.id),
      aircraftClass: Value(_aircraftClass),
      typeRating: Value(_typeRating.text),
      qualificationNumber: Value(_orNull(_qualificationNumber.text)),
      organisation: Value(_orNull(_organisation.text)),
      notes: Value(_orNull(_notes.text)),
    );
    try {
      final existing = widget.simulator;
      int? addedId;
      if (existing != null) {
        await repository.updateSimulator(existing.id, row);
      } else {
        addedId = await repository.addSimulator(row);
      }
      if (mounted) Navigator.pop(context, addedId);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  Future<void> _delete() async {
    final sim = widget.simulator!;
    final repository = ref.read(simulatorRepositoryProvider);
    final sessions = await repository.sessionCount(sim.id);
    if (!mounted) return;
    if (sessions > 0) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Simulator in use'),
          content: Text(
            '${sim.title} has $sessions logged '
            '${sessions == 1 ? 'session' : 'sessions'}. Delete them, or '
            'move them to another simulator, first.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Simulator'),
        content: Text('Delete "${sim.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
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
    if (confirmed != true || !mounted) return;
    final deleted = await repository.deleteSimulator(sim.id);
    if (mounted && deleted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
          label: Text(_isEditing ? 'Save' : 'Add'),
          icon: Icon(_isEditing ? Icons.save : Icons.add),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            // Bottom padding keeps the last field clear of the save button.
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
            children: [
              PageTitle(
                _isEditing ? 'Edit Simulator' : 'Add Simulator',
                belowCloseButton: true,
                horizontalPadding: 0,
                bottomPadding: 16,
              ),
              const SectionHeader(title: 'Device', uppercase: true),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final kind in SimulatorKind.values)
                    ChoiceChip(
                      label: Text(kind.label),
                      tooltip: kind.description,
                      selected: _kind == kind,
                      onSelected: (_) => setState(() {
                        _kind = kind;
                        if (!kind.levels.contains(_level)) _level = null;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _kind.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'A device qualified with an FSTD capability signature (FCS) '
                'is entered as the type and level its FCS is equivalent to '
                '(FCL.036).',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              if (_kind.levels.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Level', style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final level in _kind.levels)
                      ChoiceChip(
                        label: Text(level),
                        selected: _level == level,
                        onSelected: (selected) =>
                            setState(() => _level = selected ? level : null),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _qualificationNumber,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Qualification number',
                  hintText: 'e.g. Q1234',
                  prefixIcon: const Icon(Icons.verified_outlined),
                  helperText: _kind.loggedByType
                      ? 'Written in the logbook next to the aircraft type.'
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _organisation,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Training organisation',
                  hintText: 'Operator or ATO, and where',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Represents', uppercase: true),
              const SizedBox(height: 8),
              ModelCard(
                aircraft: _type,
                onTap: _pickType,
                useOuterPadding: false,
              ),
              if (_type != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setState(() {
                      _type = null;
                      _followType();
                    }),
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Generic device, no type'),
                  ),
                ),
              const SizedBox(height: 8),
              AircraftClassCard(
                aircraftClass: _aircraftClass,
                candidates: _candidates,
                onTap: _pickClass,
              ),
              if (_aircraftClass == AircraftClass.type) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _typeRating,
                  decoration: const InputDecoration(
                    labelText: 'Type rating *',
                    hintText: 'As on your licence, e.g. A320',
                    prefixIcon: Icon(Icons.badge_outlined),
                    helperText:
                        'The same name as your aircraft of that type, so '
                        'checks and FFS landings count for the rating.',
                    helperMaxLines: 3,
                  ),
                  onChanged: (_) => _typeRatingSetByUser = true,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Type rating is required.'
                      : null,
                ),
                ListenableBuilder(
                  listenable: _typeRating,
                  builder: (context, _) {
                    final current = _typeRating.text.trim();
                    final others = [
                      for (final r in _knownTypeRatings)
                        if (r != current) r,
                    ];
                    if (others.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final rating in others)
                            ActionChip(
                              label: Text(rating),
                              onPressed: () => setState(() {
                                _typeRating.text = rating;
                                _typeRatingSetByUser = true;
                              }),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 24),
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Any additional info...',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 3,
              ),
              if (_isEditing) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _delete,
                    style: TextButton.styleFrom(foregroundColor: cs.error),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete Simulator'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
