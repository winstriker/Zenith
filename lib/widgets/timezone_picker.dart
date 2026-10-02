import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import '../providers/flight_form_provider.dart';

class TimezonePicker {
  static void show({
    required BuildContext context,
    required TimezoneMode currentMode,
    required String? currentIanaLocation,
    required ValueChanged<TimezoneMode> onModeChanged,
    required ValueChanged<String?> onIanaLocationChanged,
    required bool isDeparture,
    required DateTime referenceDate,
  }) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Select Timezone',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _TimezoneListTile(
                title: 'UTC',
                leadingIcon: Icons.language,
                onTap: () {
                  Navigator.pop(ctx);
                  onModeChanged(TimezoneMode.utc);
                },
              ),
              _TimezoneListTile(
                title: 'Local Time',
                leadingIcon: Icons.access_time,
                onTap: () {
                  Navigator.pop(ctx);
                  onModeChanged(TimezoneMode.local);
                },
              ),
              _TimezoneListTile(
                title: 'Other (search world timezone...)',
                leadingIcon: Icons.search,
                onTap: () {
                  Navigator.pop(ctx);
                  _showIanaTzSearch(
                    context: context,
                    referenceDate: referenceDate,
                    currentIanaLocation: currentIanaLocation,
                    onIanaLocationChanged: onIanaLocationChanged,
                    onModeChanged: onModeChanged,
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  static void _showIanaTzSearch({
    required BuildContext context,
    required DateTime referenceDate,
    required String? currentIanaLocation,
    required ValueChanged<String?> onIanaLocationChanged,
    required ValueChanged<TimezoneMode> onModeChanged,
  }) {
    final controller = TextEditingController();
    final allTimezones = _buildTimezoneList(referenceDate);
    List<_TimezoneEntry> filtered = allTimezones;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, scrollController) {
            return StatefulBuilder(
              builder: (ctx, setModalState) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'World Timezones',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Search name, abbreviation, or offset...',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (v) {
                          setModalState(() {
                            final query = v.toLowerCase().trim();
                            if (query.isEmpty) {
                              filtered = allTimezones;
                            } else {
                              filtered = allTimezones.where((entry) {
                                final nameMatch = entry.name
                                    .toLowerCase()
                                    .contains(query);
                                final abbrMatch = entry.abbreviation
                                    .toLowerCase()
                                    .contains(query);
                                final offsetMatch = entry.offset
                                    .toLowerCase()
                                    .contains(query);
                                return nameMatch || abbrMatch || offsetMatch;
                              }).toList();
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final entry = filtered[i];
                          return _TimezoneListTile(
                            title: entry.name,
                            leading: entry.offset,
                            trailing: entry.abbreviation,
                            onTap: () {
                              Navigator.pop(ctx);
                              onModeChanged(TimezoneMode.iana);
                              onIanaLocationChanged(entry.name);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  static List<_TimezoneEntry> _buildTimezoneList(DateTime referenceDate) {
    final timezones = tz.timeZoneDatabase.locations.keys.toList();
    return timezones.map((name) {
      final location = tz.getLocation(name);
      final tzDateTime = tz.TZDateTime.from(referenceDate, location);
      return _TimezoneEntry(
        name: name,
        offset: _formatOffset(tzDateTime.timeZoneOffset),
        abbreviation: tzDateTime.timeZone.abbreviation,
      );
    }).toList();
  }

  static String _formatOffset(Duration offset) {
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    return '$sign$hours:$minutes';
  }
}

class _TimezoneEntry {
  _TimezoneEntry({
    required this.name,
    required this.offset,
    required this.abbreviation,
  });
  final String name;
  final String offset;
  final String abbreviation;
}

class _TimezoneListTile extends StatelessWidget {
  const _TimezoneListTile({
    required this.title,
    this.leadingIcon,
    this.leading,
    this.trailing,
    this.onTap,
  });
  final String title;
  final IconData? leadingIcon;
  final String? leading;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      dense: true,
      leading: leadingIcon != null
          ? Icon(leadingIcon, color: theme.colorScheme.onSurfaceVariant)
          : leading != null
          ? Text(
              leading!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontFamily: 'monospace',
              ),
            )
          : null,
      title: Text(title),
      trailing: trailing != null
          ? Text(
              trailing!,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}
