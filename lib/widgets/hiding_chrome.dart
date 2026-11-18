import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/navigation_provider.dart';

/// For the top-level tabs: hides the navigation bar and the FABs (see
/// [bottomChromeVisibleProvider]) while the user scrolls [child] down, and
/// shows them as soon as they scroll back up.
class HideChromeOnScroll extends ConsumerWidget {
  const HideChromeOnScroll({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        // Only the page's own scroll view, not e.g. a horizontal chip row.
        if (notification.depth != 0 ||
            notification.metrics.axis != Axis.vertical) {
          return false;
        }
        final chrome = ref.read(bottomChromeVisibleProvider.notifier);
        switch (notification.direction) {
          case ScrollDirection.reverse:
            chrome.hide();
          case ScrollDirection.forward:
            chrome.show();
          case ScrollDirection.idle:
            break;
        }
        return false;
      },
      child: child,
    );
  }
}

/// Slides a tab's FABs down and fades them out while
/// [bottomChromeVisibleProvider] hides the navigation bar.
class HidingFabs extends ConsumerWidget {
  const HidingFabs({super.key, required this.child});
  final Widget child;

  static const _duration = Duration(milliseconds: 260);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(bottomChromeVisibleProvider);
    final curve = visible ? Curves.easeOutCubic : Curves.easeInCubic;
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 2.5),
        duration: _duration,
        curve: curve,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: _duration,
          curve: curve,
          child: child,
        ),
      ),
    );
  }
}

/// Brings the navigation bar back and scrolls [controller] to the top, as
/// when a tab is tapped again in the navigation bar.
Future<void> scrollTabToTop(WidgetRef ref, ScrollController controller) async {
  ref.read(bottomChromeVisibleProvider.notifier).show();
  if (!controller.hasClients) return;
  // From far down, jump to near the top first: animating past hundreds of
  // rows would be slow and build every card on the way.
  final nearTop = controller.position.viewportDimension * 2;
  if (controller.offset > nearTop) controller.jumpTo(nearTop);
  await controller.animateTo(
    0,
    duration: const Duration(milliseconds: 450),
    curve: Curves.easeOutCubic,
  );
}
