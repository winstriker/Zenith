import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/crew_rules.dart';
import 'package:zenith/models/logbook_entry.dart';
import 'package:zenith/services/database.dart';

final _dep = DateTime.utc(2026, 11, 13, 8);

FlightWithStats _flight({
  String? rules = 'VFR',
  int? instrumentMinutes,
  int? nightMinutes,
  String? pilotRole = 'pic',
  LogbookOverrides? overrides,
  Duration block = const Duration(minutes: 90),
  int? simulatorId,
  bool proficiencyCheck = false,
  String? remarks = 'Nice',
}) => FlightWithStats(
  flight: Flight(
    syncId: 'test',
    id: 1,
    title: 'A → B',
    departureTime: _dep,
    arrivalTime: _dep.add(block),
    isRecording: false,
    proficiencyCheck: proficiencyCheck,
    flightRules: rules,
    instrumentMinutes: instrumentMinutes,
    nightMinutes: nightMinutes,
    pilotRole: pilotRole,
    remarks: remarks,
    dayLandings: 1,
    logbookOverrides: overrides,
    simulatorId: simulatorId,
  ),
  dataPoints: const [],
);

Duration _m(int minutes) => Duration(minutes: minutes);

void main() {
  group('IFR time', () {
    test('none for VFR, all of it for IFR', () {
      expect(
        LogbookEntry.of(_flight()).time(LogbookTimeField.ifr),
        Duration.zero,
      );
      expect(
        LogbookEntry.of(_flight(rules: 'IFR')).time(LogbookTimeField.ifr),
        _m(90),
      );
    });

    test('what was entered for rules that change on the way', () {
      for (final rules in ['Y', 'Z', 'Z2']) {
        final entry = LogbookEntry.of(
          _flight(rules: rules, instrumentMinutes: 50),
        );
        expect(entry.time(LogbookTimeField.ifr), _m(50), reason: rules);
      }
    });
  });

  test('night time is the stored one', () {
    final entry = LogbookEntry.of(_flight(nightMinutes: 20));
    expect(entry.time(LogbookTimeField.night), _m(20));
  });

  test('without overrides, everything comes from the flight', () {
    final entry = LogbookEntry.of(_flight(), selfPicName: 'ROSSI');
    expect(entry.time(LogbookTimeField.total), _m(90));
    expect(entry.time(LogbookTimeField.singlePilotSe), _m(90));
    expect(entry.time(LogbookTimeField.singlePilotMe), Duration.zero);
    expect(entry.time(LogbookTimeField.pic), _m(90));
    expect(entry.time(LogbookTimeField.dual), Duration.zero);
    expect(entry.picName, 'ROSSI');
    expect(entry.remarks, 'Nice');
    expect(entry.dayLandings, 1);
  });

  test('overrides replace single fields', () {
    final entry = LogbookEntry.of(
      _flight(
        overrides: const LogbookOverrides(
          times: {LogbookTimeField.multiPilot: Duration(minutes: 30)},
          picName: 'BIANCHI',
        ),
      ),
    );
    expect(entry.time(LogbookTimeField.multiPilot), _m(30));
    expect(entry.isOverridden(LogbookTimeField.multiPilot), isTrue);
    expect(entry.isOverridden(LogbookTimeField.total), isFalse);
    expect(entry.picName, 'BIANCHI');
  });

  test('an overridden total carries to the columns that share it', () {
    final entry = LogbookEntry.of(
      _flight(
        rules: 'IFR',
        nightMinutes: 80,
        overrides: const LogbookOverrides(
          times: {
            LogbookTimeField.total: Duration(minutes: 60),
            LogbookTimeField.dual: Duration(minutes: 10),
          },
        ),
      ),
    );
    expect(entry.computed[LogbookTimeField.total], _m(90));
    expect(entry.time(LogbookTimeField.total), _m(60));
    expect(entry.time(LogbookTimeField.singlePilotSe), _m(60));
    expect(entry.time(LogbookTimeField.pic), _m(60));
    expect(entry.time(LogbookTimeField.ifr), _m(60));
    // Night can't be longer than the flight.
    expect(entry.time(LogbookTimeField.night), _m(60));
    expect(entry.time(LogbookTimeField.dual), _m(10));
  });

  group('LogbookOverrides', () {
    const overrides = LogbookOverrides(
      times: {
        LogbookTimeField.total: Duration(minutes: 75),
        LogbookTimeField.night: Duration.zero,
      },
      picName: 'BIANCHI',
    );

    test('survive the database column', () {
      final stored = LogbookOverrides.converter.toSql(overrides);
      expect(LogbookOverrides.converter.fromSql(stored), overrides);
    });

    test('unreadable or unknown values are dropped', () {
      expect(
        LogbookOverrides.converter.fromSql('not json'),
        LogbookOverrides.empty,
      );
      expect(
        LogbookOverrides.converter.fromSql(
          '{"times": {"total": 30, "gone": 5}}',
        ),
        const LogbookOverrides(
          times: {LogbookTimeField.total: Duration(minutes: 30)},
        ),
      );
    });

    test('set and clear one field at a time', () {
      final cleared = overrides
          .withTime(LogbookTimeField.total, null)
          .withTime(LogbookTimeField.night, null)
          .withPicName(null);
      expect(cleared.isEmpty, isTrue);
      expect(overrides.count, 3);
    });
  });

  group('multi-pilot time', () {
    const sic = CrewMember(
      person: Person(syncId: 'test', id: 2, name: 'Luca', surname: 'Bianchi'),
      role: CrewRole.sic,
    );

    test('a second in command makes it multi-pilot, not single-pilot', () {
      final entry = LogbookEntry.of(_flight(), crew: const [sic]);
      expect(entry.time(LogbookTimeField.multiPilot), _m(90));
      expect(entry.time(LogbookTimeField.singlePilotSe), Duration.zero);
      expect(entry.time(LogbookTimeField.singlePilotMe), Duration.zero);
      expect(entry.time(LogbookTimeField.pic), _m(90));
    });

    test('so does being the second in command', () {
      const pic = CrewMember(
        person: Person(syncId: 'test', id: 3, name: 'Anna', surname: 'Verdi'),
        role: CrewRole.pic,
      );
      final entry = LogbookEntry.of(
        _flight(pilotRole: 'sic'),
        crew: const [pic],
      );
      expect(entry.time(LogbookTimeField.multiPilot), _m(90));
      expect(entry.time(LogbookTimeField.singlePilotSe), Duration.zero);
      expect(entry.time(LogbookTimeField.coPilot), _m(90));
    });

    test('other crew leave it single-pilot', () {
      const passenger = CrewMember(
        person: Person(syncId: 'test', id: 4, name: 'Marco', surname: 'Neri'),
        role: CrewRole.oth,
      );
      final entry = LogbookEntry.of(_flight(), crew: const [passenger]);
      expect(entry.time(LogbookTimeField.multiPilot), Duration.zero);
      expect(entry.time(LogbookTimeField.singlePilotSe), _m(90));
    });
  });

  test('instructor time is PIC time as well', () {
    final entry = LogbookEntry.of(_flight(pilotRole: 'ins'));
    expect(entry.time(LogbookTimeField.instructor), _m(90));
    expect(entry.time(LogbookTimeField.pic), _m(90));
    expect(entry.time(LogbookTimeField.dual), Duration.zero);
  });

  group('simulator sessions (AMC1 FCL.050(i)(9))', () {
    test('fill in the FSTD column only', () {
      final entry = LogbookEntry.of(
        _flight(simulatorId: 7, rules: 'IFR', nightMinutes: 30),
      );
      expect(entry.time(LogbookTimeField.fstd), _m(90));
      for (final field in LogbookTimeField.values) {
        if (field == LogbookTimeField.fstd) continue;
        expect(entry.time(field), Duration.zero, reason: field.name);
      }
      expect(entry.dayLandings, 0);
      expect(entry.picName, '');
      expect(entry.remarks, 'Nice');
    });

    test('the session time can be overridden', () {
      final entry = LogbookEntry.of(
        _flight(
          simulatorId: 7,
          overrides: LogbookOverrides(times: {LogbookTimeField.fstd: _m(240)}),
        ),
      );
      expect(entry.time(LogbookTimeField.fstd), _m(240));
      expect(entry.isOverridden(LogbookTimeField.fstd), isTrue);
    });

    test('flights leave the FSTD column empty', () {
      expect(
        LogbookEntry.of(_flight()).time(LogbookTimeField.fstd),
        Duration.zero,
      );
    });
  });

  group('pilot function and remarks (AMC1 FCL.050)', () {
    const examiner = CrewMember(
      person: Person(syncId: 'test', id: 5, name: 'Marco', surname: 'Rossi'),
      role: CrewRole.exm,
    );
    const instructor = CrewMember(
      person: Person(syncId: 'test', id: 6, name: 'Giulia', surname: 'Bassi'),
      role: CrewRole.ins,
    );
    const pic = CrewMember(
      person: Person(syncId: 'test', id: 7, name: 'Anna', surname: 'Verdi'),
      role: CrewRole.pic,
    );

    test('a check passed is PIC time, the examiner named', () {
      final entry = LogbookEntry.of(
        _flight(pilotRole: 'dual', proficiencyCheck: true, remarks: null),
        crew: const [examiner],
      );
      expect(entry.time(LogbookTimeField.pic), _m(90));
      expect(entry.time(LogbookTimeField.dual), Duration.zero);
      expect(entry.picName, 'Rossi');
      expect(entry.remarks, 'Proficiency check, examiner Marco Rossi');
    });

    test('the remarks saying which check keep their words', () {
      final entry = LogbookEntry.of(
        _flight(
          pilotRole: 'dual',
          proficiencyCheck: true,
          remarks: 'SEP skill test',
        ),
        crew: const [examiner],
      );
      expect(entry.remarks, 'Examiner Marco Rossi. SEP skill test');
    });

    test('without the check, a flight with an examiner stays dual', () {
      final entry = LogbookEntry.of(
        _flight(pilotRole: 'dual'),
        crew: const [examiner],
      );
      expect(entry.time(LogbookTimeField.dual), _m(90));
      expect(entry.time(LogbookTimeField.pic), Duration.zero);
    });

    test('dual flights name their instructor', () {
      final entry = LogbookEntry.of(
        _flight(pilotRole: 'dual'),
        crew: const [instructor],
      );
      expect(entry.remarks, 'Instructor Giulia Bassi. Nice');
    });

    test('PICUS is PIC time certified by the PIC', () {
      final entry = LogbookEntry.of(
        _flight(pilotRole: 'picus'),
        crew: const [pic],
      );
      expect(entry.time(LogbookTimeField.pic), _m(90));
      expect(entry.picName, 'Verdi');
      expect(entry.remarks, 'PICUS, PIC Anna Verdi. Nice');
    });

    test('SPIC is PIC time certified by the instructor', () {
      final entry = LogbookEntry.of(
        _flight(pilotRole: 'spic', remarks: null),
        crew: const [instructor],
      );
      expect(entry.time(LogbookTimeField.pic), _m(90));
      expect(entry.picName, 'Bassi');
      expect(entry.remarks, 'SPIC, instructor Giulia Bassi');
    });

    test('a cruise relief co-pilot logs co-pilot, multi-pilot time', () {
      final entry = LogbookEntry.of(
        _flight(pilotRole: 'crcp', remarks: null),
        crew: const [pic],
      );
      expect(entry.time(LogbookTimeField.coPilot), _m(90));
      expect(entry.time(LogbookTimeField.multiPilot), _m(90));
      expect(entry.time(LogbookTimeField.pic), Duration.zero);
      expect(entry.remarks, 'CRCP');
    });

    test('a check in an FSTD is said in the remarks', () {
      final entry = LogbookEntry.of(
        _flight(simulatorId: 3, proficiencyCheck: true, remarks: null),
        crew: const [examiner],
      );
      expect(entry.remarks, 'Proficiency check, examiner Marco Rossi');
    });

    test('PICUS, SPIC and CRCP need who certifies them in the crew', () {
      expect(crewValidationError(CrewRole.picus, const []), isNotNull);
      expect(crewValidationError(CrewRole.picus, const [pic]), isNull);
      expect(crewValidationError(CrewRole.spic, const []), isNotNull);
      expect(crewValidationError(CrewRole.spic, const [instructor]), isNull);
      expect(crewValidationError(CrewRole.crcp, const []), isNotNull);
      expect(crewValidationError(CrewRole.crcp, const [pic]), isNull);
    });
  });
}
