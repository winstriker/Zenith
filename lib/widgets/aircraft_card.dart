import 'package:flutter/material.dart';

import '../core/spacing.dart';
import '../services/database.dart';
import 'aircraft_photo_view.dart';
import 'base_card.dart';

class AircraftCard extends StatelessWidget {
  const AircraftCard({
    super.key,
    required this.aircraft,
    this.onTap,
    this.onLongPress,
    this.showStats = false,
    this.useOuterPadding = true,
  });
  final AircraftWithStats? aircraft;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showStats;
  final bool useOuterPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final icon = Icon(
      Icons.airplanemode_active,
      size: 32,
      color: colorScheme.onSecondaryContainer,
    );

    // 16:9 at the height of a card with two lines of text, the shape of
    // JetPhotos thumbnails, so they are shown whole.
    const minHeight = 80.0;
    final photo = aircraft?.photo;
    const imageWidth = minHeight * 16 / 9;

    final card = BaseCard(
      onTap: onTap,
      onLongPress: onLongPress,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Flush with the left, top and bottom edges of the card, whose
          // rounded corners clip it. Positioned so that it takes the height
          // of the content instead of setting it.
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: imageWidth,
            child: ColoredBox(
              color: colorScheme.secondaryContainer,
              // The photo replaces the icon when the aircraft has one. Its
              // link is on the aircraft's page.
              child: photo == null
                  ? icon
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        AircraftPhotoView(
                          photo: photo,
                          thumbnail: true,
                          placeholder: Center(child: icon),
                        ),
                        if (photo.isOnline)
                          Positioned(
                            left: 2,
                            right: 2,
                            bottom: 2,
                            child: Align(
                              alignment: Alignment.bottomRight,
                              child: AircraftPhotoCredit(
                                photo: photo,
                                small: true,
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: minHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(imageWidth + 16, 16, 16, 16),
              child: _content(context),
            ),
          ),
        ],
      ),
    );

    if (!useOuterPadding) return card;
    return Padding(padding: AppSpacing.cardPadding, child: card);
  }

  Widget _content(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        Expanded(
          child: aircraft == null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'No Aircraft Selected',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to select',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      aircraft!.tailNumber,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      showStats
                          ? _stats(aircraft!)
                          : "${aircraft!.manufacturer} ${aircraft!.modelFullName}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
        ),
        if (aircraft != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              aircraft!.designator,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Hours and flights with the aircraft on one line, e.g. "2100.2 hrs / 10
  /// flights".
  static String _stats(AircraftWithStats aircraft) {
    final count = aircraft.flightCount;
    final flights = '$count ${count == 1 ? 'flight' : 'flights'}';
    final minutes = aircraft.totalFlightTime;
    if (minutes == null) return flights;
    return '${(minutes / 60).toStringAsFixed(1)} hrs / $flights';
  }
}
