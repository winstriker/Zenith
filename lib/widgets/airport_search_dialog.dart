import 'dart:async';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_page_route.dart';
import '../pages/airport_form_page.dart';
import '../repositories/airport_repository.dart';
import '../services/database.dart';

class AirportSearchDialog extends ConsumerStatefulWidget {
  const AirportSearchDialog({super.key, required this.title});
  final String title;

  @override
  ConsumerState<AirportSearchDialog> createState() =>
      _AirportSearchDialogState();
}

class _AirportSearchDialogState extends ConsumerState<AirportSearchDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<Airport> _recent = [];
  List<Airport> _results = [];
  bool _loadingRecent = true;

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final recent = await ref
        .read(airportRepositoryProvider)
        .getRecentAirports(limit: 8);
    if (mounted) {
      setState(() {
        _recent = recent;
        _loadingRecent = false;
      });
    }
  }

  void _search(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final results = await ref
          .read(airportRepositoryProvider)
          .findAirports(query.trim());
      if (mounted) setState(() => _results = results);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _controller.text.trim();
    final showRecent = query.isEmpty && !_loadingRecent && _recent.isNotEmpty;
    final showResults = query.isNotEmpty && _results.isNotEmpty;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
          maxWidth: 420,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search airport by name, ICAO, IATA...',
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
                onChanged: (v) {
                  setState(() {});
                  _search(v);
                },
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: showRecent
                  ? _AirportList(
                      header: 'RECENT',
                      airports: _recent,
                      onSelected: _select,
                    )
                  : showResults
                  ? _AirportList(airports: _results, onSelected: _select)
                  : _DialogMessage(
                      query.isNotEmpty && !_loadingRecent
                          ? 'No airports found for "$query"'
                          : 'Type to search airports',
                      action: query.isEmpty || _loadingRecent
                          ? null
                          : TextButton.icon(
                              onPressed: () => _addCustom(query),
                              icon: const Icon(Icons.add_location_alt),
                              label: const Text('Add as custom airport'),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _select(Airport airport) => Navigator.pop(context, airport);

  /// Opens the form for an airport of the user's own, and picks it once
  /// added.
  Future<void> _addCustom(String query) async {
    final id = await Navigator.push<Object?>(
      context,
      AppPageRoute(
        builder: (_) =>
            AirportFormPage(initialIdent: query.contains(' ') ? null : query),
      ),
    );
    if (id is! int || !mounted) return;
    final airport = await ref.read(airportRepositoryProvider).getAirport(id);
    if (airport != null && mounted) _select(airport);
  }
}

class _AirportList extends StatelessWidget {
  const _AirportList({
    required this.airports,
    required this.onSelected,
    this.header,
  });

  final List<Airport> airports;
  final ValueChanged<Airport> onSelected;
  final String? header;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final list = ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: airports.length,
      itemBuilder: (_, i) => _AirportTile(
        airport: airports[i],
        onTap: () => onSelected(airports[i]),
      ),
    );
    if (header == null) return list;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            header!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Flexible(child: list),
      ],
    );
  }
}

class _AirportTile extends StatelessWidget {
  const _AirportTile({required this.airport, required this.onTap});

  final Airport airport;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final code =
        airport.ident ??
        airport.icaoCode ??
        airport.iataCode ??
        airport.name ??
        '----';
    final name = airport.name ?? '';
    final city = airport.municipality ?? '';
    final countryCode = airport.isoCountry;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: countryCode.length == 2
          ? SizedBox(
              width: 30,
              height: 20,
              child: CountryFlag.fromCountryCode(
                countryCode,
                theme: const ImageTheme(shape: RoundedRectangle(3)),
              ),
            )
          : Icon(Icons.local_airport, size: 20, color: cs.primary),
      title: Row(
        children: [
          Text(
            code,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      subtitle: city.isNotEmpty
          ? Text(
              city,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}

class _DialogMessage extends StatelessWidget {
  const _DialogMessage(this.message, {this.action});
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
    );
  }
}
