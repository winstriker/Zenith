// What keeps a pilot's licences usable: validity dates of ratings and
// certificates, and recency worked out from the logbook.
//
// Rules from EASA Part-FCL (Easy Access Rules, August 2020 edition):
//  * FCL.060(b)(1): to carry passengers, 3 take-offs and landings in the
//    preceding 90 days in the same class or type;
//  * FCL.060(b)(2): as PIC at night with passengers, 1 of them at night, or
//    an IR;
//  * FCL.140.A / FCL.140.H: LAPL recency;
//  * FCL.740.A(a)(2), FCL.740.A(b)(1)(ii), FCL.740.H(a)(2): revalidation of
//    class and type ratings;
//  * FCL.835(g)(2)(ii): BIR revalidation;
//  * FCL.940.FI(a)(1)(i): FI revalidation.
//
// The logbook only records landings, so every landing is taken to come with
// its take-off.

import '../services/database.dart';

/// One flight as the currency rules see it.
class CurrencyFlight {
  const CurrencyFlight({
    required this.date,
    this.total = Duration.zero,
    this.pic = Duration.zero,
    this.dual = Duration.zero,
    this.instructor = Duration.zero,
    this.ifr = Duration.zero,
    this.picIfr = Duration.zero,
    this.dayLandings = 0,
    this.nightLandings = 0,
    this.aircraftClass,
    this.typeRating,
    this.proficiencyCheck = false,
  });

  /// Departure time.
  final DateTime date;
  final Duration total;
  final Duration pic;

  /// Time as student with an instructor.
  final Duration dual;

  /// Time as instructor.
  final Duration instructor;

  /// IFR time, in any role.
  final Duration ifr;

  /// IFR time flown as PIC.
  final Duration picIfr;
  final int dayLandings;
  final int nightLandings;
  final AircraftClass? aircraftClass;
  final String? typeRating;

  /// A proficiency check with an examiner, in the class or type of the
  /// aircraft.
  final bool proficiencyCheck;

  int get landings => dayLandings + nightLandings;
}

/// A licence together with the ratings endorsed on it.
class LicenceWithRatings {
  const LicenceWithRatings(this.licence, this.ratings);
  final Licence licence;
  final List<LicenceRating> ratings;
}

enum CurrencyKind {
  /// An expiry date written on a rating, certificate or medical. Licences
  /// themselves don't expire under Part-FCL.
  validity,

  /// Worked out from the logbook.
  recency,
}

enum CurrencyStatus { valid, expiring, expired }

enum RequirementUnit { count, minutes }

/// One condition of a rule, with how much of it is done.
class Requirement {
  const Requirement(
    this.label, {
    required this.done,
    required this.needed,
    this.unit = RequirementUnit.count,
  });

  /// [done] and [needed] as durations.
  Requirement.time(
    this.label, {
    required Duration done,
    required Duration needed,
  }) : done = done.inMinutes,
       needed = needed.inMinutes,
       unit = RequirementUnit.minutes;

  final String label;
  final int done;
  final int needed;
  final RequirementUnit unit;

  bool get met => done >= needed;
  double get progress => needed == 0 ? 1 : (done / needed).clamp(0, 1);
}

/// Another way of meeting a rule, shown as its own section after the
/// item's requirements: e.g. revalidation by proficiency check, next to
/// revalidation by experience.
class RequirementSection {
  const RequirementSection({
    required this.title,
    required this.requirements,
    this.notes = const [],
    this.reference,
  });

  final String title;
  final List<Requirement> requirements;
  final List<String> notes;

  /// The Part-FCL point the section comes from.
  final String? reference;

  bool get met => requirements.isNotEmpty && requirements.every((r) => r.met);
}

