import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/aircraft_providers.dart';
import '../repositories/aircraft_repository.dart';
import '../services/database.dart';
import '../utils/icao_designator.dart';
import '../utils/icao_type_matcher.dart';
import '../widgets/empty_state.dart';
import '../widgets/model_card.dart';

class IcaoAircraftSelectPage extends ConsumerStatefulWidget {
  const IcaoAircraftSelectPage({
    super.key,
    this.suggestFor,
    this.suggestDesignator,
    this.suggestNames = const [],
  });

  /// An aircraft name found elsewhere (e.g. "Cessna 172R Skyhawk II"), shown
  /// above the types that best fit it. Those are listed first, until the
  /// user searches.
  final String? suggestFor;

  /// What else is known about that aircraft, to find the fitting types: its
  /// ICAO designator and other names it goes by.
  final String? suggestDesignator;
  final List<String> suggestNames;

  @override
  ConsumerState<IcaoAircraftSelectPage> createState() =>
      _IcaoAircraftSelectPageState();
}

class _IcaoAircraftSelectPageState
    extends ConsumerState<IcaoAircraftSelectPage> {
  final _searchController = TextEditingController();
  String _query = '';

  // Suggestions are only recomputed when the list of types changes.
  List<IcaoAircraft>? _suggestedFrom;
  List<IcaoAircraft> _suggestions = const [];

  List<IcaoAircraft> _suggestionsFrom(List<IcaoAircraft> icaoList) {
    final name = widget.suggestFor;
    if (name == null) return const [];
    if (!identical(_suggestedFrom, icaoList)) {
      _suggestedFrom = icaoList;
      _suggestions = IcaoTypeMatcher.resolve(
        designator: widget.suggestDesignator,
        names: {name, ...widget.suggestNames}.toList(),
        types: icaoList,
      ).suggestions;
    }
    return _suggestions;
  }

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
        final filtered = _query.isEmpty ? icaoList : _filter(icaoList);
        final suggestions = _query.isEmpty
            ? _suggestionsFrom(icaoList)
            : const <IcaoAircraft>[];
        // With suggestions, the list starts with a header, the suggestions
        // and a second header above all the types.
        final leading = suggestions.isEmpty ? 0 : suggestions.length + 2;

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
                  // The keyboard would hide the suggestions.
                  autofocus: widget.suggestFor == null,
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
                        itemCount: leading + filtered.length,

                        itemBuilder: (context, index) {
                          if (index < leading) {
                            if (index == 0) {
                              return _ListHeader(
                                'Suggested for “${widget.suggestFor}”',
                              );
                            }
                            if (index == leading - 1) {
                              return const _ListHeader('All types');
                            }
                            final icao = suggestions[index - 1];
                            return ModelCard(
                              aircraft: icao,
                              onTap: () => Navigator.pop(context, icao),
                            );
                          }
                          final icao = filtered[index - leading];
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

  /// Splits the query into words; an aircraft matches when every word is
  /// found in its designator, model name or manufacturer (so "Cessna C150"
  /// works). Results with a word equal to the designator come first, then
  /// those with a word that prefixes it, then everything else, preserving
  /// the original order within each group.
  List<IcaoAircraft> _filter(List<IcaoAircraft> icaoList) {
    final tokens = _query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    final exact = <IcaoAircraft>[];
    final prefix = <IcaoAircraft>[];
    final other = <IcaoAircraft>[];
    for (final icao in icaoList) {
      final d = icao.designator.toLowerCase();
      final haystack =
          '$d ${icao.modelFullName.toLowerCase()} '
          '${icao.manufacturer.toLowerCase()}';
      if (!tokens.every(haystack.contains)) continue;
      if (tokens.contains(d)) {
        exact.add(icao);
      } else if (tokens.any(d.startsWith)) {
        prefix.add(icao);
      } else {
        other.add(icao);
      }
    }
    return [...exact, ...prefix, ...other];
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

class _ListHeader extends StatelessWidget {
  const _ListHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
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
