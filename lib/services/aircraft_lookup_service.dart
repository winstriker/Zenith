import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show appBuildName;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../models/aircraft_photo.dart';
import '../providers/provider_toggles.dart';

/// What one source knows about a registration. Every part is optional: some
/// sources only have photos, others only say what the aircraft is.
class AircraftSourceResult {
  const AircraftSourceResult({
    this.registration,
    this.icaoHex,
    this.icaoDesignator,
    this.modelName,
    this.photos = const [],
  });

  /// The registration as the source spells it (e.g. "D-EABC").
  final String? registration;

  /// 24-bit ICAO address of the airframe (e.g. "3D04C4"), the "hex code"
  /// ADS-B data is filed under.
  final String? icaoHex;

  /// ICAO type designator (Doc 8643), e.g. "C172".
  final String? icaoDesignator;

  /// Manufacturer and model in the source's own words, e.g. "Cessna 172R
  /// Skyhawk II". Free text, not an ICAO name.
  final String? modelName;
  final List<AircraftPhoto> photos;

  bool get isEmpty =>
      icaoDesignator == null && modelName == null && photos.isEmpty;
}

/// What is publicly known about a registration, all sources together.
class AircraftLookupResult {
  const AircraftLookupResult({
    required this.registration,
    required this.photos,
    this.icaoDesignator,
    this.modelNames = const [],
  });

  final String registration;

  /// ICAO type designator, when a source knows it. The surest way to the
  /// aircraft type.
  final String? icaoDesignator;

  /// What the sources call the aircraft, most detailed first. Free text: see
  /// `IcaoTypeMatcher` for turning it into an ICAO type.
  final List<String> modelNames;

  /// Photos that stay online, the best sources first.
  final List<AircraftPhoto> photos;

  /// The aircraft's name to show to the user, if any source gave one.
  String? get model => modelNames.isEmpty ? null : modelNames.first;
}

/// The lookup could not be completed (no network, every service down...).
/// [message] is meant to be shown to the user.
class AircraftLookupException implements Exception {
  const AircraftLookupException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// A public service that can be asked about a registration.
abstract class AircraftLookupSource {
  const AircraftLookupSource();

  /// Names the source in the settings. Never change it.
  String get id;

  /// What the user knows the source as.
  String get label;

  /// Whether the source also says what the aircraft is (its ICAO type
  /// designator), and so is worth asking even when its photos aren't wanted.
  bool get knowsType => false;

  /// Returns null when the source doesn't know the registration, and throws
  /// when it could not be asked or answered something unreadable.
  Future<AircraftSourceResult?> lookup(http.Client client, String registration);

  /// Reads a JSON object out of [response], or null for "not found".
  static Map<String, dynamic>? jsonObject(http.Response response) {
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw http.ClientException('HTTP ${response.statusCode}');
    }
    final json = jsonDecode(utf8.decode(response.bodyBytes));
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Not a JSON object');
    }
    return json;
  }

  static String? text(Object? map, String key) {
    final value = map is Map<String, dynamic> ? map[key] : null;
    return value is String && value.trim().isNotEmpty ? value.trim() : null;
  }

  /// Only https links are kept: they end up stored and opened later.
  static String? httpsUrl(String? value) {
    if (value == null) return null;
    final uri = Uri.tryParse(value);
    return uri != null && uri.isScheme('https') && uri.host.isNotEmpty
        ? value
        : null;
  }

  /// "Mooney" + "M.20F Executive 21", or whichever of the two there is.
  static String? joinName(String? manufacturer, String? model) {
    final name = [?manufacturer, ?model].join(' ');
    return name.isEmpty ? null : name;
  }
}

/// JetPhotos, through JetAPI (https://www.jetapi.dev): several full size
/// photos with their photographer, and a model name. No designator.
class JetPhotosSource extends AircraftLookupSource {
  const JetPhotosSource();

  static const sourceId = 'jetphotos';

  @override
  String get id => sourceId;

  @override
  String get label => 'JetPhotos';

  /// How many photos to ask for, so there is something to choose from.
  static const photoCount = 8;

