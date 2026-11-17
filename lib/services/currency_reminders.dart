import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/currency.dart';
import '../providers/currency_settings_provider.dart';

/// A reminder to schedule.
@immutable
class PlannedReminder {
  const PlannedReminder({
    required this.at,
    required this.title,
    required this.body,
    required this.itemKey,
  });

  final DateTime at;
  final String title;
  final String body;

  /// [CurrencyItem.key] of what it is about.
  final String itemKey;

  @override
  bool operator ==(Object other) =>
      other is PlannedReminder &&
      other.at == at &&
      other.title == title &&
      other.body == body &&
      other.itemKey == itemKey;

  @override
  int get hashCode => Object.hash(at, title, body, itemKey);
}

/// Most reminders scheduled at once. Android caps an app's alarms at 500;
/// the earliest ones are what matters, and the list is redone whenever the
/// app is opened.
const maxPlannedReminders = 64;

/// The reminders due after [now] for [items], as [settings] want them,
/// earliest first.
List<PlannedReminder> planReminders(
  List<CurrencyItem> items,
  CurrencySettings settings,
  DateTime now,
) {
  if (!settings.notificationsEnabled) return const [];
  final dateFormat = DateFormat('d MMM yyyy');
  final planned = <PlannedReminder>[];
  for (final item in items) {
    final until = item.validUntil;
    if (until == null) continue;
    if (item.kind == CurrencyKind.recency && !settings.recencyReminders) {
      continue;
    }
    final days = <DateTime>{};
    // Earliest lead first, so two leads falling on the same day keep the
    // wording of the longer one.
    final leads = settings.leads.toList()
      ..sort((a, b) => b.approxDays.compareTo(a.approxDays));
    for (final lead in leads) {
      final day = lead.dueFor(until);
      if (!days.add(day)) continue;
      final at = DateTime(
        day.year,
        day.month,
        day.day,
        settings.reminderTime.hour,
        settings.reminderTime.minute,
      );
      if (!at.isAfter(now)) continue;
      final title = switch (item.kind) {
        CurrencyKind.validity => '${item.title} expires ${lead.relative}',
        CurrencyKind.recency => '${item.title}: currency ends ${lead.relative}',
      };
      final body = [
        'Valid until ${dateFormat.format(until)}',
        if (item.subtitle case final s? when s.isNotEmpty) s,
      ].join(' · ');
      planned.add(
        PlannedReminder(at: at, title: title, body: body, itemKey: item.key),
      );
    }
  }
  planned.sort((a, b) => a.at.compareTo(b.at));
  return planned.take(maxPlannedReminders).toList();
}

/// Schedules the licence & currency reminders as Android notifications.
class CurrencyReminderService {
  CurrencyReminderService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  static final _log = Logger('CurrencyReminderService');

  /// Payload of every reminder: tapping one opens the licences tab.
  static const payload = 'currency';

  /// Reminder ids start here, clear of any other notification of the app.
  static const _firstId = 7000;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'currency_reminders',
      'Licence & currency reminders',
      channelDescription: 'Ratings, certificates and recency about to expire',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification_licence',
    ),
  );

  Future<void>? _initialized;

  /// Last list scheduled, to skip rescheduling the same one.
  List<PlannedReminder>? _scheduled;

  /// Serialises [schedule] calls.
  Future<void> _queue = Future.value();

  /// Sets the plugin up; [onOpen] runs when a reminder is tapped, also when
  /// the tap started the app.
  Future<void> initialize({required VoidCallback onOpen}) {
    return _initialized ??= () async {
      if (defaultTargetPlatform != TargetPlatform.android) return;
      try {
        await _plugin.initialize(
          settings: const InitializationSettings(
            android: AndroidInitializationSettings('ic_notification_licence'),
          ),
          onDidReceiveNotificationResponse: (response) {
            if (response.payload == payload) onOpen();
          },
        );
        final launch = await _plugin.getNotificationAppLaunchDetails();
        if (launch?.didNotificationLaunchApp == true &&
            launch?.notificationResponse?.payload == payload) {
          onOpen();
        }
      } catch (e, s) {
        _log.warning('Notifications unavailable', e, s);
      }
    }();
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  /// Whether the app may post notifications.
  Future<bool> areEnabled() async =>
      await _android?.areNotificationsEnabled() ?? false;

  /// Asks for the notification permission (Android 13+). True when granted.
  Future<bool> requestPermission() async =>
      await _android?.requestNotificationsPermission() ?? false;

  /// Replaces the scheduled reminders with [reminders].
  Future<void> schedule(List<PlannedReminder> reminders) {
    return _queue = _queue.then((_) async {
      if (_initialized == null) return;
      await _initialized;
      if (listEquals(_scheduled, reminders)) return;
      try {
        for (final pending in await _plugin.pendingNotificationRequests()) {
          if (pending.payload == payload) {
            await _plugin.cancel(id: pending.id);
          }
        }
        for (final (i, r) in reminders.indexed) {
          await _plugin.zonedSchedule(
            id: _firstId + i,
            scheduledDate: tz.TZDateTime.from(r.at.toUtc(), tz.UTC),
            notificationDetails: _details,
            // Inexact: no exact-alarm permission needed, and minutes don't
            // matter for something due in days.
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            title: r.title,
            body: r.body,
            payload: payload,
          );
        }
        _scheduled = reminders;
        _log.fine('Scheduled ${reminders.length} reminders');
      } catch (e, s) {
        _log.warning('Could not schedule reminders', e, s);
      }
    });
  }
}