/// Something that keeps a licence usable, and until when.
class CurrencyItem {
  const CurrencyItem({
    required this.key,
    required this.kind,
    required this.title,
    required this.validUntil,
    this.subtitle,
    this.reference,
    this.requirementsTitle,
    this.requirements = const [],
    this.anyRequirement = false,
    this.notes = const [],
    this.sections = const [],
    this.lastCheck,
    this.licenceId,
    this.ratingId,
    this.medicalId,
  });

  /// Stable across recomputations: identifies the item for notifications.
  final String key;
  final CurrencyKind kind;
  final String title;
  final String? subtitle;

  /// The Part-FCL point the rule comes from.
  final String? reference;

  /// Last day it is valid. Null when a recency rule isn't met at all.
  final DateTime? validUntil;

  /// What [requirements] are for: recency, or revalidation of the rating.
  final String? requirementsTitle;
  final List<Requirement> requirements;

  /// Whether one of [requirements] is enough, rather than all of them.
  final bool anyRequirement;
  final List<String> notes;

  /// Shown after [requirements], each with its own notes and rule.
  final List<RequirementSection> sections;

  /// For a rating, its last proficiency check: the date entered on it, or a
  /// later flight logged as one.
  final DateTime? lastCheck;

  final int? licenceId;
  final int? ratingId;
  final int? medicalId;

  bool get requirementsMet => requirements.isEmpty
      ? false
      : anyRequirement
      ? requirements.any((r) => r.met)
      : requirements.every((r) => r.met);

  /// Days from [today] to [validUntil]: 0 on the last valid day, negative
  /// once expired. Null when never valid.
  int? daysLeft(DateTime today) =>
      validUntil == null ? null : daysBetween(today, validUntil!);

  /// [warnDays] before [validUntil] the item counts as expiring.
  CurrencyStatus statusOn(DateTime today, {required int warnDays}) {
    final left = daysLeft(today);
    if (left == null || left < 0) return CurrencyStatus.expired;
    if (left <= warnDays) return CurrencyStatus.expiring;
    return CurrencyStatus.valid;
  }
}

/// [d] at midnight.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Whole days from [from] to [to], ignoring the time of day and DST.
int daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// [d] moved by [months], on the same day of the month or the last one when
/// that month is shorter (31 Jan + 1 month = 28 Feb).
DateTime addMonths(DateTime d, int months) {
  final first = DateTime(d.year, d.month + months);
  final lastDay = DateTime(first.year, first.month + 1, 0).day;
  return DateTime(first.year, first.month, d.day > lastDay ? lastDay : d.day);
}

/// How type rating endorsements are compared: "b737  300-900" is "B737 300-900".
String normalizeTypeRating(String rating) =>
    rating.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');

extension LicenceTitle on Licence {
  /// "PPL(A)".
  String get title => kind == LicenceKind.other
      ? 'Licence (${category.suffix})'
      : '${kind.label}(${category.suffix})';
}

extension LicenceRatingTitle on LicenceRating {
  /// How the rating is called on the licence: "SEP (L)", "A320", "IR"...
  String get title {
    final named = name?.trim();
    final hasName = named != null && named.isNotEmpty;
    return switch (kind) {
      RatingKind.classRating => aircraftClass?.label ?? kind.label,
      RatingKind.instrument => 'IR',
      RatingKind.enRouteInstrument => 'EIR',
      RatingKind.basicInstrument => 'BIR',
      RatingKind.languageProficiency =>
        '${hasName ? named : 'Language'}${level == null ? '' : ' level $level'}',
      RatingKind.towing => hasName ? 'Towing ($named)' : kind.label,
      _ => hasName ? named : kind.label,
    };
  }

  /// Whether flights in [flight]'s aircraft count for this class or type
  /// rating.
  bool covers(CurrencyFlight flight) => switch (kind) {
    RatingKind.classRating =>
      aircraftClass != null && flight.aircraftClass == aircraftClass,
    RatingKind.typeRating =>
      flight.aircraftClass == AircraftClass.type &&
          flight.typeRating != null &&
          name != null &&
          normalizeTypeRating(flight.typeRating!) == normalizeTypeRating(name!),
    _ => false,
  };
}

