import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import '../core/spacing.dart';
import '../services/database.dart';
import '../utils/duration_formatter.dart';
import 'gradient_card.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy');
    final timeFormat = DateFormat('HH:mm');

    final card = BaseCard(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildSide(
              theme: theme,
              airport: flight.departure,
              departureTime: flight.flight.departureTime,
              arrivalTime: flight.flight.arrivalTime,
              departureIanaLocation: flight.flight.departureIanaLocation,
              arrivalIanaLocation: flight.flight.arrivalIanaLocation,
              dateFormat: dateFormat,
              timeFormat: timeFormat,
              crossAxisAlignment: CrossAxisAlignment.start,
              timeAlignment: TextAlign.left,
            ),
          ),
          const SizedBox(width: 12),
          _buildCenterSection(theme),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSide(
              theme: theme,
              airport: flight.arrival,
              departureTime: flight.flight.departureTime,
              arrivalTime: flight.flight.arrivalTime,
              departureIanaLocation: flight.flight.departureIanaLocation,
              arrivalIanaLocation: flight.flight.arrivalIanaLocation,
              dateFormat: dateFormat,
              timeFormat: timeFormat,
              crossAxisAlignment: CrossAxisAlignment.end,
              timeAlignment: TextAlign.right,
              right: true,
            ),
          ),
        ],
      ),
    );

    if (!useOuterPadding) return card;
    return Padding(padding: AppSpacing.cardPadding, child: card);
  }

  Widget _buildSide({
    required ThemeData theme,
    required Airport? airport,
    required DateTime departureTime,
    required DateTime? arrivalTime,
    required String? departureIanaLocation,
    required String? arrivalIanaLocation,
    required DateFormat dateFormat,
    required DateFormat timeFormat,
    required CrossAxisAlignment crossAxisAlignment,
    required TextAlign timeAlignment,
    bool right = false,
  }) {
    final code =
        airport?.ident ?? airport?.icaoCode ?? airport?.iataCode ?? '----';
    final name = airport?.name ?? '';
    final countryCode = airport?.isoCountry;

    // Reconstruct TZDateTime using stored IANA locations
    final depLocal = _toLocalTZDateTime(departureTime, departureIanaLocation);
    final arrLocal = arrivalTime != null
        ? _toLocalTZDateTime(arrivalTime, arrivalIanaLocation)
        : null;

    final isDeparture = !right;
    final localTime = isDeparture ? depLocal : (arrLocal ?? depLocal);
    final localTz = isDeparture
        ? (depLocal.timeZone.abbreviation)
        : (arrLocal?.timeZone.abbreviation ?? depLocal.timeZone.abbreviation);

    final utcTime = localTime.toUtc();
    final showUtc = localTime.timeZoneOffset != Duration.zero;

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          '${dateFormat.format(localTime)} $localTz',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (right) ...[
              Flexible(
                child: Text(
                  code,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            if (countryCode != null && countryCode.length == 2) ...[
              if (right) ...[const SizedBox(width: 6)],
              SizedBox(
                width: 26,
                height: 18,
                child: CountryFlag.fromCountryCode(
                  countryCode,
                  theme: const ImageTheme(shape: RoundedRectangle(3)),
                ),
              ),
              if (!right) ...[const SizedBox(width: 6)],
            ],
            if (!right) ...[
              Flexible(
                child: Text(
                  code,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        if (name.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            name,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 4),
        Text(
          '${timeFormat.format(localTime)} $localTz',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: timeAlignment,
        ),
        if (showUtc) ...[
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.7,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'UTC ${timeFormat.format(utcTime)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }

  static tz.TZDateTime _toLocalTZDateTime(
    DateTime utcTime,
    String? ianaLocation,
  ) {
    final location = ianaLocation != null
        ? tz.getLocation(ianaLocation)
        : tz.local;
    return tz.TZDateTime.from(utcTime, location);
  }

  Widget _buildCenterSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Icon(Icons.flight, size: 20, color: theme.colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            flight.duration != null
                ? DurationFormatter.hm(flight.duration!)
                : '--:--',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          if (flight.aircraft != null && flight.aircraft!.tailNumber != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                flight.aircraft!.tailNumber!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
