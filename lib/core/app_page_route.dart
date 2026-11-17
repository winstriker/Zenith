import 'package:flutter/material.dart';

/// A [MaterialPageRoute] that ignores predictive back callbacks for a gesture
/// it never started.
///
/// Works around a framework bug: [WidgetsBinding] keeps the observers of the
/// last back gesture until the next gesture starts, so a back that Android
/// delivers without a start (e.g. a quick second back while the page is still
/// animating out) reaches the already-popping route again. That route then
/// calls [NavigatorState.didStopUserGesture] a second time, failing the
/// `_userGesturesInProgress > 0` assertion (and, in release, leaving the
/// navigator's gesture count negative).
///
/// Use this instead of [MaterialPageRoute] everywhere in the app.
class AppPageRoute<T> extends MaterialPageRoute<T> {
  AppPageRoute({
    required super.builder,
    super.settings,
    super.requestFocus,
    super.maintainState,
    super.fullscreenDialog,
    super.allowSnapshotting,
    super.barrierDismissible,
    super.traversalEdgeBehavior,
    super.directionalTraversalEdgeBehavior,
  });

  bool _backGestureInProgress = false;

  @override
  void handleStartBackGesture({double progress = 0.0}) {
    _backGestureInProgress = true;
    super.handleStartBackGesture(progress: progress);
  }

  @override
  void handleCommitBackGesture() {
    if (!_backGestureInProgress) return;
    _backGestureInProgress = false;
    super.handleCommitBackGesture();
  }

  @override
  void handleCancelBackGesture() {
    if (!_backGestureInProgress) return;
    _backGestureInProgress = false;
    super.handleCancelBackGesture();
  }
}
