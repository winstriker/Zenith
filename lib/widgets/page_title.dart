import 'package:flutter/material.dart';

/// The large, left-aligned title at the top of a page, which pages show
/// instead of an app bar. It clears the status bar itself, so it goes first
/// in the page's scroll view, with no top padding there.
class PageTitle extends StatelessWidget {
  const PageTitle(
    this.title, {
    super.key,
    this.trailing,
    this.belowCloseButton = false,
    this.horizontalPadding = 16,
    this.bottomPadding = 8,
  });

  final String title;

  /// Shown at the end of the title line, e.g. an icon button.
  final Widget? trailing;

  /// Whether the page has the close FAB pinned at the top-left: the title
  /// then starts below it.
  final bool belowCloseButton;

  /// 0 when the scroll view already pads its content.
  final double horizontalPadding;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
    );
    final trailing = this.trailing;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        MediaQuery.paddingOf(context).top + (belowCloseButton ? 80 : 24),
        // An icon button brings its own padding.
        trailing == null ? horizontalPadding : horizontalPadding / 2,
        bottomPadding,
      ),
      child: trailing == null
          ? text
          : Row(
              children: [
                Expanded(child: text),
                trailing,
              ],
            ),
    );
  }
}
