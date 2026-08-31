import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logbook/main.dart';
import '../services/database.dart';

class AircraftFormPage extends ConsumerStatefulWidget {
  final Aircraft? aircraft;
  const AircraftFormPage({super.key, this.aircraft});

  @override
  ConsumerState<AircraftFormPage> createState() => _AircraftFormPageState();
}

class _AircraftFormPageState extends ConsumerState<AircraftFormPage> {
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
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
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
