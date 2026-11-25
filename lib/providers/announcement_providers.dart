import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/announcement_service.dart';
import 'shared_preferences_provider.dart';

final announcementServiceProvider = Provider((ref) => AnnouncementService());

/// Whether to fetch and show announcements. On by default.
class ShowAnnouncementsNotifier extends Notifier<bool> {
  static const prefsKey = 'show_announcements';

  @override
  bool build() => ref.read(sharedPreferencesProvider).getBool(prefsKey) ?? true;

  Future<void> set(bool value) async {
    state = value;
    await ref.read(sharedPreferencesProvider).setBool(prefsKey, value);
  }
}

final showAnnouncementsProvider =
    NotifierProvider<ShowAnnouncementsNotifier, bool>(
      ShowAnnouncementsNotifier.new,
    );

/// The announcements, newest first. Fetched once when first read (at app
/// start), again on invalidate.
final announcementsProvider = FutureProvider<List<Announcement>>(
  (ref) => ref.read(announcementServiceProvider).list(),
);

/// The markdown of one announcement.
final announcementTextProvider = FutureProvider.family<String, Announcement>(
  (ref, a) => ref.read(announcementServiceProvider).fetch(a),
);

/// The newest announcement the user has opened the list on.
class LastSeenAnnouncementNotifier extends Notifier<String?> {
  static const _key = 'last_seen_announcement';

  @override
  String? build() => ref.read(sharedPreferencesProvider).getString(_key);

  Future<void> markSeen(String name) async {
    state = name;
    await ref.read(sharedPreferencesProvider).setString(_key, name);
  }
}

final lastSeenAnnouncementProvider =
    NotifierProvider<LastSeenAnnouncementNotifier, String?>(
      LastSeenAnnouncementNotifier.new,
    );

/// Whether there is an announcement newer than the last one seen.
final hasUnreadAnnouncementsProvider = Provider<bool>((ref) {
  if (!ref.watch(showAnnouncementsProvider)) return false;
  final latest = ref.watch(announcementsProvider).value?.firstOrNull;
  return latest != null &&
      latest.file != ref.watch(lastSeenAnnouncementProvider);
});
