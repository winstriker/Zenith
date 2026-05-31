import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'pages/home_page.dart';
import 'pages/flights_page.dart';
import 'pages/settings_page.dart';

class LogbookApp extends ConsumerStatefulWidget {
  const LogbookApp({super.key});

  @override
  ConsumerState<LogbookApp> createState() => _LogbookAppState();
}

class _LogbookAppState extends ConsumerState<LogbookApp> {
  int _currentIndex = 0;

  final _pages = <Widget>[
    const HomePage(),
    const FlightsPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Logbook',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: Scaffold(
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
              icon: Icon(Icons.flight_outlined),
              selectedIcon: Icon(Icons.flight),
              label: 'Flights',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
