import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shared_preferences_provider.dart';

/// The replay speed the pilot chose for themselves, as how many times faster
/// than the flight: null until they choose one.
class CustomReplaySpeedNotifier extends Notifier<int?> {
  static const prefsKey = 'replay_custom_speed';
  static const min = 1;
  static const max = 1000;

  @override
  int? build() =>
      _allowed(ref.read(sharedPreferencesProvider).getInt(prefsKey));

  /// [value] if the picker allows it: it may come from a backup.
  static int? _allowed(int? value) =>
      value != null && value >= min && value <= max ? value : null;

  Future<void> set(int value) async {
    state = value;
    await ref.read(sharedPreferencesProvider).setInt(prefsKey, value);
  }
}

final customReplaySpeedProvider =
    NotifierProvider<CustomReplaySpeedNotifier, int?>(
      CustomReplaySpeedNotifier.new,
    );

/// The replay speed last chosen, which the next replay starts at.
abstract final class LastReplaySpeed {
  static const prefsKey = 'replay_speed';

  /// Null until a speed was chosen: replays then pick one for the flight.
  static int? read(SharedPreferences prefs) =>
      CustomReplaySpeedNotifier._allowed(prefs.getInt(prefsKey));

  static Future<void> write(SharedPreferences prefs, int value) =>
      prefs.setInt(prefsKey, value);
}
