import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import '../services/database.dart';
import 'airport_field.dart';
import 'date_button.dart';
import 'time_input.dart';
import 'time_pill.dart';
import 'tz_chip.dart';

class FlightFormCard extends StatelessWidget {
  const FlightFormCard({
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
    required this.onDepartureDateTap,
    required this.onArrivalDateTap,
    required this.onDepartureTzTap,
    required this.onArrivalTzTap,
    required this.onDepartureAirportTap,
    required this.onArrivalAirportTap,
    required this.onDepTimeChanged,
    required this.onArrTimeChanged,
    required this.departure,
    required this.arrival,
  });
  final DateTime departureDate;
  final DateTime? arrivalDate;
  final String departureCode;
  final String arrivalCode;
  final String depTime;
  final String arrTime;
  final Airport? selectedDeparture;
  final Airport? selectedArrival;
  final String depTzLabel;
  final String arrTzLabel;
  final VoidCallback onDepartureDateTap;
  final VoidCallback onArrivalDateTap;
  final VoidCallback onDepartureTzTap;
  final VoidCallback onArrivalTzTap;
  final VoidCallback onDepartureAirportTap;
  final VoidCallback onArrivalAirportTap;
  final ValueChanged<String> onDepTimeChanged;
  final ValueChanged<String> onArrTimeChanged;

  /// The instants the dates and times stand for; null until known.
  final tz.TZDateTime? departure;
  final tz.TZDateTime? arrival;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.all(0),
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
                  child: Row(
                    children: [
                      Expanded(
                        child: DateButton(
                          date: departureDate,
                          onTap: onDepartureDateTap,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TzChip(label: depTzLabel, onTap: onDepartureTzTap),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
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
                  child: _TimeSide(
                    time: IntrinsicWidth(
                      child: TimeInput(
                        value: depTime,
                        hint: 'HH:mm',
                        onChanged: onDepTimeChanged,
                        textAlign: TextAlign.start,
                      ),
                    ),
                    zone: TzChip(label: depTzLabel),
                  ),
                ),
                const SizedBox(width: 8),
                TimePill(label: "Block Time", start: departure, end: arrival),
                const SizedBox(width: 8),
                Expanded(
                  child: _TimeSide(
                    isArrival: true,
                    time: IntrinsicWidth(
                      child: TimeInput(
                        value: arrTime,
                        hint: 'HH:mm',
                        onChanged: onArrTimeChanged,
                        textAlign: TextAlign.end,
                      ),
                    ),
                    zone: TzChip(label: arrTzLabel),
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

/// [time] at the edge of the card and its [zone] towards the middle. Short of
/// room, it is the zone that shrinks: the time is always readable.
class _TimeSide extends StatelessWidget {
  const _TimeSide({
    required this.time,
    required this.zone,
    this.isArrival = false,
  });
  final Widget time;
  final Widget zone;
  final bool isArrival;

  @override
  Widget build(BuildContext context) {
    final children = [
      time,
      const SizedBox(width: 8),
      Flexible(
        child: FittedBox(fit: BoxFit.scaleDown, child: zone),
      ),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: isArrival ? children.reversed.toList() : children,
    );
  }
}
