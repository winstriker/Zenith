import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/currency.dart';
import 'shared_preferences_provider.dart';

/// How long before something expires a reminder goes off.
///
/// Stored by name: don't rename the values.
enum ReminderLead {
  threeMonths('3 months', months: 3),
  twoMonths('2 months', months: 2),
  oneMonth('1 month', months: 1),
  twoWeeks('2 weeks', days: 14),
  oneWeek('1 week', days: 7),
  threeDays('3 days', days: 3),
  oneDay('1 day', days: 1),
  onTheDay('On the last day');

  const ReminderLead(this.label, {this.months = 0, this.days = 0});

  final String label;
  final int months;
  final int days;

  /// The day the reminder for something valid until [validUntil] is due.
  DateTime dueFor(DateTime validUntil) => months > 0
      ? addMonths(validUntil, -months)
      : DateTime(validUntil.year, validUntil.month, validUntil.day - days);

  /// Roughly how many days ahead it is.
  int get approxDays => months * 30 + days;

  /// "in 3 months", "tomorrow", "today".
  String get relative => switch (this) {
    onTheDay => 'today',
    oneDay => 'tomorrow',
    _ => 'in $label',
  };
}

/// What the licence & currency reminders do.
@immutable
class CurrencySettings {
  const CurrencySettings({
    this.notificationsEnabled = true,
    this.leads = defaultLeads,
    this.recencyReminders = true,
    this.reminderTime = const TimeOfDay(hour: 9, minute: 0),
  });

  static const defaultLeads = {
    ReminderLead.threeMonths,
    ReminderLead.oneMonth,
    ReminderLead.oneWeek,
  };

  final bool notificationsEnabled;
  final Set<ReminderLead> leads;

  /// Whether recency worked out from the logbook (passengers, LAPL) gets
  /// reminders too, not only expiry dates.
  final bool recencyReminders;

  /// Time of day reminders go off.
  final TimeOfDay reminderTime;

  /// How many days before expiry something is shown as expiring: the
  /// earliest reminder, or a month without any.
  int get warnDays {
    final days = [for (final l in leads) l.approxDays];
    if (days.isEmpty) return 30;
    final max = days.reduce((a, b) => a > b ? a : b);
    return max < 7 ? 7 : max;
  }

  CurrencySettings copyWith({
    bool? notificationsEnabled,
    Set<ReminderLead>? leads,
    bool? recencyReminders,
    TimeOfDay? reminderTime,
  }) => CurrencySettings(
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    leads: leads ?? this.leads,
    recencyReminders: recencyReminders ?? this.recencyReminders,
    reminderTime: reminderTime ?? this.reminderTime,
  );

  @override
  bool operator ==(Object other) =>
      other is CurrencySettings &&
      other.notificationsEnabled == notificationsEnabled &&
      other.leads.length == leads.length &&
      other.leads.containsAll(leads) &&
      other.recencyReminders == recencyReminders &&
      other.reminderTime == reminderTime;

  @override
  int get hashCode => Object.hash(
    notificationsEnabled,
    Object.hashAllUnordered(leads),
    recencyReminders,
    reminderTime,
  );
}

class CurrencySettingsNotifier extends Notifier<CurrencySettings> {
  static const enabledKey = 'currency_notifications_enabled';
  static const leadsKey = 'currency_reminder_leads';
  static const recencyKey = 'currency_recency_reminders';
  static const timeKey = 'currency_reminder_minutes';

  @override
  CurrencySettings build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final leadNames = prefs.getStringList(leadsKey);
    final byName = ReminderLead.values.asNameMap();
    final minutes = prefs.getInt(timeKey);
    return CurrencySettings(
      notificationsEnabled: prefs.getBool(enabledKey) ?? true,
      leads: leadNames == null
          ? CurrencySettings.defaultLeads
          : {...leadNames.map((n) => byName[n]).nonNulls},
      recencyReminders: prefs.getBool(recencyKey) ?? true,
      reminderTime: minutes == null
          ? const TimeOfDay(hour: 9, minute: 0)
          : TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
  }

  Future<void> setNotificationsEnabled({required bool enabled}) async {
    state = state.copyWith(notificationsEnabled: enabled);
    await ref.read(sharedPreferencesProvider).setBool(enabledKey, enabled);
  }

  Future<void> setLead(ReminderLead lead, {required bool enabled}) async {
    final leads = {...state.leads};
    enabled ? leads.add(lead) : leads.remove(lead);
    state = state.copyWith(leads: leads);
    await ref.read(sharedPreferencesProvider).setStringList(leadsKey, [
      for (final l in ReminderLead.values)
        if (leads.contains(l)) l.name,
    ]);
  }

  Future<void> setRecencyReminders({required bool enabled}) async {
    state = state.copyWith(recencyReminders: enabled);
    await ref.read(sharedPreferencesProvider).setBool(recencyKey, enabled);
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    state = state.copyWith(reminderTime: time);
    await ref
        .read(sharedPreferencesProvider)
        .setInt(timeKey, time.hour * 60 + time.minute);
  }
}

final currencySettingsProvider =
    NotifierProvider<CurrencySettingsNotifier, CurrencySettings>(
      CurrencySettingsNotifier.new,
    );
