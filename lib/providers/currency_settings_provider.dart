import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/currency.dart';

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
    this.loaded = false,
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

  /// False until read from storage: nothing is scheduled before that.
  final bool loaded;
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
    loaded: loaded,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    leads: leads ?? this.leads,
    recencyReminders: recencyReminders ?? this.recencyReminders,
    reminderTime: reminderTime ?? this.reminderTime,
  );

  @override
  bool operator ==(Object other) =>
      other is CurrencySettings &&
      other.loaded == loaded &&
      other.notificationsEnabled == notificationsEnabled &&
      other.leads.length == leads.length &&
      other.leads.containsAll(leads) &&
      other.recencyReminders == recencyReminders &&
      other.reminderTime == reminderTime;

  @override
  int get hashCode => Object.hash(
    loaded,
    notificationsEnabled,
    Object.hashAllUnordered(leads),
    recencyReminders,
    reminderTime,
  );
}

class CurrencySettingsNotifier extends Notifier<CurrencySettings> {
  static const _enabledKey = 'currency_notifications_enabled';
  static const _leadsKey = 'currency_reminder_leads';
  static const _recencyKey = 'currency_recency_reminders';
  static const _timeKey = 'currency_reminder_minutes';

  @override
  CurrencySettings build() {
    _load();
    return const CurrencySettings();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final leadNames = prefs.getStringList(_leadsKey);
    final byName = ReminderLead.values.asNameMap();
    final minutes = prefs.getInt(_timeKey);
    state = CurrencySettings(
      loaded: true,
      notificationsEnabled: prefs.getBool(_enabledKey) ?? true,
      leads: leadNames == null
          ? CurrencySettings.defaultLeads
          : {...leadNames.map((n) => byName[n]).nonNulls},
      recencyReminders: prefs.getBool(_recencyKey) ?? true,
      reminderTime: minutes == null
          ? const TimeOfDay(hour: 9, minute: 0)
          : TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
  }

  Future<void> setNotificationsEnabled({required bool enabled}) async {
    state = state.copyWith(notificationsEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  Future<void> setLead(ReminderLead lead, {required bool enabled}) async {
    final leads = {...state.leads};
    enabled ? leads.add(lead) : leads.remove(lead);
    state = state.copyWith(leads: leads);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_leadsKey, [
      for (final l in ReminderLead.values)
        if (leads.contains(l)) l.name,
    ]);
  }

  Future<void> setRecencyReminders({required bool enabled}) async {
    state = state.copyWith(recencyReminders: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_recencyKey, enabled);
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    state = state.copyWith(reminderTime: time);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_timeKey, time.hour * 60 + time.minute);
  }
}

final currencySettingsProvider =
    NotifierProvider<CurrencySettingsNotifier, CurrencySettings>(
      CurrencySettingsNotifier.new,
    );
