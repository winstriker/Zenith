import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zenith/models/aircraft_photo.dart';
import 'package:zenith/services/aircraft_lookup_service.dart';

// Real answers of the four services, shortened.

/// https://www.jetapi.dev/api?reg=D-EABC&only_jp=true
const _jetApi = {
  'Reg': 'D-EABC',
  'Images': [
    {
      'Image': 'https://cdn.jetphotos.com/full/6/968215_1756740830.jpg',
      'Link': 'https://www.jetphotos.com/photo/11828992',
      'Thumbnail': 'https://cdn.jetphotos.com/400/6/968215_1756740830.jpg',
      'DateTaken': 'Jul 11, 2025',
      'Photographer': 'Krzysiek Dz',
      'Aircraft': 'Mooney M20F Executive 21',
    },
    {
      'Image': 'https://cdn.jetphotos.com/full/5/1241629_1723408372.jpg',
      'Link': 'https://www.jetphotos.com/photo/11441810',
      'Thumbnail': 'https://cdn.jetphotos.com/400/5/1241629_1723408372.jpg',
      'Photographer': 'Tim Donell',
      'Aircraft': 'Mooney M20F Executive 21',
    },
  ],
};

/// https://api.adsbdb.com/v0/aircraft/D-EABC
const _adsbdb = {
  'response': {
    'aircraft': {
      'type': 'M.20F Executive 21',
      'icao_type': 'M20P',
      'manufacturer': 'Mooney',
      'mode_s': '3D04C4',
      'registration': 'D-EABC',
      'registered_owner': 'Private',
      'url_photo': 'https://image.airport-data.com/aircraft/001111186.jpg',
      'url_photo_thumbnail':
          'https://airport-data.com/images/aircraft/thumbnails/001/111/001111186.jpg',
    },
  },
};

/// https://hexdb.io/api/v2/aircraft?registration=EI-DCL
const _hexdb = {
  'count': 1,
  'results': [
    {
      'hex': '4CA242',
      'registration': 'EI-DCL',
      'manufacturer': 'Boeing',
      'type': '737NG 8AS/W',
      'icao_type_code': 'B738',
      'images': {
        'full': 'https://hexdb.io/static/aircraft-images/EI-DCL.jpg',
        'thumbnail': 'https://hexdb.io/static/aircraft-images/EI-DCL-thumb.jpg',
      },
    },
  ],
};

/// https://api.planespotters.net/pub/photos/reg/D-EABC
const _planespotters = {
  'photos': [
    {
      'id': '1234567',
      'thumbnail': {
        'src': 'https://t.plnspttrs.net/12345/1234567_abc_t.jpg',
        'size': {'width': 200, 'height': 133},
      },
      'thumbnail_large': {
        'src': 'https://t.plnspttrs.net/12345/1234567_abc_280.jpg',
        'size': {'width': 420, 'height': 280},
      },
      'link': 'https://www.planespotters.net/photo/1234567/d-eabc',
      'photographer': 'Anna Rossi',
    },
  ],
};

const _contact = 'https://example.com/contact';

/// A client where each host answers what [answers] says, or 404.
MockClient _client(
  Map<String, Object> answers, {
  List<http.Request>? requests,
}) => MockClient((request) async {
  requests?.add(request);
  final answer = answers[request.url.host];
  if (answer == null) return http.Response('Not Found', 404);
  if (answer is int) return http.Response('error', answer);
  if (answer is Exception) throw answer;
  return http.Response.bytes(utf8.encode(jsonEncode(answer)), 200);
});

AircraftLookupService _service(
  Map<String, Object> answers, {
  List<http.Request>? requests,
  String contact = _contact,
  Set<String> photosOff = const {},
}) => AircraftLookupService(
  AircraftLookupService.defaultSources(
    appVersion: '1.2.3',
    planespottersContact: contact,
    photosOff: photosOff,
  ),
  _client(answers, requests: requests),
);

