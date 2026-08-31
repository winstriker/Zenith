import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database.dart';

class FlightCard extends StatelessWidget {
  final FlightWithStats flight;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const FlightCard({
    super.key,
    required this.flight,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildSide(
                  theme: theme,
                  airport: flight.departure,
                  time: flight.flight.departureTime,
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
                  time:
                      flight.flight.arrivalTime ?? flight.flight.departureTime,
                  dateFormat: dateFormat,
                  timeFormat: timeFormat,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  timeAlignment: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSide({
    required ThemeData theme,
    required Airport? airport,
    required DateTime time,
    required DateFormat dateFormat,
    required DateFormat timeFormat,
    required CrossAxisAlignment crossAxisAlignment,
    required TextAlign timeAlignment,
  }) {
    final code =
        airport?.ident ?? airport?.icaoCode ?? airport?.iataCode ?? '----';
    final name = airport?.name ?? '';
    final countryCode = airport?.isoCountry;
    final tzAbbr = _tzAbbreviation(airport?.longitudeDeg);
    final utcOffset = _utcOffsetHours(airport?.longitudeDeg);
    final displayTime = time;

    final localTz = tzAbbr ?? 'UTC';
    final isUtc = utcOffset == 0;
    final utcTime = isUtc ? null : displayTime.toUtc();

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          '${dateFormat.format(displayTime)} $localTz',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (countryCode != null && countryCode.length == 2) ...[
              SizedBox(
                width: 26,
                height: 18,
                child: CountryFlag.fromCountryCode(
                  countryCode,
                  theme: const ImageTheme(shape: RoundedRectangle(3)),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                code,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (name.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            name,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 4),
        Text(
          '${timeFormat.format(displayTime)} $localTz',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: timeAlignment,
        ),
        if (utcTime != null) ...[
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

  Widget _buildCenterSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Icon(Icons.flight, size: 20, color: theme.colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            flight.duration != null
                ? _formatDuration(flight.duration!)
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

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return '$h:${m.toString().padLeft(2, '0')}';
  }

  static int? _utcOffsetHours(double? longitude) {
    if (longitude == null) return 0;
    return (longitude / 15).round().clamp(-12, 14);
  }

  static String? _tzAbbreviation(double? longitude) {
    final offset = _utcOffsetHours(longitude);
    if (offset == null || offset == 0) return null;
    const zones = {
      -12: 'UTC-12',
      -11: 'UTC-11',
      -10: 'HST',
      -9: 'AKST',
      -8: 'PST',
      -7: 'MST',
      -6: 'CST',
      -5: 'EST',
      -4: 'AST',
      -3: 'BRT',
      -2: 'UTC-2',
      -1: 'UTC-1',
      1: 'CET',
      2: 'EET',
      3: 'MSK',
      4: 'UTC+4',
      5: 'UTC+5',
      6: 'UTC+6',
      7: 'UTC+7',
      8: 'CST',
      9: 'JST',
      10: 'AEST',
      11: 'UTC+11',
      12: 'NZST',
      13: 'UTC+13',
      14: 'UTC+14',
    };
    return zones[offset] ?? 'UTC${offset > 0 ? '+' : ''}$offset';
  }
}