  @override
  Future<AircraftSourceResult?> lookup(http.Client client, String reg) async {
    final response = await client.get(
      Uri.https('www.jetapi.dev', '/api', {
        'reg': reg,
        'only_jp': 'true',
        'photos': '$photoCount',
      }),
    );
    final json = AircraftLookupSource.jsonObject(response);
    return json == null ? null : parse(json);
  }

  static AircraftSourceResult? parse(Map<String, dynamic> json) {
    final images = json['Images'];
    if (images is! List) return null;
    final photos = <AircraftPhoto>[];
    String? model;
    for (final image in images) {
      final url = AircraftLookupSource.httpsUrl(
        AircraftLookupSource.text(image, 'Image'),
      );
      if (url == null) continue;
      photos.add(
        AircraftPhoto.online(
          url: url,
          thumbnailUrl: AircraftLookupSource.httpsUrl(
            AircraftLookupSource.text(image, 'Thumbnail'),
          ),
          link: AircraftLookupSource.httpsUrl(
            AircraftLookupSource.text(image, 'Link'),
          ),
          credit: AircraftLookupSource.text(image, 'Photographer'),
        ),
      );
      model ??= AircraftLookupSource.text(image, 'Aircraft');
    }
    if (photos.isEmpty) return null;
    return AircraftSourceResult(
      registration: AircraftLookupSource.text(json, 'Reg'),
      modelName: model,
      photos: photos,
    );
  }
}

/// adsbdb (https://www.adsbdb.com): the ICAO designator, manufacturer and
/// model, and sometimes one photo hosted by airport-data.com.
class AdsbdbSource extends AircraftLookupSource {
  const AdsbdbSource();

  static const sourceId = 'adsbdb';

  @override
  String get id => sourceId;

  @override
  String get label => 'adsbdb';

  @override
  bool get knowsType => true;

  @override
  Future<AircraftSourceResult?> lookup(http.Client client, String reg) async {
    final response = await client.get(
      Uri.https('api.adsbdb.com', '/v0/aircraft/$reg'),
    );
    final json = AircraftLookupSource.jsonObject(response);
    return json == null ? null : parse(json);
  }

  static AircraftSourceResult? parse(Map<String, dynamic> json) {
    final response = json['response'];
    final aircraft = response is Map<String, dynamic>
        ? response['aircraft']
        : null;
    if (aircraft is! Map<String, dynamic>) return null;
    final photo = AircraftLookupSource.httpsUrl(
      AircraftLookupSource.text(aircraft, 'url_photo'),
    );
    return AircraftSourceResult(
      registration: AircraftLookupSource.text(aircraft, 'registration'),
      icaoHex: AircraftLookupSource.text(aircraft, 'mode_s'),
      icaoDesignator: AircraftLookupSource.text(aircraft, 'icao_type'),
      modelName: AircraftLookupSource.joinName(
        AircraftLookupSource.text(aircraft, 'manufacturer'),
        AircraftLookupSource.text(aircraft, 'type'),
      ),
      photos: [
        if (photo != null)
          AircraftPhoto.online(
            url: photo,
            thumbnailUrl: AircraftLookupSource.httpsUrl(
              AircraftLookupSource.text(aircraft, 'url_photo_thumbnail'),
            ),
          ),
      ],
    );
  }
}

/// hexdb.io: the ICAO designator, manufacturer and model, and sometimes one
/// photo.
class HexdbSource extends AircraftLookupSource {
  const HexdbSource();

  static const sourceId = 'hexdb';

  @override
  String get id => sourceId;

  @override
  String get label => 'hexdb.io';

  @override
  bool get knowsType => true;

  @override
  Future<AircraftSourceResult?> lookup(http.Client client, String reg) async {
    final response = await client.get(
      Uri.https('hexdb.io', '/api/v2/aircraft', {'registration': reg}),
    );
    final json = AircraftLookupSource.jsonObject(response);
    return json == null ? null : parse(json);
  }

