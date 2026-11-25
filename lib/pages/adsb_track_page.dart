import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../core/app_page_route.dart';
import '../core/fab_hero_tags.dart';
import '../models/flight_track.dart';
import '../models/sync_progress.dart';
import '../providers/adsb_providers.dart';
import '../repositories/flight_repository.dart';
import '../services/adsb_flight_importer.dart';
import '../services/adsb_track_service.dart';
import '../services/adsb_track_source.dart';
import '../services/database.dart';
import '../utils/duration_formatter.dart';
import '../utils/tz_datetime.dart';
import '../widgets/airport_search_dialog.dart';
import '../widgets/page_title.dart';
import '../widgets/sync_progress_indicator.dart';
import 'adsb_settings_page.dart';
import 'adsb_track_editor_page.dart';
import 'flight_form_page.dart';

enum _SearchBy {
  registration('Tail', 'e.g. EI-DCL', Icons.airplanemode_active),
  callsign('Flight no.', 'e.g. RYR4WY', Icons.confirmation_number_outlined),
  hex('HEX', 'e.g. 4CA242', Icons.tag);

  const _SearchBy(this.label, this.hint, this.icon);
  final String label;
  final String hint;
  final IconData icon;
}

/// Looks for the track of [flight] on the ADS-B providers and saves the one
/// the user picks as the flight's track. Pops the number of positions
/// saved.
///
/// [AdsbTrackPage.import] looks for a flight to log instead: the one picked
/// fills in the flight form. Pops `true` once it is saved.
class AdsbTrackPage extends ConsumerStatefulWidget {
  const AdsbTrackPage({super.key, required FlightWithStats this.flight});

  const AdsbTrackPage.import({super.key}) : flight = null;

  /// With its current track in `dataPoints`, if it has one. Null when
  /// importing a new flight.
  final FlightWithStats? flight;

  bool get isImport => flight == null;

  @override
  ConsumerState<AdsbTrackPage> createState() => _AdsbTrackPageState();
}

class _AdsbTrackPageState extends ConsumerState<AdsbTrackPage> {
  final _controller = TextEditingController();
  var _by = _SearchBy.registration;

  /// The UTC day searched.
  late DateTime _day;

  bool _searching = false;
  AdsbSearchResult? _result;

  /// The window of the search [_result] answers.
  AdsbWindow? _window;

  /// How, and for what, the search [_result] answers looked.
  _SearchBy? _searchedBy;
  String? _searchedText;
  AdsbException? _error;

  /// The flight whose track is being fetched and saved.
  AdsbFlight? _saving;

  /// What was typed for each kind of search, so switching keeps it.
  final _typed = <_SearchBy, String>{};

  /// When importing: the airports of the flight searched by flight number,
  /// if the user gives them. They find the flights of airlines whose
  /// callsigns aren't their flight numbers.
  Airport? _from;
  Airport? _to;

  /// When importing: about when the flight searched by flight number left,
  /// in the local time of [_from]. It narrows down the flights whose
  /// landing nobody saw to the few worth checking.
  TimeOfDay? _around;

  /// [_around] on the day searched, UTC.
  DateTime? get _departureAround {
    final around = _around;
    if (around == null) return null;
    return tz.TZDateTime(
      TZDateTimeParser.locationAt(_from?.latitudeDeg, _from?.longitudeDeg) ??
          tz.UTC,
      _day.year,
      _day.month,
      _day.day,
      around.hour,
      around.minute,
    ).toUtc();
  }

