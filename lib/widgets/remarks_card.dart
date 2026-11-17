import 'dart:io';

import 'package:flutter/material.dart';

import '../services/pdf_export_service.dart';
import '../widgets/section_header.dart';

class RemarksCard extends StatelessWidget {
  const RemarksCard({
    super.key,
    required this.initialValue,
    this.onChanged,
    this.signature,
    this.onSignatureTap,
  });
  final String initialValue;
  final ValueChanged<String>? onChanged;

  /// Signature laid over the remarks in the exported logbook, if any.
  final File? signature;

  /// Adds, changes or removes the signature. Null when it can't be edited.
  final VoidCallback? onSignatureTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final editable = onChanged != null;

    return Card(
      margin: const EdgeInsets.all(0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notes, color: cs.onSurfaceVariant, size: 20),
                const SizedBox(width: 12),
                SectionHeader(
                  title: 'REMARKS & ENDORSEMENTS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (editable || initialValue.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextFormField(
                initialValue: initialValue,
                enabled: editable,
                maxLines: 3,
                style: theme.textTheme.bodyMedium,
                decoration: const InputDecoration(
                  hintText: 'Add notes, endorsements, or remarks...',
                ),
                onChanged: onChanged,
              ),
            ],
            if (signature != null) ...[
              const SizedBox(height: 12),
              _SignaturePreview(file: signature!, onTap: onSignatureTap),
            ] else if (onSignatureTap != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onSignatureTap,
                icon: const Icon(Icons.draw_outlined),
                label: const Text('Add signature'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The signature as it fits the remarks cell of the exported logbook.
class _SignaturePreview extends StatelessWidget {
  const _SignaturePreview({required this.file, this.onTap});
  final File file;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(8);
    final (:x, :y) = PdfExportService.remarksCellRatio;
    final preview = AspectRatio(
      aspectRatio: x / y,
      child: DecoratedBox(
        // On paper, whatever the theme.
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: radius,
          border: Border.all(color: cs.outlineVariant),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Image.file(
            file,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Center(
              child: Icon(Icons.broken_image_outlined, color: Colors.black38),
            ),
          ),
        ),
      ),
    );
    if (onTap == null) return preview;
    return Tooltip(
      message: 'Change signature',
      child: Stack(
        children: [
          preview,
          // Above the white paper, or the ripple wouldn't show.
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(onTap: onTap, borderRadius: radius),
            ),
          ),
        ],
      ),
    );
  }
}
