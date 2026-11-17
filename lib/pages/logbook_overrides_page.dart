import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/fab_hero_tags.dart';
import '../models/logbook_entry.dart';
import '../providers/person_providers.dart';
import '../providers/user_provider.dart';
import '../repositories/flight_repository.dart';
import '../services/database.dart';
import '../utils/duration_formatter.dart';
import '../widgets/duration_field.dart';
import '../widgets/page_title.dart';
import '../widgets/section_header.dart';

/// Lets the pilot replace any value of a flight's logbook line, for the
/// exported logbook. Date, airports, times, aircraft and landings come from
/// the flight and can't be overridden here.
class LogbookOverridesPage extends ConsumerStatefulWidget {
  const LogbookOverridesPage({super.key, required this.flight});
  final FlightWithStats flight;

  @override
  ConsumerState<LogbookOverridesPage> createState() =>
      _LogbookOverridesPageState();
}

class _LogbookOverridesPageState extends ConsumerState<LogbookOverridesPage> {
  final _formKey = GlobalKey<FormState>();
  late LogbookOverrides _draft =
      widget.flight.flight.logbookOverrides ?? LogbookOverrides.empty;
  late final _picName = TextEditingController(text: _draft.picName ?? '');
  bool _saving = false;

  static const _sections = [
    (
      'TIME',
      [
        LogbookTimeField.total,
        LogbookTimeField.singlePilotSe,
        LogbookTimeField.singlePilotMe,
        LogbookTimeField.multiPilot,
      ],
    ),
    ('OPERATIONAL CONDITION', [LogbookTimeField.night, LogbookTimeField.ifr]),
    (
      'PILOT FUNCTION',
      [
        LogbookTimeField.pic,
        LogbookTimeField.coPilot,
        LogbookTimeField.dual,
        LogbookTimeField.instructor,
      ],
    ),
  ];

  @override
  void dispose() {
    _picName.dispose();
    super.dispose();
  }

  static String? _orNull(String text) => text.trim().isEmpty ? null : text;

  void _resetAll() {
    FocusScope.of(context).unfocus();
    _picName.clear();
    setState(() => _draft = LogbookOverrides.empty);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(flightRepositoryProvider)
          .setLogbookOverrides(widget.flight.flight.id, _draft);
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final crew =
        ref.watch(flightCrewProvider(widget.flight.flight.id)).value ??
        const <CrewMember>[];
    final selfPicName = ref.watch(picNameModeProvider) == PicNameMode.self
        ? 'SELF'
        : (ref.watch(userSignatureNameProvider) ?? '');
    final entry = LogbookEntry.of(
      widget.flight,
      crew: crew,
      selfPicName: selfPicName,
      overrides: _draft,
    );

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
          icon: const Icon(Icons.save),
          label: const Text('Save'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              const PageTitle(
                'Logbook Overrides',
                belowCloseButton: true,
                horizontalPadding: 0,
                bottomPadding: 0,
              ),
              const SizedBox(height: 4),
              Text(
                'Used in the exported logbook. Empty fields keep the '
                "flight's value.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              for (final (title, fields) in _sections) ...[
                _Section(
                  title: title,
                  children: [
                    for (final field in fields)
                      _TimeRow(
                        label: field.label,
                        computed: entry.computed[field]!,
                        value: _draft.times[field],
                        onChanged: (d) =>
                            setState(() => _draft = _draft.withTime(field, d)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              _Section(
                title: 'PIC NAME',
                children: [
                  _TextRow(
                    controller: _picName,
                    hint: entry.computedPicName,
                    onChanged: (text) => setState(
                      () => _draft = _draft.withPicName(_orNull(text)),
                    ),
                  ),
                ],
              ),
              if (_draft.isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _resetAll,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Reset all'),
                  ),
                ),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: title,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// A time column: the computed value as the hint, the override as the text.
/// The field sits against the card's edge; the button putting the computed
/// value back appears to its left once there is an override.
class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.label,
    required this.computed,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final Duration computed;
  final Duration? value;
  final ValueChanged<Duration?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overridden = value != null;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: overridden ? FontWeight.w600 : null,
            ),
          ),
        ),
        if (overridden)
          IconButton(
            tooltip: 'Use computed value',
            icon: const Icon(Icons.undo, size: 20),
            visualDensity: VisualDensity.compact,
            onPressed: () {
              FocusScope.of(context).unfocus();
              onChanged(null);
            },
          ),
        SizedBox(
          width: 64,
          child: DurationField(
            value: value,
            hintText: DurationFormatter.hm(computed),
            onChanged: onChanged,
            textAlign: TextAlign.end,
            style: theme.textTheme.titleMedium,
            decoration: const InputDecoration(
              isDense: true,
              filled: false,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: UnderlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}

/// A text value: the computed one as the hint, a clear button once there is
/// an override.
class _TextRow extends StatelessWidget {
  const _TextRow({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => TextFormField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint.isEmpty ? '—' : hint,
          suffixIcon: controller.text.trim().isEmpty
              ? null
              : IconButton(
                  tooltip: 'Use computed value',
                  icon: const Icon(Icons.undo, size: 20),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