  void _showAroundInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.info_outline),
        title: const Text('Departs around'),
        content: const Text(
          'Low-cost airlines mostly fly callsigns '
          "that aren't the flight number: with the airports "
          'and about when it left, their flight is found by route.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAround() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _around ?? const TimeOfDay(hour: 12, minute: 0),
      helpText: 'Departs around',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _around = picked);
  }

  static final _time = DateFormat('HH:mm');
  static final _shortDate = DateFormat('d MMM');
  static final _longDate = DateFormat('EEE d MMM y');
  static final _number = NumberFormat.decimalPattern();

  Flight? get _flight => widget.flight?.flight;

  @override
  void initState() {
    super.initState();
    final departure = (_flight?.departureTime ?? DateTime.now()).toUtc();
    _day = DateTime.utc(departure.year, departure.month, departure.day);
    final registration = widget.flight?.aircraftWithStats?.tailNumber ?? '';
    _typed[_SearchBy.registration] = registration;
    _controller.text = registration;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The code OpenSky and FlyItalyADSB know an airport by.
  static String? _icao(Airport? airport) {
    for (final code in [airport?.icaoCode, airport?.gpsCode, airport?.ident]) {
      if (code != null && code.trim().isNotEmpty) return code.trim();
    }
    return null;
  }

  static double? _metres(int? feet) =>
      feet == null ? null : feet * TrackTools.feetToMetres;

  void _setBy(_SearchBy by) {
    if (by == _by) return;
    setState(() {
      _typed[_by] = _controller.text;
      _by = by;
      _controller.text = _typed[by] ?? '';
      // What was found for another kind of search would read as found for
      // this one.
      if (!_searching) {
        _result = null;
        _error = null;
      }
    });
  }

  Future<void> _pickAirport({required bool departure}) async {
    final airport = await showDialog<Airport>(
      context: context,
      builder: (_) => AirportSearchDialog(
        title: departure ? 'Departure airport' : 'Arrival airport',
      ),
    );
    if (airport == null || !mounted) return;
    setState(() => departure ? _from = airport : _to = airport);
  }

  Future<void> _pickDay() async {
    final now = DateTime.now().toUtc();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_day.year, _day.month, _day.day),
      firstDate: DateTime(2016),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: 'Day of the flight (UTC)',
    );
    if (picked == null || !mounted) return;
    setState(() => _day = DateTime.utc(picked.year, picked.month, picked.day));
  }

  Future<void> _search() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _searching) return;
    FocusScope.of(context).unfocus();
    final window = AdsbWindow.forDay(
      _day,
      expectedStart: _flight?.departureTime,
      expectedEnd: _flight?.arrivalTime,
    );
    final by = _by;
    setState(() {
      _searching = true;
      _error = null;
      _result = null;
      _window = window;
      _searchedBy = by;
      _searchedText = text;
    });

    AdsbSearchResult? result;
    AdsbException? error;
    try {
      final service = await ref.read(adsbTrackServiceProvider.future);
      result = switch (by) {
        _SearchBy.registration => await service.searchRegistration(
          text,
          window,
        ),
        _SearchBy.hex => await service.searchHex(text, window),
        _SearchBy.callsign => await service.searchCallsign(
          text,
          window,
          departureIcao: _icao(widget.flight?.departure ?? _from),
          arrivalIcao: _icao(widget.flight?.arrival ?? _to),
          departureAround: widget.isImport
              ? _departureAround
              : _flight?.departureTime,
        ),
      };
    } on AdsbException catch (e) {
      error = e;
    } catch (e) {
      error = AdsbException('The search failed ($e).');
    }
    if (!mounted) return;
    setState(() {
      _searching = false;
      _result = result;
      _error = error;
    });
  }

  /// The found flight that best matches when the logbook says this one
  /// took place, if any does.
  AdsbFlight? get _bestMatch {
    final start = _window?.expectedStart;
    final flights = _result?.flights ?? const <AdsbFlight>[];
    if (start == null || flights.isEmpty) return null;
    // Logged times are block times, to the minute at best.
    const slack = Duration(minutes: 15);
    final from = start.subtract(slack);
    final to = (_window?.expectedEnd ?? start).add(slack);
    final best = flights.reduce(
      (a, b) => b.overlapWith(from, to) > a.overlapWith(from, to) ? b : a,
    );
    return best.overlapWith(from, to) > Duration.zero ? best : null;
  }

  /// Lets the user cut [candidate] down to the flight they mean, and goes on
  /// with that.
  Future<void> _edit(AdsbFlight candidate) async {
    if (_saving != null) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = candidate);
    List<TrackPoint>? points;
    try {
      final service = await ref.read(adsbTrackServiceProvider.future);
      points = await service.fetchPoints(candidate);
    } on AdsbException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not load the track ($e).')),
      );
    } finally {
      if (mounted) setState(() => _saving = null);
    }
    if (points == null || !mounted) return;

    final track = points;
    final part = await navigator.push<AdsbFlight>(
      AppPageRoute(
        builder: (_) => AdsbTrackEditorPage(flight: candidate, points: track),
      ),
    );
    if (part == null || !mounted) return;
    await (widget.isImport
        ? _import(part, tile: candidate)
        : _save(part, tile: candidate));
  }

  /// Fills the flight form in with [candidate], to log it as a new flight.
  /// [tile] is the flight listed, when [candidate] was cut out of it.
  Future<void> _import(AdsbFlight candidate, {AdsbFlight? tile}) async {
    if (_saving != null) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = tile ?? candidate);
    AdsbImportDraft? draft;
    try {
      final importer = await ref.read(adsbFlightImporterProvider.future);
      draft = await importer.prepare(
        candidate,
        typedRegistration: _searchedBy == _SearchBy.registration
            ? _searchedText
            : null,
      );
    } on AdsbException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not import the flight ($e).')),
      );
    } finally {
      if (mounted) setState(() => _saving = null);
    }
    if (draft == null || !mounted) return;

    // On top of the results, so that going back offers them again.
    final saved = await navigator.push<bool>(
      AppPageRoute(builder: (_) => FlightFormPage(adsbImport: draft)),
    );
    if (saved == true && mounted) navigator.pop(true);
  }

  Future<void> _save(AdsbFlight candidate, {AdsbFlight? tile}) async {
    if (_saving != null) return;
    final flight = widget.flight!;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (flight.dataPoints.isNotEmpty) {
      final recorded = flight.flight.trackSource == null;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Replace Track'),
          content: Text(
            recorded
                ? 'This flight has a track recorded by the app. Saving the '
                      'ADS-B track deletes it.'
                : 'This flight already has an ADS-B track. Saving this one '
                      'replaces it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Replace'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() => _saving = tile ?? candidate);
    try {
      final service = await ref.read(adsbTrackServiceProvider.future);
      final points = await service.loadTrack(
        candidate,
        departureElevation: _metres(flight.departure?.elevationFt),
        arrivalElevation: _metres(flight.arrival?.elevationFt),
      );
      final saved = await ref
          .read(flightRepositoryProvider)
          .replaceTrack(
            flight.flight.id,
            points,
            source: candidate.provider.id,
          );
      if (mounted) navigator.pop(saved);
    } on AdsbException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not save the track ($e).')),
      );
    } finally {
      if (mounted) setState(() => _saving = null);
    }
  }

  void _openSettings() {
    Navigator.push(
      context,
      AppPageRoute<void>(builder: (_) => const AdsbSettingsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Watching it is what keeps the local aircraft database up to date,
    // when it is switched on.
    final registry = ref.watch(aircraftRegistryLoadProvider);
    final result = _result;
    final error = _error;

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: FloatingActionButton(
        heroTag: closeFabHeroTag,
        tooltip: 'Close',
        onPressed: () => Navigator.pop(context),
        child: const Icon(Icons.close),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          PageTitle(
            widget.isImport ? 'Import from ADS-B' : 'ADS-B Track',
            belowCloseButton: true,
            horizontalPadding: 0,
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<_SearchBy>(
                    showSelectedIcon: false,
                    segments: [
                      for (final by in _SearchBy.values)
                        ButtonSegment(value: by, label: Text(by.label)),
                    ],
                    selected: {_by},
                    onSelectionChanged: (selection) => _setBy(selection.first),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: ValueKey(_by),
                    controller: _controller,
                    autocorrect: false,
                    enableSuggestions: false,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp('[A-Za-z0-9 -]'),
                      ),
                      LengthLimitingTextInputFormatter(12),
                    ],
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      labelText: _by.label,
                      hintText: _by.hint,
                      prefixIcon: Icon(_by.icon),
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _search(),
                  ),
                  if (widget.isImport && _by == _SearchBy.callsign) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _AirportPicker(
                            label: 'From',
                            airport: _from,
                            onTap: () => _pickAirport(departure: true),
                            onClear: () => setState(() => _from = null),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AirportPicker(
                            label: 'To',
                            airport: _to,
                            onTap: () => _pickAirport(departure: false),
                            onClear: () => setState(() => _to = null),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _AroundPicker(
                            time: _around,
                            airport: _from,
                            onTap: _pickAround,
                            onClear: () => setState(() => _around = null),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.info_outline),
                          tooltip: 'About departure time',
                          onPressed: _showAroundInfo,
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event),
                    title: Text(_longDate.format(_day)),
                    subtitle: const Text('Day of the flight, UTC'),
                    trailing: const Icon(Icons.edit_calendar_outlined),
                    onTap: _pickDay,
                  ),
                  const SizedBox(height: 4),
                  FilledButton.icon(
                    onPressed: _searching || _controller.text.trim().isEmpty
                        ? null
                        : _search,
                    icon: const Icon(Icons.search),
                    label: const Text('Search'),
                  ),
                ],
              ),
            ),
          ),
          if (_by == _SearchBy.registration &&
              (registry.isRunning || registry.phase == SyncPhase.error))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SyncProgressIndicator(progress: registry, compact: true),
            ),
          const SizedBox(height: 12),
          if (_searching)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (error != null)
            _Notice(
              message: error.message,
              onSettings: error.needsSetup ? _openSettings : null,
            )
          else if (result != null) ...[
            if (result.hexes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  _describeHexes(result),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            for (final MapEntry(key: provider, value: problem)
                in result.problems.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _Notice(
                  title: provider.label,
                  message: problem.message,
                  onSettings: problem.needsSetup ? _openSettings : null,
                ),
              ),
            if (result.unseenLeftOut > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  margin: EdgeInsets.zero,
                  color: theme.colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${result.unseenLeftOut} more flights left '
                            '${_from?.iataCode ?? _from?.ident ?? 'the airport'} '
                            "whose landing wasn't seen. Give about when "
                            'yours left to look among them.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (result.flights.isEmpty && result.unseenLeftOut == 0)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.travel_explore,
                      size: 48,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No flights found',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.problems.isEmpty
                          ? 'Nothing was seen on ${_shortDate.format(_day)} '
                                '(UTC). Low flights far from a receiver '
                                'leave no trace.'
                          : 'The providers that could be asked saw nothing '
                                'on ${_shortDate.format(_day)} (UTC).',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            else if (result.flights.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  widget.isImport
                      ? 'Pick the flight to log'
                      : 'Pick the flight to save its track',
                  style: theme.textTheme.labelLarge,
                ),
              ),
              for (final candidate in result.flights)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _FlightTile(
                    flight: candidate,
                    title: _timesOf(candidate),
                    details: _detailsOf(candidate),
                    isBestMatch: identical(candidate, _bestMatch),
                    isSaving: identical(candidate, _saving),
                    actionIcon: widget.isImport
                        ? Icons.arrow_forward
                        : Icons.download,
                    onTap: _saving == null
                        ? () => widget.isImport
                              ? _import(candidate)
                              : _save(candidate)
                        : null,
                    onEdit: _saving == null ? () => _edit(candidate) : null,
                  ),
                ),
              for (final provider in {
                for (final candidate in result.flights) candidate.provider,
              })
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Text(
                    provider.attribution,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }

  static String _describeHexes(AdsbSearchResult result) {
    String one(String hex, List<String> sources) =>
        '${hex.toUpperCase()} (${sources.join(', ')})';
    final hexes = result.hexes;
    return hexes.length == 1
        ? 'ICAO address ${one(hexes.single.hex, hexes.single.sources)}'
        : 'ICAO addresses: '
              '${[for (final c in hexes) one(c.hex, c.sources)].join(' · ')}';
  }

  /// "08:40 – 09:35 UTC", with the dates when they aren't the day searched.
  String _timesOf(AdsbFlight flight) {
    bool sameDay(DateTime time) =>
        time.year == _day.year &&
        time.month == _day.month &&
        time.day == _day.day;
    String at(DateTime time) => sameDay(time)
        ? _time.format(time)
        : '${_shortDate.format(time)} ${_time.format(time)}';
    return '${at(flight.start)} – ${at(flight.end)} UTC';
  }

  static String _detailsOf(AdsbFlight flight) {
    final points = flight.points;
    return [
      ?flight.callsign,
      if (flight.departure != null || flight.arrival != null)
        '${flight.departure ?? '?'} → ${flight.arrival ?? '?'}'
            '${flight.arrivalUnseen ? ' (landing not seen)' : ''}',
      DurationFormatter.descriptive(flight.duration),
      if (points != null) '${_number.format(points.length)} positions',
    ].join(' · ');
  }
}

