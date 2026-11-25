import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import 'core/app_page_route.dart';
import 'core/theme.dart';
import 'pages/about_page.dart';
import 'pages/airports_page.dart';
import 'pages/home_page.dart';
import 'pages/intro_page.dart';
import 'pages/licences_page.dart';
import 'pages/recording_page.dart';
import 'pages/settings_page.dart';
import 'providers/aircraft_providers.dart';
import 'providers/announcement_providers.dart';
import 'providers/backup_providers.dart';
import 'providers/flight_recorder_provider.dart';
import 'providers/licence_providers.dart';
import 'providers/map_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/sync_providers.dart';
import 'providers/theme_provider.dart';
import 'providers/update_providers.dart';
import 'providers/user_provider.dart';
import 'services/update_service.dart';
import 'widgets/floating_nav_bar.dart';

class LogbookApp extends ConsumerStatefulWidget {
  const LogbookApp({super.key});

  @override
  ConsumerState<LogbookApp> createState() => _LogbookAppState();
}

class _LogbookAppState extends ConsumerState<LogbookApp> {
  // Only flips when the intro grants location access, to rebuild home.
  bool _permissionGranted = false;
  late final AppLifecycleListener _lifecycle;
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    // Automatic backups and syncs run shortly after launch and whenever the
    // app comes back to the foreground; the controller skips backups that
    // aren't due. Every change syncs a moment later (syncOnChanges), and
    // leaving the app syncs too, through WorkManager, so closing the app
    // (Android) or iOS suspending it doesn't cut it off.
    _lifecycle = AppLifecycleListener(
      onResume: () {
        _runAutomaticBackups();
        unawaited(ref.read(systemAccentProvider.notifier).load());
      },
      onPause: Platform.isAndroid || Platform.isIOS ? _syncInBackground : _sync,
    );
    Future.delayed(const Duration(), _runAutomaticBackups);
    ref.read(syncControllerProvider.notifier).syncOnChanges();
    Future.delayed(const Duration(seconds: 5), _checkForUpdates);
    Future.delayed(const Duration(seconds: 6), _checkAnnouncements);
    WidgetsBinding.instance.addPostFrameCallback((_) => _resumeRecording());
  }

  /// Picks up a recording the app was killed during, and shows it.
  Future<void> _resumeRecording() async {
    if (!await ref.read(flightRecorderProvider.notifier).resume()) return;
    unawaited(
      _navigatorKey.currentState?.push(
        AppPageRoute<void>(builder: (_) => const RecordingPage()),
      ),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _runAutomaticBackups() {
    if (!mounted || !ref.read(onboardingCompleteProvider)) return;
    unawaited(ref.read(backupControllerProvider.notifier).runAutomatic());
    _sync();
  }

  void _sync() {
    if (!mounted || !ref.read(onboardingCompleteProvider)) return;
    unawaited(ref.read(syncControllerProvider.notifier).syncAll());
  }

  void _syncInBackground() {
    if (!mounted || !ref.read(onboardingCompleteProvider)) return;
    unawaited(
      Workmanager().registerOneOffTask(
        'sync',
        'sync',
        constraints: Constraints(networkType: NetworkType.connected),
        // shortcut: an edit made while a sync is mid-run waits for the next
        // pause or launch; use append if that proves too late (it chains a
        // sync per pause while offline).
        existingWorkPolicy: ExistingWorkPolicy.keep,
      ),
    );
  }

  /// Fetches announcements, so the home page can flag unread ones.
  void _checkAnnouncements() {
    if (!mounted ||
        !ref.read(onboardingCompleteProvider) ||
        !ref.read(showAnnouncementsProvider)) {
      return;
    }
    // Offline is fine: the page shows the error when opened.
    ref.read(announcementsProvider.future).ignore();
  }

  Future<void> _checkForUpdates() async {
    if (!mounted ||
        !canSelfUpdate ||
        updatesRepoUrl.isEmpty ||
        !ref.read(onboardingCompleteProvider) ||
        !ref.read(autoUpdateCheckProvider)) {
      return;
    }
    final release = await ref.read(updateProvider.notifier).check();
    if (release == null) return;
    _messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('Zenith ${release.version} is available'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _navigatorKey.currentState?.push(
            AppPageRoute<void>(builder: (_) => const AboutPage()),
          ),
        ),
      ),
    );
  }

  void _onPermissionGranted() {
    setState(() => _permissionGranted = true);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final palette = ref.watch(paletteProvider);
    final systemAccent = ref.watch(systemColorsProvider)
        ? ref.watch(systemAccentProvider)
        : null;
    final nickname = ref.watch(userNicknameProvider);
    final signatureName = ref.watch(userSignatureNameProvider);
    final onboardingComplete = ref.watch(onboardingCompleteProvider);
    final needsIntro =
        nickname == null || signatureName == null || !onboardingComplete;
    // Pre-load the map tiles (the CARTO style, when used) so maps open
    // ready. Listened, not watched, for the same reason as below.
    ref.listen(mapTilesProvider, (_, _) {});
    // Trigger aircraft types load on app startup. Listened, not watched:
    // the lists read the table through streams, so the whole app (and any
    // animation on screen) doesn't need to rebuild when the load finishes.
    ref.listen(aircraftTypesLoadProvider, (_, _) {});
    // Applies the full screen setting from startup on.
    ref.listen(fullScreenProvider, (_, _) {});
    // Keeps licence & currency reminders scheduled, once there is a pilot.
    if (!needsIntro) ref.listen(currencyReminderSyncProvider, (_, _) {});

    return MaterialApp(
      title: 'Zenith',
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _messengerKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(
        Brightness.light,
        palette: palette,
        systemAccent: systemAccent,
      ),
      darkTheme: AppTheme.build(
        Brightness.dark,
        palette: palette,
        oled: ref.watch(oledProvider),
        systemAccent: systemAccent,
      ),
      themeMode: themeMode,
      // Keyed so the home subtree (not the whole app/navigator) is rebuilt
      // once location permission is granted.
      home: KeyedSubtree(
        key: ValueKey(_permissionGranted),
        child: needsIntro
            ? IntroPage(onPermissionGranted: _onPermissionGranted)
            : const _MainShell(),
      ),
    );
  }
}

