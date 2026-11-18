import 'package:flutter/material.dart';

import '../models/sync_progress.dart';

/// Progress bar + percentage + status line for a reference data download.
class SyncProgressIndicator extends StatelessWidget {
  const SyncProgressIndicator({
    super.key,
    required this.progress,
    this.compact = false,
  });

  final SyncProgress progress;

  /// Smaller bar and text, for banners.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final percent = progress.percent;
    final isError = progress.phase == SyncPhase.error;
    final textStyle =
        (compact ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium)
            ?.copyWith(color: isError ? cs.error : cs.onSurfaceVariant);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isError)
          ClipRRect(
            borderRadius: BorderRadius.circular(compact ? 2 : 4),
            child: LinearProgressIndicator(
              value: progress.fraction,
              minHeight: compact ? 4 : 8,
            ),
          ),
        SizedBox(height: compact ? 6 : 10),
        Row(
          children: [
            Expanded(
              child: Text(
                progress.message,
                style: textStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (percent != null && !isError) ...[
              const SizedBox(width: 8),
              Text(
                '$percent%',
                style:
                    (compact
                            ? theme.textTheme.labelMedium
                            : theme.textTheme.titleMedium)
                        ?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Shown under a page title while reference data is syncing, or after it
/// failed, with a retry button then.
class SyncBanner extends StatelessWidget {
  const SyncBanner({super.key, required this.progress, required this.onRetry});

  final SyncProgress progress;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isError = progress.phase == SyncPhase.error;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: SyncProgressIndicator(progress: progress, compact: true),
          ),
          if (isError)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
