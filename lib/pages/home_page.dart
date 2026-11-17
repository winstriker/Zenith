import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme.dart';
import '../providers/aircraft_providers.dart';
import '../providers/flight_providers.dart';
import '../providers/gps_tracking_provider.dart';
import '../providers/home_header_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/user_provider.dart';
import '../services/database.dart';
import '../utils/duration_formatter.dart';
import '../widgets/empty_state.dart';
import '../widgets/flight_card.dart';
import '../widgets/load_more.dart';
import '../widgets/pulsing_dot.dart';
import '../widgets/speed_dial_fab.dart';
import 'adsb_track_page.dart';
import 'aircrafts_page.dart';
import 'flight_detail_page.dart';
import 'flight_form_page.dart';
import 'flights_page.dart';
import 'image_crop_page.dart';
import 'recording_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  /// How many recent flights the list asks for; older ones load as it is
  /// scrolled to its end.
  int _limit = loadMorePageSize;

  /// The last flights loaded, shown while older ones load.
  List<FlightWithStats>? _flights;

  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Hides the navigation bar and the FABs while the user scrolls down
  /// through the flights, and shows them as soon as they scroll back up.
  bool _onUserScroll(UserScrollNotification notification) {
    if (notification.depth != 0) return false;
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
  }

  Future<void> _scrollToTop() async {
    ref.read(bottomChromeVisibleProvider.notifier).show();
    if (!_scroll.hasClients) return;
    // From far down, jump to near the top first: animating past hundreds
    // of flights would be slow and build every card on the way.
    final nearTop = _scroll.position.viewportDimension * 2;
    if (_scroll.offset > nearTop) _scroll.jumpTo(nearTop);
    await _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tapping Home in the navigation bar again goes back to the top.
    ref.listen(tabReselectProvider, (_, next) {
      if (next?.tab == MainTab.home) _scrollToTop();
    });
    final page = ref.watch(
      recordedFlightsPageProvider((limit: _limit, query: '', day: null)),
    );
    if (page.hasValue) _flights = page.value;
    final flights = _flights;
    final hasMore = flights != null && flights.length >= _limit;
    final flightCount = ref.watch(recordedFlightCountProvider);
    final gpsController = ref.watch(gpsTrackingControllerProvider.notifier);
    final aircraftList = ref.watch(aircraftListStreamProvider);
    final nickname = ref.watch(userNicknameProvider);
    final totalFlightTime = ref.watch(totalFlightTimeProvider);
    final isRecording = gpsController.isTracking();

    return Scaffold(
      floatingActionButton: const _HidingFabs(child: _HomeFabs()),
      body: _StatusBarScrim(
        controller: _scroll,
        // Fades in as the header's bottom edge reaches the status bar.
        showFrom: _HomeHeader._expandedHeight,
        child: NotificationListener<UserScrollNotification>(
          onNotification: _onUserScroll,
          child: LoadMoreScrollView(
            controller: _scroll,
            hasMore: hasMore,
            loading: !page.hasValue,
            onLoadMore: () => setState(() => _limit += loadMorePageSize),
            builder: (context, controller) => CustomScrollView(
              controller: controller,
              slivers: [
                _HomeHeader(nickname: nickname),
                if (isRecording)
                  const SliverToBoxAdapter(child: _RecordingBanner()),
                SliverToBoxAdapter(
                  child: _QuickStats(
                    flightCount: flightCount.when(
                      data: (val) => val,
                      error: (_, _) => -1,
                      loading: () => 0,
                    ),
                    totalMinutes: totalFlightTime.when(
                      data: (val) => val,
                      error: (_, _) => -1,
                      loading: () => 0,
                    ),
                    aircraftCount: aircraftList.when(
                      data: (val) => val.length,
                      error: (_, _) => -1,
                      loading: () => 0,
                    ),
                  ),
                ),
                _SectionHeader(
                  title: 'Recent Flights',
                  icon: Icons.flight,
                  onSeeAll: () => _openFlights(context),
                ),
                ...switch (flights) {
                  null when page.hasError => const [
                    SliverToBoxAdapter(
                      child: EmptyState(
                        icon: Icons.error_outline,
                        title: 'Error while loading flights',
                      ),
                    ),
                  ],
                  null => const [
                    SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
                  [] => const [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 40,
                        ),
                        child: EmptyState(
                          icon: Icons.flight,
                          title: 'No flights yet',
                          subtitle: 'Start recording your first flight!',
                          iconSize: 48,
                        ),
                      ),
                    ),
                  ],
                  _ => [
                    SliverList.builder(
                      itemCount: flights.length,
                      itemBuilder: (context, index) => FlightCard(
                        flight: flights[index],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => FlightDetailPage(
                              flightId: flights[index].flight.id,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (hasMore)
                      const SliverToBoxAdapter(child: LoadMoreIndicator()),
                  ],
                },
                // Keeps the last flight clear of the FAB column and the nav bar.
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 136 + MediaQuery.paddingOf(context).bottom,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Once the header has scrolled away, covers the status bar with the page
/// background, so the flights don't scroll under the clock and icons.
/// Fades in over the last few pixels before [controller] reaches
/// [showFrom].
class _StatusBarScrim extends StatelessWidget {
  const _StatusBarScrim({
    required this.controller,
    required this.showFrom,
    required this.child,
  });

  final ScrollController controller;
  final double showFrom;
  final Widget child;

  static const _fadeDistance = 24.0;

  /// Soft edge under the status bar, so cards fade out rather than being
  /// cut by a line.
  static const _edge = 16.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = theme.scaffoldBackgroundColor;
    final top = MediaQuery.paddingOf(context).top;
    final dark = theme.brightness == Brightness.dark;
    final overlay = dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: top + _edge,
          child: IgnorePointer(
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, scrim) {
                final offset = controller.hasClients ? controller.offset : 0.0;
                final t =
                    ((offset - (showFrom - _fadeDistance)) / _fadeDistance)
                        .clamp(0.0, 1.0);
                // Status bar icons for the page, once the header (which
                // sets them for itself) is gone.
                return AnnotatedRegion<SystemUiOverlayStyle>(
                  value: overlay.copyWith(statusBarColor: Colors.transparent),
                  sized: false,
                  child: Opacity(opacity: t, child: scrim),
                );
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      background,
                      background,
                      background.withValues(alpha: 0),
                    ],
                    stops: [0, top / (top + _edge), 1],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

void _openFlights(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(builder: (_) => const FlightsPage()),
  );
}

void _openAircrafts(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(builder: (_) => const AircraftsPage()),
  );
}

void _openRecording(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(builder: (_) => const RecordingPage()),
  );
}

/// "Add Flight" FAB with a small "more" FAB above it that pops up the less
/// common ways to log a flight (recording, ADS-B import).
/// Slides the FABs down and fades them out while
/// [bottomChromeVisibleProvider] hides the navigation bar.
class _HidingFabs extends ConsumerWidget {
  const _HidingFabs({required this.child});
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

class _HomeFabs extends StatelessWidget {
  const _HomeFabs();

  Future<void> _importAdsb(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final imported = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AdsbTrackPage.import()),
    );
    if (imported == true) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Flight imported')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SpeedDialFab(
      actions: [
        SpeedDialAction(
          heroTag: 'adsbFab',
          icon: Icons.settings_input_antenna,
          label: 'Import from ADS-B',
          onPressed: () => _importAdsb(context),
        ),
        SpeedDialAction(
          heroTag: 'recordFab',
          icon: Icons.fiber_manual_record,
          label: 'Record',
          backgroundColor: cs.error,
          foregroundColor: cs.onError,
          onPressed: () => _openRecording(context),
        ),
      ],
      primaryIcon: Icons.add,
      primaryLabel: 'Add Flight',
      onPrimaryPressed: () => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => const FlightFormPage()),
      ),
    );
  }
}

enum _HeaderImageAction { gallery, camera, remove }

/// The welcome banner. Shows the picture the user picked, if any, faded into
/// the page towards the bottom so the greeting reads on any picture;
/// otherwise a gradient of the theme colors.
class _HomeHeader extends ConsumerWidget {
  const _HomeHeader({required this.nickname});
  final String? nickname;

  static const _expandedHeight = 200.0;

  Future<void> _changeImage(
    BuildContext context,
    WidgetRef ref, {
    required bool hasImage,
  }) async {
    final action = await showModalBottomSheet<_HeaderImageAction>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, _HeaderImageAction.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, _HeaderImageAction.camera),
            ),
            if (hasImage)
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(ctx).colorScheme.error,
                ),
                title: Text(
                  'Remove image',
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                ),
                onTap: () => Navigator.pop(ctx, _HeaderImageAction.remove),
              ),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;
    final notifier = ref.read(homeHeaderImageProvider.notifier);
    if (action == _HeaderImageAction.remove) {
      await notifier.remove();
      return;
    }
    // Framed like the expanded header, status bar included.
    final width = MediaQuery.sizeOf(context).width;
    final height = _expandedHeight + MediaQuery.paddingOf(context).top;
    final cropped = await pickAndCropImage(
      context,
      source: action == _HeaderImageAction.gallery
          ? ImageSource.gallery
          : ImageSource.camera,
      spec: CropSpec(
        title: 'Crop header image',
        aspectRatio: width / height,
        outputWidth: 1440,
        jpegQuality: 85,
      ),
    );
    if (cropped == null) return;
    await notifier.set(cropped);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final image = ref.watch(homeHeaderImageProvider);
    final hasImage = image != null;
    final background = theme.scaffoldBackgroundColor;
    // The text sits on the faded page background, picture or not.
    final foreground = cs.onSurface;

    return SliverAppBar(
      expandedHeight: _expandedHeight,
      // Scrolls away entirely; _StatusBarScrim takes over the status bar.
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (image != null)
              Image.file(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(color: background),
              )
            else ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cs.primary,
                      cs.primary.withValues(alpha: 0.8),
                      cs.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Positioned(
                right: -40,
                top: -40,
                child: Icon(
                  Icons.flight,
                  size: 180,
                  color: cs.onPrimary.withValues(alpha: 0.1),
                ),
              ),
              Positioned(
                left: -20,
                bottom: -20,
                child: Icon(
                  Icons.flight,
                  size: 120,
                  color: cs.onPrimary.withValues(alpha: 0.08),
                ),
              ),
            ],
            // Fades from the page background at the bottom to mostly the
            // picture (or colors) at the top, like Saikou's home banner.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [background, background.withValues(alpha: 0.24)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 60, 56, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Welcome back,',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: foreground.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nickname ?? 'Pilot',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: IconButton(
                tooltip: hasImage ? 'Change header image' : 'Add header image',
                iconSize: 20,
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  foregroundColor: foreground,
                  backgroundColor: foreground.withValues(alpha: 0.12),
                ),
                onPressed: () => _changeImage(context, ref, hasImage: hasImage),
                icon: const Icon(Icons.photo_camera_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown while a flight is being recorded.
class _RecordingBanner extends StatelessWidget {
  const _RecordingBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.error.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const PulsingDot(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recording in progress',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: cs.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Tap to view recording',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onErrorContainer.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () => _openRecording(context),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Open'),
              style: FilledButton.styleFrom(
                backgroundColor: cs.error,
                foregroundColor: cs.onError,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  const _QuickStats({
    required this.flightCount,
    required this.totalMinutes,
    required this.aircraftCount,
  });

  final int flightCount;
  final int totalMinutes;
  final int aircraftCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          _StatCard(
            icon: Icons.flight_takeoff,
            value: '$flightCount',
            label: 'Total Flights',
            color: colors.info,
            onTap: () => _openFlights(context),
          ),
          const SizedBox(width: 12),
          _StatCard(
            icon: Icons.schedule,
            value: DurationFormatter.hm(Duration(minutes: totalMinutes)),
            label: 'Flight Time',
            color: colors.success,
          ),
          const SizedBox(width: 12),
          _StatCard(
            icon: Icons.airplanemode_active,
            value: '$aircraftCount',
            label: 'Aircraft',
            color: colors.warning,
            onTap: () => _openAircrafts(context),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.4,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 6),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    this.onSeeAll,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (onSeeAll != null)
              TextButton(onPressed: onSeeAll, child: const Text('See all')),
          ],
        ),
      ),
    );
  }
}
