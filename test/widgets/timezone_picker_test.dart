import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:zenith/providers/flight_form_provider.dart';
import 'package:zenith/widgets/timezone_picker.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  testWidgets('picks a mode, or a world timezone found by its offset', (
    tester,
  ) async {
    TimezoneMode? mode;
    String? location;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => TimezonePicker.show(
              context: context,
              currentMode: TimezoneMode.local,
              currentIanaLocation: null,
              onModeChanged: (m) => mode = m,
              onIanaLocationChanged: (l) => location = l,
              isDeparture: true,
              referenceDate: DateTime.utc(2026),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    Future<void> tap(Finder finder) async {
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    await tap(find.text('open'));
    expect(find.byIcon(Icons.check), findsOneWidget);
    await tap(find.text('UTC'));
    expect(mode, TimezoneMode.utc);

    await tap(find.text('open'));
    await tap(find.textContaining('Other'));
    // Nothing changes until a timezone is picked.
    expect(mode, TimezoneMode.utc);
    await tester.enterText(find.byType(TextField), '+05:45');
    await tester.pump();
    await tap(find.text('Asia/Kathmandu'));
    expect(mode, TimezoneMode.iana);
    expect(location, 'Asia/Kathmandu');
  });
}