  static AircraftSourceResult? parse(Map<String, dynamic> json) {
    final results = json['results'];
    final aircraft = results is List && results.isNotEmpty
        ? results.first
        : null;
    if (aircraft is! Map<String, dynamic>) return null;
    final images = aircraft['images'];
    final photo = AircraftLookupSource.httpsUrl(
      AircraftLookupSource.text(images, 'full'),
    );
    return AircraftSourceResult(
      registration: AircraftLookupSource.text(aircraft, 'registration'),
      icaoHex: AircraftLookupSource.text(aircraft, 'hex'),
      icaoDesignator: AircraftLookupSource.text(aircraft, 'icao_type_code'),
      modelName: AircraftLookupSource.joinName(
        AircraftLookupSource.text(aircraft, 'manufacturer'),
        AircraftLookupSource.text(aircraft, 'type'),
      ),
      photos: [
        if (photo != null)
          AircraftPhoto.online(
            url: photo,
            thumbnailUrl: AircraftLookupSource.httpsUrl(
              AircraftLookupSource.text(images, 'thumbnail'),
            ),
          ),
      ],
    );
  }
}

/// Planespotters.net (https://www.planespotters.net/photo/api): small photos
/// with their photographer and a link back, which must both be shown.
///
/// Planespotters turns away clients that don't say who runs them, so every
/// request carries [userAgent], which must contain a contact URL or e-mail
/// address, e.g. `Zenith/1.0.0 (+https://example.com/contact)`.
class PlanespottersSource extends AircraftLookupSource {
  const PlanespottersSource({required this.userAgent});
  final String userAgent;

  static const sourceId = 'planespotters';

  @override
  String get id => sourceId;

  @override
  String get label => 'Planespotters.net';

  @override
  Future<AircraftSourceResult?> lookup(http.Client client, String reg) async {
    final response = await client.get(
      Uri.https('api.planespotters.net', '/pub/photos/reg/$reg'),
      headers: {'User-Agent': userAgent},
    );
    final json = AircraftLookupSource.jsonObject(response);
    return json == null ? null : parse(json);
  }

  static AircraftSourceResult? parse(Map<String, dynamic> json) {
    final list = json['photos'];
    if (list is! List) return null;
    final photos = <AircraftPhoto>[];
    for (final photo in list.whereType<Map<String, dynamic>>()) {
      final small = AircraftLookupSource.httpsUrl(
        AircraftLookupSource.text(photo['thumbnail'], 'src'),
      );
      // The largest picture the public API hands out.
      final large =
          AircraftLookupSource.httpsUrl(
            AircraftLookupSource.text(photo['thumbnail_large'], 'src'),
          ) ??
          small;
      if (large == null) continue;
      photos.add(
        AircraftPhoto.online(
          url: large,
          thumbnailUrl: small,
          link: AircraftLookupSource.httpsUrl(
            AircraftLookupSource.text(photo, 'link'),
          ),
          credit: AircraftLookupSource.text(photo, 'photographer'),
        ),
      );
    }
    return photos.isEmpty ? null : AircraftSourceResult(photos: photos);
  }
}

/// [source], asked only what the aircraft is: its photos are left out. For
/// sources whose photos the user switched off.
class WithoutPhotos extends AircraftLookupSource {
  const WithoutPhotos(this.source);
  final AircraftLookupSource source;

  @override
  String get id => source.id;

  @override
  String get label => source.label;

  @override
  bool get knowsType => source.knowsType;

  @override
  Future<AircraftSourceResult?> lookup(http.Client client, String reg) async {
    final result = await source.lookup(client, reg);
    if (result == null) return null;
    return AircraftSourceResult(
      registration: result.registration,
      icaoHex: result.icaoHex,
      icaoDesignator: result.icaoDesignator,
      modelName: result.modelName,
    );
  }
}

/// Looks an aircraft registration up on several public services at once and
/// puts together what they know. A service that is down or doesn't know the
/// aircraft simply contributes nothing.
class AircraftLookupService {
  AircraftLookupService(this.sources, [this._client]);

  /// In order of preference: photos of the first sources come first.
  final List<AircraftLookupSource> sources;
  final http.Client? _client;

  /// A slow source is given up on, so it doesn't hold back the others.
  static const _timeout = Duration(seconds: 12);

