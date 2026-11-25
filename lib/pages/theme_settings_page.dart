import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/fab_hero_tags.dart';
import '../core/theme.dart';
import '../providers/theme_provider.dart';
import '../widgets/page_title.dart';

class ThemeSettingsPage extends ConsumerWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final palette = ref.watch(paletteProvider);
    final oled = ref.watch(oledProvider);
    final systemAccent = ref.watch(systemAccentProvider);
    final useSystem = systemAccent != null && ref.watch(systemColorsProvider);
    final brightness = switch (themeMode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => MediaQuery.platformBrightnessOf(context),
    };

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: FloatingActionButton(
        heroTag: closeFabHeroTag,
        tooltip: 'Close',
        onPressed: () => Navigator.pop(context),
        child: const Icon(Icons.close),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        children: [
          const PageTitle(
            'Theme',
            belowCloseButton: true,
            horizontalPadding: 0,
          ),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment<ThemeMode>(
                value: ThemeMode.system,
                icon: Icon(Icons.settings_suggest_outlined),
                label: Text('Auto'),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_outlined),
                label: Text('Light'),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_outlined),
                label: Text('Dark'),
              ),
            ],
            selected: {themeMode},
            onSelectionChanged: (s) =>
                ref.read(themeProvider.notifier).setThemeMode(s.first),
          ),
          const SizedBox(height: 16),
          // The system colors replace the palette: picking one does nothing.
          AnimatedOpacity(
            opacity: useSystem ? 0.38 : 1,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: useSystem,
              child: SizedBox(
                height: 252,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: AppPalette.values.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final p = AppPalette.values[i];
                    return _PalettePreview(
                      palette: p,
                      scheme: AppTheme.scheme(
                        brightness,
                        palette: p,
                        oled: oled,
                      ),
                      selected: p == palette,
                      onTap: () => ref.read(paletteProvider.notifier).set(p),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                // Only where Android has wallpaper colors (12+).
                if (systemAccent != null)
                  SwitchListTile(
                    secondary: Icon(
                      Icons.wallpaper,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('Use system colors'),
                    value: useSystem,
                    onChanged: ref.read(systemColorsProvider.notifier).set,
                  ),
                SwitchListTile(
                  secondary: Icon(
                    Icons.contrast,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('OLED black'),
                  value: oled,
                  onChanged: themeMode == ThemeMode.light
                      ? null
                      : ref.read(oledProvider.notifier).set,
                ),
                SwitchListTile(
                  secondary: Icon(
                    Icons.fullscreen,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Full screen'),
                  value: ref.watch(fullScreenProvider),
                  onChanged: ref.read(fullScreenProvider.notifier).set,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A miniature Home page drawn in [scheme]: title, stat tiles, recent
/// flights, the Add Flight FAB and the floating nav bar.
class _PalettePreview extends StatelessWidget {
  const _PalettePreview({
    required this.palette,
    required this.scheme,
    required this.selected,
    required this.onTap,
  });

  final AppPalette palette;
  final ColorScheme scheme;
  final bool selected;
  final VoidCallback onTap;

  static Widget _bar(double width, double height, Color color) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(height / 2),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final cs = scheme;
    final colors = cs.brightness == Brightness.light
        ? AppColors.light
        : AppColors.dark;

    Widget stat(Color color) => Expanded(
      child: Container(
        height: 26,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.circle, size: 7, color: color),
            const SizedBox(height: 3),
            _bar(12, 3, cs.onSurface),
          ],
        ),
      ),
    );
    Widget airport(CrossAxisAlignment align) => Column(
      crossAxisAlignment: align,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _bar(18, 4, cs.onSurface),
        const SizedBox(height: 3),
        _bar(12, 3, cs.onSurfaceVariant),
      ],
    );
    final flight = Container(
      height: 28,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          airport(CrossAxisAlignment.start),
          RotatedBox(
            quarterTurns: 1,
            child: Icon(Icons.flight, size: 9, color: cs.primary),
          ),
          airport(CrossAxisAlignment.end),
        ],
      ),
    );
    final fab = Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add, size: 9, color: cs.onPrimaryContainer),
          const SizedBox(width: 2),
          _bar(14, 3, cs.onPrimaryContainer),
        ],
      ),
    );
    final navBar = Container(
      height: 22,
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(11),
        boxShadow: [
          BoxShadow(color: cs.shadow.withValues(alpha: 0.2), blurRadius: 3),
        ],
      ),
      child: Row(
        children: [
          for (final (i, icon) in const [
            Icons.home,
            Icons.badge_outlined,
            Icons.local_airport_outlined,
            Icons.settings_outlined,
          ].indexed)
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: i == 0
                    ? ShapeDecoration(
                        color: cs.primary.withValues(alpha: 0.14),
                        shape: const StadiumBorder(),
                      )
                    : null,
                child: Icon(
                  icon,
                  size: 10,
                  color: i == 0 ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: '${palette.label} theme',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 120,
              height: 214,
              padding: const EdgeInsets.fromLTRB(8, 18, 8, 8),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              // Painted over the content: no layout shift when selected.
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? cs.primary : cs.outlineVariant,
                  width: selected ? 3 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bar(52, 7, cs.onSurface),
                  const SizedBox(height: 8),
                  Row(
                    spacing: 4,
                    children: [
                      stat(colors.info),
                      stat(colors.success),
                      stat(colors.warning),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Icon(Icons.flight, size: 8, color: cs.primary),
                      const SizedBox(width: 3),
                      _bar(34, 4, cs.onSurface),
                    ],
                  ),
                  const SizedBox(height: 2),
                  flight,
                  flight,
                  const Spacer(),
                  Align(alignment: Alignment.centerRight, child: fab),
                  const SizedBox(height: 6),
                  navBar,
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              palette.label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? Theme.of(context).colorScheme.primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
