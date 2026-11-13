import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/core/theme.dart';
import 'package:zenith/services/database.dart';
import 'package:zenith/widgets/crew_card.dart';

void main() {
  testWidgets('tapping a crew member opens the role sheet and changes role', (
    tester,
  ) async {
    const anna = Person(id: 1, name: 'Anna', surname: 'Rossi');
    var crew = [const CrewMember(person: anna, role: CrewRole.ins)];
    var removed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SingleChildScrollView(
              child: CrewCard(
                pilotRole: CrewRole.pic,
                crewMembers: crew,
                onPilotRoleChanged: (_) {},
                onCrewMemberAdded: (_) {},
                onCrewMemberRemoved: (_) => removed = true,
                onCrewMemberChanged: (i, m) => setState(() {
                  crew = [...crew]..[i] = m;
                }),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Anna Rossi'));
    await tester.pumpAndSettle();
    expect(find.text('Select Role'), findsOneWidget);

    await tester.tap(find.text('Second in Command'));
    await tester.pumpAndSettle();

    expect(crew.single.role, CrewRole.sic);
    expect(crew.single.person, anna);
    expect(find.text('Second in Command'), findsOneWidget);
    expect(removed, isFalse);

    await tester.tap(find.byTooltip('Remove from crew'));
    expect(removed, isTrue);
  });

  testWidgets('read-only card shows crew without edit controls', (
    tester,
  ) async {
    const anna = Person(id: 1, name: 'Anna', surname: 'Rossi');
    CrewMember? tapped;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: CrewCard.readOnly(
            pilotRole: CrewRole.dual,
            crewMembers: const [CrewMember(person: anna, role: CrewRole.ins)],
            onCrewMemberTap: (m) => tapped = m,
          ),
        ),
      ),
    );

    expect(find.text('Dual received'), findsOneWidget);
    expect(find.text('Anna Rossi'), findsOneWidget);
    expect(find.text('Instructor'), findsOneWidget);
    expect(find.text('Add crew member'), findsNothing);
    expect(find.text('Tap to change your role'), findsNothing);
    expect(find.byTooltip('Remove from crew'), findsNothing);

    await tester.tap(find.text('SELF'));
    await tester.pumpAndSettle();
    expect(find.text('Select Role'), findsNothing);

    await tester.tap(find.text('Anna Rossi'));
    expect(tapped?.person, anna);
  });
}
