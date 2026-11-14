import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../repositories/person_repository.dart';
import '../services/database.dart';
import '../services/person_photo_store.dart';
import '../widgets/person_avatar.dart';

enum _PhotoAction { gallery, camera, remove }

/// Full-page form that creates a new person, or edits [person] when given.
/// Pops the saved [Person].
class PersonFormPage extends ConsumerStatefulWidget {
  const PersonFormPage({
    super.key,
    this.person,
    this.initialName = '',
    this.initialSurname = '',
  });

  /// When set, the page edits this person instead of creating a new one.
  final Person? person;
  final String initialName;
  final String initialSurname;

  @override
  ConsumerState<PersonFormPage> createState() => _PersonFormPageState();
}

class _PersonFormPageState extends ConsumerState<PersonFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.person?.name ?? widget.initialName,
  );
  late final _surnameController = TextEditingController(
    text: widget.person?.surname ?? widget.initialSurname,
  );
  bool _saving = false;

  /// Newly picked picture, not yet copied into the store.
  File? _pickedPhoto;
  bool _photoRemoved = false;

  bool get _hasPhoto =>
      _pickedPhoto != null || (!_photoRemoved && widget.person?.photo != null);

  @override
  void initState() {
    super.initState();
    // The header avatar shows the name's initial while there is no photo.
    _nameController.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    await _save();
  }

  Future<void> _pickPhoto() async {
    final action = await showModalBottomSheet<_PhotoAction>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
    if (action == null) return;
    if (action == _PhotoAction.remove) {
      setState(() {
        _pickedPhoto = null;
        _photoRemoved = true;
      });
      return;
    }
    final picked = await ImagePicker().pickImage(
      source: action == _PhotoAction.gallery
          ? ImageSource.gallery
          : ImageSource.camera,
      // Keep enough resolution for the user to crop into; the cropper
      // produces the final, small file.
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (picked == null || !mounted) return;
    // image_picker reuses its cache file names (scaled_<id>.jpg), so that
    // file can vanish while uCrop is still reading it. Crop from a private,
    // uniquely named copy instead.
    final source = File(
      '${Directory.systemTemp.path}/crop_src_${const Uuid().v4()}.jpg',
    );
    await File(picked.path).copy(source.path);
    File? cropped;
    try {
      if (!mounted) return;
      cropped = await _cropSquare(source.path);
    } finally {
      if (source.existsSync()) await source.delete();
    }
    if (cropped == null || !mounted) return;
    setState(() {
      _pickedPhoto = cropped;
      _photoRemoved = false;
    });
  }

  /// Lets the user crop [path] to a square, then downsizes and compresses it
  /// so stored profile pictures stay small. Returns null if cancelled.
  Future<File?> _cropSquare(String path) async {
    final cs = Theme.of(context).colorScheme;
    final cropped = await ImageCropper().cropImage(
      sourcePath: path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      maxWidth: 512,
      maxHeight: 512,
      compressQuality: 80,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop photo',
          toolbarColor: cs.surface,
          toolbarWidgetColor: cs.onSurface,
          backgroundColor: cs.surface,
          activeControlsWidgetColor: cs.primary,
          statusBarLight: cs.brightness == Brightness.light,
          navBarLight: cs.brightness == Brightness.light,
          lockAspectRatio: true,
          initAspectRatio: CropAspectRatioPreset.square,
          aspectRatioPresets: const [CropAspectRatioPreset.square],
          hideBottomControls: false,
          cropStyle: CropStyle.circle,
        ),
        IOSUiSettings(
          title: 'Crop photo',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          aspectRatioPickerButtonHidden: true,
          aspectRatioPresets: const [CropAspectRatioPreset.square],
          cropStyle: CropStyle.circle,
        ),
      ],
    );
    return cropped == null ? null : File(cropped.path);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final repo = ref.read(personRepositoryProvider);
    final name = _nameController.text.trim();
    final surname = _surnameController.text.trim();
    final existing = widget.person;

    // Value.absent() = photo unchanged.
    var photo = const Value<String?>.absent();
    if (_pickedPhoto != null) {
      photo = Value(
        await ref.read(personPhotoStoreProvider).save(_pickedPhoto!),
      );
    } else if (_photoRemoved) {
      photo = const Value(null);
    }

    final Person result;
    if (existing == null) {
      result = await repo.addPerson(
        name: name,
        surname: surname,
        photo: photo.present ? photo.value : null,
      );
    } else {
      await repo.updatePerson(
        existing.id,
        name: name,
        surname: surname,
        photo: photo,
      );
      result = existing.copyWith(
        name: name,
        surname: surname,
        photo: photo.present ? photo : Value(existing.photo),
      );
    }
    if (mounted) Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEditing = widget.person != null;

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pop(context),
        heroTag: 'closeFab',
        child: const Icon(Icons.close),
      ),
      body: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _saving ? null : _submit,
          heroTag: 'saveFab',
          label: Text(isEditing ? 'Save' : 'Add'),
          icon: Icon(isEditing ? Icons.save : Icons.add),
        ),
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.paddingOf(context).top + 72,
                16,
                32,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.secondaryContainer,
                    cs.secondaryContainer.withValues(alpha: 0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: _PhotoButton(
                  name: _nameController.text,
                  photo: _photoRemoved ? null : widget.person?.photo,
                  file: _pickedPhoto,
                  onTap: _pickPhoto,
                ),
              ),
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
                      controller: _nameController,
                      autofocus: !isEditing && widget.initialName.isEmpty,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Name *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: _required('Name'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _surnameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: 'Surname *',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: _required('Surname'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static FormFieldValidator<String> _required(String label) =>
      (value) => (value == null || value.trim().isEmpty)
      ? '$label is required.'
      : null;
}

class _PhotoButton extends StatelessWidget {
  const _PhotoButton({
    required this.name,
    required this.photo,
    required this.file,
    required this.onTap,
  });
  final String name;
  final String? photo;
  final File? file;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Change photo',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Stack(
          children: [
            PersonAvatar(name: name, photo: photo, file: file, radius: 64),
            Positioned(
              right: 4,
              bottom: 4,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                child: const Icon(Icons.photo_camera, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
