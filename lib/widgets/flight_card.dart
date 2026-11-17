import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../core/spacing.dart';
import '../services/database.dart';
import '../utils/duration_formatter.dart';
import 'base_card.dart';
import 'overridden_icon.dart';
import 'simulator_card.dart';

class FlightCard extends StatelessWidget {
  const FlightCard({
    super.key,
    required this.flight,
    this.onTap,
    this.onLongPress,
    this.useOuterPadding = true,
    this.totalTimeOverride,
  });
  final FlightWithStats flight;

  /// Shown instead of the block time, marked as overridden, when the pilot
  /// overrode the total time for the logbook (the FSTD time of a simulator
  /// session).
  final Duration? totalTimeOverride;
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

    final card = flight.isSimulatorSession
        ? BaseCard(
            onTap: onTap,
            onLongPress: onLongPress,
            child: _SessionRow(
              flight: flight,
              start: depLocal,
              end: arrLocal,
              duration: totalTimeOverride ?? flight.duration,
              overridden: totalTimeOverride != null,
            ),
          )
        : BaseCard(
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
                  duration: totalTimeOverride ?? flight.duration,
                  overridden: totalTimeOverride != null,
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

/// A simulator session: the device on the left, its times on the right.
class _SessionRow extends StatelessWidget {
  const _SessionRow({
    required this.flight,
    required this.start,
    required this.end,
    required this.duration,
    required this.overridden,
  });

  final FlightWithStats flight;
  final tz.TZDateTime start;
  final tz.TZDateTime? end;
  final Duration? duration;
  final bool overridden;

  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _timeFormat = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sim = flight.simulator;
    final muted = theme.textTheme.labelSmall?.copyWith(
      color: cs.onSurfaceVariant,
    );
    final organisation = sim?.simulator.organisation?.trim() ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_dateFormat.format(start)} · Simulator', style: muted),
              const SizedBox(height: 6),
              Text(
                sim?.represents ?? sim?.kind.label ?? 'Simulator',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                organisation.isNotEmpty
                    ? organisation
                    : sim?.kind.description ?? '',
                style: muted,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _FlightCenter(
          duration: duration,
          overridden: overridden,
          tailNumber: sim?.deviceLabel,
          icon: simulatorIcon,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(start.timeZone.abbreviation, style: muted),
              const SizedBox(height: 6),
              Text(
                [
                  _timeFormat.format(start),
                  if (end != null) _timeFormat.format(end!),
                ].join(' – '),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FlightCenter extends StatelessWidget {
  const _FlightCenter({
    required this.duration,
    required this.tailNumber,
    this.overridden = false,
    this.icon = Icons.flight,
  });

  final Duration? duration;
  final bool overridden;

  /// Registration, or the kind of device of a simulator session.
  final String? tailNumber;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Icon(icon, size: 20, color: cs.primary),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                duration != null ? DurationFormatter.hm(duration!) : '--:--',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (overridden) ...[
                const SizedBox(width: 2),
                const OverriddenIcon(size: 18),
              ],
            ],
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
