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

/// A tap on the tab that was already selected. [serial] tells two taps on
/// the same tab apart.
typedef TabReselection = ({MainTab tab, int serial});

class TabReselectNotifier extends Notifier<TabReselection?> {
  @override
  TabReselection? build() => null;

  void reselect(MainTab tab) =>
      state = (tab: tab, serial: (state?.serial ?? 0) + 1);
}

/// The last tap on the selected tab, for the tab to react to (e.g. scroll
/// back to the top).
final tabReselectProvider =
    NotifierProvider<TabReselectNotifier, TabReselection?>(
      TabReselectNotifier.new,
    );

class BottomChromeNotifier extends Notifier<bool> {
  @override
  bool build() {
    // Every tab starts with the bar shown, whatever the last one did.
    ref.listen(mainTabProvider, (_, _) => state = true);
    return true;
  }

  void show() => state = true;
  void hide() => state = false;
}

/// Whether the navigation bar and the page's FABs are shown. A page hides
/// them while the user scrolls down its content and shows them on the way
/// back up.
final bottomChromeVisibleProvider =
    NotifierProvider<BottomChromeNotifier, bool>(BottomChromeNotifier.new);
