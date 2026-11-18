import 'package:flutter/material.dart';

import '../core/app_page_route.dart';
import '../widgets/aircraft_type_list_scaffold.dart';
import 'aircraft_type_detail_page.dart';

/// The ICAO aircraft types, plus the custom ones. Tap one to open its details.
class AircraftTypesPage extends StatelessWidget {
  const AircraftTypesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AircraftTypeListScaffold(
      title: 'Aircraft Types',
      onTap: (type) => Navigator.push(
        context,
        AppPageRoute<void>(
          builder: (_) => AircraftTypeDetailPage(initial: type),
        ),
      ),
    );
  }
}