/// Bottom-navigation shell holding the top-level tabs (see [MainTab]).
class _MainShell extends ConsumerWidget {
  const _MainShell();

  static const _pages = <MainTab, Widget>{
    MainTab.home: HomePage(),
    MainTab.licences: LicencesPage(),
    MainTab.airports: AirportsPage(),
    MainTab.settings: SettingsPage(),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(mainTabProvider).index;
    return Scaffold(
      // Tab content scrolls behind the floating bar; the bar's height reaches
      // the pages as bottom MediaQuery padding.
      extendBody: true,
      body: Builder(
        builder: (context) {
          // extendBody only raises the bottom *padding* to the bar's height,
          // but the pages' Scaffolds place their FABs by *viewPadding*: raise
          // that too, so the FABs sit above the floating bar.
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(
              viewPadding: mq.viewPadding.copyWith(
                bottom: math.max(mq.viewPadding.bottom, mq.padding.bottom),
              ),
            ),
            child: IndexedStack(
              index: currentIndex,
              children: [
                // IndexedStack keeps hidden tabs in the tree, so their heroes
                // would still take part in transitions (e.g. Home's "Add
                // Flight" FAB flying in when a page pushed from Settings is
                // popped).
                for (final tab in MainTab.values)
                  HeroMode(
                    enabled: tab.index == currentIndex,
                    child: _pages[tab]!,
                  ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _HidingNavBar(
        child: FloatingNavBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (i) {
            final tab = MainTab.values[i];
            if (i == currentIndex) {
              ref.read(tabReselectProvider.notifier).reselect(tab);
            } else {
              ref.read(mainTabProvider.notifier).select(tab);
            }
          },
          destinations: const [
            FloatingNavDestination(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              label: 'Home',
            ),
            FloatingNavDestination(
              icon: Icons.badge_outlined,
              selectedIcon: Icons.badge,
              label: 'Licences',
            ),
            FloatingNavDestination(
              icon: Icons.local_airport_outlined,
              selectedIcon: Icons.local_airport,
              label: 'Airports',
            ),
            FloatingNavDestination(
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings,
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

/// Slides the navigation bar off the bottom of the screen while
/// [bottomChromeVisibleProvider] says so. Only paints elsewhere: the bar
/// keeps its size, so the pages' bottom padding doesn't jump.
class _HidingNavBar extends ConsumerWidget {
  const _HidingNavBar({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(bottomChromeVisibleProvider);
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        // A bit past its height, so its shadow goes too.
        offset: visible ? Offset.zero : const Offset(0, 1.2),
        duration: const Duration(milliseconds: 260),
        curve: visible ? Curves.easeOutCubic : Curves.easeInCubic,
        child: child,
      ),
    );
  }
}