/// Works out every [CurrencyItem] of the pilot on [today].
class CurrencyCalculator {
  CurrencyCalculator({
    required this.licences,
    required this.medicals,
    required this.flights,
    required DateTime today,
  }) : today = dateOnly(today);

  final List<LicenceWithRatings> licences;
  final List<MedicalCertificate> medicals;
  final List<CurrencyFlight> flights;
  final DateTime today;

  /// The flights that happened by the end of [today].
  late final List<CurrencyFlight> _flown = [
    for (final f in flights)
      if (!dateOnly(f.date).isAfter(today)) f,
  ]..sort((a, b) => b.date.compareTo(a.date));

  late final Set<AircraftClass> _classesHeld = {
    for (final l in licences)
      for (final r in l.ratings)
        if (r.kind == RatingKind.classRating && r.aircraftClass != null)
          r.aircraftClass!,
  };

  List<CurrencyItem> compute() => [
    for (final m in medicals) _medical(m),
    for (final l in licences) ...[
      for (final r in l.ratings)
        if (r.expiryDate != null) _ratingValidity(l.licence, r),
      ..._laplRecency(l),
    ],
    ..._passengerRecency(),
  ];

  // Validity -----------------------------------------------------------------

  CurrencyItem _medical(MedicalCertificate m) => CurrencyItem(
    key: 'medical:${m.id}',
    kind: CurrencyKind.validity,
    title: 'Medical ${m.medicalClass.label}',
    subtitle: m.limitations,
    validUntil: dateOnly(m.expiryDate),
    medicalId: m.id,
  );

