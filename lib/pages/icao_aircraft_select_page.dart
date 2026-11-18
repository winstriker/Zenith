import 'package:flutter/material.dart';

import '../services/database.dart';
import '../widgets/aircraft_type_list_scaffold.dart';

/// Lists the ICAO aircraft types and pops the chosen [IcaoAircraft].
class IcaoAircraftSelectPage extends StatelessWidget {
  const IcaoAircraftSelectPage({
    super.key,
    this.suggestFor,
    this.suggestDesignator,
    this.suggestNames = const [],
  });

  /// See [AircraftTypeListScaffold.suggestFor].
  final String? suggestFor;
  final String? suggestDesignator;
  final List<String> suggestNames;

  @override
  Widget build(BuildContext context) {
    return AircraftTypeListScaffold(
      title: 'Select Aircraft Type',
      autofocusSearch: true,
      suggestFor: suggestFor,
      suggestDesignator: suggestDesignator,
      suggestNames: suggestNames,
      onTap: (type) => Navigator.pop(context, type),
      // A type created from the picker is the one being picked.
      onCreated: (type) => Navigator.pop(context, type),
    );
  }
}
