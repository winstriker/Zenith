import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logbook/main.dart';
import '../services/database.dart';
import '../providers/aircraft_providers.dart';
import '../widgets/aircraft_card.dart';

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
                  onTap: () => _showEditDialog(aws),
                );
              },
            ),
    );
  }

  Future<void> _showAddDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => _AircraftFormDialog(aircraft: null),
    );
    if (result == true) {
      ref.read(aircraftListProvider.notifier).refresh();
    }
  }

  Future<void> _showEditDialog(AircraftWithStats aws) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => _AircraftFormDialog(aircraft: aws.aircraft),
    );
    if (result == true) {
      ref.read(aircraftListProvider.notifier).refresh();
    }
  }
}

class _AircraftFormDialog extends ConsumerStatefulWidget {
  final Aircraft? aircraft;
  const _AircraftFormDialog({this.aircraft});

  @override
  ConsumerState<_AircraftFormDialog> createState() => _AircraftFormDialogState();
}

class _AircraftFormDialogState extends ConsumerState<_AircraftFormDialog> {
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
    final isEditing = widget.aircraft != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Aircraft' : 'Add Aircraft'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(
                  labelText: 'Model',
                  hintText: 'e.g. Cessna 172S Skyhawk',
                  prefixIcon: Icon(Icons.model_training),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tailController,
                decoration: const InputDecoration(
                  labelText: 'Tail Number',
                  hintText: 'e.g. N123AB',
                  prefixIcon: Icon(Icons.numbers),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Any additional info...',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (isEditing)
          TextButton(
            onPressed: () => _deleteAircraft(),
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            child: const Text('Delete'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(isEditing ? 'Save' : 'Add'),
        ),
      ],
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
