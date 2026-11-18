import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_page_route.dart';
import '../core/fab_hero_tags.dart';
import '../providers/user_provider.dart';
import '../repositories/pilot_profile_repository.dart';
import '../services/database.dart';
import '../services/pdf_export_service.dart';
import '../services/person_photo_store.dart';
import '../utils/duration_formatter.dart';
import '../widgets/page_title.dart';
import '../widgets/section_header.dart';
import '../widgets/signature_preview.dart';
import 'image_crop_page.dart';
import 'previous_totals_page.dart';
import 'signature_pad_page.dart';

enum _SignatureAction { draw, upload, remove }

/// The pilot's own data: their names, the totals of their previous logbook
/// and the signature that signs the exported one.
class PersonalDataPage extends ConsumerStatefulWidget {
  const PersonalDataPage({super.key});

  @override
  ConsumerState<PersonalDataPage> createState() => _PersonalDataPageState();
}

class _PersonalDataPageState extends ConsumerState<PersonalDataPage> {
  bool _savingSignature = false;

  Future<void> _editName() async {
    final name = await _editText(
      title: 'Full Name',
      initial: ref.read(userSignatureNameProvider) ?? '',
      hint: 'e.g. John A. Smith',
      helper: null,
    );
    if (name != null) {
      await ref.read(userSignatureNameProvider.notifier).setSignatureName(name);
    }
  }

  Future<void> _editAddress(String? current) async {
    final address = await _editText(
      title: 'Address',
      initial: current ?? '',
      hint: 'Street, postcode, city, country',
      helper: null,
      multiline: true,
    );
    if (address != null) {
      await ref.read(pilotProfileRepositoryProvider).setAddress(address);
    }
  }

  Future<void> _editNickname() async {
    final nickname = await _editText(
      title: 'Nickname',
      initial: ref.read(userNicknameProvider) ?? '',
      hint: 'e.g. Captain',
      helper: null,
    );
    if (nickname != null) {
      await ref.read(userNicknameProvider.notifier).setNickname(nickname);
    }
  }

  /// The trimmed text, or null when cancelled. Never empty, unless
  /// [multiline], where empty clears it.
  Future<String?> _editText({
    required String title,
    required String initial,
    required String hint,
    required String? helper,
    bool multiline = false,
  }) => showDialog<String>(
    context: context,
    builder: (_) => _TextDialog(
      title: title,
      initial: initial,
      hint: hint,
      helper: helper,
      multiline: multiline,
    ),
  );

  Future<void> _editPreviousTotals() => Navigator.push<bool>(
    context,
    AppPageRoute(builder: (_) => const PreviousTotalsPage()),
  );

