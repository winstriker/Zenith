import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/aircraft_repository.dart';
import '../services/database.dart';
import '../widgets/aircraft_list_scaffold.dart';
import 'aircraft_detail_page.dart';

class AircraftsPage extends ConsumerStatefulWidget {
  const AircraftsPage({super.key});

  @override
  ConsumerState<AircraftsPage> createState() => _AircraftsPageState();
}

class _AircraftsPageState extends ConsumerState<AircraftsPage> {
  @override
  Widget build(BuildContext context) {
    return AircraftListScaffold(
      title: 'My Aircrafts',
      onTap: _showDetailPage,
      onLongPress: _confirmDelete,
    );
  }

  Future<void> _showDetailPage(AircraftWithStats aws) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AircraftDetailPage(aircraftId: aws.id),
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
      await ref.read(aircraftRepositoryProvider).deleteAircraft(aws.id);
      // Stream provider automatically updates
    }
  }
}
