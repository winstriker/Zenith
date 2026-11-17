import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_page_route.dart';
import '../repositories/licence_repository.dart';
import '../services/database.dart';
import '../widgets/licence_form_widgets.dart';
import 'licence_detail_page.dart';

/// Creates a licence, or edits [licence] when given. A new licence opens on
/// its page once saved, for its ratings to be added.
class LicenceFormPage extends ConsumerStatefulWidget {
  const LicenceFormPage({super.key, this.licence});

  final Licence? licence;

  @override
  ConsumerState<LicenceFormPage> createState() => _LicenceFormPageState();
}

class _LicenceFormPageState extends ConsumerState<LicenceFormPage> {
  late LicenceKind _kind = widget.licence?.kind ?? LicenceKind.ppl;
  late AircraftCategory _category =
      widget.licence?.category ?? AircraftCategory.aeroplane;
  late final _number = TextEditingController(text: widget.licence?.number);
  late final _issuedBy = TextEditingController(text: widget.licence?.issuedBy);
  late final _notes = TextEditingController(text: widget.licence?.notes);
  late DateTime? _issueDate = widget.licence?.issueDate;
  late DateTime? _checkDate = widget.licence?.proficiencyCheckDate;
  bool _saving = false;

  bool get _isLaplA =>
      _kind == LicenceKind.lapl && _category == AircraftCategory.aeroplane;

  @override
  void dispose() {
    _number.dispose();
    _issuedBy.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _setKind(LicenceKind kind) {
    setState(() {
      _kind = kind;
      if (!kind.categories.contains(_category)) {
        _category = kind.categories.first;
      }
    });
  }

  static Value<String?> _text(TextEditingController c) {
    final text = c.text.trim();
    return Value(text.isEmpty ? null : text);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final repo = ref.read(licenceRepositoryProvider);
    final companion = LicencesCompanion(
      kind: Value(_kind),
      category: Value(_category),
      number: _text(_number),
      issuedBy: _text(_issuedBy),
      issueDate: Value(_issueDate),
      proficiencyCheckDate: Value(_isLaplA ? _checkDate : null),
      notes: _text(_notes),
    );
    final existing = widget.licence;
    if (existing != null) {
      await repo.updateLicence(existing.id, companion);
      if (mounted) Navigator.pop(context);
      return;
    }
    final id = await repo.addLicence(companion);
    await askForReminderPermission(ref);
    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      AppPageRoute<void>(builder: (_) => LicenceDetailPage(licenceId: id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _kind == LicenceKind.other
        ? 'Licence (${_category.suffix})'
        : '${_kind.label}(${_category.suffix})';
    return LicenceFormScaffold(
      title: title,
      subtitle: _kind.description,
      isEditing: widget.licence != null,
      saving: _saving,
      onSave: _save,
      children: [
        DropdownButtonFormField<LicenceKind>(
          initialValue: _kind,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Licence',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
          items: [
            for (final k in LicenceKind.values)
              DropdownMenuItem(
                value: k,
                child: Text(
                  k == LicenceKind.other
                      ? k.description
                      : '${k.label} · ${k.description}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (k) => _setKind(k!),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<AircraftCategory>(
          key: ValueKey(_kind),
          initialValue: _category,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Aircraft category',
            prefixIcon: Icon(Icons.category_outlined),
          ),
          items: [
            for (final c in _kind.categories)
              DropdownMenuItem(
                value: c,
                child: Text('${c.label} (${c.suffix})'),
              ),
          ],
          onChanged: (c) => setState(() => _category = c!),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _number,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Licence number',
            prefixIcon: Icon(Icons.numbers),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _issuedBy,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Issued by',
            hintText: 'e.g. ENAC, LBA, DGAC',
            prefixIcon: Icon(Icons.account_balance_outlined),
          ),
        ),
        const SizedBox(height: 16),
        OptionalDateField(
          label: 'Issue date',
          value: _issueDate,
          lastDate: DateTime.now(),
          onChanged: (d) => setState(() => _issueDate = d),
        ),
        if (_isLaplA) ...[
          const SizedBox(height: 16),
          OptionalDateField(
            label: 'Last proficiency check',
            icon: Icons.fact_check_outlined,
            value: _checkDate,
            lastDate: DateTime.now(),
            helperText:
                'A proficiency check with an examiner keeps a LAPL(A) recent '
                'for 2 years (FCL.140.A).',
            onChanged: (d) => setState(() => _checkDate = d),
          ),
        ],
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