/// A flight a provider saw, to pick.
class _FlightTile extends StatelessWidget {
  const _FlightTile({
    required this.flight,
    required this.title,
    required this.details,
    required this.isBestMatch,
    required this.isSaving,
    required this.actionIcon,
    required this.onTap,
    required this.onEdit,
  });

  final AdsbFlight flight;
  final String title;
  final String details;
  final bool isBestMatch;
  final bool isSaving;
  final IconData actionIcon;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: isBestMatch ? cs.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(details, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      [
                        flight.provider.label,
                        if (flight.byRoute) 'found by route',
                        if (isBestMatch) 'matches the logged times',
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isBestMatch
                            ? cs.onPrimaryContainer
                            : cs.onSurfaceVariant,
                        fontWeight: isBestMatch ? FontWeight.w600 : null,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit track',
                icon: const Icon(Icons.content_cut),
                onPressed: onEdit,
              ),
              const SizedBox(width: 12),
              if (isSaving)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              else
                Icon(actionIcon, color: cs.primary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Something that went wrong, with a way to the settings when that is
/// where it gets fixed.
class _Notice extends StatelessWidget {
  const _Notice({required this.message, this.title, this.onSettings});
  final String? title;
  final String message;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: cs.errorContainer,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, onSettings == null ? 16 : 8, 12),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: cs.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: cs.onErrorContainer,
                      ),
                    ),
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
            if (onSettings != null)
              TextButton(
                onPressed: onSettings,
                style: TextButton.styleFrom(
                  foregroundColor: cs.onErrorContainer,
                ),
                child: const Text('Settings'),
              ),
          ],
        ),
      ),
    );
  }
}

