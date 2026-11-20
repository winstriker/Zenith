import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/fab_hero_tags.dart';
import '../repositories/airport_repository.dart';
import '../services/database.dart';
import '../widgets/logbook_override_widgets.dart';
import '../widgets/page_title.dart';

/// Lets the pilot choose how an airport is written in the PLACE columns of
/// the exported logbook, its ident by default, and the note describing it
/// under the pages that use it: by default only for airports without an
/// ICAO code (AMC1 FCL.050(i)(3)), worked out from the airport's data.
class AirportLogbookPage extends ConsumerStatefulWidget {
  const AirportLogbookPage({super.key, required this.airport});
  final Airport airport;

  @override
  ConsumerState<AirportLogbookPage> createState() => _AirportLogbookPageState();
}

class _AirportLogbookPageState extends ConsumerState<AirportLogbookPage> {
  late final _ident = TextEditingController(
    text: widget.airport.logbookIdent ?? '',
  );
  late final _note = TextEditingController(
    text: widget.airport.logbookNote ?? '',
  );

  /// Null: the default, a note only when the airport has no ICAO code.
  late bool? _annotate = widget.airport.logbookAnnotate;
  bool _saving = false;

  @override
  void dispose() {
    _ident.dispose();
    _note.dispose();
    super.dispose();
  }

  void _resetAll() {
    FocusScope.of(context).unfocus();
    _ident.clear();
    _note.clear();
    setState(() => _annotate = null);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(airportRepositoryProvider)
          .setLogbookEntry(
            widget.airport.id,
            ident: _ident.text,
            annotate: _annotate,
            note: _note.text,
          );
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final airport = widget.airport;
    // The page as it stands, for the preview.
    final draft = airport.copyWith(
      logbookIdent: Value(_ident.text),
      logbookAnnotate: Value(_annotate),
      logbookNote: Value(_note.text),
    );
    final annotate = _annotate ?? airport.needsLogbookNote;

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
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            const PageTitle(
              'Logbook Overrides',
              belowCloseButton: true,
              horizontalPadding: 0,
              bottomPadding: 0,
            ),
            const SizedBox(height: 16),
            LogbookOverrideSection(
              title: 'DEPARTURE · ARRIVAL · PLACE',
              children: [
                LogbookOverrideTextRow(
                  controller: _ident,
                  label: 'Identifier',
                  hint: airport.ident ?? '',
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
              ],
            ),
            const SizedBox(height: 16),
            LogbookOverrideSection(
              title: 'NOTE UNDER THE PAGE',
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Describe the airport'),
                  value: annotate,
                  // Back to null when it matches the default again.
                  onChanged: (v) => setState(
                    () => _annotate = v == airport.needsLogbookNote ? null : v,
                  ),
                ),
                if (annotate) ...[
                  LogbookOverrideTextRow(
                    controller: _note,
                    label: 'Note',
                    hint: airport.defaultLogbookNote(draft.logbookPlace),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
            const SizedBox(height: 16),
            LogbookOverrideSection(
              title: 'IN THE LOGBOOK',
              children: [
                const SizedBox(height: 8),
                _Preview(
                  place: draft.logbookPlace,
                  note: draft.logbookNoteLine,
                ),
                const SizedBox(height: 8),
              ],
            ),
            if (draft.hasLogbookOverride) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _resetAll,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text("Use the airport's data"),
                ),
              ),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

/// The PLACE cell as it prints, black on paper, and the note under the
/// table.
class _Preview extends StatelessWidget {
  const _Preview({required this.place, required this.note});

  final String place;
  final String? note;

  @override
  Widget build(BuildContext context) {
    const ink = Colors.black;
    final note = this.note;
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 36, minWidth: 96),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(border: Border.all(width: 0.6)),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: Text(
                place.isEmpty ? '—' : place,
                style: const TextStyle(color: ink, fontSize: 14),
              ),
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 8),
            Text(note, style: const TextStyle(color: ink, fontSize: 10)),
          ],
        ],
      ),
    );
  }
}
