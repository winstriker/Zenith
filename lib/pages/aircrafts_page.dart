import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database.dart';
import '../providers/aircraft_providers.dart';
import '../widgets/aircraft_card.dart';
import 'aircraft_form_page.dart';
import 'aircraft_detail_page.dart';
import '../main.dart';

class AircraftsPage extends ConsumerStatefulWidget {
  const AircraftsPage({super.key});

  @override
  ConsumerState<AircraftsPage> createState() => _AircraftsPageState();
}

class _AircraftsPageState extends ConsumerState<AircraftsPage> {
  @override
  Widget build(BuildContext context) {
    final aircraftList = ref.watch(aircraftListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Aircraft'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add aircraft',
            onPressed: () => _showAddDialog(),
          ),
        ],
      ),
      body: aircraftList.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.airplanemode_active,
                      size: 64,
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No aircraft yet',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your first aircraft to start tracking flights.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => _showAddDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Aircraft'),
                    ),
                  ],
                ),
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
  }

  Future<void> _showAddDialog() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AircraftFormPage()),
    );
    if (result == true) {
      ref.read(aircraftListProvider.notifier).refresh();
    }
  }

  Future<void> _showDetailPage(AircraftWithStats aws) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AircraftDetailPage(aircraft: aws)),
    );
    if (result == true) {
      ref.read(aircraftListProvider.notifier).refresh();
    }
  }

  Future<void> _confirmDelete(AircraftWithStats aws) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Aircraft'),
        content: Text(
          'Are you sure you want to delete "${aws.aircraft.type}"?',
        ),
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
      ref.read(aircraftListProvider.notifier).refresh();
    }
  }
}
