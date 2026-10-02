import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/aircraft_providers.dart';
import '../widgets/aircraft_card.dart';
import '../widgets/empty_state.dart';
import 'aircraft_form_page.dart';

class AircraftSelectPage extends ConsumerStatefulWidget {
  const AircraftSelectPage({super.key});

  @override
  ConsumerState<AircraftSelectPage> createState() => _AircraftSelectPageState();
}

class _AircraftSelectPageState extends ConsumerState<AircraftSelectPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aircraftAsync = ref.watch(aircraftListStreamProvider);

    return aircraftAsync.when(
      data: (aircraftList) {
        final filtered = _query.isEmpty
            ? aircraftList
            : aircraftList.where((aws) {
                final q = _query.toLowerCase();
                return aws.modelFullName.toLowerCase().contains(q) ||
                    aws.manufacturer.toLowerCase().contains(q) ||
                    (aws.notes?.toLowerCase().contains(q) ?? false);
              }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Select Aircraft'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Add new aircraft',
                onPressed: _addAircraft,
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search aircraft...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ),
              Expanded(
                child: aircraftList.isEmpty
                    ? EmptyState(
                        icon: Icons.airplanemode_active,
                        title: 'No aircraft yet',
                        subtitle:
                            'Add your first aircraft to start tracking flights.',
                        action: FilledButton.icon(
                          onPressed: _addAircraft,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Aircraft'),
                        ),
                      )
                    : filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.search_off,
                        iconSize: 48,
                        iconOpacity: 0.4,
                        title: 'No aircraft match "$_query"',
                        action: OutlinedButton.icon(
                          onPressed: _addAircraft,
                          icon: const Icon(Icons.add),
                          label: const Text('Add New Aircraft'),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 4, bottom: 80),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final aws = filtered[index];
                          return AircraftCard(
                            aircraft: aws,
                            onTap: () => Navigator.pop(context, aws),
                            showStats: true,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  Future<void> _addAircraft() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const AircraftFormPage()),
    );
    // Stream provider automatically updates
  }
}
