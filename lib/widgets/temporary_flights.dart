import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_page_route.dart';
import '../pages/flight_form_page.dart';
import '../providers/flight_providers.dart';
import '../services/database.dart';
import 'flight_card.dart';

/// The recorded flights still to be completed, as a sliver: a header and
/// their cards, from the first to the last recorded position. Tapping one
/// opens it in the flight form, where saving puts it in the logbook. Empty
/// when there are none.
class TemporaryFlightsSliver extends ConsumerWidget {
  const TemporaryFlightsSliver({super.key});

  Future<void> _confirmDiscard(
    BuildContext context,
    WidgetRef ref,
    FlightWithStats flight,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard recording?'),
        content: const Text('The recorded track will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(flightServiceProvider).deleteSession(flight.flight.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flights = ref.watch(temporaryFlightsProvider).value ?? const [];
    if (flights.isEmpty) return const SliverToBoxAdapter();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
            child: Row(
              children: [
                Icon(Icons.edit_note, size: 20, color: cs.tertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'To complete',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Recorded flights, not in the logbook until saved',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverList.builder(
          itemCount: flights.length,
          itemBuilder: (context, index) {
            final flight = flights[index];
            return FlightCard(
              flight: flight,
              onTap: () => Navigator.push(
                context,
                AppPageRoute<void>(
                  builder: (_) => FlightFormPage(flightToEdit: flight),
                ),
              ),
              onLongPress: () => _confirmDiscard(context, ref, flight),
            );
          },
        ),
      ],
    );
  }
}
