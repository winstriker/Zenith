import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/fab_hero_tags.dart';
import '../providers/carto_provider.dart';
import '../providers/map_provider.dart';
import '../widgets/page_title.dart';
import '../widgets/secret_status.dart';
import '../widgets/section_header.dart';

/// Which base map the app draws, and the CARTO API key it needs.
class MapSettingsPage extends ConsumerWidget {
  const MapSettingsPage({super.key});

  Future<void> _editApiKey(
    BuildContext context,
    WidgetRef ref, {
    required bool isSet,
  }) async {
    final result = await showDialog<_ApiKeyResult>(
      context: context,
      builder: (_) => _ApiKeyDialog(isSet: isSet),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: FloatingActionButton(
        heroTag: closeFabHeroTag,
        tooltip: 'Close',
        onPressed: () => Navigator.pop(context),
        child: const Icon(Icons.close),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          8 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          const PageTitle('Map', belowCloseButton: true, horizontalPadding: 0),
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
                      Expanded(child: SecretStatus(isSet: cartoKey != null)),
                      FilledButton.tonal(
                        onPressed: () =>
                            _editApiKey(context, ref, isSet: cartoKey != null),
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
  const _ApiKeyDialog({required this.isSet});

  /// Whether a key is saved already. It is never shown: a new one
  /// replaces it.
  final bool isSet;

  @override
  State<_ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends State<_ApiKeyDialog> {
  final _controller = TextEditingController();
  bool _show = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final key = _controller.text.trim();
    if (key.isEmpty) {
      setState(() => _error = 'Paste your API key');
      return;
    }
    Navigator.pop(context, _ApiKeySave(key));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isSet ? 'Change CARTO API Key' : 'CARTO API Key'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        autocorrect: false,
        enableSuggestions: false,
        obscureText: !_show,
        decoration: InputDecoration(
          hintText: widget.isSet
              ? 'Paste a new key to replace the saved one'
              : 'Paste your API key',
          border: const OutlineInputBorder(),
          errorText: _error,
          suffixIcon: IconButton(
            tooltip: _show ? 'Hide' : 'Show',
            icon: Icon(_show ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _show = !_show),
          ),
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (widget.isSet)
          TextButton(
            onPressed: () => Navigator.pop(context, const _ApiKeyRemove()),
            child: const Text('Remove'),
          ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
