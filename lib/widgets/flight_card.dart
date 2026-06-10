import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/unit_provider.dart';
import '../services/database.dart';

class FlightCard extends ConsumerWidget {
  final FlightWithStats flight;
  final VoidCallback? onTap;

  const FlightCard({super.key, required this.flight, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');
    final unitMode = ref.watch(unitProvider);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.flight_takeoff, color: theme.colorScheme.onPrimaryContainer, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          flight.flight.title,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${dateFormat.format(flight.flight.departureTime)} · ${timeFormat.format(flight.flight.departureTime)}',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (flight.aircraftType != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        flight.aircraftType!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatItem(label: 'Duration', value: flight.duration != null ? '${flight.duration!.inMinutes} min' : '--'),
                  const SizedBox(width: 24),
                  _StatItem(
                    label: 'Max Alt',
                    value: flight.maxAltitude != null
                        ? unitMode == MeasurementUnit.metric
                            ? '${flight.maxAltitude!.toStringAsFixed(0)} m'
                            : '${(flight.maxAltitude! * 3.28084).toStringAsFixed(0)} ft'
                        : '--',
                  ),
                  const SizedBox(width: 24),
                  _StatItem(
                    label: 'Distance',
                    value: flight.totalDistance != null
                        ? unitMode == MeasurementUnit.metric
                            ? '${flight.totalDistance!.toStringAsFixed(1)} km'
                            : '${(flight.totalDistance! * 0.539957).toStringAsFixed(1)} nm'
                        : '--',
                  ),
                ],
              ),
              if (flight.departureIdent != null || flight.arrivalIdent != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (flight.departureIdent != null)
                      _RouteChip(label: flight.departureIdent!, icon: Icons.flight_takeoff),
                    if (flight.departureIdent != null && flight.arrivalIdent != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward, size: 16, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    if (flight.arrivalIdent != null)
                      _RouteChip(label: flight.arrivalIdent!, icon: Icons.flight_land),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _RouteChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _RouteChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.colorScheme.onTertiaryContainer),
          const SizedBox(width: 4),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onTertiaryContainer)),
        ],
      ),
    );
  }
}
