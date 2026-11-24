import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/currency.dart';
import 'package:zenith/providers/currency_settings_provider.dart';
import 'package:zenith/services/currency_reminders.dart';
import 'package:zenith/services/database.dart';

void main() {
  final today = DateTime(2026, 11, 16);

  Licence licence({
    int id = 1,
    LicenceKind kind = LicenceKind.ppl,
    AircraftCategory category = AircraftCategory.aeroplane,
    DateTime? check,
    DateTime? issued,
  }) => Licence(
    id: id,
    kind: kind,
    category: category,
    proficiencyCheckDate: check,
    issueDate: issued,
  );

  var nextRatingId = 1;
  LicenceRating rating(
    RatingKind kind, {
    AircraftClass? cls,
    String? name,
    DateTime? expiry,
    DateTime? lastCheck,
    int licenceId = 1,
    bool lightSingleEngine = false,
  }) => LicenceRating(
    id: nextRatingId++,
    licence: licenceId,
    kind: kind,
    aircraftClass: cls,
    name: name,
    expiryDate: expiry,
    lastCheckDate: lastCheck,
    lightSingleEngine: lightSingleEngine,
  );

  CurrencyFlight flight(
    DateTime date, {
    AircraftClass cls = AircraftClass.sepLand,
    String? type,
    int landings = 1,
    int nightLandings = 0,
    Duration total = const Duration(hours: 1),
    Duration? pic,
    Duration dual = Duration.zero,
    Duration instructor = Duration.zero,
    bool check = false,
    SimulatorKind? simulator,
    Duration ifr = Duration.zero,
    bool approach = false,
    Duration sessionInstruction = Duration.zero,
    int mountain = 0,
    bool cruiseRelief = false,
    EngineType? engine,
  }) => CurrencyFlight(
    date: date,
    total: total,
    pic: pic ?? (dual > Duration.zero ? Duration.zero : total),
    dual: dual,
    instructor: instructor,
    dayLandings: landings,
    nightLandings: nightLandings,
    aircraftClass: cls,
    typeRating: type,
    proficiencyCheck: check,
    simulator: simulator,
    ifr: ifr,
    picIfr: ifr,
    instrumentApproach: approach,
    sessionInstruction: sessionInstruction,
    mountainLandings: mountain,
    cruiseRelief: cruiseRelief,
    engineType: engine,
  );

  List<CurrencyItem> compute(
    List<LicenceWithRatings> licences,
    List<CurrencyFlight> flights, {
    List<MedicalCertificate> medicals = const [],
  }) => CurrencyCalculator(
    licences: licences,
    medicals: medicals,
    flights: flights,
    today: today,
  ).compute();

  CurrencyItem item(List<CurrencyItem> items, String key) =>
      items.singleWhere((i) => i.key == key);

  group('dates', () {
    test('addMonths keeps the day or clamps to the month end', () {
      expect(addMonths(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
      expect(addMonths(DateTime(2024, 2, 29), 12), DateTime(2025, 2, 28));
      expect(addMonths(DateTime(2026, 3, 15), -3), DateTime(2025, 12, 15));
      expect(addMonths(DateTime(2026, 11, 16), 24), DateTime(2028, 11, 16));
    });

    test('daysBetween ignores DST', () {
      // Clocks change in Europe on 29 March 2026.
      expect(daysBetween(DateTime(2026, 3, 28), DateTime(2026, 3, 30)), 2);
    });
  });

  group('passengers (FCL.060(b)(1))', () {
    final sep = LicenceWithRatings(licence(), [
      rating(RatingKind.classRating, cls: AircraftClass.sepLand),
    ]);

    test('current until the third most recent landing is 90 days old', () {
      final items = compute(
        [sep],
        [
          flight(DateTime(2026, 11, 10), landings: 2),
          flight(DateTime(2026, 10)),
          flight(DateTime(2026, 9), landings: 5),
        ],
      );
      final pax = item(items, 'passengers:class:sepLand');
      expect(pax.validUntil, DateTime(2026, 12, 30)); // 1 Oct + 90 days
      // 1 Sep is still within the 90 days.
      expect(pax.requirements.single.done, 8);
      expect(pax.daysLeft(today), 44);
      expect(pax.statusOn(today, warnDays: 30), CurrencyStatus.valid);
      expect(pax.statusOn(today, warnDays: 60), CurrencyStatus.expiring);
    });

    test('not current with fewer than 3 landings in 90 days', () {
      final items = compute(
        [sep],
        [
          flight(DateTime(2026, 11, 10), landings: 2),
          flight(DateTime(2026, 8), landings: 5), // too old
        ],
      );
      final pax = item(items, 'passengers:class:sepLand');
      expect(pax.validUntil, isNull);
      expect(pax.requirements.single.done, 2);
      expect(pax.statusOn(today, warnDays: 30), CurrencyStatus.expired);
    });

    test('only flights in the same class or type count', () {
      final items = compute(
        [
          LicenceWithRatings(licence(), [
            rating(RatingKind.typeRating, name: 'b737 300-900'),
          ]),
        ],
        [
          flight(DateTime(2026, 11), landings: 3),
          flight(
            DateTime(2026, 11, 2),
            cls: AircraftClass.type,
            type: 'B737  300-900',
            landings: 3,
          ),
          flight(
            DateTime(2026, 11, 3),
            cls: AircraftClass.type,
            type: 'A320',
            landings: 3,
          ),
        ],
      );
      final pax = item(items, 'passengers:type:B737 300-900');
      expect(pax.requirements.single.done, 3);
      expect(pax.validUntil, DateTime(2027, 1, 31));
    });

    test('future flights are ignored', () {
      final items = compute([sep], [flight(DateTime(2026, 12), landings: 3)]);
      expect(item(items, 'passengers:class:sepLand').validUntil, isNull);
    });
  });

  test('no passenger currency on an expired rating', () {
    final expired = LicenceWithRatings(licence(), [
      rating(
        RatingKind.classRating,
        cls: AircraftClass.tmg,
        expiry: DateTime(2026, 9, 2),
      ),
      rating(RatingKind.night),
    ]);
    final items = compute(
      [expired],
      [flight(DateTime(2026, 11), cls: AircraftClass.tmg, landings: 3)],
    );
    expect(items.where((i) => i.kind == CurrencyKind.recency), isEmpty);
    // Renewal, not revalidation.
    final validity = items.singleWhere((i) => i.key.startsWith('rating:'));
    expect(validity.requirements, isEmpty);
    expect(validity.reference, 'FCL.740(b)');

    // Still tracked when the same class is valid on another licence.
    final valid = LicenceWithRatings(licence(id: 2), [
      rating(
        RatingKind.classRating,
        cls: AircraftClass.tmg,
        expiry: DateTime(2028, 1, 31),
        licenceId: 2,
      ),
    ]);
    final both = compute(
      [expired, valid],
      [flight(DateTime(2026, 11), cls: AircraftClass.tmg, landings: 3)],
    );
    expect(item(both, 'passengers:class:tmg').licenceId, 2);
  });

  group('night passengers (FCL.060(b)(2))', () {
    test('only with night privileges', () {
      final ppl = LicenceWithRatings(licence(), [
        rating(RatingKind.classRating, cls: AircraftClass.sepLand),
      ]);
      expect(
        compute([ppl], const []).where((i) => i.key.startsWith('night:')),
        isEmpty,
      );
      final withNight = LicenceWithRatings(licence(), [
        rating(RatingKind.classRating, cls: AircraftClass.sepLand),
        rating(RatingKind.night),
      ]);
      final items = compute(
        [withNight],
        [flight(DateTime(2026, 10, 20), landings: 0, nightLandings: 1)],
      );
      expect(
        item(items, 'night:class:sepLand').validUntil,
        DateTime(2027, 1, 18),
      );
    });

    test('a valid IR covers it', () {
      final items = compute([
        LicenceWithRatings(licence(), [
          rating(RatingKind.classRating, cls: AircraftClass.mepLand),
          rating(RatingKind.instrument, expiry: DateTime(2027, 5, 31)),
        ]),
      ], const []);
      final night = item(items, 'night:class:mepLand');
      expect(night.validUntil, DateTime(2027, 5, 31));
      expect(night.notes.single, contains('instrument rating'));
    });
  });

  group('SEP revalidation by experience (FCL.740.A(b)(1)(ii))', () {
    test('counts the 12 months before expiry', () {
      final sep = rating(
        RatingKind.classRating,
        cls: AircraftClass.sepLand,
        expiry: DateTime(2027, 3, 31),
      );
      final items = compute(
        [
          LicenceWithRatings(licence(), [sep]),
        ],
        [
          for (var i = 0; i < 10; i++)
            flight(DateTime(2026, 4, 1 + i), landings: 2),
          flight(
            DateTime(2026, 6),
            dual: const Duration(hours: 1, minutes: 10),
            total: const Duration(hours: 1, minutes: 10),
          ),
          flight(DateTime(2026, 3, 30), landings: 10), // before the window
        ],
      );
      final validity = item(items, 'rating:${sep.id}');
      expect(validity.validUntil, DateTime(2027, 3, 31));
      final byLabel = {for (final r in validity.requirements) r.label: r};
      expect(byLabel['Flight time']!.done, 11 * 60 + 10);
      expect(byLabel['Flight time']!.met, isFalse);
      expect(byLabel['PIC time']!.met, isTrue);
      expect(byLabel['Take-offs and landings']!.done, 21);
      expect(byLabel['Refresher training with an instructor']!.met, isTrue);
      expect(validity.requirementsMet, isFalse);
    });

    test('or by proficiency check (FCL.740.A(b)(1)(i))', () {
      final sep = rating(
        RatingKind.classRating,
        cls: AircraftClass.sepLand,
        expiry: DateTime(2027, 3, 31),
      );
      final items = compute(
        [
          LicenceWithRatings(licence(), [sep]),
        ],
        [flight(DateTime(2026, 4, 10), check: true)],
      );
      final validity = item(items, 'rating:${sep.id}');
      expect(validity.reference, 'FCL.740.A(b)(1)(ii)');
      final check = validity.sections.single;
      expect(check.title, 'Revalidation by proficiency check');
      expect(check.reference, 'FCL.740.A(b)(1)(i)');
      // In the validity period, before the 3 months' window: it counts,
      // the new validity starting from it.
      expect(check.met, isTrue);
      expect(check.notes, contains(contains('31 Dec 2026')));
      expect(validity.requirementsMet, isFalse);
    });

    test('SEP (L) and TMG count for each other', () {
      final sep = rating(
        RatingKind.classRating,
        cls: AircraftClass.sepLand,
        expiry: DateTime(2027, 3, 31),
      );
      final tmg = rating(
        RatingKind.classRating,
        cls: AircraftClass.tmg,
        expiry: DateTime(2027, 3, 31),
      );
      final items = compute(
        [
          LicenceWithRatings(licence(), [sep, tmg]),
        ],
        [
          flight(DateTime(2026, 5), total: const Duration(hours: 7)),
          flight(
            DateTime(2026, 5, 2),
            cls: AircraftClass.tmg,
            total: const Duration(hours: 5),
          ),
        ],
      );
      for (final r in [sep, tmg]) {
        final time = item(items, 'rating:${r.id}').requirements.first;
        expect(time.done, 12 * 60);
        expect(time.met, isTrue);
      }
    });
  });

  test('multi-engine: 10 sectors or a check during the validity period', () {
    final mep = rating(
      RatingKind.classRating,
      cls: AircraftClass.mepLand,
      expiry: DateTime(2027, 2, 28),
      lastCheck: DateTime(2026, 4, 10),
    );
    final items = compute(
      [
        LicenceWithRatings(licence(), [mep]),
      ],
      [flight(DateTime(2026, 6), cls: AircraftClass.mepLand)],
    );
    final validity = item(items, 'rating:${mep.id}');
    expect(validity.anyRequirement, isTrue);
    expect(validity.requirements.first.done, 1);
    expect(validity.requirementsMet, isTrue);
  });

  group('proficiency check flights', () {
    test('count as the last check of the rating covering the aircraft', () {
      final mep = rating(
        RatingKind.classRating,
        cls: AircraftClass.mepLand,
        expiry: DateTime(2027, 2, 28),
        lastCheck: DateTime(2025, 1, 10),
      );
      final sep = rating(
        RatingKind.classRating,
        cls: AircraftClass.sepLand,
        expiry: DateTime(2027, 2, 28),
      );
      final items = compute(
        [
          LicenceWithRatings(licence(), [mep, sep]),
        ],
        [flight(DateTime(2026, 5, 3), cls: AircraftClass.mepLand, check: true)],
      );
      final validity = item(items, 'rating:${mep.id}');
      expect(validity.lastCheck, DateTime(2026, 5, 3));
      // The route sector with an examiner.
      expect(validity.requirements[1].met, isTrue);
      final check = validity.sections.single;
      expect(check.reference, 'FCL.740.A(a)(1)');
      expect(check.met, isTrue);
      expect(check.notes.last, contains('3 May 2026'));
      // Another class: not its check.
      expect(item(items, 'rating:${sep.id}').lastCheck, isNull);
    });

    test('an older flight doesn\'t replace a later check date', () {
      final mep = rating(
        RatingKind.classRating,
        cls: AircraftClass.mepLand,
        expiry: DateTime(2027, 2, 28),
        lastCheck: DateTime(2026, 6, 2),
      );
      final items = compute(
        [
          LicenceWithRatings(licence(), [mep]),
        ],
        [flight(DateTime(2026, 5, 3), cls: AircraftClass.mepLand, check: true)],
      );
      expect(item(items, 'rating:${mep.id}').lastCheck, DateTime(2026, 6, 2));
    });

    test('keep a LAPL(A) recent for 2 years', () {
      final items = compute(
        [LicenceWithRatings(licence(kind: LicenceKind.lapl), const [])],
        [flight(DateTime(2026, 6, 15), check: true)],
      );
      expect(item(items, 'lapl:1').validUntil, DateTime(2028, 6, 15));
    });
  });

  test('SET and IR revalidate by proficiency check only', () {
    final set = rating(
      RatingKind.classRating,
      cls: AircraftClass.setLand,
      expiry: DateTime(2027, 3, 31),
    );
    final ir = rating(RatingKind.instrument, expiry: DateTime(2027, 3, 31));
    final items = compute([
      LicenceWithRatings(licence(), [set, ir]),
    ], const []);
    final setItem = item(items, 'rating:${set.id}');
    expect(setItem.requirements, isEmpty);
    expect(setItem.reference, isNull);
    expect(setItem.sections.single.reference, 'FCL.740.A(b)(3)');
    expect(setItem.sections.single.met, isFalse);
    final irCheck = item(items, 'rating:${ir.id}').sections.single;
    expect(irCheck.reference, 'FCL.625.A(a)');
    expect(irCheck.requirements.single.label, 'IR proficiency check');
  });

  test('helicopter type: 2 hours on type during the validity period', () {
    final r44 = rating(
      RatingKind.typeRating,
      name: 'R44',
      expiry: DateTime(2027, 1, 31),
    );
    final items = compute(
      [
        LicenceWithRatings(licence(category: AircraftCategory.helicopter), [
          r44,
        ]),
      ],
      [
        flight(
          DateTime(2026, 3),
          cls: AircraftClass.type,
          type: 'R44',
          total: const Duration(hours: 2),
        ),
      ],
    );
    expect(item(items, 'rating:${r44.id}').requirementsMet, isTrue);
  });

  group('LAPL(A) recency (FCL.140.A)', () {
    test('needs 12 h, 12 landings and 1 h with an instructor in 2 years', () {
      final items = compute(
        [LicenceWithRatings(licence(kind: LicenceKind.lapl), const [])],
        [
          flight(DateTime(2025, 1, 10), dual: const Duration(hours: 1)),
          for (var i = 0; i < 11; i++)
            flight(DateTime(2026, 1, 1 + i), landings: 2),
          // Not a LAPL(A) class.
          flight(
            DateTime(2026, 2),
            cls: AircraftClass.mepLand,
            total: const Duration(hours: 5),
          ),
        ],
      );
      final lapl = item(items, 'lapl:1');
      // The dual flight brings the time to 12 h and is the only refresher:
      // the rule holds until it is 2 years old.
      expect(lapl.validUntil, DateTime(2027, 1, 10));
      expect(lapl.requirements.every((r) => r.met), isTrue);
    });

    test('a proficiency check keeps it for 2 years', () {
      final items = compute([
        LicenceWithRatings(
          licence(kind: LicenceKind.lapl, check: DateTime(2026, 6, 15)),
          const [],
        ),
      ], const []);
      expect(item(items, 'lapl:1').validUntil, DateTime(2028, 6, 15));
    });
  });

  group('simulator sessions', () {
    final a320 = rating(RatingKind.typeRating, name: 'A320');

    CurrencyFlight session(
      DateTime date,
      SimulatorKind kind, {
      int landings = 0,
      bool check = false,
      AircraftClass cls = AircraftClass.type,
      String? type = 'A320',
    }) => flight(
      date,
      cls: cls,
      type: type,
      landings: landings,
      total: Duration.zero,
      check: check,
      simulator: kind,
    );

    test('FFS landings count for passengers (FCL.060(b)(1))', () {
      final items = compute(
        [
          LicenceWithRatings(licence(kind: LicenceKind.atpl), [a320]),
        ],
        [
          session(DateTime(2026, 11, 2), SimulatorKind.ffs, landings: 3),
          // Not an FFS: doesn't count.
          session(DateTime(2026, 11, 3), SimulatorKind.ftd, landings: 5),
        ],
      );
      final pax = item(items, 'passengers:type:A320');
      expect(pax.requirements.single.done, 3);
      expect(pax.validUntil, DateTime(2027, 1, 31));
    });

    test("don't count as flight experience", () {
      final sep = rating(
        RatingKind.classRating,
        cls: AircraftClass.sepLand,
        expiry: DateTime(2027, 3, 31),
      );
      final items = compute(
        [
          LicenceWithRatings(licence(), [sep]),
        ],
        [
          flight(DateTime(2026, 6), landings: 2),
          session(
            DateTime(2026, 6, 2),
            SimulatorKind.ffs,
            cls: AircraftClass.sepLand,
            type: null,
            landings: 20,
          ),
        ],
      );
      final byLabel = {
        for (final r in item(items, 'rating:${sep.id}').requirements)
          r.label: r,
      };
      expect(byLabel['Take-offs and landings']!.done, 2);
    });

    test('a check in an FSTD is the last check of its type', () {
      final typeRating = rating(
        RatingKind.typeRating,
        name: 'A320',
        expiry: DateTime(2027, 5, 31),
      );
      final items = compute(
        [
          LicenceWithRatings(licence(kind: LicenceKind.atpl), [typeRating]),
        ],
        [session(DateTime(2026, 5, 20), SimulatorKind.ffs, check: true)],
      );
      expect(
        item(items, 'rating:${typeRating.id}').lastCheck,
        DateTime(2026, 5, 20),
      );
    });

    test('a BITD is no place for a check, nor a LAPL check', () {
      final typeRating = rating(
        RatingKind.typeRating,
        name: 'A320',
        expiry: DateTime(2027, 5, 31),
      );
      final items = compute(
        [
          LicenceWithRatings(licence(kind: LicenceKind.atpl), [typeRating]),
          LicenceWithRatings(licence(id: 2, kind: LicenceKind.lapl), const []),
        ],
        [
          session(DateTime(2026, 5, 20), SimulatorKind.bitd, check: true),
          session(
            DateTime(2026, 6, 15),
            SimulatorKind.ffs,
            cls: AircraftClass.sepLand,
            type: null,
            check: true,
          ),
        ],
      );
      expect(item(items, 'rating:${typeRating.id}').lastCheck, isNull);
      expect(item(items, 'lapl:2').validUntil, isNull);
    });
  });

  test('medicals are validity items, licences never expire', () {
    final items = compute(
      [LicenceWithRatings(licence(id: 3), const [])],
      const [],
      medicals: [
        MedicalCertificate(
          id: 5,
          medicalClass: MedicalClass.class2,
          expiryDate: DateTime(2026, 11, 10),
        ),
      ],
    );
    expect(items.where((i) => i.key.startsWith('licence:')), isEmpty);
    final medical = item(items, 'medical:5');
    expect(medical.statusOn(today, warnDays: 30), CurrencyStatus.expired);
    expect(medical.daysLeft(today), -6);
  });

  group('validity periods', () {
    test('class ratings: 2 years single-engine, 1 year multi-engine', () {
      expect(
        RatingKind.classRating.validityFor(
          aircraftClass: AircraftClass.sepLand,
        ),
        24,
      );
      expect(
        RatingKind.classRating.validityFor(aircraftClass: AircraftClass.mepSea),
        12,
      );
      expect(RatingKind.instrument.validityFor(), 12);
      expect(RatingKind.instructor.validityFor(), 36);
      expect(RatingKind.languageProficiency.validityFor(level: 4), 48);
      expect(RatingKind.languageProficiency.validityFor(level: 6), isNull);
    });
  });

  group('Easy Access Rules, October 2026', () {
    test('mountain rating: no expiry, privileges kept by landings', () {
      final mountain = rating(
        RatingKind.mountain,
        // Entered before the rating stopped expiring: ignored.
        expiry: DateTime(2026, 1, 31),
      );
      final items = compute(
        [
          LicenceWithRatings(licence(), [mountain]),
        ],
        [
          flight(DateTime(2025, 6, 10), landings: 4, mountain: 4),
          flight(DateTime(2026, 2, 3), landings: 2, mountain: 2),
          flight(DateTime(2026, 3, 3), landings: 5),
        ],
      );
      expect(items.where((i) => i.key == 'rating:${mountain.id}'), isEmpty);
      final privileges = item(items, 'mountain:${mountain.id}');
      expect(privileges.kind, CurrencyKind.recency);
      expect(privileges.reference, 'FCL.815(d)');
      expect(privileges.requirements.single.done, 6);
      // The 6th landing back is 2 years old on 10 Jun 2027.
      expect(privileges.validUntil, DateTime(2027, 6, 10));
      expect(privileges.ratingId, mountain.id);
    });

    test('mountain rating: or a proficiency check in the last 2 years', () {
      final mountain = rating(
        RatingKind.mountain,
        lastCheck: DateTime(2025, 9),
      );
      final items = compute([
        LicenceWithRatings(licence(), [mountain]),
      ], const []);
      expect(
        item(items, 'mountain:${mountain.id}').validUntil,
        DateTime(2027, 9),
      );
      expect(RatingKind.mountain.validityFor(), isNull);
    });

    group('helicopter type ratings (FCL.740.H)', () {
      LicenceRating r44({bool light = true}) => rating(
        RatingKind.typeRating,
        name: 'R44',
        expiry: DateTime(2027, 1, 31),
        lightSingleEngine: light,
      );

      test('light single-engine: 6 h PIC and a refresher instead', () {
        final r = r44();
        final items = compute(
          [
            LicenceWithRatings(licence(category: AircraftCategory.helicopter), [
              r,
            ]),
          ],
          [
            for (var i = 0; i < 3; i++)
              flight(
                DateTime(2026, 3, 1 + i),
                cls: AircraftClass.type,
                type: 'R44',
                total: const Duration(hours: 2),
              ),
            // The refresher, half in an FSTD of the type, in the 3 months
            // before expiry (from 31 Oct 2026).
            flight(
              DateTime(2026, 11, 2),
              cls: AircraftClass.type,
              type: 'R44',
              total: const Duration(minutes: 30),
              dual: const Duration(minutes: 30),
            ),
            flight(
              DateTime(2026, 11, 3),
              cls: AircraftClass.type,
              type: 'R44',
              total: Duration.zero,
              landings: 0,
              simulator: SimulatorKind.ftd,
              sessionInstruction: const Duration(minutes: 30),
            ),
          ],
        );
        final validity = item(items, 'rating:${r.id}');
        expect(validity.reference, 'FCL.740.H(a)(1)(i)');
        expect(validity.sections, hasLength(2));
        expect(validity.sections.first.reference, 'FCL.740.H(a)(1)(ii)');
        final light = validity.sections.last;
        expect(light.reference, 'FCL.740.H(a)(2)(ii)');
        expect(light.requirements[0].done, 6 * 60);
        expect(light.requirements[1].done, 60);
        expect(light.met, isTrue);
      });

      test('not offered for other helicopter types', () {
        final r = r44(light: false);
        final items = compute([
          LicenceWithRatings(licence(category: AircraftCategory.helicopter), [
            r,
          ]),
        ], const []);
        expect(item(items, 'rating:${r.id}').sections, hasLength(1));
      });

      test('LAPL(H) refresher training may be flown in an FSTD', () {
        final r = rating(RatingKind.typeRating, name: 'R22');
        final items = compute(
          [
            LicenceWithRatings(
              licence(
                kind: LicenceKind.lapl,
                category: AircraftCategory.helicopter,
              ),
              [r],
            ),
          ],
          [
            for (var i = 0; i < 6; i++)
              flight(
                DateTime(2026, 6, 1 + i),
                cls: AircraftClass.type,
                type: 'R22',
              ),
            flight(
              DateTime(2026, 6, 10),
              cls: AircraftClass.type,
              type: 'R22',
              total: Duration.zero,
              landings: 0,
              simulator: SimulatorKind.ftd,
              sessionInstruction: const Duration(hours: 1),
            ),
          ],
        );
        final lapl = item(items, 'lapl:1:${r.id}');
        expect(lapl.requirements.every((q) => q.met), isTrue);
        expect(lapl.validUntil, DateTime(2027, 6));
      });
    });

    test('SEP (L) and SEP (S): 1 h PIC and 6 landings in each', () {
      final land = rating(
        RatingKind.classRating,
        cls: AircraftClass.sepLand,
        expiry: DateTime(2027, 3, 31),
      );
      final sea = rating(
        RatingKind.classRating,
        cls: AircraftClass.sepSea,
        expiry: DateTime(2027, 3, 31),
      );
      final items = compute(
        [
          LicenceWithRatings(licence(), [land, sea]),
        ],
        [
          flight(
            DateTime(2026, 5),
            total: const Duration(hours: 10),
            landings: 10,
          ),
          flight(
            DateTime(2026, 5, 2),
            cls: AircraftClass.sepSea,
            total: const Duration(hours: 2),
            landings: 2,
          ),
        ],
      );
      final byLabel = {
        for (final r in item(items, 'rating:${sea.id}').requirements)
          r.label: r,
      };
      expect(byLabel['Flight time']!.done, 12 * 60);
      expect(byLabel['Take-offs and landings in SEP (L)']!.met, isTrue);
      expect(byLabel['PIC time in SEP (S)']!.met, isTrue);
      expect(byLabel['Take-offs and landings in SEP (S)']!.done, 2);
      expect(byLabel['Take-offs and landings in SEP (S)']!.met, isFalse);
    });

    test('BIR: 6 h PIC under IFR, 3 approaches and a training flight', () {
      final bir = rating(
        RatingKind.basicInstrument,
        expiry: DateTime(2027, 3, 31),
      );
      final items = compute(
        [
          LicenceWithRatings(licence(), [bir]),
        ],
        [
          for (var i = 0; i < 3; i++)
            flight(
              DateTime(2026, 5, 1 + i),
              total: const Duration(hours: 2),
              ifr: const Duration(hours: 2),
              approach: true,
            ),
          flight(
            DateTime(2026, 6),
            total: const Duration(hours: 1, minutes: 5),
            dual: const Duration(hours: 1, minutes: 5),
          ),
        ],
      );
      final validity = item(items, 'rating:${bir.id}');
      expect(validity.reference, 'FCL.835(g)(2)(ii)');
      expect(validity.requirementsMet, isTrue);
      expect(validity.sections.single.reference, 'FCL.835(g)(2)(i)');
      expect(validity.notes, contains(contains('every other revalidation')));
    });

    test('VCA type rating: 2 h on type and a check (Article 4f)', () {
      final vca = rating(
        RatingKind.vcaTypeRating,
        name: 'VC2',
        expiry: DateTime(2027, 2, 28),
      );
      final items = compute(
        [
          LicenceWithRatings(licence(kind: LicenceKind.cpl), [vca]),
        ],
        [
          flight(
            DateTime(2026, 11),
            cls: AircraftClass.type,
            type: 'VC2',
            total: const Duration(hours: 2),
            landings: 3,
          ),
        ],
      );
      final validity = item(items, 'rating:${vca.id}');
      expect(validity.reference, 'Article 4f(5)(a)(i)');
      expect(validity.requirementsMet, isTrue);
      expect(validity.sections.single.reference, 'Article 4f(5)(a)(ii)');
      expect(
        item(items, 'passengers:type:VC2').requirements.single.met,
        isTrue,
      );
      expect(RatingKind.vcaTypeRating.validityFor(), 12);
    });

    group('GPL (Regulation (EU) 2025/134)', () {
      final gplLicence = licence(
        kind: LicenceKind.gpl,
        category: AircraftCategory.gyroplane,
        issued: DateTime(2026, 4),
      );

      test('recency: 12 h, 12 landings, 1 h refresher in 2 years', () {
        final spg = rating(RatingKind.classRating, cls: AircraftClass.spg);
        final items = compute(
          [
            LicenceWithRatings(gplLicence, [spg]),
          ],
          [
            flight(
              DateTime(2026, 5),
              cls: AircraftClass.spg,
              dual: const Duration(hours: 1),
            ),
            for (var i = 0; i < 11; i++)
              flight(DateTime(2026, 6, 1 + i), cls: AircraftClass.spg),
          ],
        );
        final recency = item(items, 'gpl:1:${spg.id}');
        expect(recency.reference, 'FCL.240.G');
        expect(recency.validUntil, DateTime(2028, 5));
        // Passengers after 10 h as PIC since the issue: 11 h flown.
        expect(items.where((i) => i.key == 'gpl-passengers:1'), isEmpty);
        // FCL.060(b) applies to gyroplanes: no landings in the last 90
        // days.
        expect(item(items, 'passengers:class:spg').validUntil, isNull);
      });

      test('passengers only after 10 h as PIC', () {
        final items = compute(
          [LicenceWithRatings(gplLicence, const [])],
          [
            // Before the issue: doesn't count.
            flight(DateTime(2026, 3), cls: AircraftClass.spg),
            flight(
              DateTime(2026, 5),
              cls: AircraftClass.spg,
              total: const Duration(hours: 4),
            ),
          ],
        );
        final pax = item(items, 'gpl-passengers:1');
        expect(pax.reference, 'FCL.205.G(a)(2)');
        expect(pax.validUntil, isNull);
        expect(pax.requirements.single.done, 4 * 60);
        expect(item(items, 'gpl:1').reference, 'FCL.240.G');
      });
    });

    test('cruise relief co-pilot: 3 sectors in 90 days (FCL.060(b)(3))', () {
      final b777 = rating(
        RatingKind.typeRating,
        name: 'B777',
        expiry: DateTime(2027, 5, 31),
      );
      CurrencyFlight crcp(DateTime d) => flight(
        d,
        cls: AircraftClass.type,
        type: 'B777',
        landings: 0,
        cruiseRelief: true,
      );
      final items = compute(
        [
          LicenceWithRatings(licence(kind: LicenceKind.atpl), [b777]),
        ],
        [
          crcp(DateTime(2026, 11)),
          crcp(DateTime(2026, 10)),
          crcp(DateTime(2026, 9)),
        ],
      );
      final cr = item(items, 'crcp:type:B777');
      expect(cr.requirements.single.done, 3);
      expect(cr.validUntil, DateTime(2026, 11, 30));
      // No cruise relief flown: nothing to show.
      expect(
        compute([
          LicenceWithRatings(licence(kind: LicenceKind.atpl), [b777]),
        ], const []).where((i) => i.key.startsWith('crcp:')),
        isEmpty,
      );
    });

    test('SEP variants with another type of engine (FCL.710(d))', () {
      final sep = rating(RatingKind.classRating, cls: AircraftClass.sepLand);
      final items = compute(
        [
          LicenceWithRatings(licence(), [sep]),
        ],
        [
          flight(DateTime(2026, 10), engine: EngineType.piston),
          flight(DateTime(2025, 2, 10), engine: EngineType.electric),
        ],
      );
      expect(
        item(items, 'sep-variant:electric').validUntil,
        DateTime(2027, 2, 10),
      );
      // Only piston SEPs flown: nothing to track.
      expect(
        compute(
          [
            LicenceWithRatings(licence(), [sep]),
          ],
          [flight(DateTime(2026, 10), engine: EngineType.piston)],
        ).where((i) => i.key.startsWith('sep-variant:')),
        isEmpty,
      );
    });

    group('renewal (FCL.740(b), FCL.625(c))', () {
      test('an instructor may assess an SEP rating for 3 years', () {
        final sep = rating(
          RatingKind.classRating,
          cls: AircraftClass.sepLand,
          expiry: DateTime(2025, 1, 31),
        );
        final validity = item(
          compute([
            LicenceWithRatings(licence(), [sep]),
          ], const []),
          'rating:${sep.id}',
        );
        expect(validity.reference, 'FCL.740(b)');
        expect(validity.notes.first, contains('or an instructor'));
        expect(validity.notes.last, contains('31 Jan 2028'));
      });

      test('an IR not renewed for 7 years means the exams again', () {
        final ir = rating(RatingKind.instrument, expiry: DateTime(2019, 1, 31));
        final validity = item(
          compute([
            LicenceWithRatings(licence(), [ir]),
          ], const []),
          'rating:${ir.id}',
        );
        expect(validity.reference, 'FCL.625(c)');
        expect(validity.notes.last, contains('FCL.625(d)'));
      });
    });

    test('FI(As) revalidate with 20 hours of instruction', () {
      final fi = rating(
        RatingKind.instructor,
        name: 'FI(As)',
        expiry: DateTime(2027, 5, 31),
      );
      final validity = item(
        compute([
          LicenceWithRatings(licence(), [fi]),
        ], const []),
        'rating:${fi.id}',
      );
      expect(validity.requirements.single.needed, 20 * 60);
    });

    test('class and type checks may be EBT practical assessments', () {
      final mep = rating(
        RatingKind.classRating,
        cls: AircraftClass.mepLand,
        expiry: DateTime(2027, 2, 28),
      );
      final items = compute([
        LicenceWithRatings(licence(), [mep]),
      ], const []);
      expect(
        item(items, 'rating:${mep.id}').sections.single.notes,
        contains(contains('EBT practical assessment')),
      );
    });
  });

  group('planReminders', () {
    final medical = CurrencyItem(
      key: 'medical:1',
      kind: CurrencyKind.validity,
      title: 'Medical Class 2',
      validUntil: DateTime(2027, 3, 31),
    );
    final pax = CurrencyItem(
      key: 'passengers:class:sepLand',
      kind: CurrencyKind.recency,
      title: 'Passengers on SEP (L)',
      validUntil: DateTime(2026, 12, 20),
    );
    const settings = CurrencySettings(
      leads: {ReminderLead.threeMonths, ReminderLead.oneMonth},
      reminderTime: TimeOfDay(hour: 9, minute: 30),
    );

    test('one per lead still ahead, earliest first', () {
      final now = DateTime(2026, 11, 16, 12);
      final plan = planReminders([medical, pax], settings, now);
      expect(
        [for (final r in plan) r.at],
        [
          // Passengers: 3 months before is past, 1 month before is 20 Nov.
          DateTime(2026, 11, 20, 9, 30),
          DateTime(2026, 12, 31, 9, 30),
          DateTime(2027, 2, 28, 9, 30),
        ],
      );
      expect(plan[0].title, 'Passengers on SEP (L): currency ends in 1 month');
      expect(plan[1].title, 'Medical Class 2 expires in 3 months');
      expect(plan[1].body, 'Valid until 31 Mar 2027');
    });

    test('recency can be left out, and everything turned off', () {
      final now = DateTime(2026, 11, 16, 12);
      expect(
        planReminders([pax], settings.copyWith(recencyReminders: false), now),
        isEmpty,
      );
      expect(
        planReminders(
          [medical, pax],
          settings.copyWith(notificationsEnabled: false),
          now,
        ),
        isEmpty,
      );
    });

    test('a reminder later today is still planned', () {
      final plan = planReminders(
        [medical],
        const CurrencySettings(
          leads: {ReminderLead.onTheDay},
          reminderTime: TimeOfDay(hour: 18, minute: 0),
        ),
        DateTime(2027, 3, 31, 8),
      );
      expect(plan.single.title, 'Medical Class 2 expires today');
    });
  });
}
