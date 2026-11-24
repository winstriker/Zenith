import 'package:flutter/material.dart';

/// Spacing shared by the pages and cards.
class AppSpacing {
  AppSpacing._();

  /// Distance of page content from the screen edges.
  static const double pageHorizontal = 16.0;

  /// Around each card of a list.
  static const EdgeInsets cardPadding = EdgeInsets.symmetric(
    horizontal: pageHorizontal,
    vertical: 6,
  );
}
