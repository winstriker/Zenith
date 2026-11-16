import 'dart:async';

import 'package:http/http.dart' as http;

import 'adsb_track_source.dart';
import 'aircraft_lookup_service.dart';
import 'registry_database.dart';

/// Something that knows which 24-bit ICAO address (the "hex code" ADS-B
/// data is filed under) a registration has.
abstract class HexSource {
  const HexSource();

  /// Names the source in the settings. Never change it.
  String get id;

  /// What the user knows the source as.
  String get label;

  /// The addresses known for [registration], six lower case hex digits
  /// each. Empty when the source doesn't know it; throws when it could not
  /// be asked.
  Future<List<String>> hexesFor(http.Client client, String registration);
}

/// The registry downloaded onto the device (tar1090-db): no network needed,
/// once it is there.
class LocalHexSource extends HexSource {
  const LocalHexSource(this.database);
  final RegistryDatabase database;

  static const sourceId = 'local';

  @override
  String get id => sourceId;

  @override
  String get label => 'Local database';

  @override
  Future<List<String>> hexesFor(http.Client client, String registration) {
    return database.hexesFor(registration);
  }
}

/// One of the services the aircraft lookup already asks about a
/// registration (adsbdb, hexdb.io): their answer has the address too.
class LookupHexSource extends HexSource {
  const LookupHexSource(this.source);
  final AircraftLookupSource source;

  @override
  String get id => source.id;

  @override
  String get label => source.label;

  @override
  Future<List<String>> hexesFor(http.Client client, String registration) async {
    final result = await source.lookup(client, registration);
    final hex = AdsbTrackSource.normalizeHex(result?.icaoHex);
    return [?hex];
  }
}

/// An address a registration may have, and who says so.
class HexCandidate {
  const HexCandidate(this.hex, this.sources);

  /// Six lower case hex digits.
  final String hex;

  /// Labels of the sources that gave this address.
  final List<String> sources;
}

/// What the sources know of a registration.
class HexResolution {
  const HexResolution({required this.candidates, required this.unreachable});

  /// The most agreed upon first. Usually one; more when the sources
  /// disagree, as they do for a registration that moved to another
  /// airframe.
  final List<HexCandidate> candidates;

  /// Labels of the sources that could not be asked.
  final List<String> unreachable;
}

/// Asks every enabled source which ICAO address a registration has.
class AircraftHexResolver {
  const AircraftHexResolver(this.sources);

  /// In order of preference.
  final List<HexSource> sources;

  /// A slow source is given up on, so it doesn't hold back the others.
  static const _timeout = Duration(seconds: 12);

  /// Every source the app can use. The online ones are the lookup services
  /// that know addresses.
  static List<HexSource> allSources(RegistryDatabase registry) => [
    LocalHexSource(registry),
    const LookupHexSource(AdsbdbSource()),
    const LookupHexSource(HexdbSource()),
  ];

  Future<HexResolution> resolve(http.Client client, String registration) async {
    final reg = registration.trim().toUpperCase();
    if (reg.isEmpty || sources.isEmpty) {
      return const HexResolution(candidates: [], unreachable: []);
    }
    final answers = await Future.wait([
      for (final source in sources) _ask(source, client, reg),
    ]);

    final bySource = <String, List<String>>{};
    final unreachable = <String>[];
    for (final (i, answer) in answers.indexed) {
      if (answer == null) {
        unreachable.add(sources[i].label);
        continue;
      }
      for (final hex in answer) {
        (bySource[hex] ??= []).add(sources[i].label);
      }
    }
    // Map entries keep the order the addresses were first seen in, which is
    // the sources' order of preference: that settles ties.
    final found = bySource.entries.toList();
    final order = [for (var i = 0; i < found.length; i++) i]
      ..sort((a, b) {
        final agreed = found[b].value.length.compareTo(found[a].value.length);
        return agreed != 0 ? agreed : a.compareTo(b);
      });
    return HexResolution(
      candidates: [
        for (final i in order) HexCandidate(found[i].key, found[i].value),
      ],
      unreachable: unreachable,
    );
  }

  /// What [source] knows, or null when it could not be asked.
  Future<List<String>?> _ask(
    HexSource source,
    http.Client client,
    String registration,
  ) async {
    try {
      return await source.hexesFor(client, registration).timeout(_timeout);
    } catch (_) {
      return null;
    }
  }
}
