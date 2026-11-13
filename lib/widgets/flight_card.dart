import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../core/spacing.dart';
import '../services/database.dart';
import '../utils/duration_formatter.dart';
import 'base_card.dart';

class FlightCard extends StatelessWidget {
  const FlightCard({
    super.key,
    required this.flight,
    this.onTap,
    this.onLongPress,
    this.useOuterPadding = true,
  });
  final FlightWithStats flight;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool useOuterPadding;

  static tz.TZDateTime _toLocalTZDateTime(
    DateTime utcTime,
    String? ianaLocation,
  ) {
    final location = ianaLocation != null
        ? tz.getLocation(ianaLocation)
        : tz.local;
    return tz.TZDateTime.from(utcTime, location);
  }

  @override
  Widget build(BuildContext context) {
    // Reconstruct TZDateTime using stored IANA locations
    final f = flight.flight;
    final depLocal = _toLocalTZDateTime(
      f.departureTime,
      f.departureIanaLocation,
    );
    final arrLocal = f.arrivalTime != null
        ? _toLocalTZDateTime(f.arrivalTime!, f.arrivalIanaLocation)
        : null;

    final card = BaseCard(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _FlightEndpoint(
              airport: flight.departure,
              localTime: depLocal,
              alignEnd: false,
            ),
          ),
          const SizedBox(width: 12),
          _FlightCenter(
            duration: flight.duration,
            tailNumber: flight.aircraftWithStats?.tailNumber,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _FlightEndpoint(
              airport: flight.arrival,
              localTime: arrLocal ?? depLocal,
              alignEnd: true,
            ),
          ),
        ],
      ),
    );

    if (!useOuterPadding) return card;
    return Padding(padding: AppSpacing.cardPadding, child: card);
  }
}

/// Departure (left aligned) or arrival (right aligned) column of a flight.
class _FlightEndpoint extends StatelessWidget {
  const _FlightEndpoint({
    required this.airport,
    required this.localTime,
    required this.alignEnd,
  });

  final Airport? airport;
  final tz.TZDateTime localTime;
  final bool alignEnd;

  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _timeFormat = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final code =
        airport?.ident ?? airport?.icaoCode ?? airport?.iataCode ?? '----';
    final name = airport?.name ?? '';
    final countryCode = airport?.isoCountry;
    final localTz = localTime.timeZone.abbreviation;
    final showUtc = localTime.timeZoneOffset != Duration.zero;

    final codeText = Flexible(
      child: Text(
        code,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
      ),
    );
    final flag = countryCode != null && countryCode.length == 2
        ? SizedBox(
            width: 26,
            height: 18,
            child: CountryFlag.fromCountryCode(
              countryCode,
              theme: const ImageTheme(shape: RoundedRectangle(3)),
            ),
          )
        : null;

    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          '${_dateFormat.format(localTime)} $localTz',
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: alignEnd
              ? [
                  codeText,
                  if (flag != null) ...[const SizedBox(width: 6), flag],
                ]
              : [
                  if (flag != null) ...[flag, const SizedBox(width: 6)],
                  codeText,
                ],
        ),
        if (name.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            name,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 4),
        Text(
          '${_timeFormat.format(localTime)} $localTz',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
        ),
        if (showUtc) ...[
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'UTC ${_timeFormat.format(localTime.toUtc())}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FlightCenter extends StatelessWidget {
  const _FlightCenter({required this.duration, required this.tailNumber});

  final Duration? duration;
  final String? tailNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Icon(Icons.flight, size: 20, color: cs.primary),
          const SizedBox(height: 4),
          Text(
            duration != null ? DurationFormatter.hm(duration!) : '--:--',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          if (tailNumber != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                tailNumber!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
