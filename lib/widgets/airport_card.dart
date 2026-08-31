import 'package:flutter/material.dart';
import 'package:logbook/services/database.dart';
import '../core/spacing.dart';
import 'gradient_card.dart';
import 'info_chip.dart';

class AirportCard extends StatelessWidget {
  final Airport airport;
  final VoidCallback? onTap;
  final double? distanceKm;

  const AirportCard({
    super.key,
    required this.airport,
    this.onTap,
    this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: AppSpacing.cardPadding,
      child: BaseCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _airportIcon(airport.type),
                    color: cs.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        airport.name ?? "",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        airport.municipality ?? airport.isoCountry,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (airport.ident != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      airport.ident!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                InfoChip(
                  label: AirportType.getDisplayName(airport.type),
                  backgroundColor: cs.tertiaryContainer,
                  textColor: cs.onTertiaryContainer,
                ),
                if (distanceKm != null) ...[
                  const SizedBox(width: 8),
                  InfoChip(
                    label: distanceKm! < 1
                        ? '${(distanceKm! * 1000).toStringAsFixed(0)} m'
                        : '${distanceKm!.toStringAsFixed(1)} km',
                    icon: Icons.near_me,
                    backgroundColor: cs.surfaceContainerHighest,
                    textColor: cs.onSurfaceVariant,
                  ),
                ],
                if (airport.elevationFt != null) ...[
                  const SizedBox(width: 8),
                  InfoChip(
                    label: '${airport.elevationFt!.toStringAsFixed(0)} ft',
                    icon: Icons.trending_up,
                    backgroundColor: cs.surfaceContainerHighest,
                    textColor: cs.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _airportIcon(AirportType type) {
    switch (type) {
      case AirportType.largeAirport:
      case AirportType.mediumAirport:
      case AirportType.smallAirport:
        return Icons.flight;
      case AirportType.heliport:
        return Icons.airplanemode_active;
      case AirportType.seaplaneBase:
        return Icons.directions_boat;
      case AirportType.closed:
        return Icons.block;
      case AirportType.balloonport:
        return Icons.cloud_sharp;
      default:
        return Icons.flight;
    }
  }
}