  Future<void> _pickSignature({required bool hasSignature}) async {
    final action = await showModalBottomSheet<_SignatureAction>(
      context: context,
      builder: (ctx) {
        final error = Theme.of(ctx).colorScheme.error;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.draw_outlined),
                title: const Text('Draw signature'),
                onTap: () => Navigator.pop(ctx, _SignatureAction.draw),
              ),
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const Text('Upload PNG'),
                onTap: () => Navigator.pop(ctx, _SignatureAction.upload),
              ),
              if (hasSignature)
                ListTile(
                  leading: Icon(Icons.delete_outline, color: error),
                  title: Text(
                    'Remove signature',
                    style: TextStyle(color: error),
                  ),
                  onTap: () => Navigator.pop(ctx, _SignatureAction.remove),
                ),
            ],
          ),
        );
      },
    );
    if (action == null || !mounted) return;
    final File? picked;
    switch (action) {
      case _SignatureAction.remove:
        picked = null;
      case _SignatureAction.draw:
        picked = await Navigator.push<File>(
          context,
          AppPageRoute(builder: (_) => const SignaturePadPage()),
        );
        if (picked == null) return;
      case _SignatureAction.upload:
        final (:x, :y) = PdfExportService.pilotSignatureRatio;
        picked = await pickAndCropImage(
          context,
          source: ImageSource.gallery,
          // An upload keeps its original file, and so its transparency.
          maxPickSize: null,
          spec: CropSpec(
            title: 'Fit signature',
            aspectRatio: x / y,
            // About 400 dpi in a 37 mm wide box.
            outputWidth: 600,
            allowOutside: true,
          ),
        );
        if (picked == null) return;
    }
    if (!mounted) return;
    setState(() => _savingSignature = true);
    try {
      await ref.read(pilotProfileRepositoryProvider).setSignature(picked);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save signature: $e')));
      }
    } finally {
      if (mounted) setState(() => _savingSignature = false);
    }
  }

  static String _totalsSummary(PreviousTotals totals) {
    if (totals.isEmpty) return 'Not entered';
    final total = totals.time(LogbookTimeField.total);
    final landings = totals.dayLandings + totals.nightLandings;
    return [
      '${DurationFormatter.hm(total)} total time',
      if (landings > 0) '$landings ${landings == 1 ? 'landing' : 'landings'}',
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final name = ref.watch(userSignatureNameProvider);
    final nickname = ref.watch(userNicknameProvider);
    final profile = ref.watch(pilotProfileProvider);
    final totals = profile.value?.previousTotals ?? PreviousTotals.empty;
    final signatureName = profile.value?.signatureFile;
    final signatureDir = ref.watch(signatureDirectoryProvider).value;
    final signature = signatureName == null || signatureDir == null
        ? null
        : File('${signatureDir.path}/$signatureName');
    final (:x, :y) = PdfExportService.pilotSignatureRatio;

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
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          const PageTitle(
            'Personal Data',
            belowCloseButton: true,
            horizontalPadding: 0,
          ),
          const SectionHeader(title: 'Pilot', uppercase: true),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.badge_outlined, color: cs.primary),
                  title: const Text('Full Name'),
                  subtitle: Text(name ?? '—'),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: _editName,
                ),
                const Divider(height: 1, indent: 72),
                ListTile(
                  leading: Icon(Icons.person_outline, color: cs.primary),
                  title: const Text('Nickname'),
                  subtitle: Text(nickname ?? '—'),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: _editNickname,
                ),
                const Divider(height: 1, indent: 72),
                ListTile(
                  leading: Icon(Icons.home_outlined, color: cs.primary),
                  title: const Text('Address'),
                  subtitle: Text(profile.value?.address ?? '—'),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: profile.hasValue
                      ? () => _editAddress(profile.value?.address)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const SectionHeader(title: 'Logbook', uppercase: true),
          Card(
            child: ListTile(
              leading: Icon(Icons.history_edu_outlined, color: cs.primary),
              title: const Text('Previous Logbook'),
              subtitle: Text(_totalsSummary(totals)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _editPreviousTotals,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.draw_outlined, color: cs.primary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          "Pilot's Signature",
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      if (_savingSignature)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (signature != null)
                    SignaturePreview(
                      // A new file name per change: no stale image.
                      key: ValueKey(signature.path),
                      file: signature,
                      aspectRatio: x / y,
                      onTap: _savingSignature
                          ? null
                          : () => _pickSignature(hasSignature: true),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: _savingSignature || !profile.hasValue
                          ? null
                          : () => _pickSignature(hasSignature: false),
                      icon: const Icon(Icons.draw_outlined),
                      label: const Text('Add signature'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextDialog extends StatefulWidget {
  const _TextDialog({
    required this.title,
    required this.initial,
    required this.hint,
    required this.helper,
    this.multiline = false,
  });

  final String title;
  final String initial;
  final String hint;
  final String? helper;

  /// Several lines, and may be left empty.
  final bool multiline;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  late final _controller = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final text = _controller.text.trim();
    if (text.isEmpty && !widget.multiline) {
      setState(() => _error = "Can't be empty");
      return;
    }
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        minLines: widget.multiline ? 2 : 1,
        maxLines: widget.multiline ? 4 : 1,
        keyboardType: widget.multiline ? TextInputType.multiline : null,
        decoration: InputDecoration(
          hintText: widget.hint,
          helperText: widget.helper,
          helperMaxLines: 2,
          errorText: _error,
        ),
        onSubmitted: widget.multiline ? null : (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
