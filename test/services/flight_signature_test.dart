import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/services/database.dart';
import 'package:zenith/services/flight_service.dart';
import 'package:zenith/services/person_photo_store.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late LogbookDatabase db;
  late Directory root;
  late SignatureStore store;
  late FlightService service;

  setUp(() async {
    db = LogbookDatabase(NativeDatabase.memory());
    root = await Directory.systemTemp.createTemp('zenith_sig');
    store = SignatureStore(() async => root);
    service = FlightService(db, store);
  });

  tearDown(() async {
    await db.close();
    await root.delete(recursive: true);
  });

  Future<String> stored(List<int> bytes) async {
    final source = File('${root.path}/source.png')..writeAsBytesSync(bytes);
    return store.save(source);
  }

  Future<File> fileOf(String name) async =>
      File('${(await store.directory).path}/$name');

  Future<int> addFlight({String? signature}) => service.addFlight(
    departureId: null,
    arrivalId: null,
    title: 'A → B',
    departureTime: DateTime.utc(2026, 5, 1, 8),
    signatureFile: signature,
  );

  Future<void> update(int id, Value<String?> signature) => service.updateFlight(
    flightId: id,
    departureId: null,
    arrivalId: null,
    title: 'A → B',
    departureTime: DateTime.utc(2026, 5, 1, 8),
    signatureFile: signature,
  );

  Future<String?> signatureOf(int id) async => (await (db.select(
    db.flights,
  )..where((f) => f.id.equals(id))).getSingle()).signatureFile;

  test('editing without touching the signature keeps it', () async {
    final name = await stored([1]);
    final id = await addFlight(signature: name);
    await update(id, const Value.absent());
    expect(await signatureOf(id), name);
    expect((await fileOf(name)).existsSync(), isTrue);
  });

  test('a replaced signature has its file deleted', () async {
    final old = await stored([1]);
    final id = await addFlight(signature: old);
    final replacement = await stored([2]);
    await update(id, Value(replacement));
    expect(await signatureOf(id), replacement);
    expect((await fileOf(old)).existsSync(), isFalse);
    expect((await fileOf(replacement)).readAsBytesSync(), [2]);
  });

  test('a removed signature has its file deleted', () async {
    final name = await stored([1]);
    final id = await addFlight(signature: name);
    await update(id, const Value(null));
    expect(await signatureOf(id), isNull);
    expect((await fileOf(name)).existsSync(), isFalse);
  });

  test('deleting a flight deletes its signature', () async {
    final name = await stored([1]);
    final id = await addFlight(signature: name);
    await service.deleteSession(id);
    expect((await fileOf(name)).existsSync(), isFalse);
  });
}
