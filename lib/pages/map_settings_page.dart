import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/carto_provider.dart';
import '../providers/map_provider.dart';
import '../widgets/section_header.dart';

/// Which base map the app draws, and the CARTO API key it needs.
class MapSettingsPage extends ConsumerWidget {
  const MapSettingsPage({super.key});

  Future<void> _editApiKey(
    BuildContext context,
    WidgetRef ref,
    String? currentKey,
  ) async {
    final result = await showDialog<_ApiKeyResult>(
      context: context,
      builder: (_) => _ApiKeyDialog(currentKey: currentKey),
    );
    if (result == null) return;
    final notifier = ref.read(cartoApiKeyProvider.notifier);
    switch (result) {
      case _ApiKeyRemove():
        await notifier.clearKey();
      case _ApiKeySave(:final key):
        await notifier.setKey(key);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cartoKey = ref.watch(cartoApiKeyProvider);
    final source = ref.watch(effectiveMapSourceProvider);
    // CARTO picked and keyed, but the maps fell back to OpenStreetMap.
    final cartoFailed =
        source == MapSource.carto &&
        ref.watch(mapTilesProvider).value is OsmMapTiles;

    return Scaffold(
      appBar: AppBar(title: const Text('Map'), centerTitle: true),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          8 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          const SectionHeader(title: 'Map Style', uppercase: true),
          Card(
            child: RadioGroup<MapSource>(
              groupValue: source,
              onChanged: (value) {
                if (value != null) {
                  ref.read(mapSourceProvider.notifier).setSource(value);
                }
              },
              child: Column(
                children: [
                  RadioListTile<MapSource>(
                    value: MapSource.carto,
                    enabled: cartoKey != null,
                    title: const Text('CARTO Voyager'),
                    subtitle: Text(
                      cartoKey == null
                          ? 'Vector map · add a CARTO API key below to use it'
                          : 'Vector map · needs a CARTO API key',
                    ),
                  ),
                  const Divider(height: 1, indent: 72),
                  const RadioListTile<MapSource>(
                    value: MapSource.osm,
                    title: Text('OpenStreetMap'),
                    subtitle: Text('Raster map · no key needed'),
                  ),
                ],
              ),
            ),
          ),
          if (cartoFailed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(
                "The CARTO map couldn't be loaded, so OpenStreetMap is shown "
                'instead. Check the API key and your connection.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          const SizedBox(height: 8),
          const SectionHeader(title: 'CARTO', uppercase: true),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.vpn_key, color: theme.colorScheme.primary),
                      const SizedBox(width: 16),
                      Text('API Key', style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          cartoKey != null
                              ? '${cartoKey.substring(0, cartoKey.length > 8 ? 8 : cartoKey.length)}...'
                              : 'Not set',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cartoKey != null
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.error,
                          ),
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: () => _editApiKey(context, ref, cartoKey),
                        child: Text(cartoKey != null ? 'Change' : 'Add'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

sealed class _ApiKeyResult {
  const _ApiKeyResult();
}

class _ApiKeySave extends _ApiKeyResult {
  const _ApiKeySave(this.key);
  final String key;
}

class _ApiKeyRemove extends _ApiKeyResult {
  const _ApiKeyRemove();
}

class _ApiKeyDialog extends StatefulWidget {
  const _ApiKeyDialog({required this.currentKey});
  final String? currentKey;

  @override
  State<_ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends State<_ApiKeyDialog> {
  late final _controller = TextEditingController(text: widget.currentKey ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('CARTO API Key'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: 'Paste your API key',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (widget.currentKey != null)
          TextButton(
            onPressed: () => Navigator.pop(context, const _ApiKeyRemove()),
            child: const Text('Remove'),
          ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, _ApiKeySave(_controller.text)),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
