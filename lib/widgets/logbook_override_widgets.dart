import 'package:flutter/material.dart';

import 'section_header.dart';

/// A card of overridable logbook values under [title].
class LogbookOverrideSection extends StatelessWidget {
  const LogbookOverrideSection({
    super.key,
    required this.title,
    required this.children,
  });
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: title,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// A text value: the computed one as the hint, a clear button once there is
/// an override.
class LogbookOverrideTextRow extends StatelessWidget {
  const LogbookOverrideTextRow({
    super.key,
    required this.controller,
    this.label,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;

  /// Shown above the field, when given.
  final String? label;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: label == null
              ? null
              : FloatingLabelBehavior.always,
          hintText: hint.isEmpty ? '—' : hint,
          suffixIcon: controller.text.trim().isEmpty
              ? null
              : IconButton(
                  tooltip: 'Use computed value',
                  icon: const Icon(Icons.undo, size: 20),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
