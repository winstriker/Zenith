import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_page_route.dart';
import '../core/fab_hero_tags.dart';
import '../repositories/aircraft_repository.dart';
import '../services/aircraft_lookup_service.dart';
import '../services/database.dart';
import '../services/person_photo_store.dart';
import '../services/registry_database.dart';
import '../utils/icao_type_matcher.dart';
import '../widgets/aircraft_class_card.dart';
import '../widgets/aircraft_photo_view.dart';
import '../widgets/model_card.dart';
import 'icao_aircraft_select_page.dart';
import 'image_crop_page.dart';

enum _PhotoAction { online, gallery, camera, remove }

/// Full-page form that creates a new aircraft, or edits [aircraft] when
/// given. Pops `true` when the aircraft was deleted, and the id of the new
/// aircraft when one was added.
class AircraftFormPage extends ConsumerStatefulWidget {
  const AircraftFormPage({super.key, this.aircraft, this.initialTailNumber});
  final AircraftWithStats? aircraft;

  /// For a new aircraft: the registration to start with, which is looked
  /// up straight away.
  final String? initialTailNumber;

  @override
  ConsumerState<AircraftFormPage> createState() => _AircraftFormPageState();
}

class _AircraftFormPageState extends ConsumerState<AircraftFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _tailController = TextEditingController();
  final _notesController = TextEditingController();
  final _typeRatingController = TextEditingController();

  IcaoAircraft? _selectedIcaoAircraft;

  /// True when the type was filled in by the registration lookup, so a new
  /// lookup may replace it. A type the user picked is never replaced.
  bool _typeFromLookup = false;

  AircraftClass? _aircraftClass;

  /// While false, the class follows the aircraft type.
  bool _classSetByUser = false;

  /// While false, the type rating follows the aircraft type.
  bool _typeRatingSetByUser = false;

  /// Type ratings already given to other aircraft, offered as shortcuts.
  List<String> _knownTypeRatings = const [];

  /// The stored photo, or the online photo that has been chosen.
  AircraftPhoto? _photo;

  /// Newly picked picture, not yet copied into the store. Wins over [_photo].
  File? _pickedPhoto;
  bool _photoChanged = false;

  bool _lookingUp = false;
  AircraftLookupResult? _lookup;

  /// Why the last lookup found nothing.
  String? _lookupNote;
  bool _saving = false;

  bool get _hasPhoto => _pickedPhoto != null || _photo != null;

  /// Classes the selected type allows.
  List<AircraftClass> get _candidates {
    final type = _selectedIcaoAircraft;
    if (type == null) return const [];
    return AircraftClass.candidatesFor(
      description: type.description,
      engineCount: type.engineCount,
      engineType: type.engineType,
    );
  }

  @override
  void initState() {
    super.initState();
    final aircraft = widget.aircraft;
    _tailController.text =
        aircraft?.tailNumber ?? widget.initialTailNumber ?? '';
    _notesController.text = aircraft?.notes ?? '';

    if (aircraft != null) {
      _selectedIcaoAircraft = aircraft.toIcaoAircraft();
      _photo = aircraft.photo;
      _aircraftClass = aircraft.aircraftClass;
      _classSetByUser = aircraft.aircraftClass != null;
      _typeRatingController.text = aircraft.typeRating ?? '';
      _typeRatingSetByUser = aircraft.typeRating != null;
      _followType();
    }

    ref.read(aircraftRepositoryProvider).getTypeRatings().then((ratings) {
      if (mounted) setState(() => _knownTypeRatings = ratings);
    });

    if (aircraft == null && _tailController.text.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _lookUp();
      });
    }
  }

  @override
  void dispose() {
    _tailController.dispose();
    _notesController.dispose();
    _typeRatingController.dispose();
    super.dispose();
  }

  /// Brings the class and the type rating in line with the selected type,
  /// unless the user chose them. Call inside setState.
  void _followType() {
    if (!_classSetByUser) {
      final candidates = _candidates;
      _aircraftClass = candidates.length == 1 ? candidates.single : null;
    }
    if (!_typeRatingSetByUser) {
      // Only a starting point: ratings often cover several designators.
      _typeRatingController.text = _aircraftClass == AircraftClass.type
          ? _selectedIcaoAircraft?.designator ?? ''
          : '';
    }
  }

  // ---------------------------------------------------------------------------
  // Registration lookup
  // ---------------------------------------------------------------------------

  Future<void> _lookUp() async {
    final registration = _tailController.text.trim();
    if (registration.isEmpty || _lookingUp) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _lookingUp = true;
      _lookupNote = null;
    });

    AircraftLookupResult? result;
    IcaoTypeMatch? match;
    String? note;
    try {
      result = await ref
          .read(aircraftLookupServiceProvider)
          .lookup(registration);
      if (result == null) {
        note = 'Nothing found for "$registration".';
      } else if (result.icaoDesignator != null ||
          result.modelNames.isNotEmpty) {
        final types = await ref
            .read(aircraftRepositoryProvider)
            .getAllIcaoAircrafts();
        match = IcaoTypeMatcher.resolve(
          designator: result.icaoDesignator,
          names: result.modelNames,
          types: types,
        );
      }
    } on AircraftLookupException catch (e) {
      note = e.message;
    }
    if (!mounted) return;

    setState(() {
      _lookingUp = false;
      _lookupNote = note;
      final found = result;
      if (found == null) return;
      _lookup = found;

      // Take the source's spelling, unless the field changed meanwhile.
      if (RegistryDatabase.normalizeRegistration(_tailController.text) ==
          RegistryDatabase.normalizeRegistration(found.registration)) {
        _tailController.text = found.registration;
      }
      if (!_hasPhoto && found.photos.isNotEmpty) {
        _selectOnline(found.photos.first);
      } else if (found.photos.isEmpty) {
        _lookupNote = 'No photos found for this aircraft.';
      }

      final best = match?.best;
      if (best != null && (_selectedIcaoAircraft == null || _typeFromLookup)) {
        _selectedIcaoAircraft = best;
        _typeFromLookup = true;
        _followType();
      }
    });
  }

  Future<void> _openTypeSelector() async {
    final selected = await Navigator.push<IcaoAircraft>(
      context,
      AppPageRoute(
        builder: (_) => IcaoAircraftSelectPage(
          suggestFor: _lookup?.model,
          suggestDesignator: _lookup?.icaoDesignator,
          suggestNames: _lookup?.modelNames ?? const [],
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() {
        _selectedIcaoAircraft = selected;
        _typeFromLookup = false;
        _followType();
      });
    }
  }

  Future<void> _pickClass() async {
    final choice = await showAircraftClassPicker(
      context,
      selected: _aircraftClass,
      candidates: _candidates,
    );
    if (choice == null || !mounted) return;
    setState(() {
      _aircraftClass = choice.aircraftClass;
      _classSetByUser = true;
      _followType();
    });
  }

  // ---------------------------------------------------------------------------
  // Photo
  // ---------------------------------------------------------------------------

  /// Uses a photo that stays online. Call inside setState.
  void _selectOnline(AircraftPhoto photo) {
    _pickedPhoto = null;
    _photo = photo;
    _photoChanged = true;
  }

  Future<void> _photoOptions() async {
    final canSearch = _tailController.text.trim().isNotEmpty;
    final action = await showModalBottomSheet<_PhotoAction>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              enabled: canSearch,
              leading: const Icon(Icons.travel_explore),
              title: const Text('Search online'),
              subtitle: Text(
                canSearch
                    ? 'Photos of ${_tailController.text.trim()}'
                    : 'Enter the registration first',
              ),
              onTap: () => Navigator.pop(ctx, _PhotoAction.online),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, _PhotoAction.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, _PhotoAction.camera),
            ),
            if (_hasPhoto)
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(ctx).colorScheme.error,
                ),
                title: Text(
                  'Remove photo',
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                ),
                onTap: () => Navigator.pop(ctx, _PhotoAction.remove),
              ),
          ],
        ),
      ),
    );
    switch (action) {
      case null:
        return;
      case _PhotoAction.online:
        await _lookUp();
      case _PhotoAction.gallery:
        await _pickPhoto(ImageSource.gallery);
      case _PhotoAction.camera:
        await _pickPhoto(ImageSource.camera);
      case _PhotoAction.remove:
        setState(() {
          _pickedPhoto = null;
          _photo = null;
          _photoChanged = true;
        });
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final cropped = await pickAndCropImage(
      context,
      source: source,
      // The shape of the header.
      spec: const CropSpec(
        title: 'Crop photo',
        aspectRatio: 3 / 2,
        outputWidth: 1600,
        jpegQuality: 85,
      ),
    );
    if (cropped == null || !mounted) return;
    setState(() {
      _pickedPhoto = cropped;
      _photoChanged = true;
    });
  }

  // ---------------------------------------------------------------------------
  // Save / delete
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final type = _selectedIcaoAircraft;
    if (type == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an aircraft type')),
      );
      return;
    }

    setState(() => _saving = true);
    final photos = ref.read(aircraftPhotoStoreProvider);
    String? storedFile;
    try {
      var photo = _photo;
      if (_pickedPhoto != null) {
        storedFile = await photos.save(_pickedPhoto!);
        photo = AircraftPhoto.file(storedFile);
      }
      final repository = ref.read(aircraftRepositoryProvider);
      final tailNumber = _tailController.text.trim();
      final notes = _notesController.text.trim();
      final existing = widget.aircraft;

      int? addedId;
      if (existing != null) {
        await repository.updateAircraft(
          existing.id,
          icaoAircraftId: type.id,
          tailNumber: tailNumber,
          notes: notes.isEmpty ? null : notes,
          aircraftClass: _aircraftClass,
          typeRating: _typeRatingController.text,
          photo: _photoChanged ? Value(photo) : const Value.absent(),
        );
      } else {
        addedId = await repository.addAircraft(
          icaoAircraftId: type.id,
          tailNumber: tailNumber,
          notes: notes.isEmpty ? null : notes,
          aircraftClass: _aircraftClass,
          typeRating: _typeRatingController.text,
          photo: photo,
        );
      }

      if (mounted) Navigator.pop(context, addedId);
    } catch (e) {
      // Don't leave a photo behind that no aircraft points to.
      await photos.delete(storedFile);
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  Future<void> _deleteAircraft() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Aircraft'),
        content: Text(
          'Delete "${widget.aircraft!.tailNumber}"? Flights using this aircraft will be unlinked.',
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
    if (confirmed == true && mounted) {
      final repository = ref.read(aircraftRepositoryProvider);
      await repository.deleteAircraft(widget.aircraft!.id);
      if (mounted) Navigator.pop(context, true);
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isEditing = widget.aircraft != null;
    final lookup = _lookup;
    final photo = _photo;

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pop(context),
        heroTag: closeFabHeroTag,
        child: const Icon(Icons.close),
      ),
      body: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _saving ? null : _save,
          heroTag: primaryFabHeroTag,
          label: Text(isEditing ? "Save" : "Add"),
          icon: Icon(isEditing ? Icons.save : Icons.add),
        ),
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            AspectRatio(
              aspectRatio: aircraftPhotoAspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AircraftPhotoView(
                    photo: photo,
                    pickedFile: _pickedPhoto,
                    placeholder: const AircraftHeaderGradient(),
                  ),
                  if (_pickedPhoto == null && photo != null && photo.isOnline)
                    Positioned(
                      left: 16,
                      right: 80,
                      bottom: 16,
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: AircraftPhotoCredit(photo: photo),
                      ),
                    ),
                  Positioned(
                    right: 16,
                    bottom: 12,
                    child: FloatingActionButton.small(
                      heroTag: 'photoFab',
                      tooltip: _hasPhoto ? 'Change photo' : 'Add photo',
                      onPressed: _photoOptions,
                      child: Icon(
                        _hasPhoto ? Icons.photo_camera : Icons.add_a_photo,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (lookup != null && lookup.photos.isNotEmpty)
              _OnlinePhotosStrip(
                photos: lookup.photos,
                selectedUrl: _pickedPhoto == null ? photo?.url : null,
                onSelected: (p) => setState(() => _selectOnline(p)),
                onUseOwn: () => _pickPhoto(ImageSource.gallery),
              ),
            Padding(
              // Bottom padding keeps the last field clear of the save button.
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _tailController,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.search,
                      onFieldSubmitted: (_) => _lookUp(),
                      decoration: InputDecoration(
                        labelText: 'Tail Number',
                        hintText: 'e.g. I-ABCD',
                        prefixIcon: const Icon(Icons.numbers),
                        helperText: _lookupNote,
                        helperMaxLines: 3,
                        suffixIcon: _lookingUp
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.travel_explore),
                                tooltip: 'Look up registration',
                                onPressed: _lookUp,
                              ),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Tail number is required.'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    ModelCard(
                      aircraft: _selectedIcaoAircraft,
                      onTap: _openTypeSelector,
                      useOuterPadding: false,
                    ),

                    const SizedBox(height: 16),
                    AircraftClassCard(
                      aircraftClass: _aircraftClass,
                      candidates: _candidates,
                      onTap: _pickClass,
                    ),
                    if (_aircraftClass == AircraftClass.type) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _typeRatingController,
                        decoration: const InputDecoration(
                          labelText: 'Type rating *',
                          hintText: 'As on your licence, e.g. A320',
                          prefixIcon: Icon(Icons.badge_outlined),
                          helperText:
                              'Give aircraft covered by the same type rating '
                              'the same name, so their flights count together.',
                          helperMaxLines: 3,
                        ),
                        onChanged: (_) => _typeRatingSetByUser = true,
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Type rating is required.'
                            : null,
                      ),
                      _TypeRatingShortcuts(
                        ratings: _knownTypeRatings,
                        controller: _typeRatingController,
                        onSelected: (rating) => setState(() {
                          _typeRatingController.text = rating;
                          _typeRatingSetByUser = true;
                        }),
                      ),
                    ],

                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        hintText: 'Any additional info...',
                        prefixIcon: Icon(Icons.notes),
                      ),
                      maxLines: 3,
                    ),
                    if (isEditing) ...[
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _deleteAircraft,
                        style: TextButton.styleFrom(foregroundColor: cs.error),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete Aircraft'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The photos found online of the aircraft, to choose from, followed by a
/// tile to use an own picture instead.
class _OnlinePhotosStrip extends StatelessWidget {
  const _OnlinePhotosStrip({
    required this.photos,
    required this.selectedUrl,
    required this.onSelected,
    required this.onUseOwn,
  });

  final List<AircraftPhoto> photos;

  /// Full size URL of the photo in use, if it is one of [photos].
  final String? selectedUrl;
  final ValueChanged<AircraftPhoto> onSelected;
  final VoidCallback onUseOwn;

  static const _tileWidth = 120.0;
  static const _tileHeight = 80.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final count = photos.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            count == 1
                ? '1 photo found online'
                : '$count photos found online · tap to choose',
            style: theme.textTheme.labelLarge?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        SizedBox(
          height: _tileHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: count + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == count) {
                return _StripTile(
                  onTap: onUseOwn,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(height: 4),
                      Text('Use my own', style: theme.textTheme.labelSmall),
                    ],
                  ),
                );
              }
              final photo = photos[index];
              final selected = photo.url == selectedUrl;
              final source = photo.source;
              return Semantics(
                selected: selected,
                label: [
                  'Photo ${index + 1}',
                  if (photo.credit != null) 'by ${photo.credit}',
                  if (source != null) 'from $source',
                ].join(', '),
                child: _StripTile(
                  selected: selected,
                  onTap: () => onSelected(photo),
                  child: AircraftPhotoView(
                    photo: photo,
                    thumbnail: true,
                    placeholder: Icon(
                      Icons.image_outlined,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StripTile extends StatelessWidget {
  const _StripTile({
    required this.child,
    required this.onTap,
    this.selected = false,
  });
  final Widget child;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: _OnlinePhotosStrip._tileWidth,
      child: Material(
        color: cs.surfaceContainerHighest,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: selected
              ? BorderSide(color: cs.primary, width: 3)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              child,
              if (selected)
                Positioned(
                  top: 6,
                  right: 6,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    child: const Icon(Icons.check, size: 14),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Type ratings used on other aircraft, one tap away. Hidden when there is
/// nothing to offer besides what the field already says.
class _TypeRatingShortcuts extends StatelessWidget {
  const _TypeRatingShortcuts({
    required this.ratings,
    required this.controller,
    required this.onSelected,
  });
  final List<String> ratings;
  final TextEditingController controller;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final current = controller.text.trim();
        final others = [
          for (final rating in ratings)
            if (rating != current) rating,
        ];
        if (others.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final rating in others)
                ActionChip(
                  label: Text(rating),
                  onPressed: () => onSelected(rating),
                ),
            ],
          ),
        );
      },
    );
  }
}
