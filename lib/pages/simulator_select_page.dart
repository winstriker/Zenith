import 'package:flutter/material.dart';

import '../widgets/simulator_list_scaffold.dart';

/// Lets the flight form pick a simulator; pops with the chosen
/// `SimulatorWithStats`.
class SimulatorSelectPage extends StatelessWidget {
  const SimulatorSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SimulatorListScaffold(
      title: 'Select Simulator',
      autofocusSearch: true,
      showStats: true,
      onTap: (sim) => Navigator.pop(context, sim),
    );
  }
}
