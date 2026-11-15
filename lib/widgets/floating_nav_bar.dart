import 'package:flutter/material.dart';

/// One tab of a [FloatingNavBar].
class FloatingNavDestination {
  const FloatingNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Bottom navigation drawn as a rounded, elevated bar inset from the screen
/// edges, instead of a full-width bar glued to the bottom. The selected tab
/// gets a tinted pill around both its icon and its label, which slides to
/// the new tab when the selection changes.
///
/// Meant for a [Scaffold.bottomNavigationBar] with [Scaffold.extendBody] set,
/// so the body scrolls behind it. The body then gets the bar's height as
/// bottom [MediaQuery] padding, which scroll views should add to their bottom
/// padding. Nested Scaffolds place FABs by viewPadding instead, so the shell
/// must raise that as well.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<FloatingNavDestination> destinations;

  static const _radius = 28.0;
  static const _height = 64.0;

  /// Gap between the pill and its slot's edges.
  static const _pillInset = EdgeInsets.symmetric(horizontal: 10, vertical: 6);

  static const _slideDuration = Duration(milliseconds: 380);
  static const _slideCurve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Material(
          color: cs.surfaceContainer,
          elevation: 3,
          shadowColor: cs.shadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: _height,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final slotWidth = constraints.maxWidth / destinations.length;
                return Stack(
                  children: [
                    // One pill shared by all tabs, sliding under the selected
                    // one.
                    AnimatedPositioned(
                      duration: _slideDuration,
                      curve: _slideCurve,
                      left: selectedIndex * slotWidth + _pillInset.left,
                      width: slotWidth - _pillInset.horizontal,
                      top: _pillInset.top,
                      bottom: _pillInset.bottom,
                      child: DecoratedBox(
                        decoration: ShapeDecoration(
                          color: cs.primary.withValues(alpha: 0.14),
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (final (i, destination) in destinations.indexed)
                          Expanded(
                            child: _NavItem(
                              destination: destination,
                              selected: i == selectedIndex,
                              onTap: () => onDestinationSelected(i),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final FloatingNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  static const _duration = Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      excludeSemantics: true,
      // No ink ripple: the sliding pill is the tap feedback.
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: FloatingNavBar._pillInset,
          // Animates 0 → 1 as the tab becomes selected, tinting icon and
          // label while the pill slides in.
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: selected ? 1 : 0),
            duration: _duration,
            curve: Curves.easeOut,
            builder: (context, t, _) {
              final foreground = Color.lerp(
                cs.onSurfaceVariant,
                cs.primary,
                t,
              )!;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: _duration,
                    child: Icon(
                      selected ? destination.selectedIcon : destination.icon,
                      key: ValueKey(selected),
                      color: foreground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.lerp(
                        FontWeight.w500,
                        FontWeight.w700,
                        t,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
