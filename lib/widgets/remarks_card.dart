import 'dart:io';

import 'package:flutter/material.dart';

import '../services/pdf_export_service.dart';
import '../widgets/section_header.dart';
import 'signature_preview.dart';

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
    final (:x, :y) = PdfExportService.remarksCellRatio;
    final remarksRatio = x / y;

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
              SignaturePreview(
                file: signature!,
                aspectRatio: remarksRatio,
                onTap: onSignatureTap,
              ),
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
