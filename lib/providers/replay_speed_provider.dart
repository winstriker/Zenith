import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The replay speed the pilot chose for themselves, as how many times faster
/// than the flight: null until they choose one.
class CustomReplaySpeedNotifier extends Notifier<int?> {
  static const prefsKey = 'replay_custom_speed';
  static const min = 1;
  static const max = 1000;

  @override
  int? build() {
    SharedPreferences.getInstance().then((prefs) {
      final value = prefs.getInt(prefsKey);
      // It may come from a backup: only a speed the picker allows.
      if (ref.mounted && value != null && value >= min && value <= max) {
        state = value;
      }
    });
    return null;
  }

  Future<void> set(int value) async {
    state = value;
    await (await SharedPreferences.getInstance()).setInt(prefsKey, value);
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
  static Future<int?> read() async {
    final value = (await SharedPreferences.getInstance()).getInt(prefsKey);
    // It may come from a backup: only a speed the picker allows.
    const min = CustomReplaySpeedNotifier.min;
    const max = CustomReplaySpeedNotifier.max;
    return value != null && value >= min && value <= max ? value : null;
  }

  static Future<void> write(int value) async =>
      (await SharedPreferences.getInstance()).setInt(prefsKey, value);
}
