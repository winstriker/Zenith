import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/fab_hero_tags.dart';
import '../repositories/pilot_profile_repository.dart';
import '../services/database.dart';
import '../widgets/duration_field.dart';
import '../widgets/page_title.dart';
import '../widgets/section_header.dart';

/// Lets the pilot enter the totals of the logbook they kept before the app.
/// They are carried forward into the first page of the exported logbook,
/// and counted in the app's totals.
///
/// Pops true once saved.
class PreviousTotalsPage extends ConsumerStatefulWidget {
  const PreviousTotalsPage({super.key});

  @override
  ConsumerState<PreviousTotalsPage> createState() => _PreviousTotalsPageState();
}

class _PreviousTotalsPageState extends ConsumerState<PreviousTotalsPage> {
  final _formKey = GlobalKey<FormState>();

  /// Null until the saved totals are loaded.
  PreviousTotals? _draft;
  bool _saving = false;

  /// Bumped by "Clear all", so the fields start over empty.
  int _generation = 0;

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
        LogbookTimeField.picus,
        LogbookTimeField.coPilot,
        LogbookTimeField.dual,
        LogbookTimeField.instructor,
      ],
    ),
    ('FSTD SESSIONS', [LogbookTimeField.fstd]),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await ref.read(pilotProfileRepositoryProvider).get();
    if (!mounted) return;
    setState(() => _draft = profile?.previousTotals ?? PreviousTotals.empty);
  }

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(pilotProfileRepositoryProvider).setPreviousTotals(draft);
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _clearAll() {
    FocusScope.of(context).unfocus();
    setState(() {
      _draft = PreviousTotals.empty;
      _generation++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = _draft;

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
          onPressed: _saving || draft == null ? null : _save,
          icon: const Icon(Icons.save),
          label: const Text('Save'),
        ),
        body: draft == null
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    const PageTitle(
                      'Previous Logbook',
                      belowCloseButton: true,
                      horizontalPadding: 0,
                      bottomPadding: 0,
                    ),
                    const SizedBox(height: 16),
                    for (final (title, fields) in _sections) ...[
                      _Section(
                        title: title,
                        children: [
                          for (final field in fields)
                            _Row(
                              label: field.label,
                              child: DurationField(
                                key: ValueKey((field, _generation)),
                                value: draft.times[field],
                                maxHourDigits: 5,
                                hintText: '0:00',
                                textAlign: TextAlign.end,
                                style: theme.textTheme.titleMedium,
                                decoration: _fieldDecoration,
                                onChanged: (d) => setState(
                                  () => _draft = _draft!.withTime(field, d),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    _Section(
                      title: 'LANDINGS',
                      children: [
                        _Row(
                          label: 'Day',
                          child: _CountField(
                            key: ValueKey(('day', _generation)),
                            value: draft.dayLandings,
                            onChanged: (n) => setState(
                              () => _draft = _draft!.withLandings(day: n),
                            ),
                          ),
                        ),
                        _Row(
                          label: 'Night',
                          child: _CountField(
                            key: ValueKey(('night', _generation)),
                            value: draft.nightLandings,
                            onChanged: (n) => setState(
                              () => _draft = _draft!.withLandings(night: n),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (draft.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _clearAll,
                          icon: const Icon(Icons.restart_alt),
                          label: const Text('Clear all'),
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

const _fieldDecoration = InputDecoration(
  isDense: true,
  filled: false,
  contentPadding: EdgeInsets.symmetric(vertical: 12),
  border: InputBorder.none,
  enabledBorder: InputBorder.none,
  focusedBorder: UnderlineInputBorder(),
);

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

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ),
        SizedBox(width: 96, child: child),
      ],
    );
  }
}

/// A whole number, empty for zero.
class _CountField extends StatelessWidget {
  const _CountField({super.key, required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value == 0 ? '' : '$value',
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      textAlign: TextAlign.end,
      style: Theme.of(context).textTheme.titleMedium,
      decoration: _fieldDecoration.copyWith(hintText: '0'),
      onChanged: (text) => onChanged(int.tryParse(text) ?? 0),
    );
  }
}
