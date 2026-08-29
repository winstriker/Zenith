import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/aircraft_providers.dart';
import '../widgets/aircraft_card.dart';
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
    final aircraftList = ref.watch(aircraftListProvider);
    final theme = Theme.of(context);
    final filtered = _query.isEmpty
        ? aircraftList
        : aircraftList.where((aws) {
            final q = _query.toLowerCase();
            return aws.aircraft.type.toLowerCase().contains(q) ||
                (aws.aircraft.model?.toLowerCase().contains(q) ?? false) ||
                (aws.aircraft.tailNumber?.toLowerCase().contains(q) ?? false);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Aircraft'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add new aircraft',
            onPressed: () => _addAircraft(),
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
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          Expanded(
            child: aircraftList.isEmpty
                ? _buildEmptyState(theme)
                : filtered.isEmpty
                    ? _buildNoResults(theme)
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 4, bottom: 80),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final aws = filtered[index];
                          return AircraftCard(
                            aircraft: aws,
                            onTap: () => Navigator.pop(context, aws.aircraft),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final cs = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.airplanemode_active,
              size: 64,
              color: cs.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No aircraft yet',
              style: theme.textTheme.titleLarge?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first aircraft to start tracking flights.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _addAircraft(),
              icon: const Icon(Icons.add),
              label: const Text('Add Aircraft'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults(ThemeData theme) {
    final cs = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: cs.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No aircraft match "$_query"',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _addAircraft(),
              icon: const Icon(Icons.add),
              label: const Text('Add New Aircraft'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addAircraft() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AircraftFormPage()),
    );
    if (result == true) {
      ref.read(aircraftListProvider.notifier).refresh();
    }
  }
}
