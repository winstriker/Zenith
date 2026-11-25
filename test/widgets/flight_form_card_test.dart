import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/widgets/flight_form_card.dart';
import 'package:zenith/widgets/time_pill.dart';
import 'package:zenith/widgets/tz_chip.dart';

void main() {
  for (final (dep, arr) in [('UTC', 'GMT'), ('UTC', '+1245')]) {
    testWidgets('$dep and $arr leave the hint whole, the card centered', (
      tester,
    ) async {
      // Wide for the test font, whose letters are.
      tester.view.physicalSize = const Size(420, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlightFormCard(
              departureDate: DateTime(2026, 11, 25),
              arrivalDate: null,
              departureCode: '',
              arrivalCode: '',
              depTime: '13:10',
              arrTime: '',
              selectedDeparture: null,
              selectedArrival: null,
              depTzLabel: dep,
              arrTzLabel: arr,
              onDepartureDateTap: () {},
              onArrivalDateTap: () {},
              onDepartureTzTap: () {},
              onArrivalTzTap: () {},
              onDepartureAirportTap: () {},
              onArrivalAirportTap: () {},
              onDepTimeChanged: (_) {},
              onArrTimeChanged: (_) {},
              departure: null,
              arrival: null,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);

      final hint = tester.renderObject<RenderParagraph>(
        find.text('HH:mm').last,
      );
      expect(
        hint.size.width,
        greaterThanOrEqualTo(hint.getMaxIntrinsicWidth(double.infinity)),
      );

      final middle = tester.getCenter(find.byType(FlightFormCard)).dx;
      double at(Finder f) => tester.getCenter(f).dx;
      expect(at(find.byType(TimePill)), middle);
      expect(at(find.byIcon(Icons.flight)), middle);
      final chips = find.byType(TzChip);
      expect(
        (tester.getRect(chips.at(0)).right + tester.getRect(chips.at(1)).left) /
            2,
        middle,
      );
    });
  }
}
