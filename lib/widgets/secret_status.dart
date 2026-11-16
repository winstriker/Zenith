import 'package:flutter/material.dart';

/// Whether a key or secret is saved, without showing any of it.
class SecretStatus extends StatelessWidget {
  const SecretStatus({
    super.key,
    required this.isSet,
    this.missing = 'Not set',
    this.isRequired = true,
  });

  final bool isSet;

  /// What to show when nothing is saved.
  final String missing;

  /// Whether nothing saved is a problem, shown in the error colour.
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSet
        ? theme.colorScheme.primary
        : isRequired
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isSet ? Icons.check_circle : Icons.remove_circle_outline,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            isSet ? 'Saved' : missing,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
