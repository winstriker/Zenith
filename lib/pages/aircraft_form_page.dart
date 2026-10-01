import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database.dart';
import '../repositories/aircraft_repository.dart';
import '../widgets/aircraft_details_card.dart';
import '../widgets/gradient_card.dart';
import '../widgets/info_chip.dart';
import '../widgets/model_card.dart';
import 'icao_aircraft_select_page.dart';

class AircraftFormPage extends ConsumerStatefulWidget {
  const AircraftFormPage({super.key, this.aircraft});
  final AircraftWithStats? aircraft;

  @override
  ConsumerState<AircraftFormPage> createState() => _AircraftFormPageState();
}

class _AircraftFormPageState extends ConsumerState<AircraftFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _tailController = TextEditingController();
  final _notesController = TextEditingController();

  IcaoAircraft? _selectedIcaoAircraft;

  @override
  void initState() {
    super.initState();
    _tailController.text = widget.aircraft?.aircraft.tailNumber ?? '';
    _notesController.text = widget.aircraft?.aircraft.notes ?? '';

    if (widget.aircraft != null) {
      _selectedIcaoAircraft = widget.aircraft!.icaoAircraft;
    }
  }

  @override
  void dispose() {
    _tailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _openTypeSelector() async {
    final selected = await Navigator.push<IcaoAircraft>(
      context,
      MaterialPageRoute(builder: (_) => const IcaoAircraftSelectPage()),
    );
    if (selected != null && mounted) {
      setState(() => _selectedIcaoAircraft = selected);
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
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pop(context),
        heroTag: "closeFab",
        child: const Icon(Icons.close),
      ),
      body: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _save,
          heroTag: "saveFab",
          label: Text(isEditing ? "Save" : "Add"),
          icon: Icon(isEditing ? Icons.save : Icons.add),
        ),
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: 280,
              //TODO: Aircraft image
              child: Container(
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
                    const SizedBox(height: 16),

                    ModelCard(
                      aircraft: _selectedIcaoAircraft,
                      onTap: _openTypeSelector,
                      useOuterPadding: false,
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
      ),
    );
  }
}
