import 'package:flutter/material.dart';

/// Centralized spacing constants for consistent layout across the app.
class AppSpacing {
  AppSpacing._();

  // Horizontal page padding - used for content distance from screen edges
  static const double pageHorizontal = 16.0;

  // Card horizontal padding - distance from card edge to screen edge in lists
  static const double cardHorizontal = 16.0;

  // Vertical padding between cards in lists
  static const double cardVertical = 6.0;

  // Section padding - used for section headers and grouped content
  static const double sectionHorizontal = 16.0;

  // Form padding - used for form content
  static const double formHorizontal = 16.0;

  // Hero section padding - used for detail page hero headers
  static const double heroHorizontal = 16.0;

  // Common EdgeInsets for page-level horizontal padding
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: pageHorizontal,
  );

  // EdgeInsets for list view with standard vertical padding
  static const EdgeInsets listPadding = EdgeInsets.only(top: 8, bottom: 80);

  // EdgeInsets for card items in lists
  static const EdgeInsets cardPadding = EdgeInsets.symmetric(
    horizontal: cardHorizontal,
    vertical: cardVertical,
  );
}
