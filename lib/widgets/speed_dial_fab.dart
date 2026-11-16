import 'package:flutter/material.dart';

import '../core/fab_hero_tags.dart';

/// An entry of a [SpeedDialFab].
class SpeedDialAction {
  const SpeedDialAction({
    required this.heroTag,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  });

  final Object heroTag;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
}

/// A page's main extended FAB, with a small "more" FAB above it that pops up
/// the less common [actions].
class SpeedDialFab extends StatefulWidget {
  const SpeedDialFab({
    super.key,
    required this.actions,
    required this.primaryIcon,
    required this.primaryLabel,
    required this.onPrimaryPressed,
  });

  /// From top to bottom.
  final List<SpeedDialAction> actions;
  final IconData primaryIcon;
  final String primaryLabel;
  final VoidCallback onPrimaryPressed;

  @override
  State<SpeedDialFab> createState() => _SpeedDialFabState();
}

class _SpeedDialFabState extends State<SpeedDialFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
    reverseDuration: const Duration(milliseconds: 220),
  );
  bool _open = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _controller.forward() : _controller.reverse();
  }

  /// Closes the menu before running [action], so it is closed on return.
  void _run(VoidCallback action) {
    if (_open) _toggle();
    action();
  }

  /// Pops [child] up from the "more" FAB: it fades in, slides up and scales
  /// with a slight overshoot. [start] (0..0.2) staggers the entries so the
  /// one nearest the FAB appears first.
  Widget _popIn(Widget child, {required double start}) {
    final pop = _controller.drive(
      CurveTween(
        curve: Interval(start, start + 0.8, curve: Curves.easeOutBack),
      ),
    );
    return FadeTransition(
      opacity: _controller.drive(
        CurveTween(curve: Interval(start, start + 0.5, curve: Curves.easeOut)),
      ),
      child: SlideTransition(
        position: pop.drive(
          Tween(begin: const Offset(0, 0.5), end: Offset.zero),
        ),
        child: ScaleTransition(
          scale: pop.drive(Tween(begin: 0.6, end: 1.0)),
          alignment: Alignment.bottomRight,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = widget.actions;
    final last = actions.length - 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Grows the room for the entries along with their pop-in.
        SizeTransition(
          sizeFactor: _controller.drive(CurveTween(curve: Curves.easeOutCubic)),
          alignment: Alignment.bottomRight,
          child: IgnorePointer(
            ignoring: !_open,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final (i, action) in actions.indexed) ...[
                  _popIn(
                    start: last == 0 ? 0 : 0.2 * (last - i) / last,
                    _SpeedDialEntry(
                      action: action,
                      onPressed: () => _run(action.onPressed),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
        FloatingActionButton.small(
          heroTag: moreFabHeroTag,
          tooltip: _open ? 'Close' : 'More',
          onPressed: _toggle,
          // Cross-fades "more" into "close" while turning a quarter.
          child: Stack(
            alignment: Alignment.center,
            children: [
              FadeTransition(
                opacity: _controller.drive(Tween(begin: 1.0, end: 0.0)),
                child: RotationTransition(
                  turns: _controller
                      .drive(CurveTween(curve: Curves.easeOutCubic))
                      .drive(Tween(begin: 0.0, end: 0.25)),
                  child: const Icon(Icons.more_horiz),
                ),
              ),
              FadeTransition(
                opacity: _controller,
                child: RotationTransition(
                  turns: _controller
                      .drive(CurveTween(curve: Curves.easeOutCubic))
                      .drive(Tween(begin: -0.25, end: 0.0)),
                  child: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FloatingActionButton.extended(
          heroTag: primaryFabHeroTag,
          icon: Icon(widget.primaryIcon),
          label: Text(widget.primaryLabel),
          onPressed: () => _run(widget.onPrimaryPressed),
        ),
      ],
    );
  }
}

/// Compact extended FAB used for the speed-dial entries.
class _SpeedDialEntry extends StatelessWidget {
  const _SpeedDialEntry({required this.action, required this.onPressed});

  final SpeedDialAction action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        floatingActionButtonTheme: theme.floatingActionButtonTheme.copyWith(
          extendedSizeConstraints: const BoxConstraints.tightFor(height: 40),
          extendedPadding: const EdgeInsetsDirectional.only(start: 12, end: 16),
          extendedIconLabelSpacing: 8,
        ),
      ),
      child: FloatingActionButton.extended(
        heroTag: action.heroTag,
        backgroundColor: action.backgroundColor,
        foregroundColor: action.foregroundColor,
        icon: Icon(action.icon, size: 20),
        label: Text(action.label),
        onPressed: onPressed,
      ),
    );
  }
}