  CurrencyItem _ratingValidity(Licence licence, LicenceRating r) {
    final expiry = dateOnly(r.expiryDate!);
    final validity = r.kind.validityFor(
      aircraftClass: r.aircraftClass,
      level: r.level,
    );
    // Start of the current validity period, for "during the validity
    // period" requirements.
    final periodStart = addMonths(expiry, -(validity ?? 12));
    final checkWindow = addMonths(expiry, -3);
    final checkInWindow = _checkWindowNote(checkWindow, expiry);
    final lastCheck = _lastCheck(r);
    final flownCheck = _lastCheckFlight((f) => _checksFor(r, f));
    final checkInPeriod =
        lastCheck != null &&
        !lastCheck.isBefore(periodStart) &&
        !lastCheck.isAfter(today);
    // A check flown during this validity period (or its 3 months' window)
    // revalidates the rating: the examiner endorses a new expiry date.
    final checkFlownNote =
        flownCheck != null && !flownCheck.isBefore(periodStart)
        ? _checkFlownNote(flownCheck)
        : null;

    /// Revalidation by proficiency check, under [reference]: in the 3
    /// months before expiry, or earlier with the validity starting from the
    /// check ([earlierRef]).
    RequirementSection checkSection(
      String reference, {
      String label = 'Proficiency check with an examiner',
      String earlierRef = 'FCL.740(a)',
      String? note,
    }) => RequirementSection(
      title: 'Revalidation by proficiency check',
      reference: reference,
      requirements: [
        Requirement(label, done: checkInPeriod ? 1 : 0, needed: 1),
      ],
      notes: [
        ?note,
        '${today.isBefore(checkWindow) ? 'From' : 'Since'} '
            '${_date(checkWindow)}, the 3 months before expiry.',
        'Passed earlier, the new validity period starts from the date of '
            'the check ($earlierRef).',
        ?checkFlownNote,
      ],
    );

    var requirementsTitle = '';
    var requirements = const <Requirement>[];
    var anyRequirement = false;
    final notes = <String>[];
    final sections = <RequirementSection>[];
    String? reference = r.kind.reference;

    final aeroplane = licence.category == AircraftCategory.aeroplane;
    // Once expired, a rating can't be revalidated any more: it has to be
    // renewed (FCL.740(b), FCL.625(c)).
    if (expiry.isBefore(today)) {
      final (renewalRef, renewal) = switch (r.kind) {
        RatingKind.classRating || RatingKind.typeRating => (
          'FCL.740(b)',
          'Expired: to renew it, pass a proficiency check, after refresher '
              'training if the training organisation deems it necessary.',
        ),
        RatingKind.instrument => (
          'FCL.625(c)',
          'Expired: to renew it, pass an IR proficiency check, after '
              'refresher training if the training organisation deems it '
              'necessary.',
        ),
        _ => (r.kind.reference, null),
      };
      return CurrencyItem(
        key: 'rating:${r.id}',
        kind: CurrencyKind.validity,
        title: r.title,
        subtitle: licence.title,
        reference: renewalRef,
        validUntil: expiry,
        notes: [
          ?renewal,
          if (flownCheck != null && flownCheck.isAfter(expiry))
            _checkFlownNote(flownCheck),
        ],
        lastCheck: lastCheck,
        licenceId: licence.id,
        ratingId: r.id,
      );
    }
    switch (r.kind) {
      case RatingKind.classRating:
        final c = r.aircraftClass;
        if (c == AircraftClass.sepLand ||
            c == AircraftClass.sepSea ||
            c == AircraftClass.tmg) {
          reference = 'FCL.740.A(b)(1)(ii)';
          // FCL.740.A(b)(2): SEP (L) and TMG revalidate each other.
          final counted = {c!};
          if ((c == AircraftClass.sepLand || c == AircraftClass.tmg) &&
              _classesHeld.contains(AircraftClass.sepLand) &&
              _classesHeld.contains(AircraftClass.tmg)) {
            counted.addAll(const [AircraftClass.sepLand, AircraftClass.tmg]);
          }
          final window = _between(
            addMonths(expiry, -12),
            expiry,
            (f) => counted.contains(f.aircraftClass),
          );
          requirementsTitle = 'Revalidation by experience';
          requirements = [
            Requirement.time(
              'Flight time',
              done: _sum(window, (f) => f.total),
              needed: const Duration(hours: 12),
            ),
            Requirement.time(
              'PIC time',
              done: _sum(window, (f) => f.pic),
              needed: const Duration(hours: 6),
            ),
            Requirement(
              'Take-offs and landings',
              done: window.fold(0, (s, f) => s + f.landings),
              needed: 12,
            ),
            Requirement.time(
              'Refresher training with an instructor',
              done: _sum(window, (f) => f.dual),
              needed: const Duration(hours: 1),
            ),
          ];
          notes.add(
            'Counted from ${_date(addMonths(expiry, -12))}, the 12 months '
            'before expiry'
            '${counted.length > 1 ? ', in SEP (L) and TMG together' : ''}.',
          );
          notes.add(
            'The refresher flight isn\'t needed after a proficiency check, '
            'skill test or assessment of competence in another class or type.',
          );
          sections.add(
            checkSection(
              'FCL.740.A(b)(1)(i)',
              note: 'Instead of revalidation by experience.',
            ),
          );
        } else if (c == AircraftClass.setLand || c == AircraftClass.setSea) {
          // The check is the only way: its section says it all.
          reference = null;
          sections.add(checkSection('FCL.740.A(b)(3)'));
        } else if (c == AircraftClass.mepLand || c == AircraftClass.mepSea) {
          reference = 'FCL.740.A(a)(2)';
          (requirementsTitle, requirements, anyRequirement) = _routeSectors(
            r,
            periodStart,
            expiry,
          );
          sections.add(
            checkSection(
              'FCL.740.A(a)(1)',
              note: 'Needed as well as the route sectors.',
            ),
          );
        }
      case RatingKind.typeRating:
        if (aeroplane) {
          reference = 'FCL.740.A(a)(2)';
          (requirementsTitle, requirements, anyRequirement) = _routeSectors(
            r,
            periodStart,
            expiry,
          );
          sections.add(
            checkSection(
              'FCL.740.A(a)(1)',
              note: 'Needed as well as the route sectors.',
            ),
          );
        } else if (licence.category == AircraftCategory.helicopter) {
          reference = 'FCL.740.H(a)(2)';
          final window = _between(periodStart, expiry, r.covers);
          requirementsTitle = 'During the validity period';
          requirements = [
            Requirement.time(
              'Flight time on type',
              done: _sum(window, (f) => f.total),
              needed: const Duration(hours: 2),
            ),
          ];
          notes.add('The proficiency check counts towards the 2 hours.');
          sections.add(
            checkSection(
              'FCL.740.H(a)(1)',
              note: 'Needed as well as the 2 hours on type.',
            ),
          );
        } else {
          notes.add(checkInWindow);
        }
      case RatingKind.instrument:
        // FCL.625(b): only by proficiency check, its section says it all.
        reference = null;
        final (irRef, combinedRef) = switch (licence.category) {
          AircraftCategory.aeroplane => ('FCL.625.A(a)', 'FCL.625.A(a)(2)'),
          AircraftCategory.helicopter => ('FCL.625.H(a)', 'FCL.625.H(a)(2)'),
          _ => ('FCL.625(b)', null),
        };
        sections.add(
          checkSection(
            irRef,
            label: 'IR proficiency check',
            earlierRef: 'FCL.625(b)(2)',
            note: combinedRef == null
                ? null
                : 'Can be combined with the class or type rating proficiency '
                      'check ($combinedRef).',
          ),
        );
      case RatingKind.enRouteInstrument:
        notes.add(checkInWindow);
      case RatingKind.basicInstrument:
        final window = _between(periodStart, expiry, (_) => true);
        requirementsTitle = 'During the validity period';
        requirements = [
          Requirement.time(
            'PIC time under IFR',
            done: _sum(window, (f) => f.picIfr),
            needed: const Duration(hours: 6),
          ),
        ];
        notes.add(
          'Also 3 instrument approaches and a training flight with an '
          'instructor, or a proficiency check, in the 3 months before '
          'expiry (from ${_date(checkWindow)}).',
        );
      case RatingKind.instructor:
        final named = normalizeTypeRating(r.name ?? '');
        if (named.startsWith('FI')) {
          reference = 'FCL.940.FI';
          final window = _between(periodStart, expiry, (_) => true);
          requirementsTitle = 'During the validity period';
          requirements = [
            Requirement.time(
              'Flight instruction',
              done: _sum(window, (f) => f.instructor),
              needed: const Duration(hours: 50),
            ),
          ];
          notes.add(
            'Revalidation needs 2 of: 50 hours of instruction, instructor '
            'refresher training, an assessment of competence in the last 12 '
            'months (required at least every other revalidation).',
          );
        }
      case RatingKind.examiner:
        notes.add(
          'Revalidation needs at least 6 skill tests, proficiency checks or '
          'assessments of competence, and an examiner refresher course in '
          'the last 12 months.',
        );
      case RatingKind.mountain:
        notes.add(
          'Revalidated with 6 landings on a mountain surface in the last '
          '2 years, or a proficiency check.',
        );
      case RatingKind.languageProficiency:
      case RatingKind.night:
      case RatingKind.aerobatic:
      case RatingKind.towing:
      case RatingKind.flightTest:
      case RatingKind.other:
        break;
    }

    // Where there is no check section, the flown check still gets said.
    if (sections.isEmpty && checkFlownNote != null) notes.add(checkFlownNote);

    return CurrencyItem(
      key: 'rating:${r.id}',
      kind: CurrencyKind.validity,
      title: r.title,
      subtitle: licence.title,
      reference: reference,
      validUntil: expiry,
      requirementsTitle: requirements.isEmpty ? null : requirementsTitle,
      requirements: requirements,
      anyRequirement: anyRequirement,
      notes: notes,
      sections: sections,
      lastCheck: lastCheck,
      licenceId: licence.id,
      ratingId: r.id,
    );
  }

