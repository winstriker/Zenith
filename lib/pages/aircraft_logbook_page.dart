import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/fab_hero_tags.dart';
import '../repositories/aircraft_repository.dart';
import '../services/database.dart';
import '../widgets/logbook_override_widgets.dart';
import '../widgets/page_title.dart';

/// Lets the pilot choose how an aircraft is written in column 4 ("make,
/// model, variant") of the exported logbook: its ICAO type designator by
/// default, or a type of their own with a subtitle line under it, e.g. for
/// the variant of a larger aircraft.
class AircraftLogbookPage extends ConsumerStatefulWidget {
  const AircraftLogbookPage({super.key, required this.aircraft});
  final AircraftWithStats aircraft;

  @override
  ConsumerState<AircraftLogbookPage> createState() =>
      _AircraftLogbookPageState();
}

class _AircraftLogbookPageState extends ConsumerState<AircraftLogbookPage> {
  late final _type = TextEditingController(
    text: widget.aircraft.logbookType ?? '',
  );
  late final _subtitle = TextEditingController(
    text: widget.aircraft.logbookSubtitle ?? '',
  );
  bool _saving = false;

  @override
  void dispose() {
    _type.dispose();
    _subtitle.dispose();
    super.dispose();
  }

  void _resetAll() {
    FocusScope.of(context).unfocus();
    _type.clear();
    _subtitle.clear();
    setState(() {});
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(aircraftRepositoryProvider)
          .setLogbookEntry(
            widget.aircraft.id,
            type: _type.text,
            subtitle: _subtitle.text,
          );
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final designator = widget.aircraft.designator;
    final type = _type.text.trim().isEmpty ? designator : _type.text.trim();
    final subtitle = _subtitle.text.trim();
    final overridden =
        _type.text.trim().isNotEmpty || _subtitle.text.trim().isNotEmpty;

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
              title: 'AIRCRAFT · MAKE, MODEL, VARIANT',
              children: [
                LogbookOverrideTextRow(
                  controller: _type,
                  label: 'Type',
                  hint: designator,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                LogbookOverrideTextRow(
                  controller: _subtitle,
                  label: 'Subtitle',
                  hint: 'e.g. 747-400F',
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
              ],
            ),
            const SizedBox(height: 16),
            LogbookOverrideSection(
              title: 'IN THE LOGBOOK',
              children: [
                const SizedBox(height: 8),
                _CellPreview(
                  type: type,
                  subtitle: subtitle.isEmpty ? null : subtitle,
                  registration: widget.aircraft.tailNumber,
                ),
                const SizedBox(height: 8),
              ],
            ),
            if (overridden) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _resetAll,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Use the ICAO type'),
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

/// Column 4 of the logbook as it prints: black on paper, type and
/// registration side by side, centred.
class _CellPreview extends StatelessWidget {
  const _CellPreview({
    required this.type,
    required this.subtitle,
    required this.registration,
  });

  final String type;
  final String? subtitle;
  final String registration;

  @override
  Widget build(BuildContext context) {
    const ink = Colors.black;
    final border = Border.all(width: 0.6);
    TextStyle style(double size, {FontWeight? weight}) =>
        TextStyle(color: ink, fontSize: size, fontWeight: weight, height: 1.15);
    Widget cell(Widget child, {required int flex}) => Expanded(
      flex: flex,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(border: border),
        alignment: Alignment.center,
        child: child,
      ),
    );

    // Both cells as tall as the taller one, in a list of unbounded height.
    return Container(
      color: Colors.white,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            cell(
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Centred, as in the exported logbook.
                  Text(type, style: style(14), textAlign: TextAlign.center),
                  if (subtitle case final s?)
                    Text(s, style: style(10), textAlign: TextAlign.center),
                ],
              ),
              flex: 13,
            ),
            cell(Text(registration, style: style(14)), flex: 9),
          ],
        ),
      ),
    );
  }
}
