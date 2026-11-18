import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/database_provider.dart';
import '../services/database.dart';
import '../services/person_photo_store.dart';

/// The pilot's data kept in the logbook database (see [PilotProfile]): the
/// totals carried forward from before the app, their address and their
/// signature.
class PilotProfileRepository {
  PilotProfileRepository(this._db, this._signatures);
  final LogbookDatabase _db;
  final SignatureStore _signatures;

  SimpleSelectStatement<$PilotProfileTable, PilotProfileRow> get _row =>
      _db.select(_db.pilotProfile)
        ..where((p) => p.id.equals(PilotProfile.rowId));

  /// The profile, or null until something has been saved.
  Stream<PilotProfileRow?> watch() => _row.watchSingleOrNull();

  Future<PilotProfileRow?> get() => _row.getSingleOrNull();

  Future<void> setPreviousTotals(PreviousTotals totals) => _write(
    PilotProfileCompanion(
      previousTotals: Value(totals.isEmpty ? null : totals),
    ),
  );

  /// The pilot's postal address, for the logbook's personal details
  /// (AMC1 FCL.050(a)(1)). Empty clears it.
  Future<void> setAddress(String address) => _write(
    PilotProfileCompanion(
      address: Value(address.trim().isEmpty ? null : address.trim()),
    ),
  );

  /// Copies [source] into the signature folder as the pilot's signature,
  /// replacing (and deleting) the previous one. Null removes it.
  Future<void> setSignature(File? source) async {
    final previous = (await get())?.signatureFile;
    final name = source == null ? null : await _signatures.save(source);
    try {
      await _write(PilotProfileCompanion(signatureFile: Value(name)));
    } catch (_) {
      // Don't leave a file behind that nothing points to.
      await _signatures.delete(name);
      rethrow;
    }
    await _signatures.delete(previous);
  }

  Future<void> _write(PilotProfileCompanion changes) =>
      _db.transaction(() async {
        final updated = await (_db.update(
          _db.pilotProfile,
        )..where((p) => p.id.equals(PilotProfile.rowId))).write(changes);
        if (updated == 0) {
          await _db
              .into(_db.pilotProfile)
              .insert(changes.copyWith(id: const Value(PilotProfile.rowId)));
        }
      });
}

final pilotProfileRepositoryProvider = Provider<PilotProfileRepository>(
  (ref) => PilotProfileRepository(
    ref.watch(databaseProvider),
    ref.watch(signatureStoreProvider),
  ),
);

final pilotProfileProvider = StreamProvider<PilotProfileRow?>(
  (ref) => ref.watch(pilotProfileRepositoryProvider).watch(),
);

/// The totals logged before the app; empty when none were entered.
final previousTotalsProvider = Provider<PreviousTotals>(
  (ref) =>
      ref.watch(pilotProfileProvider).value?.previousTotals ??
      PreviousTotals.empty,
);
