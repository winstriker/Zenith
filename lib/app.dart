import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'core/theme.dart';
import 'pages/airports_page.dart';
import 'pages/home_page.dart';
import 'pages/intro_page.dart';
import 'pages/settings_page.dart';
import 'providers/aircraft_providers.dart';
import 'providers/backup_providers.dart';
import 'providers/map_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'widgets/floating_nav_bar.dart';

class LogbookApp extends ConsumerStatefulWidget {
  const LogbookApp({super.key});

  @override
  ConsumerState<LogbookApp> createState() => _LogbookAppState();
}

class _LogbookAppState extends ConsumerState<LogbookApp> {
  int _currentIndex = 0;
  bool _checkingPermission = true;
  bool _permissionGranted = false;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    // Automatic backups run shortly after launch and whenever the app comes
    // back to the foreground; the controller skips them if none is due.
    _lifecycle = AppLifecycleListener(onResume: _runAutomaticBackups);
    Future.delayed(const Duration(seconds: 5), _runAutomaticBackups);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _runAutomaticBackups() {
    if (!mounted || !ref.read(onboardingCompleteProvider)) return;
    unawaited(ref.read(backupControllerProvider.notifier).runAutomatic());
  }

  void _onPermissionGranted() {
    setState(() => _permissionGranted = true);
  }

  Future<void> _checkLocationPermission() async {
    final status = await Geolocator.checkPermission();
    if (!mounted) return;
    setState(() {
      _permissionGranted =
          status == LocationPermission.always ||
          status == LocationPermission.whileInUse;
      _checkingPermission = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
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

    return MaterialApp(
      title: 'Logbook',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      // Keyed so the home subtree (not the whole app/navigator) is rebuilt
      // once location permission is granted.
      home: KeyedSubtree(
        key: ValueKey(_permissionGranted),
        child: _checkingPermission
            ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            : needsIntro
            ? IntroPage(onPermissionGranted: _onPermissionGranted)
            : _MainShell(
                currentIndex: _currentIndex,
                onDestinationSelected: (i) => setState(() => _currentIndex = i),
              ),
      ),
    );
  }
}

/// Bottom-navigation shell holding the three top-level tabs.
class _MainShell extends StatelessWidget {
  const _MainShell({
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  static const _pages = <Widget>[HomePage(), AirportsPage(), SettingsPage()];

  @override
  Widget build(BuildContext context) {
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
                for (final (i, page) in _pages.indexed)
                  HeroMode(enabled: i == currentIndex, child: page),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: FloatingNavBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: const [
          FloatingNavDestination(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: 'Home',
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
    );
  }
}
