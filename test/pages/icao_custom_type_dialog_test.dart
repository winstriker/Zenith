import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/pages/icao_aircraft_select_page.dart';
import 'package:zenith/providers/database_provider.dart';
import 'package:zenith/services/database.dart';

void main() {
  late LogbookDatabase db;

  setUp(() {
    db = LogbookDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
  });

  tearDown(() => db.close());

  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: IcaoAircraftSelectPage()),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add custom aircraft type'));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Future<List<IcaoAircraft>> userTypes(WidgetTester tester) async =>
      (await tester.runAsync(
        () => (db.select(
          db.icaoAircrafts,
        )..where((t) => t.userInserted.equals(true))).get(),
      ))!;

  testWidgets('rejects a designator that is not 4 characters', (tester) async {
    await openDialog(tester);

    await tester.enterText(field('ICAO Type Designator *'), 'C17');
    await tester.enterText(field('Model Full Name *'), 'Globemaster');
    await tester.enterText(field('Manufacturer *'), 'Boeing');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text('Must be exactly 4 characters'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(await userTypes(tester), isEmpty);
  });

  testWidgets('saves a valid 4-character, upper-cased designator', (
    tester,
  ) async {
    await openDialog(tester);

    await tester.enterText(field('ICAO Type Designator *'), 'c172');
    await tester.enterText(field('Model Full Name *'), 'Skyhawk');
    await tester.enterText(field('Manufacturer *'), 'Cessna');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    final saved = await userTypes(tester);
    expect(saved, hasLength(1));
    expect(saved.single.designator, 'C172');
    expect(saved.single.modelFullName, 'Skyhawk');
  });
}
