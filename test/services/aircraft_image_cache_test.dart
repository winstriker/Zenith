import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/models/aircraft_photo.dart';
import 'package:zenith/providers/shared_preferences_provider.dart';
import 'package:zenith/services/aircraft_image_cache.dart';
import 'package:zenith/widgets/aircraft_photo_view.dart';

/// A 1x1 PNG.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9'
  'awAAAABJRU5ErkJggg==',
);

const _url = 'https://cdn.jetphotos.com/full/1/a.jpg';

void main() {
  late Directory root;
  late bool online;
  late int downloads;
  late Map<String, Uint8List> remote;

  AircraftImageCache cache({int maxBytes = 1000}) => AircraftImageCache(
    () async => root,
    maxBytes: maxBytes,
    client: MockClient((request) async {
      if (!online) throw const SocketException('offline');
      downloads++;
      final bytes = remote['${request.url}'];
      return bytes == null
          ? http.Response('Not Found', 404)
          : http.Response.bytes(bytes, 200);
    }),
  );

  setUp(() {
    root = Directory.systemTemp.createTempSync('zenith_images');
    online = true;
    downloads = 0;
    remote = {
      _url: Uint8List.fromList([1, 2, 3]),
    };
  });

  tearDown(() => root.deleteSync(recursive: true));

  List<File> saved() {
    final dir = Directory('${root.path}/aircraft_images');
    return dir.existsSync() ? dir.listSync().whereType<File>().toList() : [];
  }

  test('a picture seen online is there offline, in a new session', () async {
    expect(await cache().load(_url), [1, 2, 3]);
    expect(saved(), hasLength(1));

    online = false;
    expect(await cache().load(_url), [1, 2, 3]);
    expect(downloads, 1);
  });

  test('a picture never seen is not there offline', () async {
    online = false;
    await expectLater(cache().load(_url), throwsA(isA<SocketException>()));
    expect(saved(), isEmpty);
  });

  test('a failed download is not kept', () async {
    final images = cache();
    await expectLater(
      images.load('https://cdn.jetphotos.com/full/1/gone.jpg'),
      throwsA(isA<http.ClientException>()),
    );
    expect(saved(), isEmpty);
    // And the picture can still arrive later.
    remote['https://cdn.jetphotos.com/full/1/gone.jpg'] = Uint8List(4);
    expect(
      await images.load('https://cdn.jetphotos.com/full/1/gone.jpg'),
      hasLength(4),
    );
  });

  test('a picture asked for twice at once is downloaded once', () async {
    final images = cache();
    await Future.wait([images.load(_url), images.load(_url)]);
    expect(downloads, 1);
  });

  test('the size is known and everything can be deleted', () async {
    final images = cache();
    expect(await images.size(), 0);
    await images.load(_url);
    expect(await images.size(), 3);

    await images.clear();

    expect(await images.size(), 0);
    expect(saved(), isEmpty);
    // Still usable afterwards.
    expect(await images.load(_url), [1, 2, 3]);
    expect(downloads, 2);
  });

  test('never grows past its limit: the least recently seen go', () async {
    final images = cache(maxBytes: 250);
    String url(int i) => 'https://cdn.jetphotos.com/full/1/$i.jpg';
    for (var i = 1; i <= 3; i++) {
      remote[url(i)] = Uint8List(100)..fillRange(0, 100, i);
    }
    final dir = Directory('${root.path}/aircraft_images');
    Future<void> age(int i, Duration ago) async {
      for (final file in dir.listSync().whereType<File>()) {
        if (file.readAsBytesSync().first == i) {
          file.setLastModifiedSync(DateTime.now().subtract(ago));
        }
      }
    }

    await images.load(url(1));
    await images.load(url(2));
    await images.trim();
    expect(await images.size(), 200);
    // 2 was seen long ago, 1 more recently.
    await age(1, const Duration(hours: 1));
    await age(2, const Duration(days: 30));

    await images.load(url(3));
    await images.trim();

    expect(await images.size(), 200);
    online = false;
    expect((await images.load(url(1))).first, 1);
    expect((await images.load(url(3))).first, 3);
    await expectLater(images.load(url(2)), throwsA(anything));
  });

  test('with a limit of 0 nothing is kept', () async {
    final images = cache(maxBytes: 0);
    expect(await images.load(_url), [1, 2, 3]);
    await images.trim();
    expect(saved(), isEmpty);
  });

  test('lowering the limit deletes what no longer fits', () async {
    final images = cache();
    String url(int i) => 'https://cdn.jetphotos.com/full/1/$i.jpg';
    for (var i = 1; i <= 3; i++) {
      remote[url(i)] = Uint8List(100)..fillRange(0, 100, i);
      await images.load(url(i));
    }
    await images.trim();
    expect(await images.size(), 300);

    images.maxBytes = 150;
    await images.trim();
    expect(await images.size(), lessThanOrEqualTo(150));

    images.maxBytes = 0;
    await images.trim();
    expect(saved(), isEmpty);
  });

  test('the limit chosen in the settings is remembered and applied', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = [
      sharedPreferencesProvider.overrideWithValue(
        await SharedPreferences.getInstance(),
      ),
    ];
    var container = ProviderContainer(overrides: prefs);
    final images = container.read(aircraftImageCacheProvider);
    expect(images.maxBytes, AircraftImageCache.defaultMaxBytes);
    await container
        .read(aircraftImageCacheLimitProvider.notifier)
        .setMaxBytes(50 * 1024 * 1024);
    expect(images.maxBytes, 50 * 1024 * 1024);
    container.dispose();

    container = ProviderContainer(overrides: prefs);
    addTearDown(container.dispose);
    expect(
      container.read(aircraftImageCacheProvider).maxBytes,
      50 * 1024 * 1024,
    );
  });

  testWidgets('Planespotters photos are kept offline too', (tester) async {
    const photo = AircraftPhoto.online(
      url: 'https://t.plnspttrs.net/12345/1234567_abc_280.jpg',
      link: 'https://www.planespotters.net/photo/1234567/d-eabc',
      credit: 'Anna Rossi',
    );
    expect(photo.source, 'Planespotters.net');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [aircraftImageCacheProvider.overrideWithValue(cache())],
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: AircraftPhotoView(
            photo: photo,
            placeholder: Text('placeholder'),
          ),
        ),
      ),
    );
    expect(
      tester.widget<Image>(find.byType(Image)).image,
      isA<CachedAircraftImage>(),
    );
    await tester.pumpWidget(const SizedBox());
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  });

  test('photos are credited to the site they come from', () {
    String? source(String url, [String? link]) =>
        AircraftPhoto.online(url: url, link: link).source;
    expect(source('https://cdn.jetphotos.com/full/1/a.jpg'), 'JetPhotos');
    expect(
      source('https://image.airport-data.com/aircraft/1.jpg'),
      'Airport-Data.com',
    );
    expect(source('https://hexdb.io/static/aircraft-images/X.jpg'), 'hexdb.io');
    expect(source('https://www.example.org/a.jpg'), 'example.org');
    expect(const AircraftPhoto.file('mine.jpg').source, isNull);
  });

  testWidgets('the photo of an aircraft shows offline once it was seen', (
    tester,
  ) async {
    remote[_url] = _png;
    const photo = AircraftPhoto.online(url: _url);

    Future<bool> shows(AircraftImageCache images) async {
      // Flutter's own in-memory cache must not be what makes it work.
      imageCache.clear();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [aircraftImageCacheProvider.overrideWithValue(images)],
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: AircraftPhotoView(
              photo: photo,
              placeholder: Text('placeholder'),
            ),
          ),
        ),
      );
      // Each step of loading (disk, download, decoding) needs real time.
      for (var i = 0; i < 20; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      final raw = find.byType(RawImage);
      final shown =
          raw.evaluate().isNotEmpty &&
          tester.widget<RawImage>(raw).image != null;
      await tester.pumpWidget(const SizedBox());
      return shown;
    }

    online = false;
    expect(await shows(cache()), isFalse);
    expect(find.text('placeholder'), findsNothing);

    online = true;
    expect(await shows(cache()), isTrue);
    expect(downloads, 1);

    online = false;
    expect(await shows(cache()), isTrue);
    expect(downloads, 1);
  });
}
