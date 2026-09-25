import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:logbook/widgets/airport_field.dart';
import 'package:logbook/widgets/date_button.dart';
import 'package:logbook/widgets/time_input.dart';
import 'package:logbook/widgets/time_pill.dart';
import 'package:logbook/widgets/tz_chip.dart';
import 'package:logbook/services/database.dart';

class FlightDetailsCard extends StatelessWidget {
  final DateTime departureDate;
  final DateTime arrivalDate;
  final String departureCode;
  final String arrivalCode;
  final String depTime;
  final String arrTime;
  final Airport? selectedDeparture;
  final Airport? selectedArrival;
  final String depTzLabel;
  final String arrTzLabel;
  final String blockTime;
  final VoidCallback onDepartureDateTap;
  final VoidCallback onArrivalDateTap;
  final VoidCallback onDepartureTzTap;
  final VoidCallback onArrivalTzTap;
  final VoidCallback onDepartureAirportTap;
  final VoidCallback onArrivalAirportTap;
  final ValueChanged<String> onDepTimeChanged;
  final ValueChanged<String> onArrTimeChanged;
  final tz.TZDateTime Function(String, DateTime, String?) parseDateTime;
  final String? depIanaLocation;
  final String? arrIanaLocation;

  const FlightDetailsCard({
    super.key,
    required this.departureDate,
    required this.arrivalDate,
    required this.departureCode,
    required this.arrivalCode,
    required this.depTime,
    required this.arrTime,
    required this.selectedDeparture,
    required this.selectedArrival,
    required this.depTzLabel,
    required this.arrTzLabel,
    required this.blockTime,
    required this.onDepartureDateTap,
    required this.onArrivalDateTap,
    required this.onDepartureTzTap,
    required this.onArrivalTzTap,
    required this.onDepartureAirportTap,
    required this.onArrivalAirportTap,
    required this.onDepTimeChanged,
    required this.onArrTimeChanged,
    required this.parseDateTime,
    required this.depIanaLocation,
    required this.arrIanaLocation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      margin: EdgeInsets.all(0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'DEP',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'ARR',
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DateButton(
                    date: departureDate,
                    onTap: onDepartureDateTap,
                  ),
                ),
                const SizedBox(width: 8),
                TzChip(label: depTzLabel, onTap: onDepartureTzTap),
                const SizedBox(width: 8),
                TzChip(label: arrTzLabel, onTap: onArrivalTzTap),
                const SizedBox(width: 8),
                Expanded(
                  child: DateButton(
                    date: arrivalDate,
                    onTap: onArrivalDateTap,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AirportField(
                    code: departureCode,
                    label: 'DEP Airport',
                    selectedAirport: selectedDeparture,
                    onTap: onDepartureAirportTap,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.flight,
                    color: cs.onSurfaceVariant,
                    size: 20,
                  ),
                ),
                Expanded(
                  child: AirportField(
                    code: arrivalCode,
                    label: 'ARR Airport',
                    selectedAirport: selectedArrival,
                    onTap: onArrivalAirportTap,
                    isArrival: true,
                  ),
                ),
              ],
            ),
            if (selectedDeparture?.name != null ||
                selectedArrival?.name != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedDeparture?.name ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 36),
                  Expanded(
                    child: Text(
                      selectedArrival?.name ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TimeInput(
                    value: depTime,
                    hint: 'HH:mm',
                    onChanged: onDepTimeChanged,
                  ),
                ),
                const SizedBox(width: 8),
                TzChip(label: depTzLabel, onTap: null),
                const SizedBox(width: 8),
                TimePill(
                  label: "Block Time",
                  start: (depTime.isEmpty || depIanaLocation == null)
                      ? null
                      : parseDateTime(depTime, departureDate, depIanaLocation),
                  end: (arrTime.isEmpty || arrIanaLocation == null)
                      ? null
                      : parseDateTime(arrTime, arrivalDate, arrIanaLocation),
                ),
                const SizedBox(width: 8),
                TzChip(label: arrTzLabel, onTap: null),
                const SizedBox(width: 8),
                Expanded(
                  child: TimeInput(
                    value: arrTime,
                    hint: 'HH:mm',
                    onChanged: onArrTimeChanged,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
