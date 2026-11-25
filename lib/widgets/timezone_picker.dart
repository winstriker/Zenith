import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import '../providers/flight_form_provider.dart';
import 'picker_sheet.dart';

class TimezonePicker {
  static Future<void> show({
    required BuildContext context,
    required TimezoneMode currentMode,
    required String? currentIanaLocation,
    required ValueChanged<TimezoneMode> onModeChanged,
    required ValueChanged<String?> onIanaLocationChanged,
    required bool isDeparture,
    required DateTime referenceDate,
  }) async {
    final mode = await showPickerSheet<TimezoneMode>(
      context,
      title: 'Select Timezone',
      items: TimezoneMode.values,
      label: (m) => switch (m) {
        TimezoneMode.utc => 'UTC',
        TimezoneMode.local => 'Local Time',
        TimezoneMode.iana => 'Other (search world timezone...)',
      },
      selected: currentMode,
    );
    if (mode == null || !context.mounted) return;
    if (mode != TimezoneMode.iana) return onModeChanged(mode);

    final location = await showPickerSheet<String>(
      context,
      title: 'World Timezones',
      items: tz.timeZoneDatabase.locations.keys.toList(),
      label: (name) => name,
      subtitle: (name) {
        final date = tz.TZDateTime.from(referenceDate, tz.getLocation(name));
        return '${_formatOffset(date.timeZoneOffset)} · '
            '${date.timeZone.abbreviation}';
      },
      selected: currentIanaLocation,
      searchHint: 'Search name, abbreviation, or offset...',
    );
    if (location == null || !context.mounted) return;
    onModeChanged(TimezoneMode.iana);
    onIanaLocationChanged(location);
  }

  static String _formatOffset(Duration offset) {
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    return '$sign$hours:$minutes';
  }
}
