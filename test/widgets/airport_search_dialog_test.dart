import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/providers/database_provider.dart';
import 'package:zenith/services/database.dart';
import 'package:zenith/widgets/airport_search_dialog.dart';

void main() {
  late LogbookDatabase db;

  setUp(() async {
    db = LogbookDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    await db.customStatement('PRAGMA foreign_keys = OFF');
    await db
        .into(db.airports)
        .insert(
          AirportsCompanion.insert(
            id: const Value(1),
            ident: const Value('LIRF'),
            type: AirportType.largeAirport,
            name: const Value('Leonardo da Vinci–Fiumicino Airport'),
            continent: 'EU',
            isoCountry: 'IT',
            isoRegion: 'IT-62',
            municipality: const Value('Rome'),
          ),
        );
  });

  tearDown(() => db.close());

  Future<void> pumpDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MaterialApp(
          home: Scaffold(body: AirportSearchDialog(title: 'Departure')),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }

  testWidgets('shows a hint before typing', (tester) async {
    await pumpDialog(tester);
    expect(find.text('Type to search airports'), findsOneWidget);
  });

  testWidgets('finds airports from the injected database', (tester) async {
    await pumpDialog(tester);

    await tester.enterText(find.byType(TextField), 'LIRF');
    // Debounce in the dialog is 350ms.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    expect(find.widgetWithText(ListTile, 'LIRF'), findsOneWidget);
    expect(find.text('Rome'), findsOneWidget);
  });

  testWidgets('shows an empty message when nothing matches', (tester) async {
    await pumpDialog(tester);

    await tester.enterText(find.byType(TextField), 'ZZZZ');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    expect(find.text('No airports found for "ZZZZ"'), findsOneWidget);
  });
}
