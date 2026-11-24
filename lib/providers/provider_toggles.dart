import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/adsb_track_source.dart';
import 'shared_preferences_provider.dart';

/// The ids of the things of one kind (online services, airport types) that
/// the user switched off in the settings.
///
/// What is *off* is what gets saved, so that one added by a later version
/// starts switched on like the others did, unless it is in [_defaultOff].
class DisabledIdsNotifier extends Notifier<Set<String>> {
  DisabledIdsNotifier(this._key, [this._defaultOff = const {}]);
  final String _key;

  /// Switched off until the user makes a choice.
  final Set<String> _defaultOff;

  @override
  Set<String> build() =>
      ref.read(sharedPreferencesProvider).getStringList(_key)?.toSet() ??
      _defaultOff;

  bool isEnabled(String id) => !state.contains(id);

  Future<void> setEnabled(String id, {required bool enabled}) async {
    if (enabled == isEnabled(id)) return;
    state = enabled ? ({...state}..remove(id)) : {...state, id};
    await ref
        .read(sharedPreferencesProvider)
        .setStringList(_key, state.toList()..sort());
  }
}

/// Preference keys of the toggles below.
const disabledTrackProvidersKey = 'adsb_disabled_track_providers';
const disabledHexSourcesKey = 'adsb_disabled_hex_sources';
const disabledPhotoSourcesKey = 'photo_disabled_sources';

/// ADS-B track providers (`AdsbProvider.id`) not to fetch tracks from.
/// All off by default: each needs an API key.
final disabledTrackProvidersProvider =
    NotifierProvider<DisabledIdsNotifier, Set<String>>(
      () => DisabledIdsNotifier(disabledTrackProvidersKey, {
        for (final provider in AdsbProvider.values) provider.id,
      }),
    );

/// Sources (`HexSource.id`) not to ask which ICAO address a registration
/// has.
final disabledHexSourcesProvider =
    NotifierProvider<DisabledIdsNotifier, Set<String>>(
      () => DisabledIdsNotifier(disabledHexSourcesKey),
    );

/// Sources (`AircraftLookupSource.id`) not to take aircraft photos from.
final disabledPhotoSourcesProvider =
    NotifierProvider<DisabledIdsNotifier, Set<String>>(
      () => DisabledIdsNotifier(disabledPhotoSourcesKey),
    );
