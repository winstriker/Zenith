import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_page_route.dart';
import '../models/currency.dart';
import '../repositories/licence_repository.dart';
import '../services/database.dart';
import '../widgets/currency_widgets.dart';
import '../widgets/licence_form_widgets.dart';
import '../widgets/picker_sheet.dart';
import 'rating_detail_page.dart';

/// Adds a rating to [licence], or edits [rating] when given.
class RatingFormPage extends ConsumerStatefulWidget {
  const RatingFormPage({super.key, required this.licence, this.rating});

  final Licence licence;
  final LicenceRating? rating;

  @override
  ConsumerState<RatingFormPage> createState() => _RatingFormPageState();
}

class _RatingFormPageState extends ConsumerState<RatingFormPage> {
  late RatingKind _kind = widget.rating?.kind ?? _kinds.first;
  late AircraftClass? _class = widget.rating?.aircraftClass;
  late int? _level = widget.rating?.level;
  late final _name = TextEditingController(text: widget.rating?.name);
  late final _notes = TextEditingController(text: widget.rating?.notes);
  late DateTime? _issueDate = widget.rating?.issueDate;
  late DateTime? _lastCheck = widget.rating?.lastCheckDate;
  late DateTime? _expiry = widget.rating?.expiryDate;
  late bool _lightSingleEngine = widget.rating?.lightSingleEngine ?? false;
  List<String> _suggestions = const [];
  bool _saving = false;
  bool _submitted = false;

  AircraftCategory get _category => widget.licence.category;
  bool get _otherLicence => widget.licence.kind == LicenceKind.other;

  /// Kinds that make sense on the licence.
  late final List<RatingKind> _kinds = [
    for (final k in RatingKind.values)
      if (switch (k) {
        // The aeroplane class ratings, or the SPG class of a GPL.
        RatingKind.classRating =>
          _category == AircraftCategory.aeroplane ||
              _category == AircraftCategory.gyroplane ||
              _otherLicence,
        RatingKind.typeRating || RatingKind.night => !const [
          AircraftCategory.sailplane,
          AircraftCategory.balloon,
        ].contains(_category),
        // No IR for gyroplanes.
        RatingKind.instrument => !const [
          AircraftCategory.sailplane,
          AircraftCategory.balloon,
          AircraftCategory.gyroplane,
        ].contains(_category),
        // Article 4f(1): issued to CPL(A) and CPL(H) holders.
        RatingKind.vcaTypeRating =>
          (_category == AircraftCategory.aeroplane ||
                  _category == AircraftCategory.helicopter) &&
              const [
                LicenceKind.cpl,
                LicenceKind.atpl,
                LicenceKind.other,
              ].contains(widget.licence.kind),
        RatingKind.basicInstrument ||
        RatingKind.mountain => _category == AircraftCategory.aeroplane,
        _ => true,
      })
        k,
  ];

