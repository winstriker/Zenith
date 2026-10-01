import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/app.dart';

void main() {
  testWidgets('App renders home page', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: LogbookApp()));

    expect(find.text('Pilot Logbook'), findsOneWidget);
    expect(find.text('Recent Flights'), findsOneWidget);
  });
}
