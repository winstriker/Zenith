import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'core/theme.dart';
import 'pages/home_page.dart';
import 'pages/airports_page.dart';
import 'pages/settings_page.dart';
import 'pages/intro_page.dart';

import 'providers/theme_provider.dart';
import 'providers/carto_provider.dart';
import 'providers/user_provider.dart';
import 'providers/aircraft_providers.dart';

class LogbookApp extends ConsumerStatefulWidget {
  const LogbookApp({super.key});

  @override
  ConsumerState<LogbookApp> createState() => _LogbookAppState();
}

class _LogbookAppState extends ConsumerState<LogbookApp> {
  int _currentIndex = 0;
  bool _checkingPermission = true;
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
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

  final _pages = <Widget>[
    const HomePage(),
    const AirportsPage(),
    const SettingsPage(),
  ];

  Widget _buildMainApp() {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_airport_outlined),
            selectedIcon: Icon(Icons.local_airport),
            label: 'Airports',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final apiKey = ref.watch(cartoApiKeyProvider);
    final nickname = ref.watch(userNicknameProvider);
    final signatureName = ref.watch(userSignatureNameProvider);
    final onboardingComplete = ref.watch(onboardingCompleteProvider);
    final needsIntro = nickname == null || signatureName == null || !onboardingComplete;
    // Pre-load CARTO style as soon as the API key is available
    if (apiKey != null && apiKey.isNotEmpty) {
      ref.watch(cartoStyleProvider);
    }
    // Trigger aircraft types load on app startup
    ref.watch(aircraftTypesLoadProvider);

    return MaterialApp(
      key: ValueKey(_permissionGranted),
      title: 'Logbook',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: _checkingPermission
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : needsIntro
              ? IntroPage(onPermissionGranted: _onPermissionGranted)
              : _buildMainApp(),
    );
  }
}
