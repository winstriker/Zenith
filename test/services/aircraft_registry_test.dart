import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/sync_progress.dart';
import 'package:zenith/services/aircraft_registry_service.dart';
import 'package:zenith/services/registry_database.dart';

/// Lines of the real tar1090-db `aircraft.csv`:
/// hex;registration;type;flags;description;year;owner;
const _csv =
    '000001;;;10;;;Miscode - VARIOUS;\n'
    '0000BA;;BALL;00;;;Miscode - VARIOUS;\n'
    '004002;Z-WPA;B732;00;BOEING 737-200;;;\n'
    '4010EE;G-EZBZ;A319;00;AIRBUS A-319;;;\n'
    '4CA242;EI-DCL;B738;00;BOEING 737-800;;;\n'
    // Listed twice, and a registration two airframes have had.
    '4CA242;EI-DCL;B738;00;BOEING 737-800;;;\n'
    '3D04C4;D-EABC;M20P;00;MOONEY M-20;;;\n'
    '3D99ZZ;D-EBAD;C172;00;not a hex code;;;\n'
    '3D1111;D-EABC;C172;00;CESSNA 172;;;\n'
    'A12345;N123AB;C172;00;CESSNA 172 Skyhawk;1978;Somebody Ünïcode;\r\n'
    'no semicolons at all\n'
    '\n'
    'ABCDEF;N999ZZ';

Uint8List _gz(String csv) => Uint8List.fromList(gzip.encode(utf8.encode(csv)));

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late RegistryDatabase db;
  setUp(() => db = RegistryDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('the CSV gives registration and address of the registered aircraft', () {
    final rows = AircraftRegistryService.parseRegistry(
      Uint8List.fromList(utf8.encode(_csv)),
    ).toList();

    expect(
      [for (final (registration, hex, _) in rows) '$registration=$hex'],
      [
        'ZWPA=004002',
        'GEZBZ=4010ee',
        'EIDCL=4ca242',
        'EIDCL=4ca242',
        'DEABC=3d04c4',
        'DEABC=3d1111',
        'N123AB=a12345',
        'N999ZZ=abcdef',
      ],
    );
    // How far into the file each line ends, for the progress bar.
    expect(rows.last.$3, utf8.encode(_csv).length);
    expect(rows.map((r) => r.$3), [...rows.map((r) => r.$3)]..sort());
  });

  test('a download replaces the registry, whatever way it is spelt', () async {
    final fractions = <double>[];
    final count = await AircraftRegistryService.syncRegistry(
      db,
      _gz(_csv),
      etag: '"v1"',
      onProgress: fractions.add,
    );

    expect(count, 7);
    expect(await db.hexesFor('g-ezbz'), ['4010ee']);
    expect(await db.hexesFor(' G EZBZ '), ['4010ee']);
    expect(await db.hexesFor('D-EABC'), unorderedEquals(['3d04c4', '3d1111']));
    expect(await db.hexesFor('I-NONE'), isEmpty);
    expect(await db.hexesFor('-'), isEmpty);
    expect(await db.meta('etag'), '"v1"');
    expect(fractions.last, 1);

    // The next list has lost an aircraft.
    await AircraftRegistryService.syncRegistry(
      db,
      _gz('4010EE;G-EZBZ;A319;00;;;;\n'),
    );
    expect(await db.hexesFor('EI-DCL'), isEmpty);
    expect(await db.hexesFor('G-EZBZ'), ['4010ee']);
    expect(await db.meta('etag'), isNull);
  });

  test('a file gzipped twice on the way is read all the same', () async {
    final twice = Uint8List.fromList(gzip.encode(_gz(_csv)));
    expect(await AircraftRegistryService.syncRegistry(db, twice), 7);
  });

  test('an empty or unreadable file never replaces the registry', () async {
    await AircraftRegistryService.syncRegistry(db, _gz(_csv), etag: '"v1"');

    await expectLater(
      AircraftRegistryService.syncRegistry(db, _gz('<html>Not found</html>')),
      throwsStateError,
    );
    expect(await db.hexesFor('G-EZBZ'), ['4010ee']);
    expect(await db.meta('etag'), '"v1"');
  });

  group('loadData', () {
    // A file on disk: the writing happens in another isolate, which can't
    // share a database that only lives in this one's memory.
    late Directory dir;
    late RegistryDatabase fileDb;
    setUp(() {
      dir = Directory.systemTemp.createTempSync('zenith_registry');
      fileDb = RegistryDatabase(NativeDatabase(File('${dir.path}/r.sqlite')));
    });
    tearDown(() async {
      await fileDb.close();
      dir.deleteSync(recursive: true);
    });

    test('downloads, then only asks whether the list changed', () async {
      final asked = <String?>[];
      var answer =
          RegistryDownload(_gz(_csv), etag: '"v1"') as RegistryDownload?;
      final service = AircraftRegistryService(
        fileDb,
        downloader: (etag, onProgress) async {
          asked.add(etag);
          onProgress(50, 100);
          return answer;
        },
      );
      addTearDown(service.dispose);
      final phases = <SyncPhase>[];
      service.progress.addListener(
        () => phases.add(service.progress.value.phase),
      );

      expect((await service.status()).isDownloaded, isFalse);
      await service.loadData();

      expect(service.progress.value.phase, SyncPhase.done);
      expect(
        phases,
        containsAllInOrder([
          SyncPhase.downloading,
          SyncPhase.parsing,
          SyncPhase.done,
        ]),
      );
      final status = await service.status();
      expect(status.aircraft, 7);
      expect(status.updatedAt, isNotNull);
      expect(await fileDb.hexesFor('EI-DCL'), ['4ca242']);
      // Nothing on the device yet: the file is wanted whatever its tag.
      expect(asked, [null]);

      // Already checked today.
      await service.loadData();
      expect(asked, hasLength(1));

      // Asked for: the server is told which version is here, and says it
      // still has the same (304).
      answer = null;
      await service.loadData(force: true);
      expect(asked, [null, '"v1"']);
      expect(service.progress.value.phase, SyncPhase.done);
      expect((await service.status()).aircraft, 7);

      // A new list came out.
      answer = RegistryDownload(
        _gz('4010EE;G-EZBZ;A319;00;;;;\n'),
        etag: '"v2"',
      );
      await service.loadData(force: true);
      expect((await service.status()).aircraft, 1);
      expect(await fileDb.meta('etag'), '"v2"');
    });

    test('a failed download keeps what was there and says so', () async {
      var fail = false;
      final service = AircraftRegistryService(
        fileDb,
        downloader: (etag, onProgress) async {
          if (fail) throw const SocketException('offline');
          return RegistryDownload(_gz(_csv));
        },
      );
      addTearDown(service.dispose);
      await service.loadData();

      fail = true;
      await service.loadData(force: true);

      expect(service.progress.value.phase, SyncPhase.error);
      expect(service.progress.value.message, contains('Could not download'));
      expect((await service.status()).aircraft, 7);
    });

    test('clear deletes the list', () async {
      final service = AircraftRegistryService(
        fileDb,
        downloader: (etag, onProgress) async =>
            RegistryDownload(_gz(_csv), etag: '"v1"'),
      );
      addTearDown(service.dispose);
      await service.loadData();

      await service.clear();

      expect((await service.status()).isDownloaded, isFalse);
      expect(await fileDb.hexesFor('EI-DCL'), isEmpty);
      expect(await fileDb.meta('etag'), isNull);
      expect(service.progress.value.phase, SyncPhase.idle);
    });
  });
}
