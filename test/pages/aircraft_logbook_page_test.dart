import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/pages/aircraft_logbook_page.dart';
import 'package:zenith/services/database.dart';

void main() {
  const aircraft = AircraftWithStats(
    id: 1,
    tailNumber: 'D-KBFF',
    icaoAircraft: 1,
    description: AircraftDescription.motorglider,
    modelFullName: 'HK-36 Super Dimona',
    designator: 'DIMO',
    manufacturer: 'DIAMOND',
    engineCount: 1,
    engineType: EngineType.piston,
    wakeTurbolenceCategory: WakeTurbulenceCategory.L,
    wakeTurbolenceGroup: WakeTurbulenceGroup.Z,
    userInserted: false,
    logbookSubtitle: 'HK-36 TTC',
  );

  testWidgets('shows the fields and a preview of the logbook cell', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: AircraftLogbookPage(aircraft: aircraft)),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Type'), findsOneWidget);
    // The ICAO type in the preview, the subtitle under it.
    expect(find.text('DIMO'), findsWidgets);
    expect(find.text('HK-36 TTC'), findsWidgets);

    await tester.enterText(find.byType(TextFormField).first, 'HK36');
    await tester.pump();
    expect(find.text('HK36'), findsWidgets);
    expect(find.text('Use the ICAO type'), findsOneWidget);
  });
}