  /// FCL.740.A(a)(2): 10 route sectors in the class or type during the
  /// validity period, or 1 with an examiner (which may be the proficiency
  /// check).
  (String, List<Requirement>, bool) _routeSectors(
    LicenceRating r,
    DateTime periodStart,
    DateTime expiry,
  ) {
    final sectors = _between(periodStart, expiry, r.covers).length;
    final check = _lastCheck(r);
    final checkInPeriod =
        check != null && !check.isBefore(periodStart) && !check.isAfter(today);
    return (
      'During the validity period',
      [
        Requirement('Route sectors', done: sectors, needed: 10),
        Requirement(
          'Route sector with an examiner',
          done: checkInPeriod ? 1 : 0,
          needed: 1,
        ),
      ],
      true,
    );
  }

  /// The last proficiency check of [r]: the date entered on the rating, or
  /// a later flight logged as a check for it.
  DateTime? _lastCheck(LicenceRating r) => _latest(
    r.lastCheckDate == null ? null : dateOnly(r.lastCheckDate!),
    _lastCheckFlight((f) => _checksFor(r, f)),
  );

  /// Whether [f], logged as a proficiency check, is one for [r]: in its
  /// class or type, or under IFR for an IR (FCL.625.A(a)(2): the IR check
  /// may be combined with the class or type one).
  static bool _checksFor(LicenceRating r, CurrencyFlight f) => switch (r.kind) {
    RatingKind.instrument => f.ifr > Duration.zero,
    _ => r.covers(f),
  };