/// An optional airport of a flight-number search.
class _AirportPicker extends StatelessWidget {
  const _AirportPicker({
    required this.label,
    required this.airport,
    required this.onTap,
    required this.onClear,
  });
  final String label;
  final Airport? airport;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final airport = this.airport;
    final code = airport?.iataCode ?? airport?.ident ?? airport?.name;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        isEmpty: airport == null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            label == 'From' ? Icons.flight_takeoff : Icons.flight_land,
          ),
          suffixIcon: airport == null
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.close),
                  onPressed: onClear,
                ),
        ),
        child: Text(code ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

/// About when the flight searched by flight number left.
class _AroundPicker extends StatelessWidget {
  const _AroundPicker({
    required this.time,
    required this.airport,
    required this.onTap,
    required this.onClear,
  });
  final TimeOfDay? time;
  final Airport? airport;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final time = this.time;
    final airport = this.airport;
    final where = airport == null
        ? 'UTC'
        : 'local time at ${airport.iataCode ?? airport.ident ?? 'From'}';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        isEmpty: time == null,
        decoration: InputDecoration(
          labelText: 'Departs around ($where)',
          prefixIcon: const Icon(Icons.schedule),
          suffixIcon: time == null
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.close),
                  onPressed: onClear,
                ),
        ),
        child: Text(
          time == null
              ? ''
              : '${time.hour.toString().padLeft(2, '0')}:'
                    '${time.minute.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }
}
