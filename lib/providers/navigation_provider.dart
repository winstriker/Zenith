import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The top-level tabs of the app, in navigation bar order.
enum MainTab { home, licences, airports, settings }

class MainTabNotifier extends Notifier<MainTab> {
  @override
  MainTab build() => MainTab.home;

  void select(MainTab tab) => state = tab;
}

/// The tab shown by the main shell. Anything can switch it, e.g. a tapped
/// notification.
final mainTabProvider = NotifierProvider<MainTabNotifier, MainTab>(
  MainTabNotifier.new,
);