  /// The day of the last flight logged as a proficiency check that [test]
  /// accepts.
  DateTime? _lastCheckFlight(bool Function(CurrencyFlight) test) {
    for (final f in _flown) {
      if (f.proficiencyCheck && test(f)) return dateOnly(f.date);
    }
    return null;
  }

  static DateTime? _latest(DateTime? a, DateTime? b) =>
      a == null || (b != null && b.isAfter(a)) ? b : a;

  String _checkFlownNote(DateTime on) =>
      'Proficiency check flown on ${_date(on)}: set the new expiry date '
      'once the examiner has endorsed it.';

  String _checkWindowNote(DateTime opens, DateTime expiry) {
    final verb = today.isBefore(opens) ? 'opens' : 'opened';
    return 'Proficiency check window $verb on ${_date(opens)} (3 months '
        'before expiry).';
  }

  // Recency ------------------------------------------------------------------

  /// FCL.060(b): passengers by day and by night, for every class and type
  /// rating held on a powered aircraft licence.
  List<CurrencyItem> _passengerRecency() {
    final ratings = <String, (Licence, LicenceRating)>{};
    var nightPrivileges = false;
    DateTime? irValidUntil;
    for (final l in licences) {
      if (l.licence.kind.includesNight) nightPrivileges = true;
      for (final r in l.ratings) {
        if (r.kind == RatingKind.night) nightPrivileges = true;
        if (r.kind == RatingKind.instrument) {
          nightPrivileges = true;
          // An IR counts once its expiry date is known.
          final until = r.expiryDate == null ? null : dateOnly(r.expiryDate!);
          if (until != null &&
              (irValidUntil == null || until.isAfter(irValidUntil))) {
            irValidUntil = until;
          }
        }
        final powered = const [
          AircraftCategory.aeroplane,
          AircraftCategory.helicopter,
          AircraftCategory.poweredLift,
          AircraftCategory.airship,
        ].contains(l.licence.category);
        // No currency to keep on a rating that has expired: it has to be
        // renewed first.
        if (!powered || _expired(r)) continue;
        final key = switch (r.kind) {
          RatingKind.classRating when r.aircraftClass != null =>
            'class:${r.aircraftClass!.name}',
          RatingKind.typeRating when (r.name?.trim() ?? '').isNotEmpty =>
            'type:${normalizeTypeRating(r.name!)}',
          _ => null,
        };
        if (key != null) ratings.putIfAbsent(key, () => (l.licence, r));
      }
    }

    final items = <CurrencyItem>[];
    for (final MapEntry(key: key, value: (licence, rating))
        in ratings.entries) {
      final covered = _flown.where(rating.covers).toList();
      final day = _rolling(
        covered,
        amount: (f) => f.landings,
        needed: 3,
        until: _plus90Days,
      );
      items.add(
        CurrencyItem(
          key: 'passengers:$key',
          kind: CurrencyKind.recency,
          title: 'Passengers on ${rating.title}',
          reference: 'FCL.060(b)(1)',
          validUntil: day.validUntil,
          requirementsTitle: 'In the last 90 days',
          requirements: [
            Requirement('Take-offs and landings', done: day.done, needed: 3),
          ],
          licenceId: licence.id,
          ratingId: rating.id,
        ),
      );
      if (!nightPrivileges) continue;
      final night = _rolling(
        covered,
        amount: (f) => f.nightLandings,
        needed: 1,
        until: _plus90Days,
      );
      final ir = irValidUntil;
      final irCovers = ir != null && !ir.isBefore(today);
      final until = [night.validUntil, if (irCovers) ir].nonNulls
          .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
      items.add(
        CurrencyItem(
          key: 'night:$key',
          kind: CurrencyKind.recency,
          title: 'Night passengers on ${rating.title}',
          subtitle: 'As PIC, last 90 days',
          reference: 'FCL.060(b)(2)',
          validUntil: until,
          requirementsTitle: 'In the last 90 days',
          requirements: [
            Requirement(
              'Night take-offs and landings',
              done: night.done,
              needed: 1,
            ),
          ],
          notes: [
            if (irCovers)
              'Your instrument rating covers this until ${_date(ir)}.',
          ],
          licenceId: licence.id,
          ratingId: rating.id,
        ),
      );
    }
    return items;
  }

