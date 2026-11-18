import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../core/fab_hero_tags.dart';
import '../providers/airport_providers.dart';
import '../repositories/airport_repository.dart';
import '../services/database.dart';
import '../widgets/page_title.dart';
import '../widgets/picker_sheet.dart';
import '../widgets/section_header.dart';

/// Full-page form that adds an airport of the user's own (an airstrip
/// missing from OurAirports, say), or edits [airport] when given. Pops `true`
/// when the airport was deleted, and the id of the new airport when one was
/// added.
class AirportFormPage extends ConsumerStatefulWidget {
  const AirportFormPage({super.key, this.airport, this.initialIdent});

  /// A custom airport (see [CustomAirport]) to edit.
  final Airport? airport;

  /// For a new airport: the identifier to start with.
  final String? initialIdent;

  @override
  ConsumerState<AirportFormPage> createState() => _AirportFormPageState();
}

/// The types offered for a new airport: "undefined" isn't one.
const _types = [
  AirportType.smallAirport,
  AirportType.mediumAirport,
  AirportType.largeAirport,
  AirportType.heliport,
  AirportType.seaplaneBase,
  AirportType.balloonport,
  AirportType.closed,
];

class _AirportFormPageState extends ConsumerState<AirportFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _ident = TextEditingController();
  final _name = TextEditingController();
  final _icao = TextEditingController();
  final _iata = TextEditingController();
  final _municipality = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  final _elevation = TextEditingController();

  AirportType _type = AirportType.smallAirport;
  String? _countryCode;
  String? _regionCode;

  /// Set when the identifier is already used, until it is edited.
  String? _identError;
  bool _locating = false;
  bool _saving = false;

  bool get _isEditing => widget.airport != null;

  @override
  void initState() {
    super.initState();
    final a = widget.airport;
    if (a == null) {
      _ident.text = widget.initialIdent?.trim().toUpperCase() ?? '';
      return;
    }
    _ident.text = a.ident ?? '';
    _name.text = a.name ?? '';
    _icao.text = a.icaoCode ?? '';
    _iata.text = a.iataCode ?? '';
    _municipality.text = a.municipality ?? '';
    _latitude.text = a.latitudeDeg?.toString() ?? '';
    _longitude.text = a.longitudeDeg?.toString() ?? '';
    _elevation.text = a.elevationFt?.toString() ?? '';
    _type = a.type;
    _countryCode = a.isoCountry;
    _regionCode = a.isoRegion;
  }

  @override
  void dispose() {
    for (final c in [
      _ident,
      _name,
      _icao,
      _iata,
      _municipality,
      _latitude,
      _longitude,
      _elevation,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  static String? _orNull(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Accepts a decimal comma too, as typed on many keyboards.
  static double? _parseCoordinate(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  String? _validateCoordinate(String? value, {required double limit}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Required';
    final parsed = _parseCoordinate(text);
    if (parsed == null) return 'Not a number';
    if (parsed.abs() > limit) return 'Between -$limit and $limit';
    return null;
  }

  Future<void> _useCurrentLocation() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Location permission denied.')),
        );
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      _latitude.text = position.latitude.toStringAsFixed(6);
      _longitude.text = position.longitude.toStringAsFixed(6);
      if (_elevation.text.trim().isEmpty && position.altitude != 0) {
        // Metres above the WGS84 ellipsoid: close enough for an airstrip.
        _elevation.text = (position.altitude * 3.28084).round().toString();
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not get your location: $e')),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pickCountry(List<Country> countries) async {
    final current = countries.where((c) => c.code == _countryCode).firstOrNull;
    final picked = await showPickerSheet<Country>(
      context,
      title: 'Country',
      items: countries,
      label: (c) => c.name,
      subtitle: (c) => c.code,
      selected: current,
      searchHint: 'Search countries...',
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (picked.code != _countryCode) _regionCode = null;
      _countryCode = picked.code;
    });
  }

  Future<void> _pickRegion(List<Region> regions) async {
    final current = regions.where((r) => r.code == _regionCode).firstOrNull;
    final picked = await showPickerSheet<Region>(
      context,
      title: 'Region',
      items: regions,
      label: (r) => r.name,
      subtitle: (r) => r.code,
      selected: current,
      searchHint: 'Search regions...',
    );
    if (picked == null || !mounted) return;
    setState(() => _regionCode = picked.code);
  }

  Future<void> _save(List<Country> countries) async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final country = countries.where((c) => c.code == _countryCode).firstOrNull;
    final countryCode = _countryCode!;
    final repository = ref.read(airportRepositoryProvider);
    final ident = _ident.text.trim().toUpperCase();
    setState(() => _saving = true);

    try {
      if (await repository.isIdentTaken(ident, exceptId: widget.airport?.id)) {
        if (!mounted) return;
        setState(() {
          _saving = false;
          _identError = 'Another airport already uses $ident';
        });
        _formKey.currentState!.validate();
        return;
      }

      final row = AirportsCompanion(
        ident: Value(ident),
        type: Value(_type),
        name: Value(_name.text.trim()),
        latitudeDeg: Value(_parseCoordinate(_latitude.text)),
        longitudeDeg: Value(_parseCoordinate(_longitude.text)),
        elevationFt: Value(int.tryParse(_elevation.text.trim())),
        continent: Value(
          country?.continent ?? widget.airport?.continent ?? '??',
        ),
        isoCountry: Value(countryCode),
        // OurAirports files airports with no region under "<country>-U-A".
        isoRegion: Value(_regionCode ?? '$countryCode-U-A'),
        municipality: Value(_orNull(_municipality.text)),
        icaoCode: Value(_orNull(_icao.text)?.toUpperCase()),
        iataCode: Value(_orNull(_iata.text)?.toUpperCase()),
      );

      final existing = widget.airport;
      int? addedId;
      if (existing != null) {
        await repository.updateCustomAirport(existing.id, row);
        ref.invalidate(airportDetailsProvider(existing.id));
      } else {
        addedId = await repository.addCustomAirport(row);
      }
      if (mounted) Navigator.pop(context, addedId);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  Future<void> _delete() async {
    final airport = widget.airport!;
    final repository = ref.read(airportRepositoryProvider);
    final name = airport.name ?? airport.ident ?? 'this airport';
    if (await repository.isAirportReferencedInFlights(airport.id)) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Airport in use'),
          content: Text(
            '$name is the departure or arrival of logged flights. Change '
            'those flights first.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Airport'),
        content: Text('Delete "$name"?'),
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
    if (confirmed != true || !mounted) return;
    final deleted = await repository.deleteCustomAirport(airport.id);
    if (mounted && deleted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final countries = ref.watch(countriesStreamProvider).value ?? const [];
    final countryCode = _countryCode;
    final regions = countryCode == null
        ? const <Region>[]
        : ref.watch(regionsStreamProvider(countryCode)).value ?? const [];
    final country = countries.where((c) => c.code == countryCode).firstOrNull;
    final region = regions.where((r) => r.code == _regionCode).firstOrNull;

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: FloatingActionButton(
        heroTag: closeFabHeroTag,
        tooltip: 'Close',
        onPressed: () => Navigator.pop(context),
        child: const Icon(Icons.close),
      ),
      body: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          heroTag: primaryFabHeroTag,
          onPressed: _saving ? null : () => _save(countries),
          label: Text(_isEditing ? 'Save' : 'Add'),
          icon: Icon(_isEditing ? Icons.save : Icons.add),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            // Bottom padding keeps the last field clear of the save button.
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
            children: [
              PageTitle(
                _isEditing ? 'Edit Airport' : 'Add Airport',
                belowCloseButton: true,
                horizontalPadding: 0,
                bottomPadding: 16,
              ),
              const SectionHeader(title: 'Identification', uppercase: true),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ident,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9-]')),
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: const InputDecoration(
                  labelText: 'Identifier *',
                  hintText: 'e.g. LI0001',
                  prefixIcon: Icon(Icons.tag),
                  helperText: 'The code written in the logbook.',
                ),
                onChanged: (_) {
                  if (_identError != null) setState(() => _identError = null);
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Identifier is required.';
                  }
                  return _identError;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  hintText: 'e.g. Aviosuperficie Rossi',
                  prefixIcon: Icon(Icons.local_airport),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Name is required.'
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _icao,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp('[A-Za-z0-9]'),
                        ),
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'ICAO code',
                        hintText: 'LIMC',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _iata,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp('[A-Za-z0-9]'),
                        ),
                        LengthLimitingTextInputFormatter(3),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'IATA code',
                        hintText: 'MXP',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Type', uppercase: true),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final type in _types)
                    ChoiceChip(
                      label: Text(AirportType.getDisplayName(type)),
                      selected: _type == type,
                      onSelected: (_) => setState(() => _type = type),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Location', uppercase: true),
              const SizedBox(height: 8),
              FormField<String>(
                // Keyed on the value so the field's state follows _countryCode.
                key: ValueKey('country-$countryCode'),
                initialValue: countryCode,
                validator: (value) =>
                    value == null ? 'Country is required.' : null,
                builder: (field) => _PickerField(
                  label: 'Country *',
                  icon: Icons.public,
                  value: country?.name ?? countryCode,
                  errorText: field.errorText,
                  helperText: countries.isEmpty
                      ? 'Countries appear once the airport data is '
                            'downloaded.'
                      : null,
                  onTap: countries.isEmpty
                      ? null
                      : () => _pickCountry(countries),
                ),
              ),
              const SizedBox(height: 16),
              _PickerField(
                label: 'Region',
                icon: Icons.map_outlined,
                value: region?.name,
                onTap: regions.isEmpty ? null : () => _pickRegion(regions),
                onClear: _regionCode == null
                    ? null
                    : () => setState(() => _regionCode = null),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _municipality,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'City',
                  prefixIcon: Icon(Icons.location_city),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitude,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Latitude *',
                        hintText: '45.630600',
                      ),
                      validator: (v) => _validateCoordinate(v, limit: 90),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _longitude,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Longitude *',
                        hintText: '8.728110',
                      ),
                      validator: (v) => _validateCoordinate(v, limit: 180),
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _locating ? null : _useCurrentLocation,
                  icon: _locating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location, size: 18),
                  label: const Text('Use my current location'),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _elevation,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Elevation',
                  suffixText: 'ft',
                  prefixIcon: Icon(Icons.terrain),
                ),
              ),
              if (_isEditing) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _delete,
                    style: TextButton.styleFrom(foregroundColor: cs.error),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete Airport'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A read-only field that opens a picker when tapped.
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
    this.onClear,
    this.errorText,
    this.helperText,
  });

  final String label;
  final IconData icon;
  final String? value;

  /// Null disables the field.
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final String? errorText;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final onClear = this.onClear;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        isEmpty: value == null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          errorText: errorText,
          helperText: helperText,
          helperMaxLines: 2,
          enabled: onTap != null,
          suffixIcon: onClear != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  tooltip: 'Clear',
                  onPressed: onClear,
                )
              : const Icon(Icons.arrow_drop_down),
        ),
        child: value == null ? null : Text(value!),
      ),
    );
  }
}
