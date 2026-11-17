import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/licence_repository.dart';
import '../services/database.dart';
import '../widgets/licence_form_widgets.dart';

/// Adds a medical certificate, or edits [medical] when given.
class MedicalFormPage extends ConsumerStatefulWidget {
  const MedicalFormPage({super.key, this.medical});

  final MedicalCertificate? medical;

  @override
  ConsumerState<MedicalFormPage> createState() => _MedicalFormPageState();
}

class _MedicalFormPageState extends ConsumerState<MedicalFormPage> {
  late MedicalClass _class =
      widget.medical?.medicalClass ?? MedicalClass.class2;
  late DateTime? _examination = widget.medical?.examinationDate;
  late DateTime? _expiry = widget.medical?.expiryDate;
  late final _limitations = TextEditingController(
    text: widget.medical?.limitations,
  );
  late final _notes = TextEditingController(text: widget.medical?.notes);
  bool _saving = false;
  bool _submitted = false;

  @override
  void dispose() {
    _limitations.dispose();
    _notes.dispose();
    super.dispose();
  }

  static Value<String?> _text(TextEditingController c) {
    final text = c.text.trim();
    return Value(text.isEmpty ? null : text);
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    final expiry = _expiry;
    if (expiry == null) return;
    setState(() => _saving = true);
    final companion = MedicalCertificatesCompanion(
      medicalClass: Value(_class),
      examinationDate: Value(_examination),
      expiryDate: Value(expiry),
      limitations: _text(_limitations),
      notes: _text(_notes),
    );
    final repo = ref.read(licenceRepositoryProvider);
    final existing = widget.medical;
    if (existing == null) {
      await repo.addMedical(companion);
      await askForReminderPermission(ref);
    } else {
      await repo.updateMedical(existing.id, companion);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LicenceFormScaffold(
      title: 'Medical ${_class.label}',
      isEditing: widget.medical != null,
      saving: _saving,
      onSave: _save,
      children: [
        Text('Class', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<MedicalClass>(
          segments: [
            for (final c in MedicalClass.values)
              ButtonSegment(
                value: c,
                label: Text(
                  (c == MedicalClass.class1 || c == MedicalClass.class2)
                      ? c.label.replaceFirst('Class ', '')
                      : c.label,
                ),
              ),
          ],
          selected: {_class},
          onSelectionChanged: (s) => setState(() => _class = s.first),
        ),
        const SizedBox(height: 24),
        OptionalDateField(
          label: 'Examination date',
          value: _examination,
          lastDate: DateTime.now(),
          onChanged: (d) => setState(() => _examination = d),
        ),
        const SizedBox(height: 16),
        OptionalDateField(
          label: 'Valid until *',
          icon: Icons.event_busy_outlined,
          value: _expiry,
          errorText: _submitted && _expiry == null
              ? 'The expiry date is required.'
              : null,
          onChanged: (d) => setState(() => _expiry = d),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _limitations,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Limitations',
            hintText: 'e.g. VML',
            prefixIcon: Icon(Icons.visibility_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _notes,
          minLines: 1,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Notes',
            prefixIcon: Icon(Icons.notes),
          ),
        ),
      ],
    );
  }
}