  /// FCL.140.A and FCL.140.H.
  List<CurrencyItem> _laplRecency(LicenceWithRatings l) {
    final licence = l.licence;
    if (licence.kind != LicenceKind.lapl) return const [];
    switch (licence.category) {
      case AircraftCategory.aeroplane:
        const classes = [
          AircraftClass.sepLand,
          AircraftClass.sepSea,
          AircraftClass.tmg,
        ];
        return [
          _laplItem(
            key: 'lapl:${licence.id}',
            title: '${licence.title} recency',
            reference: 'FCL.140.A',
            flown: _flown
                .where((f) => classes.contains(f.aircraftClass))
                .toList(),
            months: 24,
            time: const Duration(hours: 12),
            landings: 12,
            check: _latest(
              licence.proficiencyCheckDate == null
                  ? null
                  : dateOnly(licence.proficiencyCheckDate!),
              _lastCheckFlight((f) => classes.contains(f.aircraftClass)),
            ),
            licence: licence,
          ),
        ];
      case AircraftCategory.helicopter:
        return [
          for (final r in l.ratings)
            if (r.kind == RatingKind.typeRating && !_expired(r))
              _laplItem(
                key: 'lapl:${licence.id}:${r.id}',
                title: '${licence.title} recency on ${r.title}',
                reference: 'FCL.140.H',
                flown: _flown.where(r.covers).toList(),
                months: 12,
                time: const Duration(hours: 6),
                landings: 6,
                check: _lastCheck(r),
                licence: licence,
                rating: r,
              ),
        ];
      default:
        return const [];
    }
  }

