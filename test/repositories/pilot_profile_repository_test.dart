import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/repositories/pilot_profile_repository.dart';
import 'package:zenith/services/database.dart';
import 'package:zenith/services/person_photo_store.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late LogbookDatabase db;
  late Directory root;
  late SignatureStore store;
  late PilotProfileRepository repository;

  setUp(() async {
    db = LogbookDatabase(NativeDatabase.memory());
    root = await Directory.systemTemp.createTemp('zenith_profile');
    store = SignatureStore(() async => root);
    repository = PilotProfileRepository(db, store);
  });

  tearDown(() async {
    await db.close();
    await root.delete(recursive: true);
  });

  File source(List<int> bytes) =>
      File('${root.path}/source.png')..writeAsBytesSync(bytes);

  Future<File> fileOf(String name) async =>
      File('${(await store.directory).path}/$name');

  final totals = const PreviousTotals()
      .withTime(LogbookTimeField.total, const Duration(hours: 1200))
      .withLandings(day: 300);

  test('nothing saved yet', () async {
    expect(await repository.get(), isNull);
  });

  test('totals and signature are kept side by side', () async {
    await repository.setPreviousTotals(totals);
    await repository.setSignature(source([1]));
    final profile = (await repository.get())!;
    expect(profile.previousTotals, totals);
    expect((await fileOf(profile.signatureFile!)).readAsBytesSync(), [1]);

    // Changing one leaves the other.
    await repository.setPreviousTotals(PreviousTotals.empty);
    final cleared = (await repository.get())!;
    expect(cleared.previousTotals, isNull);
    expect(cleared.signatureFile, profile.signatureFile);
  });

  test('a replaced or removed signature has its file deleted', () async {
    await repository.setSignature(source([1]));
    final first = (await repository.get())!.signatureFile!;
    await repository.setSignature(source([2]));
    final second = (await repository.get())!.signatureFile!;
    expect(second, isNot(first));
    expect((await fileOf(first)).existsSync(), isFalse);
    expect((await fileOf(second)).readAsBytesSync(), [2]);

    await repository.setSignature(null);
    expect((await repository.get())!.signatureFile, isNull);
    expect((await fileOf(second)).existsSync(), isFalse);
  });

  test('watch follows the changes', () async {
    final seen = repository.watch().map((p) => p?.previousTotals);
    expect(seen, emitsInOrder([isNull, totals]));
    await pumpEventQueue();
    await repository.setPreviousTotals(totals);
  });
}
