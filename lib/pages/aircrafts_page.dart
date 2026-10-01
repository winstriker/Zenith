import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';
import '../providers/aircraft_providers.dart';
import '../services/database.dart';
import '../widgets/aircraft_card.dart';
import '../widgets/empty_state.dart';
import 'aircraft_detail_page.dart';
import 'aircraft_form_page.dart';

class AircraftsPage extends ConsumerStatefulWidget {
  const AircraftsPage({super.key});

  @override
  ConsumerState<AircraftsPage> createState() => _AircraftsPageState();
}

class _AircraftsPageState extends ConsumerState<AircraftsPage> {
  @override
  Widget build(BuildContext context) {
    final aircraftAsync = ref.watch(aircraftListStreamProvider);

    return aircraftAsync.when(
      data: (aircraftList) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('My Aircraft'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Add aircraft',
                onPressed: _showAddDialog,
              ),
            ],
          ),
          body: aircraftList.isEmpty
              ? EmptyState(
                  icon: Icons.airplanemode_active,
                  title: 'No aircraft yet',
                  subtitle:
                      'Add your first aircraft to start tracking flights.',
                  action: FilledButton.icon(
                    onPressed: _showAddDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Aircraft'),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: aircraftList.length,
                  itemBuilder: (context, index) {
                    final aws = aircraftList[index];
                    return AircraftCard(
                      aircraft: aws,
                      onTap: () => _showDetailPage(aws),
                      onLongPress: () => _confirmDelete(aws),
                    );
                  },
                ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  Future<void> _showAddDialog() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AircraftFormPage()),
    );
    // Stream provider automatically updates, no manual refresh needed
  }

  Future<void> _showDetailPage(AircraftWithStats aws) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AircraftDetailPage(aircraftId: aws.aircraft.id),
      ),
    );
    // Stream provider automatically updates
  }

  Future<void> _confirmDelete(AircraftWithStats aws) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Aircraft'),
        content: Text('Are you sure you want to delete "${aws.tailNumber}"?'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final db = ref.read(databaseProvider);
      await db.deleteAircraft(aws.aircraft.id);
      // Stream provider automatically updates
    }
  }
}
