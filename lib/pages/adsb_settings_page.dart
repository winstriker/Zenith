import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme.dart';
import '../models/sync_progress.dart';
import '../providers/adsb_providers.dart';
import '../providers/provider_toggles.dart';
import '../services/adsb_flyitalyadsb_source.dart';
import '../services/adsb_opensky_source.dart';
import '../services/adsb_track_source.dart';
import '../services/aircraft_hex_resolver.dart';
import '../services/aircraft_lookup_service.dart';
import '../services/aircraft_registry_service.dart';
import '../widgets/secret_status.dart';
import '../widgets/section_header.dart';
import '../widgets/sync_progress_indicator.dart';

/// Where flight tracks are fetched from, with which accounts, and what
/// turns a registration into the ICAO address the tracks are filed under.
class AdsbSettingsPage extends ConsumerWidget {
  const AdsbSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final providersOff = ref.watch(disabledTrackProvidersProvider);
    final credentials =
        ref.watch(adsbCredentialsProvider).value ?? const AdsbCredentials();
    final flyItalyOn = !providersOff.contains(AdsbProvider.flyItalyAdsb.id);
    final openSkyOn = !providersOff.contains(AdsbProvider.openSky.id);

    void setProvider(AdsbProvider provider, bool enabled) => ref
        .read(disabledTrackProvidersProvider.notifier)
        .setEnabled(provider.id, enabled: enabled);

    return Scaffold(
      appBar: AppBar(title: const Text('ADS-B'), centerTitle: true),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          8 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          const SectionHeader(title: 'Track Providers', uppercase: true),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SwitchListTile(
                  value: flyItalyOn,
                  onChanged: (on) => setProvider(AdsbProvider.flyItalyAdsb, on),
                  title: Text(AdsbProvider.flyItalyAdsb.label),
                  subtitle: Text(
                    credentials.hasFlyItalyKey
                        ? 'Tracks of the last 7 days'
                        : 'Needs an API key · free ones cover the last 7 days',
                  ),
                ),
                if (flyItalyOn)
                  _CredentialRow(
                    label: 'API key',
                    isSet: credentials.hasFlyItalyKey,
                    missing: 'Not set',
                    isRequired: true,
                    onEdit: () => showDialog<void>(
                      context: context,
                      builder: (_) =>
                          _FlyItalyKeyDialog(isSet: credentials.hasFlyItalyKey),
                    ),
                  ),
                const Divider(height: 1, indent: 16),
                SwitchListTile(
                  value: openSkyOn,
                  onChanged: (on) => setProvider(AdsbProvider.openSky, on),
                  title: Text(AdsbProvider.openSky.label),
                  subtitle: Text(
                    credentials.hasOpenSky
                        ? 'Tracks of the last 30 days'
                        : 'Tracks of the last 30 days · rate limited ',
                  ),
                ),
                if (openSkyOn)
                  _CredentialRow(
                    label: 'API client',
                    isSet: credentials.hasOpenSky,
                    missing: 'Anonymous',
                    isRequired: false,
                    onEdit: () => showDialog<void>(
                      context: context,
                      builder: (_) =>
                          _OpenSkyDialog(isSet: credentials.hasOpenSky),
                    ),
                  ),
              ],
            ),
          ),
          if (!flyItalyOn && !openSkyOn) ...[
            const _Caption(
              'No provider on: tracks can only be recorded by the app',
              isWarning: true,
            ),
          ],
          const SizedBox(height: 8),
          const SectionHeader(title: 'ICAO Address Lookup', uppercase: true),
          const _HexSourcesCard(),
          const SizedBox(height: 8),
          const SectionHeader(
            title: 'Attributions & huge thanks to',
            uppercase: true,
          ),
          for (final provider in AdsbProvider.values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Text(
                provider.attribution,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text, {this.isWarning = false});
  final String text;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: isWarning
              ? theme.colorScheme.error
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// A key or account under its provider's switch: whether one is saved
/// (never what it is), and a button to change it.
class _CredentialRow extends StatelessWidget {
  const _CredentialRow({
    required this.label,
    required this.isSet,
    required this.missing,
    required this.isRequired,
    required this.onEdit,
  });

  final String label;

  final bool isSet;

  /// What to show when nothing is saved.
  final String missing;

  /// Whether the provider is of no use without it.
  final bool isRequired;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Icon(
            Icons.vpn_key_outlined,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelMedium),
                SecretStatus(
                  isSet: isSet,
                  missing: missing,
                  isRequired: isRequired,
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: onEdit,
            child: Text(isSet ? 'Change' : 'Add'),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ICAO address sources
// -----------------------------------------------------------------------------

class _HexSourcesCard extends ConsumerWidget {
  const _HexSourcesCard();

  static const _subtitles = {
    AdsbdbSource.sourceId: 'Online · api.adsbdb.com',
    HexdbSource.sourceId: 'Online · hexdb.io',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sources = ref.watch(hexSourcesProvider);
    final off = ref.watch(disabledHexSourcesProvider);
    final allOff = sources.every((source) => off.contains(source.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (i, source) in sources.indexed) ...[
                if (i > 0) const Divider(height: 1, indent: 16),
                if (source.id == LocalHexSource.sourceId)
                  _LocalDatabaseTile(enabled: !off.contains(source.id))
                else
                  SwitchListTile(
                    value: !off.contains(source.id),
                    onChanged: (on) => ref
                        .read(disabledHexSourcesProvider.notifier)
                        .setEnabled(source.id, enabled: on),
                    title: Text(source.label),
                    subtitle: Text(_subtitles[source.id] ?? 'Online'),
                  ),
              ],
            ],
          ),
        ),
        if (allOff)
          const _Caption(
            'With all of these switched off, tracks can only be searched by '
            'flight number or ICAO address.',
            isWarning: true,
          ),
      ],
    );
  }
}

