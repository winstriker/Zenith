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
  }) => Licence(
    id: id,
    kind: kind,
    category: category,
    proficiencyCheckDate: check,
  );

  var nextRatingId = 1;
  LicenceRating rating(
    RatingKind kind, {
    AircraftClass? cls,
    String? name,
    DateTime? expiry,
    DateTime? lastCheck,
    int licenceId = 1,
  }) => LicenceRating(
    id: nextRatingId++,
    licence: licenceId,
    kind: kind,
    aircraftClass: cls,
    name: name,
    expiryDate: expiry,
    lastCheckDate: lastCheck,
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
      loaded: true,
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
          loaded: true,
          leads: {ReminderLead.onTheDay},
          reminderTime: TimeOfDay(hour: 18, minute: 0),
        ),
        DateTime(2027, 3, 31, 8),
      );
      expect(plan.single.title, 'Medical Class 2 expires today');
    });
  });
}
