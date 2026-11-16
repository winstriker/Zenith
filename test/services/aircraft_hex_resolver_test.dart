import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zenith/services/aircraft_hex_resolver.dart';
import 'package:zenith/services/aircraft_lookup_service.dart';
import 'package:zenith/services/registry_database.dart';

// Real answers, shortened.

/// https://api.adsbdb.com/v0/aircraft/G-EZBZ
const _adsbdb = {
  'response': {
    'aircraft': {
      'type': 'A319 111',
      'icao_type': 'A319',
      'manufacturer': 'Airbus',
      'mode_s': '4010EE',
      'registration': 'G-EZBZ',
    },
  },
};

/// https://hexdb.io/api/v2/aircraft?registration=G-EZBZ
Map<String, Object> _hexdb(String hex) => {
  'count': 1,
  'results': [
    {'hex': hex, 'registration': 'G-EZBZ', 'icao_type_code': 'A319'},
  ],
};

MockClient _client(Map<String, Object> answers, {List<Uri>? requests}) =>
    MockClient((request) async {
      requests?.add(request.url);
      final answer = answers[request.url.host];
      if (answer == null) return http.Response('Not Found', 404);
      if (answer is int) return http.Response('error', answer);
      if (answer is Exception) throw answer;
      return http.Response.bytes(utf8.encode(jsonEncode(answer)), 200);
    });

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late RegistryDatabase registry;
  setUp(() => registry = RegistryDatabase(NativeDatabase.memory()));
  tearDown(() => registry.close());

  Future<void> register(String registration, String hex) => registry
      .into(registry.registeredAircrafts)
      .insert(
        RegisteredAircraftsCompanion.insert(
          registration: RegistryDatabase.normalizeRegistration(registration),
          hex: hex,
        ),
      );

  AircraftHexResolver resolver() =>
      AircraftHexResolver(AircraftHexResolver.allSources(registry));

  test('the sources are the local database, adsbdb and hexdb.io', () {
    final sources = AircraftHexResolver.allSources(registry);
    expect(sources.map((s) => s.id), ['local', 'adsbdb', 'hexdb']);
    expect(sources.map((s) => s.label), [
      'Local database',
      'adsbdb',
      'hexdb.io',
    ]);
  });

  test('every source is asked, and they agree', () async {
    await register('G-EZBZ', '4010ee');
    final requests = <Uri>[];

    final resolution = await resolver().resolve(
      _client({
        'api.adsbdb.com': _adsbdb,
        'hexdb.io': _hexdb('4010EE'),
      }, requests: requests),
      ' g-ezbz ',
    );

    expect(requests.map((u) => u.toString()), [
      'https://api.adsbdb.com/v0/aircraft/G-EZBZ',
      'https://hexdb.io/api/v2/aircraft?registration=G-EZBZ',
    ]);
    final candidate = resolution.candidates.single;
    expect(candidate.hex, '4010ee');
    expect(candidate.sources, ['Local database', 'adsbdb', 'hexdb.io']);
    expect(resolution.unreachable, isEmpty);
  });

  test('when they disagree, the most agreed upon comes first', () async {
    // The registration moved to another airframe, and one source is behind.
    await register('G-EZBZ', '400000');

    final resolution = await resolver().resolve(
      _client({'api.adsbdb.com': _adsbdb, 'hexdb.io': _hexdb('4010EE')}),
      'G-EZBZ',
    );

    expect(resolution.candidates.map((c) => c.hex), ['4010ee', '400000']);
    expect(resolution.candidates.first.sources, ['adsbdb', 'hexdb.io']);
  });

  test('a tie goes to the preferred source', () async {
    await register('G-EZBZ', '400000');

    final resolution = await resolver().resolve(
      _client({'api.adsbdb.com': _adsbdb}),
      'G-EZBZ',
    );

    expect(resolution.candidates.map((c) => c.hex), ['400000', '4010ee']);
  });

  test('a source that is down is named, the others still answer', () async {
    final resolution = await resolver().resolve(
      _client({
        'api.adsbdb.com': http.ClientException('offline'),
        'hexdb.io': _hexdb('4010EE'),
      }),
      'G-EZBZ',
    );

    expect(resolution.candidates.single.hex, '4010ee');
    expect(resolution.unreachable, ['adsbdb']);
  });

  test('nobody knowing the registration is not an error', () async {
    final resolution = await resolver().resolve(
      // hexdb.io answers an empty list, adsbdb 404.
      _client({
        'hexdb.io': {'count': 0, 'results': <Object>[]},
      }),
      'ZZ-NOPE',
    );

    expect(resolution.candidates, isEmpty);
    expect(resolution.unreachable, isEmpty);
  });

  test('something that is no ICAO address is not taken for one', () async {
    final resolution = await resolver().resolve(
      _client({'hexdb.io': _hexdb('N/A')}),
      'G-EZBZ',
    );
    expect(resolution.candidates, isEmpty);
  });

  test('only the sources switched on are asked', () async {
    await register('G-EZBZ', '4010ee');
    final requests = <Uri>[];
    final local = AircraftHexResolver([LocalHexSource(registry)]);

    final resolution = await local.resolve(
      _client({'api.adsbdb.com': _adsbdb}, requests: requests),
      'G-EZBZ',
    );

    expect(requests, isEmpty);
    expect(resolution.candidates.single.sources, ['Local database']);
    expect(
      (await const AircraftHexResolver(
        [],
      ).resolve(_client({}), 'G-EZBZ')).candidates,
      isEmpty,
    );
  });

  test('the lookup sources still give what the aircraft form needs', () {
    final adsbdb = AdsbdbSource.parse(_adsbdb)!;
    expect(adsbdb.icaoHex, '4010EE');
    expect(adsbdb.icaoDesignator, 'A319');
    expect(HexdbSource.parse(_hexdb('4010EE'))!.icaoHex, '4010EE');
  });
}
