import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/database_provider.dart';
import '../providers/flight_providers.dart';
import '../providers/user_provider.dart';
import '../services/database.dart';
import '../services/file_opener.dart';
import '../services/pdf_export_service.dart';
import '../widgets/section_header.dart';

enum ExportFormat {
  pdf(
    label: 'PDF',
    description: 'EASA-compliant logbook, ready to print',
    icon: Icons.picture_as_pdf_outlined,
    available: true,
  ),
  csv(
    label: 'CSV',
    description: 'Spreadsheet-friendly flight list',
    icon: Icons.table_chart_outlined,
    available: false,
  ),
  json(
    label: 'JSON',
    description: 'Full data dump for backup or import',
    icon: Icons.data_object,
    available: false,
  );

  const ExportFormat({
    required this.label,
    required this.description,
    required this.icon,
    required this.available,
  });

  final String label;
  final String description;
  final IconData icon;
  final bool available;
}

class ExportPage extends ConsumerStatefulWidget {
  const ExportPage({super.key});

  @override
  ConsumerState<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends ConsumerState<ExportPage> {
  static final _log = Logger('Export');

  ExportFormat _format = ExportFormat.pdf;
  bool _exporting = false;

  Future<void> _export() async {
    final flights = ref.read(flightListStreamProvider).value ?? [];
    if (flights.isEmpty) {
      _showSnack('No flights to export');
      return;
    }

    setState(() => _exporting = true);
    try {
      switch (_format) {
        case ExportFormat.pdf:
          await _exportPdf(flights);
        case ExportFormat.csv:
          // TODO: implement CSV export
          throw UnimplementedError('CSV export not implemented yet');
        case ExportFormat.json:
          // TODO: implement JSON export
          throw UnimplementedError('JSON export not implemented yet');
      }
    } catch (e, st) {
      _log.severe('${_format.label} export failed', e, st);
      _showSnack('Export failed: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportPdf(List<FlightWithStats> flights) async {
    final crew = await ref
        .read(databaseProvider)
        .getCrewForFlights(flights.map((f) => f.flight.id));
    final file = await PdfExportService.generateLogbook(
      flights,
      crewByFlight: crew,
      pilotName: ref.read(userSignatureNameProvider),
      picNameMode: ref.read(picNameModeProvider),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Export Data'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          const SectionHeader(title: 'Format', uppercase: true),
          Card(
            child: Column(
              children: [
                for (final (i, format) in ExportFormat.values.indexed) ...[
                  if (i > 0) const Divider(height: 1, indent: 72),
                  ListTile(
                    enabled: format.available && !_exporting,
                    leading: Icon(format.icon),
                    title: Text(format.label),
                    subtitle: Text(
                      format.available ? format.description : 'Coming soon',
                    ),
                    trailing: Icon(
                      _format == format
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: _format == format
                          ? theme.colorScheme.primary
                          : null,
                    ),
                    onTap: () => setState(() => _format = format),
                  ),
                ],
              ],
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
            label: Text(_exporting ? 'Exporting…' : 'Export ${_format.label}'),
          ),
        ],
      ),
    );
  }
}
