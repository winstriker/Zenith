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
}