/// The copy of tar1090-db on the device: its switch, how fresh it is, and
/// its download.
class _LocalDatabaseTile extends ConsumerWidget {
  const _LocalDatabaseTile({required this.enabled});
  final bool enabled;

  static final _date = DateFormat('d MMM y');
  static final _number = NumberFormat.decimalPattern();

  static String _describe(RegistryStatus? status) {
    if (status == null) return '';
    if (!status.isDownloaded) {
      return 'On this device · tar1090-db · not downloaded yet (about 9 MB)';
    }
    final updated = status.updatedAt;
    return '${_number.format(status.aircraft)} aircraft'
        '${updated == null ? '' : ' · ${_date.format(updated)}'}';
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete tar1090-db'),
        content: const Text('Local database will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    // Off first: left on, the empty database would be downloaded again.
    await ref
        .read(disabledHexSourcesProvider.notifier)
        .setEnabled(LocalHexSource.sourceId, enabled: false);
    await ref.read(aircraftRegistryLoadProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watching the progress is what starts the (daily) check, when the
    // database is switched on.
    final progress = ref.watch(aircraftRegistryLoadProvider);
    final status = ref.watch(aircraftRegistryStatusProvider).value;
    final showProgress =
        enabled && (progress.isRunning || progress.phase == SyncPhase.error);
    final downloaded = status?.isDownloaded ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          value: enabled,
          onChanged: (on) => ref
              .read(disabledHexSourcesProvider.notifier)
              .setEnabled(LocalHexSource.sourceId, enabled: on),
          title: const Text('Local tar1090-db'),
          subtitle: Text(_describe(status)),
        ),
        if (showProgress)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SyncProgressIndicator(progress: progress, compact: true),
          ),
        if (!progress.isRunning && (enabled || downloaded))
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: [
                if (enabled)
                  TextButton.icon(
                    onPressed: () => ref
                        .read(aircraftRegistryLoadProvider.notifier)
                        .refresh(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(
                      progress.phase == SyncPhase.error
                          ? 'Retry'
                          : downloaded
                          ? 'Check for updates'
                          : 'Download',
                    ),
                  ),
                if (downloaded)
                  TextButton.icon(
                    onPressed: () => _delete(context, ref),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Credential dialogs
// -----------------------------------------------------------------------------

/// A line of help with a link in a credentials dialog.
class _HelpLink extends StatelessWidget {
  const _HelpLink({required this.text, required this.link, required this.url});
  final String text;
  final String link;
  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        InkWell(
          onTap: () =>
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              link,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                decoration: TextDecoration.underline,
                decorationColor: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FlyItalyKeyDialog extends ConsumerStatefulWidget {
  const _FlyItalyKeyDialog({required this.isSet});

  /// Whether a key is saved already. It is never shown: a new one
  /// replaces it.
  final bool isSet;

  @override
  ConsumerState<_FlyItalyKeyDialog> createState() => _FlyItalyKeyDialogState();
}

class _FlyItalyKeyDialogState extends ConsumerState<_FlyItalyKeyDialog> {
  final _controller = TextEditingController();
  bool _checking = false;
  bool _show = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final key = _controller.text.trim();
    if (key.isEmpty) {
      setState(() => _error = 'Paste your API key');
      return;
    }
    setState(() {
      _checking = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final client = ref.read(httpClientFactoryProvider)();
    bool? accepted;
    try {
      accepted = await FlyItalyAdsbSource.checkKey(
        client,
        key,
        userAgent: appUserAgent,
      );
    } on AdsbException {
      // Could not be asked: the key is saved unchecked.
    } finally {
      client.close();
    }
    if (!mounted) return;
    if (accepted == false) {
      setState(() {
        _checking = false;
        _error = "FlyItalyADSB doesn't accept this key";
      });
      return;
    }
    await ref.read(adsbCredentialsProvider.notifier).setFlyItalyApiKey(key);
    if (!mounted) return;
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          accepted == true
              ? 'FlyItalyADSB API key saved'
              : 'API key saved. It could not be checked: no connection.',
        ),
      ),
    );
  }

  Future<void> _remove() async {
    await ref.read(adsbCredentialsProvider.notifier).setFlyItalyApiKey(null);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.isSet ? 'Change FlyItalyADSB API Key' : 'FlyItalyADSB API Key',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              enabled: !_checking,
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
                errorMaxLines: 2,
                suffixIcon: IconButton(
                  tooltip: _show ? 'Hide' : 'Show',
                  icon: Icon(_show ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _show = !_show),
                ),
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            const _HelpLink(
              text:
                  'A key is free and comes by e-mail in seconds. It is '
                  'yours alone: every request the app makes counts on it.',
              link: 'flyitalyadsb.com/data/api',
              url: 'https://flyitalyadsb.com/data/api/#api-key',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _checking ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (widget.isSet)
          TextButton(
            onPressed: _checking ? null : _remove,
            child: const Text('Remove'),
          ),
        FilledButton(
          onPressed: _checking ? null : _save,
          child: _checking
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

class _OpenSkyDialog extends ConsumerStatefulWidget {
  const _OpenSkyDialog({required this.isSet});

  /// Whether an API client is saved already. It is never shown: a new
  /// one replaces it.
  final bool isSet;

  @override
  ConsumerState<_OpenSkyDialog> createState() => _OpenSkyDialogState();
}

class _OpenSkyDialogState extends ConsumerState<_OpenSkyDialog> {
  final _id = TextEditingController();
  final _secret = TextEditingController();
  bool _checking = false;
  bool _showSecret = false;
  String? _error;

  @override
  void dispose() {
    _id.dispose();
    _secret.dispose();
    super.dispose();
  }

  /// OpenSky hands the two out together, as a `credentials.json`: pasted
  /// whole into either field, it fills both.
  void _onPasted(String text) {
    final credentials = OpenSkyCredentials.fromJson(text);
    if (credentials == null) return;
    _id.text = credentials.clientId;
    _secret.text = credentials.clientSecret;
  }

  Future<void> _save() async {
    final id = _id.text.trim();
    final secret = _secret.text.trim();
    if (id.isEmpty || secret.isEmpty) {
      setState(() => _error = 'Enter both the client ID and its secret');
      return;
    }
    setState(() {
      _checking = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final client = ref.read(httpClientFactoryProvider)();
    var verified = false;
    try {
      // Signing in is the check.
      await OpenSkySource.requestToken(client, id, secret);
      verified = true;
    } on AdsbException catch (e) {
      if (e.needsSetup) {
        if (!mounted) return;
        setState(() {
          _checking = false;
          _error = "OpenSky doesn't accept this client ID and secret";
        });
        return;
      }
      // Could not be asked: saved unchecked.
    } finally {
      client.close();
    }
    await ref.read(adsbCredentialsProvider.notifier).setOpenSky(id, secret);
    if (!mounted) return;
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          verified
              ? 'Signed in to OpenSky'
              : 'OpenSky API client saved. It could not be checked: no '
                    'connection.',
        ),
      ),
    );
  }

  Future<void> _remove() async {
    await ref.read(adsbCredentialsProvider.notifier).setOpenSky(null, null);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.isSet ? 'Change OpenSky API Client' : 'OpenSky API Client',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _id,
              enabled: !_checking,
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: 'Client ID',
                border: const OutlineInputBorder(),
                helperText: widget.isSet
                    ? 'Enter a new client to replace the saved one'
                    : null,
                helperMaxLines: 2,
              ),
              onChanged: _onPasted,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _secret,
              enabled: !_checking,
              autocorrect: false,
              enableSuggestions: false,
              obscureText: !_showSecret,
              decoration: InputDecoration(
                labelText: 'Client secret',
                border: const OutlineInputBorder(),
                errorText: _error,
                errorMaxLines: 2,
                suffixIcon: IconButton(
                  tooltip: _showSecret ? 'Hide' : 'Show',
                  icon: Icon(
                    _showSecret ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _showSecret = !_showSecret),
                ),
              ),
              onChanged: _onPasted,
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            const _HelpLink(
              text:
                  'OpenSky answers without an account too, but only a few '
                  'times a day. With a free account, create an API client '
                  'on your account page and enter it here (or paste its '
                  'credentials.json). Non-commercial use only.',
              link: 'opensky-network.org/my-opensky/account',
              url: 'https://opensky-network.org/my-opensky/account',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _checking ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (widget.isSet)
          TextButton(
            onPressed: _checking ? null : _remove,
            child: const Text('Remove'),
          ),
        FilledButton(
          onPressed: _checking ? null : _save,
          child: _checking
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
