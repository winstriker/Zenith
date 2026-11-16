import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'registry_database.g.dart';

/// One aircraft of the downloaded registry: which 24-bit ICAO address
/// (the "hex code" ADS-B data is filed under) a registration has.
///
/// Keyed on the registration, which is what gets looked up, so the table
/// is its own index. A registration can have several addresses: it may have
/// been given to another airframe.
@DataClassName('RegisteredAircraft')
class RegisteredAircrafts extends Table {
  /// Upper case letters and digits only: "D-EABC" is stored as "DEABC".
  TextColumn get registration => text()();

  /// Six hex digits, lower case.
  TextColumn get hex => text()();

  @override
  Set<Column<Object>> get primaryKey => {registration, hex};

  @override
  bool get withoutRowId => true;
}

/// What is known about the downloaded registry itself (see
/// `AircraftRegistryService`). Kept next to the rows so both always change
/// together.
@DataClassName('RegistryMetaEntry')
class RegistryMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// The aircraft registry (tar1090-db), in a file of its own.
///
/// It is not in the logbook database because that one is copied whole into
/// every backup, and some 600,000 rows that can be downloaded again at any
/// time have no place there. Nothing in the logbook points into this
/// database, so it can be emptied or deleted freely.
@DriftDatabase(tables: [RegisteredAircrafts, RegistryMeta])
class RegistryDatabase extends _$RegistryDatabase {
  factory RegistryDatabase([QueryExecutor? executor]) {
    if (executor != null) return RegistryDatabase._(executor);
    return _instance ??= RegistryDatabase._(_openConnection());
  }

  RegistryDatabase._(super.executor);
  static RegistryDatabase? _instance;

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'aircraft_registry',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }

  /// "d-eabc" → "DEABC": how registrations are stored and compared.
  static String normalizeRegistration(String registration) =>
      registration.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');

  /// The ICAO addresses filed under [registration], or none.
  Future<List<String>> hexesFor(String registration) async {
    final key = normalizeRegistration(registration);
    if (key.isEmpty) return const [];
    final rows = await (select(
      registeredAircrafts,
    )..where((a) => a.registration.equals(key))).get();
    return [for (final row in rows) row.hex];
  }

  /// The registrations filed under the ICAO address [hex], as
  /// [normalizeRegistration] spells them, or none.
  ///
  /// The table is keyed on the registration, so this reads all of it: fine
  /// for the odd lookup (an import), not for a list.
  Future<List<String>> registrationsFor(String hex) async {
    final key = hex.trim().toLowerCase();
    if (key.isEmpty) return const [];
    final rows = await (select(
      registeredAircrafts,
    )..where((a) => a.hex.equals(key))).get();
    return [for (final row in rows) row.registration];
  }

  Future<String?> meta(String key) async {
    final row = await (select(
      registryMeta,
    )..where((m) => m.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setMeta(String key, String value) =>
      into(registryMeta).insertOnConflictUpdate(
        RegistryMetaCompanion.insert(key: key, value: value),
      );
}