  CurrencyItem _laplItem({
    required String key,
    required String title,
    required String reference,
    required List<CurrencyFlight> flown,
    required int months,
    required Duration time,
    required int landings,
    required DateTime? check,
    required Licence licence,
    LicenceRating? rating,
  }) {
    DateTime until(DateTime d) => addMonths(d, months);
    final flying = _rolling(
      flown,
      amount: (f) => (f.pic + f.dual).inMinutes,
      needed: time.inMinutes,
      until: until,
    );
    final ldg = _rolling(
      flown,
      amount: (f) => f.landings,
      needed: landings,
      until: until,
    );
    final refresher = _rolling(
      flown,
      amount: (f) => f.dual.inMinutes,
      needed: 60,
      until: until,
    );
    final byExperience =
        [flying.validUntil, ldg.validUntil, refresher.validUntil].contains(null)
        ? null
        : [
            flying.validUntil!,
            ldg.validUntil!,
            refresher.validUntil!,
          ].reduce((a, b) => a.isBefore(b) ? a : b);
    final byCheck = check == null ? null : until(dateOnly(check));
    final validUntil = [byExperience, byCheck].nonNulls.fold<DateTime?>(
      null,
      (a, b) => a == null || b.isAfter(a) ? b : a,
    );
    final period = months == 12 ? '12 months' : '2 years';
    return CurrencyItem(
      key: key,
      kind: CurrencyKind.recency,
      title: title,
      subtitle: 'Last $period',
      reference: reference,
      validUntil: validUntil,
      requirementsTitle: 'In the last $period',
      requirements: [
        Requirement.time(
          'Flight time as PIC or dual',
          done: Duration(minutes: flying.done),
          needed: time,
        ),
        Requirement('Take-offs and landings', done: ldg.done, needed: landings),
        Requirement.time(
          'Refresher training with an instructor',
          done: Duration(minutes: refresher.done),
          needed: const Duration(hours: 1),
        ),
      ],
      notes: [
        if (byCheck != null)
          'Proficiency check on ${_date(dateOnly(check!))}: recent until '
              '${_date(byCheck)}.'
        else
          'Or pass a proficiency check with an examiner.',
      ],
      licenceId: licence.id,
      ratingId: rating?.id,
    );
  }

  // Helpers ------------------------------------------------------------------

  /// Whether [r] has an expiry date that is past.
  bool _expired(LicenceRating r) =>
      r.expiryDate != null && dateOnly(r.expiryDate!).isBefore(today);

  /// Flights flown from [from] to [to] (both included, and never after
  /// today) that [test] accepts.
  List<CurrencyFlight> _between(
    DateTime from,
    DateTime to,
    bool Function(CurrencyFlight) test,
  ) => [
    for (final f in _flown)
      if (!dateOnly(f.date).isBefore(from) &&
          !dateOnly(f.date).isAfter(to) &&
          test(f))
        f,
  ];

  static Duration _sum(
    Iterable<CurrencyFlight> flights,
    Duration Function(CurrencyFlight) of,
  ) => flights.fold(Duration.zero, (s, f) => s + of(f));

  /// A rolling-window rule: at least [needed] of [amount] in the flights
  /// that still count today, a flight on day d counting until [until](d).
  ///
  /// [flown] must be most recent first. The rule is met until the day the
  /// flight that reached [needed] stops counting; [done] is how much counts
  /// today.
  ({DateTime? validUntil, int done}) _rolling(
    List<CurrencyFlight> flown, {
    required int Function(CurrencyFlight) amount,
    required int needed,
    required DateTime Function(DateTime) until,
  }) {
    var done = 0;
    DateTime? validUntil;
    for (final f in flown) {
      final lastDay = until(dateOnly(f.date));
      if (lastDay.isBefore(today)) break;
      final a = amount(f);
      if (a <= 0) continue;
      done += a;
      if (validUntil == null && done >= needed) validUntil = lastDay;
    }
    return (validUntil: validUntil, done: done);
  }

  /// Calendar days, not 90 × 24 h: those land on the wrong day across a DST
  /// change.
  static DateTime _plus90Days(DateTime d) =>
      DateTime(d.year, d.month, d.day + 90);

  static String _date(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}
