import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/models/flight_track.dart';
import 'package:zenith/pages/adsb_track_editor_page.dart';
import 'package:zenith/providers/map_provider.dart';
import 'package:zenith/providers/shared_preferences_provider.dart';
import 'package:zenith/services/adsb_track_source.dart';

final _start = DateTime.utc(2026, 11, 10, 9);
final _points = [
  for (var i = 0; i < 3; i++)
    TrackPoint(
      time: _start.add(Duration(minutes: 30 * i)),
      latitude: 45 + i / 10,
      longitude: 9,
      onGround: i == 1,
      altitude: i == 1 ? null : 1000,
    ),
];

void main() {
  testWidgets('pops the part kept, never less than two points', (tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    AdsbFlight? part;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          // No tiles to load.
          mapTilesProvider.overrideWithValue(const AsyncLoading()),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => part = await Navigator.push<AdsbFlight>(
                context,
                MaterialPageRoute(
                  builder: (_) => AdsbTrackEditorPage(
                    flight: AdsbFlight(
                      provider: AdsbProvider.openSky,
                      icao24: '4ca242',
                      start: _points.first.time,
                      end: _points.last.time,
                    ),
                    points: _points,
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    // The map's spinner never settles.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byTooltip('End one position earlier'));
    await tester.pump();
    expect(find.text('09:30:00 UTC · on the ground'), findsOneWidget);

    // Only two points are left: neither end goes further.
    await tester.tap(find.byTooltip('End one position earlier'));
    await tester.tap(find.byTooltip('Start one position later'));
    await tester.pump();

    await tester.tap(find.textContaining('Use this part'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(part?.points, _points.sublist(0, 2));
    expect(part?.end, _points[1].time);
    expect(tester.takeException(), isNull);
  });
}
