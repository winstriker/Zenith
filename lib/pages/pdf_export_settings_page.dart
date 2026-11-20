import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:share_plus/share_plus.dart';

import '../core/fab_hero_tags.dart';
import '../models/currency.dart';
import '../providers/database_provider.dart';
import '../providers/user_provider.dart';
import '../repositories/flight_repository.dart';
import '../repositories/licence_repository.dart';
import '../repositories/pilot_profile_repository.dart';
import '../services/database.dart';
import '../services/file_opener.dart';
import '../services/pdf_export_service.dart';
import '../services/person_photo_store.dart';
import '../widgets/page_title.dart';

class PdfExportSettingsPage extends ConsumerStatefulWidget {
  const PdfExportSettingsPage({super.key});

  @override
  ConsumerState<PdfExportSettingsPage> createState() =>
      _PdfExportSettingsPageState();
}

class _PdfExportSettingsPageState extends ConsumerState<PdfExportSettingsPage> {
  static final _log = Logger('Export');

  bool _exporting = false;

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      // Read now, and whole: the logbook has to contain every flight.
      final flights = await ref
          .read(flightRepositoryProvider)
          .allRecordedFlights();
      if (flights.isEmpty) {
        _showSnack('No flights to export');
        return;
      }
      await _exportPdf(flights);
    } catch (e, st) {
      _log.severe('PDF export failed', e, st);
      _showSnack('Export failed: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportPdf(List<FlightWithStats> flights) async {
    final crew = await ref
        .read(databaseProvider)
        .getCrewForFlights(flights.map((f) => f.flight.id));
    final store = ref.read(signatureStoreProvider);
    final signatures = <int, Uint8List>{};
    for (final f in flights) {
      final name = f.flight.signatureFile;
      final bytes = name == null ? null : await store.read(name);
      if (bytes != null) signatures[f.flight.id] = bytes;
    }
    final profile = await ref.read(pilotProfileRepositoryProvider).get();
    final pilotSignatureFile = profile?.signatureFile;
    // The holder's licence numbers, for the cover (AMC1 FCL.050(a)(1)).
    final licences = await ref
        .read(licenceRepositoryProvider)
        .watchLicences()
        .first;
    final file = await PdfExportService.generateLogbook(
      flights,
      crewByFlight: crew,
      signatures: signatures,
      pilotSignature: pilotSignatureFile == null
          ? null
          : await store.read(pilotSignatureFile),
      previousTotals: profile?.previousTotals ?? PreviousTotals.empty,
      pilotName: ref.read(userSignatureNameProvider),
      picNameMode: ref.read(picNameModeProvider),
      picusColumn: ref.read(picusColumnProvider),
      address: profile?.address,
      licences: [
        for (final l in licences)
          if (l.licence.number?.trim() case final number?
              when number.isNotEmpty)
            '${l.licence.title} $number',
      ],
    );
    _log.info('Logbook PDF written to ${file.path}');
    if (!await file.exists()) {
      throw StateError('Generated PDF not found at ${file.path}');
    }

    await FileOpener.open(file.path, mimeType: 'application/pdf');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Logbook exported'),
        action: SnackBarAction(label: 'Share', onPressed: () => _share(file)),
      ),
    );
  }

  Future<void> _share(File file) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf')],
          subject: 'Logbook export',
        ),
      );
    } catch (e, st) {
      _log.severe('Sharing ${file.path} failed', e, st);
      _showSnack('Share failed: $e');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final picNameMode = ref.watch(picNameModeProvider);

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: FloatingActionButton(
        heroTag: closeFabHeroTag,
        tooltip: 'Close',
        onPressed: () => Navigator.pop(context),
        child: const Icon(Icons.close),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        children: [
          const PageTitle(
            'PDF Export',
            belowCloseButton: true,
            horizontalPadding: 0,
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.badge_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'PIC Name in Logbook',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<PicNameMode>(
                      segments: const [
                        ButtonSegment<PicNameMode>(
                          value: PicNameMode.self,
                          icon: Icon(Icons.person_outline),
                          label: Text('SELF'),
                        ),
                        ButtonSegment<PicNameMode>(
                          value: PicNameMode.name,
                          icon: Icon(Icons.badge_outlined),
                          label: Text('Pilot name'),
                        ),
                      ],
                      selected: {picNameMode},
                      onSelectionChanged: (s) => ref
                          .read(picNameModeProvider.notifier)
                          .setMode(s.first),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: SwitchListTile(
              secondary: Icon(
                Icons.supervisor_account_outlined,
                color: theme.colorScheme.primary,
              ),
              title: const Text('PICUS column'),
              subtitle: const Text(
                'Log PIC under supervision time in its own column',
              ),
              value: ref.watch(picusColumnProvider),
              onChanged: ref.read(picusColumnProvider.notifier).set,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _exporting ? null : _export,
            icon: _exporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_download_outlined),
            label: Text(_exporting ? 'Exporting…' : 'Export PDF'),
          ),
        ],
      ),
    );
  }
}
