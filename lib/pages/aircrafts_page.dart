import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_page_route.dart';
import '../repositories/aircraft_repository.dart';
import '../repositories/simulator_repository.dart';
import '../services/database.dart';
import '../widgets/aircraft_list_scaffold.dart';
import '../widgets/simulator_card.dart';
import '../widgets/simulator_list_scaffold.dart';
import 'aircraft_detail_page.dart';
import 'simulator_detail_page.dart';

enum _Fleet { aircraft, simulators }

/// The user's aircraft and, behind a split button, their simulators.
class AircraftsPage extends ConsumerStatefulWidget {
  const AircraftsPage({super.key});

  @override
  ConsumerState<AircraftsPage> createState() => _AircraftsPageState();
}

class _AircraftsPageState extends ConsumerState<AircraftsPage> {
  _Fleet _fleet = _Fleet.aircraft;

  @override
  Widget build(BuildContext context) {
    final header = Padding(
      // 8 on top keeps the split button's border clear of the title.
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<_Fleet>(
          segments: const [
            ButtonSegment(
              value: _Fleet.aircraft,
              label: Text('Aircraft'),
              icon: Icon(Icons.airplanemode_active),
            ),
            ButtonSegment(
              value: _Fleet.simulators,
              label: Text('Simulators'),
              icon: Icon(simulatorIcon),
            ),
          ],
          selected: {_fleet},
          onSelectionChanged: (s) => setState(() => _fleet = s.single),
        ),
      ),
    );

    return switch (_fleet) {
      _Fleet.aircraft => AircraftListScaffold(
        key: const ValueKey(_Fleet.aircraft),
        title: 'My Aircrafts',
        header: header,
        onTap: _showAircraft,
        onLongPress: _confirmDeleteAircraft,
      ),
      _Fleet.simulators => SimulatorListScaffold(
        key: const ValueKey(_Fleet.simulators),
        title: 'My Simulators',
        header: header,
        showStats: true,
        onTap: _showSimulator,
        onLongPress: _confirmDeleteSimulator,
      ),
    };
  }

  Future<void> _showAircraft(AircraftWithStats aws) async {
    await Navigator.push(
      context,
      AppPageRoute<void>(
        builder: (_) => AircraftDetailPage(aircraftId: aws.id),
      ),
    );
  }

  Future<void> _showSimulator(SimulatorWithStats sim) async {
    await Navigator.push(
      context,
      AppPageRoute<void>(
        builder: (_) => SimulatorDetailPage(simulatorId: sim.id),
      ),
    );
  }

  Future<bool> _confirmDelete(String title, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text('Are you sure you want to delete "$name"?'),
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
    return confirmed == true;
  }

  Future<void> _confirmDeleteAircraft(AircraftWithStats aws) async {
    if (await _confirmDelete('Delete Aircraft', aws.tailNumber)) {
      await ref.read(aircraftRepositoryProvider).deleteAircraft(aws.id);
    }
  }

  Future<void> _confirmDeleteSimulator(SimulatorWithStats sim) async {
    final messenger = ScaffoldMessenger.of(context);
    if (sim.sessionCount > 0) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${sim.title} has sessions logged: delete them, or move them '
            'to another simulator, first.',
          ),
        ),
      );
      return;
    }
    if (!await _confirmDelete('Delete Simulator', sim.title)) return;
    final deleted = await ref
        .read(simulatorRepositoryProvider)
        .deleteSimulator(sim.id);
    if (!deleted) {
      messenger.showSnackBar(
        SnackBar(content: Text('${sim.title} has sessions logged.')),
      );
    }
  }
}
