import 'package:flutter/material.dart';

/// The home page's banner layout on the plain page background: a tall app
/// bar that scrolls away, with the title at its bottom-left. A sliver, so it
/// goes first in a [CustomScrollView].
class PageHeader extends StatelessWidget {
  const PageHeader(this.title, {super.key, this.trailing});

  final String title;

  /// Shown at the end of the title line, e.g. an icon button.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trailing = this.trailing;
    return SliverAppBar(
      // Puts the title where PageTitle(belowCloseButton: true) has it: 80 above, a
      // 36-high headlineMedium line, 8 below.
      expandedHeight: 124,
      automaticallyImplyLeading: false,
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          // An icon button brings its own padding.
          padding: EdgeInsets.fromLTRB(16, 0, trailing == null ? 16 : 8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
