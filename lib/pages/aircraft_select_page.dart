import 'package:flutter/material.dart';

import '../widgets/aircraft_list_scaffold.dart';

/// Lets the flight form pick an aircraft; pops with the chosen
/// [AircraftWithStats].
class AircraftSelectPage extends StatelessWidget {
  const AircraftSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AircraftListScaffold(
      title: 'Select Aircraft',
      autofocusSearch: true,
      showStats: true,
      onTap: (aws) => Navigator.pop(context, aws),
    );
  }
}
