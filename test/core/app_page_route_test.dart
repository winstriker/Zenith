import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/core/app_page_route.dart';

Future<void> _sendBackGesture(
  WidgetTester tester,
  String method, [
  Map<String, Object?>? args,
]) async {
  final message = const StandardMethodCodec().encodeMethodCall(
    MethodCall(method, args),
  );
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.backGesture.name,
    message,
    (_) {},
  );
}

const _startArgs = <String, Object?>{
  'touchOffset': <double>[5.0, 300.0],
  'progress': 0.0,
  'swipeEdge': 0, // left
};

void main() {
  testWidgets(
    'a back committed without a start while the page animates out is ignored',
    (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(navigatorKey: navigatorKey, home: const Text('home')),
      );
      navigatorKey.currentState!.push(
        AppPageRoute<void>(builder: (_) => const Text('page')),
      );
      await tester.pumpAndSettle();

      // A real predictive back gesture that pops the page.
      await _sendBackGesture(tester, 'startBackGesture', _startArgs);
      await _sendBackGesture(tester, 'commitBackGesture');
      await tester.pump(const Duration(milliseconds: 50));

      // A second back delivered without a start, mid pop animation.
      await _sendBackGesture(tester, 'commitBackGesture');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('home'), findsOneWidget);
      expect(navigatorKey.currentState!.userGestureInProgress, isFalse);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
