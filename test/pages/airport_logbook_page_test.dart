import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/pages/airport_logbook_page.dart';
import 'package:zenith/services/database.dart';

void main() {
  const airport = Airport(
    id: 1,
    ident: 'IT-0042',
    type: AirportType.smallAirport,
    name: 'Aviosuperficie Rossi',
    latitudeDeg: 45.5,
    longitudeDeg: 9.25,
    continent: 'EU',
    isoCountry: 'IT',
    isoRegion: 'IT-25',
  );

  testWidgets('shows the fields and a preview of the logbook', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: AirportLogbookPage(airport: airport)),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Identifier'), findsOneWidget);
    // No ICAO code: described under the page by default (the note field's
    // hint and the preview).
    expect(
      find.text("IT-0042 – Aviosuperficie Rossi, IT – 45°30.00'N 009°15.00'E"),
      findsNWidgets(2),
    );
    expect(find.text("Use the airport's data"), findsNothing);

    await tester.enterText(find.byType(TextFormField).first, 'ROSSI');
    await tester.pump();
    expect(find.text('ROSSI'), findsWidgets);
    expect(
      find.text("ROSSI – Aviosuperficie Rossi, IT – 45°30.00'N 009°15.00'E"),
      findsNWidgets(2),
    );

    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(find.textContaining('Aviosuperficie Rossi'), findsNothing);
    expect(find.text("Use the airport's data"), findsOneWidget);
  });
}
