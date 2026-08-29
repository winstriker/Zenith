import 'dart:async';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import '../services/database.dart';

class AirportSearchDialog extends StatefulWidget {
  final String title;
  const AirportSearchDialog({super.key, required this.title});

  @override
  State<AirportSearchDialog> createState() => _AirportSearchDialogState();
}

class _AirportSearchDialogState extends State<AirportSearchDialog> {
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
    final db = LogbookDatabase();
    try {
      final recent = await db.getRecentAirports(limit: 8);
      if (mounted) {
        setState(() {
          _recent = recent;
          _loadingRecent = false;
        });
      }
    } finally {
      db.close();
    }
  }

  void _search(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final db = LogbookDatabase();
      try {
        final results = await db.searchAirports(query: query.trim(), limit: 15);
        if (mounted) setState(() => _results = results);
      } finally {
        db.close();
      }
    });
  }

  String _airportCode(Airport a) =>
      a.ident ?? a.icaoCode ?? a.iataCode ?? a.name ?? '----';

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
          maxHeight: MediaQuery.of(context).size.height * 0.7,
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                  ? _buildRecentList(theme)
                  : showResults
                      ? _buildResultList(theme)
                      : query.isNotEmpty && !_loadingRecent
                          ? _buildEmptyState(theme, 'No airports found for "$query"')
                          : _buildEmptyState(theme, 'Type to search airports'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentList(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'RECENT',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 8),
            itemCount: _recent.length,
            itemBuilder: (_, i) => _buildAirportTile(theme, _recent[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildResultList(ThemeData theme) {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: _results.length,
      itemBuilder: (_, i) => _buildAirportTile(theme, _results[i]),
    );
  }

  Widget _buildAirportTile(ThemeData theme, Airport airport) {
    final code = _airportCode(airport);
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
          : Icon(Icons.local_airport, size: 20, color: theme.colorScheme.primary),
      title: Row(
        children: [
          Text(
            code,
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
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
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            )
          : null,
      onTap: () => Navigator.pop(context, airport),
    );
  }

  Widget _buildEmptyState(ThemeData theme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
