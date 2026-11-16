import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/widgets/duration_field.dart';

/// Two fields inside a Form where typing in one changes the other, like the
/// IFR / VFR split of the flight form.
class _Split extends StatefulWidget {
  const _Split();
  @override
  State<_Split> createState() => _SplitState();
}

class _SplitState extends State<_Split> {
  static const _block = Duration(minutes: 90);
  Duration? _ifr;

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        children: [
          DurationField(
            key: const Key('ifr'),
            value: _ifr,
            onChanged: (d) => setState(() => _ifr = d),
          ),
          DurationField(
            key: const Key('vfr'),
            value: _ifr == null ? null : _block - _ifr!,
            onChanged: (d) =>
                setState(() => _ifr = d == null ? null : _block - d),
          ),
        ],
      ),
    );
  }
}

void main() {
  testWidgets('a value worked out elsewhere shows up in the other field', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: _Split())));
    await tester.enterText(find.byKey(const Key('ifr')), '0030');
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('01:00'), findsOneWidget);
  });
}