  /// Whether the rating is a helicopter type rating, which may be for a
  /// light single-engine type (FCL.740.H(a)(2)).
  bool get _helicopterType =>
      _kind == RatingKind.typeRating &&
      _category == AircraftCategory.helicopter;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    if (!_kind.hasName) {
      setState(() => _suggestions = const []);
      return;
    }
    final kind = _kind;
    final names = await ref
        .read(licenceRepositoryProvider)
        .ratingNameSuggestions(kind);
    if (mounted && kind == _kind) setState(() => _suggestions = names);
  }

  void _setKind(RatingKind kind) {
    setState(() {
      _kind = kind;
      _submitted = false;
    });
    _loadSuggestions();
  }

  /// Whether the rating has proficiency checks (or assessments of
  /// competence) worth recording.
  bool get _hasChecks => switch (_kind) {
    RatingKind.classRating ||
    RatingKind.typeRating ||
    RatingKind.vcaTypeRating ||
    RatingKind.instrument ||
    RatingKind.basicInstrument ||
    RatingKind.mountain ||
    RatingKind.instructor ||
    RatingKind.examiner => true,
    _ => false,
  };

  int? get _validityMonths =>
      _kind.validityFor(aircraftClass: _class, level: _level);

  /// The expiry the last check (or the issue) gives the rating: from the old
  /// expiry when the check was in the 3 months before it (FCL.740(a),
  /// FCL.625(b)), from the check otherwise.
  DateTime? get _suggestedExpiry {
    final months = _validityMonths;
    final base = _lastCheck ?? _issueDate;
    if (months == null || base == null) return null;
    final oldExpiry = widget.rating?.expiryDate;
    if (oldExpiry != null &&
        _lastCheck != null &&
        !dateOnly(base).isBefore(addMonths(dateOnly(oldExpiry), -3)) &&
        !dateOnly(base).isAfter(dateOnly(oldExpiry))) {
      return addMonths(dateOnly(oldExpiry), months);
    }
    return addMonths(dateOnly(base), months);
  }

  String? get _nameError {
    if (!_submitted || !_kind.hasName) return null;
    final optional = _kind == RatingKind.towing;
    return !optional && _name.text.trim().isEmpty
        ? '${_kind.nameLabel} is required.'
        : null;
  }

  String? get _classError =>
      _submitted && _kind == RatingKind.classRating && _class == null
      ? 'Choose the class.'
      : null;

  Future<void> _save() async {
    setState(() => _submitted = true);
    if (_nameError != null || _classError != null) return;
    setState(() => _saving = true);
    final name = _name.text.trim();
    final notes = _notes.text.trim();
    final companion = LicenceRatingsCompanion(
      licence: Value(widget.licence.id),
      kind: Value(_kind),
      aircraftClass: Value(_kind == RatingKind.classRating ? _class : null),
      name: Value(_kind.hasName && name.isNotEmpty ? name : null),
      level: Value(_kind == RatingKind.languageProficiency ? _level : null),
      issueDate: Value(_issueDate),
      lastCheckDate: Value(_hasChecks ? _lastCheck : null),
      // FCL.815(d): a mountain rating no longer expires.
      expiryDate: Value(_kind == RatingKind.mountain ? null : _expiry),
      lightSingleEngine: Value(_helicopterType && _lightSingleEngine),
      notes: Value(notes.isEmpty ? null : notes),
    );
    final repo = ref.read(licenceRepositoryProvider);
    final existing = widget.rating;
    if (existing != null) {
      await repo.updateRating(existing.id, companion);
      if (mounted) Navigator.pop(context);
      return;
    }
    final id = await repo.addRating(companion);
    await askForReminderPermission(ref);
    if (!mounted) return;
    // A new rating opens on its page, as a new licence does.
    await Navigator.pushReplacement(
      context,
      AppPageRoute<void>(
        builder: (_) =>
            RatingDetailPage(licenceId: widget.licence.id, ratingId: id),
      ),
    );
  }

  String get _title {
    final name = _name.text.trim();
    return switch (_kind) {
      RatingKind.classRating => _class?.label ?? 'Class rating',
      RatingKind.instrument => 'IR',
      RatingKind.basicInstrument => 'BIR',
      _ when _kind.hasName && name.isNotEmpty => name,
      _ => _kind.label,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggested = _suggestedExpiry;
    return LicenceFormScaffold(
      title: _title,
      subtitle: widget.licence.title,
      isEditing: widget.rating != null,
      saving: _saving,
      onSave: _save,
      children: [
        SelectField<RatingKind>(
          label: 'Kind',
          icon: ratingKindIcon(_kind),
          value: _kind,
          items: _kinds,
          itemLabel: (k) => k.label,
          onChanged: _setKind,
        ),
        if (_kind == RatingKind.classRating) ...[
          const SizedBox(height: 16),
          SelectField<AircraftClass>(
            label: 'Class',
            icon: Icons.flight,
            value: _class,
            items: AircraftClass.forCategory(_otherLicence ? null : _category),
            itemLabel: (c) => '${c.label} · ${c.description}',
            errorText: _classError,
            onChanged: (c) => setState(() => _class = c),
          ),
        ],
        if (_kind.hasName) ...[
          const SizedBox(height: 16),
          _NameField(
            key: ValueKey(_kind),
            controller: _name,
            label: _kind.nameLabel,
            hint: _kind.nameHint,
            errorText: _nameError,
            suggestions: _suggestions,
            onChanged: () => setState(() {}),
            isRequired: _kind != RatingKind.towing,
            capitalization: switch (_kind) {
              RatingKind.typeRating ||
              RatingKind.vcaTypeRating ||
              RatingKind.instructor ||
              RatingKind.examiner => TextCapitalization.characters,
              _ => TextCapitalization.sentences,
            },
          ),
        ],
        if (_helicopterType) ...[
          const SizedBox(height: 8),
          SwitchListTile(
            value: _lightSingleEngine,
            onChanged: (v) => setState(() => _lightSingleEngine = v),
            contentPadding: EdgeInsets.zero,
            title: const Text('Single-engine, up to 3 175 kg'),
            subtitle: const Text(
              'Maximum take-off mass up to 3 175 kg: may be revalidated with '
              '6 hours as PIC and a refresher training instead of a check '
              '(FCL.740.H(a)(2)).',
            ),
          ),
        ],
        if (_kind == RatingKind.languageProficiency) ...[
          const SizedBox(height: 16),
          Text('Level', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 4, label: Text('4 · Operational')),
              ButtonSegment(value: 5, label: Text('5 · Extended')),
              ButtonSegment(value: 6, label: Text('6 · Expert')),
            ],
            emptySelectionAllowed: true,
            selected: {?_level},
            onSelectionChanged: (s) =>
                setState(() => _level = s.isEmpty ? null : s.first),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Level 4 is valid 4 years, level 5 6 years, level 6 doesn\'t '
              'expire (FCL.055).',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        OptionalDateField(
          label: 'Issue date',
          value: _issueDate,
          lastDate: DateTime.now(),
          onChanged: (d) => setState(() => _issueDate = d),
        ),
        if (_hasChecks) ...[
          const SizedBox(height: 16),
          OptionalDateField(
            label: _kind == RatingKind.instructor
                ? 'Last assessment of competence'
                : 'Last proficiency check',
            icon: Icons.fact_check_outlined,
            value: _lastCheck,
            lastDate: DateTime.now(),
            onChanged: (d) => setState(() => _lastCheck = d),
          ),
        ],
        if (_kind == RatingKind.mountain)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'The mountain rating doesn\'t expire. Its privileges need 6 '
              'landings on mountain surfaces or a proficiency check in the '
              'last 2 years (FCL.815(d)).',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else ...[
          const SizedBox(height: 16),
          OptionalDateField(
            label: 'Valid until',
            icon: Icons.event_busy_outlined,
            value: _expiry,
            onChanged: (d) => setState(() => _expiry = d),
          ),
        ],
        if (_kind != RatingKind.mountain &&
            suggested != null &&
            suggested != _expiry) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: ActionChip(
              avatar: const Icon(Icons.auto_fix_high, size: 18),
              label: Text('Use ${formatLicenceDate(suggested)}'),
              tooltip: 'Expiry worked out from the last check or issue date',
              onPressed: () => setState(() => _expiry = suggested),
            ),
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

/// Text field for a rating's name, suggesting the names already used.
class _NameField extends StatefulWidget {
  const _NameField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.errorText,
    required this.suggestions,
    required this.onChanged,
    required this.capitalization,
    this.isRequired = true,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? errorText;
  final List<String> suggestions;
  final VoidCallback onChanged;
  final TextCapitalization capitalization;
  final bool isRequired;

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      optionsBuilder: (value) {
        final query = normalizeTypeRating(value.text);
        return widget.suggestions.where((s) {
          final option = normalizeTypeRating(s);
          return option.contains(query) && option != query;
        });
      },
      onSelected: (_) => widget.onChanged(),
      fieldViewBuilder: (context, controller, focusNode, onSubmit) => TextField(
        controller: controller,
        focusNode: focusNode,
        textCapitalization: widget.capitalization,
        onChanged: (_) => widget.onChanged(),
        decoration: InputDecoration(
          labelText: widget.isRequired ? '${widget.label} *' : widget.label,
          hintText: widget.hint,
          errorText: widget.errorText,
          prefixIcon: const Icon(Icons.edit_outlined),
        ),
      ),
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240, maxWidth: 360),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                for (final option in options)
                  ListTile(
                    title: Text(option),
                    onTap: () => onSelected(option),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