void main() {
  test('asks every service and puts their answers together', () async {
    final requests = <http.Request>[];
    final service = _service({
      'www.jetapi.dev': _jetApi,
      'api.adsbdb.com': _adsbdb,
      'api.planespotters.net': _planespotters,
    }, requests: requests);

    final result = (await service.lookup(' d-eabc '))!;

    expect(
      requests.map((r) => '${r.url.host}${r.url.path}'),
      unorderedEquals([
        'www.jetapi.dev/api',
        'hexdb.io/api/v2/aircraft',
        'api.adsbdb.com/v0/aircraft/D-EABC',
        'api.planespotters.net/pub/photos/reg/D-EABC',
      ]),
    );
    final jetApi = requests.firstWhere((r) => r.url.host == 'www.jetapi.dev');
    expect(jetApi.url.queryParameters['reg'], 'D-EABC');
    expect(jetApi.url.queryParameters['only_jp'], 'true');
    final hexdb = requests.firstWhere((r) => r.url.host == 'hexdb.io');
    expect(hexdb.url.queryParameters['registration'], 'D-EABC');

    expect(result.registration, 'D-EABC');
    expect(result.icaoDesignator, 'M20P');
    expect(result.model, 'Mooney M20F Executive 21');
    expect(result.modelNames, [
      'Mooney M20F Executive 21',
      'Mooney M.20F Executive 21',
    ]);

    // JetPhotos first, then the others.
    expect(result.photos.map((p) => p.source), [
      'JetPhotos',
      'JetPhotos',
      'Airport-Data.com',
      'Planespotters.net',
    ]);
    final first = result.photos.first;
    expect(first.url, 'https://cdn.jetphotos.com/full/6/968215_1756740830.jpg');
    expect(
      first.thumbnailUrl,
      'https://cdn.jetphotos.com/400/6/968215_1756740830.jpg',
    );
    expect(first.link, 'https://www.jetphotos.com/photo/11828992');
    expect(first.credit, 'Krzysiek Dz');
  });

  test('Planespotters is told who is asking, and only it', () async {
    final requests = <http.Request>[];
    await _service({'api.adsbdb.com': _adsbdb}, requests: requests).lookup('X');

    for (final request in requests) {
      final agent = request.headers['User-Agent'];
      if (request.url.host == 'api.planespotters.net') {
        expect(agent, 'Zenith/1.2.3 (+$_contact)');
      } else {
        expect(agent, isNull);
      }
    }
  });

  test('without a contact, Planespotters is not asked', () async {
    final requests = <http.Request>[];
    await _service(
      {'api.adsbdb.com': _adsbdb},
      requests: requests,
      contact: '  ',
    ).lookup('D-EABC');

    expect(requests, hasLength(3));
    expect(
      requests.map((r) => r.url.host),
      isNot(contains('api.planespotters.net')),
    );
  });

  test('Planespotters gives its larger thumbnail, credit and link', () async {
    final result = (await _service({
      'api.planespotters.net': _planespotters,
    }).lookup('D-EABC'))!;

    expect(result.icaoDesignator, isNull);
    expect(result.modelNames, isEmpty);
    expect(
      result.photos.single,
      const AircraftPhoto.online(
        url: 'https://t.plnspttrs.net/12345/1234567_abc_280.jpg',
        thumbnailUrl: 'https://t.plnspttrs.net/12345/1234567_abc_t.jpg',
        link: 'https://www.planespotters.net/photo/1234567/d-eabc',
        credit: 'Anna Rossi',
      ),
    );
  });

  test('hexdb gives the designator, a name and a photo', () async {
    final result = (await _service({'hexdb.io': _hexdb}).lookup('EI-DCL'))!;

    expect(result.registration, 'EI-DCL');
    expect(result.icaoDesignator, 'B738');
    expect(result.modelNames, ['Boeing 737NG 8AS/W']);
    expect(
      result.photos.single,
      const AircraftPhoto.online(
        url: 'https://hexdb.io/static/aircraft-images/EI-DCL.jpg',
        thumbnailUrl:
            'https://hexdb.io/static/aircraft-images/EI-DCL-thumb.jpg',
      ),
    );
    expect(result.photos.single.source, 'hexdb.io');
  });

  test('an aircraft can be known without any photo', () async {
    final result = (await _service({
      'api.adsbdb.com': {
        'response': {
          'aircraft': {
            'type': 'F172N',
            'icao_type': 'C172',
            'manufacturer': 'Reims/Cessna',
            'registration': 'OE-DVK',
            'url_photo': null,
            'url_photo_thumbnail': null,
          },
        },
      },
      'hexdb.io': {
        'count': 1,
        'results': [
          {
            'registration': 'OE-DVK',
            'manufacturer': 'Reims/Cessna',
            'type': 'F172N',
            'icao_type_code': 'C172',
            'images': null,
          },
        ],
      },
    }).lookup('OE-DVK'))!;

    expect(result.icaoDesignator, 'C172');
    // The same name twice is given once.
    expect(result.modelNames, ['Reims/Cessna F172N']);
    expect(result.photos, isEmpty);
  });

  test('a service that is down does not spoil the others', () async {
    final result = (await _service({
      'www.jetapi.dev': 503,
      'hexdb.io': http.ClientException('no route'),
      'api.planespotters.net': 403,
      'api.adsbdb.com': _adsbdb,
    }).lookup('D-EABC'))!;

    expect(result.icaoDesignator, 'M20P');
    expect(result.photos.single.source, 'Airport-Data.com');
  });

  test('a registration nobody knows is not an error', () async {
    // adsbdb and JetAPI answer 404, hexdb an empty list.
    final service = _service({
      'hexdb.io': {'count': 0, 'results': <Object>[]},
    });
    expect(await service.lookup('I-ZZZZ'), isNull);
  });

  test('an empty registration is not looked up', () async {
    final requests = <http.Request>[];
    expect(await _service({}, requests: requests).lookup('  '), isNull);
    expect(requests, isEmpty);
  });

  test('when no service can be reached, that is said in words', () async {
    final offline = _service({
      'www.jetapi.dev': http.ClientException('no route'),
      'hexdb.io': http.ClientException('no route'),
      'api.adsbdb.com': 500,
      'api.planespotters.net': http.ClientException('no route'),
    });
    await expectLater(
      offline.lookup('I-ABCD'),
      throwsA(
        isA<AircraftLookupException>().having(
          (e) => e.message,
          'message',
          contains('connection'),
        ),
      ),
    );
  });

  test('links that are not https are dropped', () {
    final jet = JetPhotosSource.parse({
      'Images': [
        {'Image': 'file:///etc/passwd', 'Aircraft': 'Nope'},
        {'Image': 'https://cdn.jetphotos.com/full/1/a.jpg', 'Link': 'ftp://x'},
      ],
    })!;
    expect(jet.photos, hasLength(1));
    // No thumbnail given: the full picture is used.
    expect(
      jet.photos.single.thumbnailUrl,
      'https://cdn.jetphotos.com/full/1/a.jpg',
    );
    expect(jet.photos.single.link, isNull);

    final adsbdb = AdsbdbSource.parse({
      'response': {
        'aircraft': {'icao_type': 'C172', 'url_photo': 'http://plain/a.jpg'},
      },
    })!;
    expect(adsbdb.photos, isEmpty);
    expect(adsbdb.icaoDesignator, 'C172');
  });

  group('photo sources switched off', () {
    const everything = {
      'www.jetapi.dev': _jetApi,
      'api.adsbdb.com': _adsbdb,
      'hexdb.io': _hexdb,
      'api.planespotters.net': _planespotters,
    };

    test('the settings list the four of them', () {
      final sources = AircraftLookupService.allSources(
        appVersion: '1.2.3',
        planespottersContact: _contact,
      );
      expect(sources.map((s) => s.id), [
        'jetphotos',
        'hexdb',
        'adsbdb',
        'planespotters',
      ]);
      expect(sources.map((s) => s.label), [
        'JetPhotos',
        'hexdb.io',
        'adsbdb',
        'Planespotters.net',
      ]);
    });

    test('a source that only has photos is not asked at all', () async {
      final requests = <http.Request>[];
      final result = (await _service(
        everything,
        requests: requests,
        photosOff: {'jetphotos', 'planespotters'},
      ).lookup('D-EABC'))!;

      expect(
        requests.map((r) => r.url.host),
        unorderedEquals(['hexdb.io', 'api.adsbdb.com']),
      );
      expect(result.photos.map((p) => p.source), [
        'hexdb.io',
        'Airport-Data.com',
      ]);
    });

    test('a source that knows the type is still asked for it', () async {
      final requests = <http.Request>[];
      final result = (await _service(
        everything,
        requests: requests,
        photosOff: {'adsbdb', 'hexdb'},
      ).lookup('D-EABC'))!;

      // Asked, for what the aircraft is...
      expect(requests.map((r) => r.url.host), contains('api.adsbdb.com'));
      expect(result.icaoDesignator, 'B738');
      expect(result.modelNames, contains('Mooney M.20F Executive 21'));
      // ...but none of their photos are offered.
      expect(result.photos.map((p) => p.source).toSet(), {
        'JetPhotos',
        'Planespotters.net',
      });
    });

    test('with every source off there are no photos, only the type', () async {
      final result = (await _service(
        everything,
        photosOff: {'jetphotos', 'hexdb', 'adsbdb', 'planespotters'},
      ).lookup('D-EABC'))!;

      expect(result.photos, isEmpty);
      expect(result.icaoDesignator, isNotNull);
    });
  });

  test('answers of an unexpected shape give nothing', () {
    expect(JetPhotosSource.parse({'Reg': 'X', 'Images': null}), isNull);
    expect(JetPhotosSource.parse({'Reg': 'X', 'Images': <Object>[]}), isNull);
    expect(AdsbdbSource.parse({'response': 'unknown aircraft'}), isNull);
    expect(HexdbSource.parse({'count': 0, 'results': <Object>[]}), isNull);
    expect(PlanespottersSource.parse({'photos': <Object>[]}), isNull);
    expect(PlanespottersSource.parse({'error': 'nope'}), isNull);
  });
}