  /// Every source the app can use, in order of preference.
  /// [planespottersContact] is the contact URL or e-mail address
  /// Planespotters asks for; without it, Planespotters is left out.
  static List<AircraftLookupSource> allSources({
    required String? appVersion,
    required String planespottersContact,
  }) {
    final contact = planespottersContact.trim();
    return [
      const JetPhotosSource(),
      const HexdbSource(),
      const AdsbdbSource(),
      if (contact.isNotEmpty)
        PlanespottersSource(
          userAgent: 'Zenith/${appVersion ?? 'dev'} (+$contact)',
        ),
    ];
  }

  /// The sources to ask, given the ids of those whose photos the user
  /// doesn't want ([photosOff]). Such a source is not asked at all, unless
  /// it also knows the aircraft's type: then it is still asked for that.
  static List<AircraftLookupSource> defaultSources({
    required String? appVersion,
    required String planespottersContact,
    Set<String> photosOff = const {},
  }) {
    return [
      for (final source in allSources(
        appVersion: appVersion,
        planespottersContact: planespottersContact,
      ))
        if (!photosOff.contains(source.id))
          source
        else if (source.knowsType)
          WithoutPhotos(source),
    ];
  }

  /// Returns null when no source knows the registration. Throws when none
  /// could be asked.
  Future<AircraftLookupResult?> lookup(String registration) async {
    final reg = registration.trim().toUpperCase();
    if (reg.isEmpty || sources.isEmpty) return null;

    final client = _client ?? http.Client();
    final List<(AircraftSourceResult?, bool)> answers;
    try {
      answers = await Future.wait([
        for (final source in sources) _ask(source, client, reg),
      ]);
    } finally {
      if (_client == null) client.close();
    }

    if (answers.every((answer) => !answer.$2)) {
      throw const AircraftLookupException(
        'Could not reach the lookup services. Check your connection.',
      );
    }
    final found = [
      for (final (result, _) in answers)
        if (result != null && !result.isEmpty) result,
    ];
    if (found.isEmpty) return null;

    final seen = <String>{};
    return AircraftLookupResult(
      registration:
          found.map((r) => r.registration).nonNulls.firstOrNull ?? reg,
      icaoDesignator: found
          .map((r) => r.icaoDesignator?.toUpperCase())
          .nonNulls
          .firstOrNull,
      modelNames: {...found.map((r) => r.modelName).nonNulls}.toList(),
      photos: [
        for (final result in found)
          for (final photo in result.photos)
            if (seen.add(photo.url!)) photo,
      ],
    );
  }

  /// What [source] knows, and whether it answered at all.
  Future<(AircraftSourceResult?, bool)> _ask(
    AircraftLookupSource source,
    http.Client client,
    String reg,
  ) async {
    try {
      return (await source.lookup(client, reg).timeout(_timeout), true);
    } catch (_) {
      // Down, slow, or talking nonsense: the other sources may still help.
      return (null, false);
    }
  }
}

/// Who Planespotters can reach about this app's requests. Public, and the
/// same for every build unless `--dart-define PLANESPOTTERS_CONTACT=...`
/// says otherwise (an empty value switches Planespotters off).
const planespottersContact = String.fromEnvironment(
  'PLANESPOTTERS_CONTACT',
  defaultValue: 'https://github.com/winstriker/Zenith',
);

/// How the app names itself to the services that want to know who is
/// asking.
const appUserAgent = 'Zenith/${appBuildName ?? 'dev'} (+$planespottersContact)';

/// The photo sources the settings list.
final photoSourcesProvider = Provider<List<AircraftLookupSource>>((ref) {
  return AircraftLookupService.allSources(
    appVersion: appBuildName,
    planespottersContact: planespottersContact,
  );
});

final aircraftLookupServiceProvider = Provider<AircraftLookupService>((ref) {
  return AircraftLookupService(
    AircraftLookupService.defaultSources(
      appVersion: appBuildName,
      planespottersContact: planespottersContact,
      photosOff: ref.watch(disabledPhotoSourcesProvider),
    ),
  );
});
