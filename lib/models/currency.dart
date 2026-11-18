// What keeps a pilot's licences usable: validity dates of ratings and
// certificates, and recency worked out from the logbook.
//
// Rules from EASA Part-FCL (Easy Access Rules for Aircrew, October 2026
// edition: Regulation (EU) No 1178/2011 as last amended by Implementing
// Regulations (EU) 2024/2076, 2025/134 and 2026/781):
//  * FCL.060(b)(1): to carry passengers, 3 take-offs and landings as pilot
//    flying in the preceding 90 days in the same class or type;
//  * FCL.060(b)(2): as PIC at night with passengers, 1 of them at night, or
//    an IR;
//  * FCL.060(b)(3): cruise relief co-pilots;
//  * FCL.140.A, FCL.140.H, FCL.240.G: LAPL and GPL recency;
//  * FCL.205.G(a)(2): GPL passengers after 10 hours as PIC;
//  * FCL.710(d), FCL.140.A(c): SEP variants with another type of engine;
//  * FCL.740, FCL.740.A, FCL.740.H, Article 4f: validity, revalidation and
//    renewal of class and type ratings, VCA type ratings included;
//  * FCL.625, FCL.625.A, FCL.835(g): IR and BIR;
//  * FCL.815(d): mountain rating privileges;
//  * FCL.940.FI, FCL.1025: instructor and examiner certificates.
//
// The logbook only records landings, so every landing is taken to come with
// its take-off.
//
// Simulator sessions count where Part-FCL lets an FSTD stand in for the
// aircraft: their landings for FCL.060(b) when flown in an FFS, a
// proficiency check passed in one, and the refresher training of
// helicopter pilots (FCL.140.H(b), FCL.740.H(a)(2)(ii)(B)). Everything else
// asks for flight time.

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
    this.simulator,
    this.engineType,
    this.instrumentApproach = false,
    this.sessionInstruction = Duration.zero,
    this.mountainLandings = 0,
    this.cruiseRelief = false,
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

  /// The kind of device of a simulator session; null for a flight. A
  /// session has the class or type the device represents, and no time
  /// (it isn't flight time).
  final SimulatorKind? simulator;

  /// The aircraft's engine, telling SEP variants apart (FCL.710(d)).
  final EngineType? engineType;

  /// Whether the flight ended with an instrument approach procedure.
  final bool instrumentApproach;

  /// For a simulator session: its time, when received as instruction.
  final Duration sessionInstruction;

  /// Landings on a surface designated to require a mountain rating.
  final int mountainLandings;

  /// Whether the pilot flew as cruise relief co-pilot.
  final bool cruiseRelief;

  int get landings => dayLandings + nightLandings;

  /// Time with an instructor, in the aircraft or (for the rules that allow
  /// it) in an FSTD.
  Duration get instruction => dual + sessionInstruction;
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
    RatingKind.typeRating || RatingKind.vcaTypeRating =>
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

  /// The flights and simulator sessions that happened by the end of
  /// [today], most recent first.
  late final List<CurrencyFlight> _logged = [
    for (final f in flights)
      if (!dateOnly(f.date).isAfter(today)) f,
  ]..sort((a, b) => b.date.compareTo(a.date));

  /// The flights of [_logged]: what every rule but the few that accept an
  /// FSTD looks at.
  late final List<CurrencyFlight> _flown = [
    for (final f in _logged)
      if (f.simulator == null) f,
  ];

  /// FCL.060(b): flights, and sessions in an FFS.
  late final List<CurrencyFlight> _recencyFlown = [
    for (final f in _logged)
      if (f.simulator == null || f.simulator!.countsForRecency) f,
  ];

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
        // The mountain rating doesn't expire any more (FCL.815(d)): an
        // expiry date entered before that isn't one.
        if (r.expiryDate != null && r.kind != RatingKind.mountain)
          _ratingValidity(l.licence, r),
      for (final r in l.ratings)
        if (r.kind == RatingKind.mountain) _mountainRecency(l.licence, r),
      ..._laplRecency(l),
      ..._gplRecency(l),
    ],
    ..._passengerRecency(),
    ..._cruiseReliefRecency(),
    ..._sepVariantRecency(),
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

  /// The note on an EBT practical assessment standing in for the check.
  static String _ebtNote(String reference) =>
      'An EBT practical assessment (Appendix 10) at an operator with an EBT '
      'programme for it counts as the proficiency check ($reference).';

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
    final windowNote =
        '${today.isBefore(checkWindow) ? 'From' : 'Since'} '
        '${_date(checkWindow)}, the 3 months before expiry.';

    /// Revalidation by proficiency check, under [reference]: in the 3
    /// months before expiry, or earlier with the validity starting from the
    /// check ([earlierRef]). [ebtRef]: where an EBT practical assessment
    /// stands in for it.
    RequirementSection checkSection(
      String reference, {
      String title = 'Revalidation by proficiency check',
      String label = 'Proficiency check with an examiner',
      String earlierRef = 'FCL.740(a)(1)',
      String? note,
      String? ebtRef,
    }) => RequirementSection(
      title: title,
      reference: reference,
      requirements: [
        Requirement(label, done: checkInPeriod ? 1 : 0, needed: 1),
      ],
      notes: [
        ?note,
        windowNote,
        'Passed earlier, the new validity period starts from the date of '
            'the check ($earlierRef).',
        if (ebtRef != null) _ebtNote(ebtRef),
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
    final helicopter = licence.category == AircraftCategory.helicopter;
    // Once expired, a rating can't be revalidated any more: it has to be
    // renewed.
    if (expiry.isBefore(today)) {
      final (renewalRef, renewal) = _renewal(r, expiry, helicopter: helicopter);
      return CurrencyItem(
        key: 'rating:${r.id}',
        kind: CurrencyKind.validity,
        title: r.title,
        subtitle: licence.title,
        reference: renewalRef,
        validUntil: expiry,
        notes: [
          ...renewal,
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
          final held = _classesHeld;
          final counted = {c!};
          // FCL.740.A(b)(2): SEP (L) and TMG revalidate each other.
          if ((c == AircraftClass.sepLand || c == AircraftClass.tmg) &&
              held.contains(AircraftClass.sepLand) &&
              held.contains(AircraftClass.tmg)) {
            counted.addAll(const [AircraftClass.sepLand, AircraftClass.tmg]);
          }
          // FCL.740.A(b)(4): so do SEP (L) and SEP (S), with some of the
          // experience in each.
          final landAndSea =
              (c == AircraftClass.sepLand || c == AircraftClass.sepSea) &&
              held.contains(AircraftClass.sepLand) &&
              held.contains(AircraftClass.sepSea);
          if (landAndSea) {
            counted.addAll(const [AircraftClass.sepLand, AircraftClass.sepSea]);
          }
          final from = addMonths(expiry, -12);
          final window = _between(
            from,
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
            if (landAndSea)
              for (final each in const [
                AircraftClass.sepLand,
                AircraftClass.sepSea,
              ]) ...[
                Requirement.time(
                  'PIC time in ${each.label}',
                  done: _sum(
                    window.where((f) => f.aircraftClass == each),
                    (f) => f.pic,
                  ),
                  needed: const Duration(hours: 1),
                ),
                Requirement(
                  'Take-offs and landings in ${each.label}',
                  done: window
                      .where((f) => f.aircraftClass == each)
                      .fold(0, (s, f) => s + f.landings),
                  needed: 6,
                ),
              ],
          ];
          notes.add(
            'Counted from ${_date(from)}, the 12 months before expiry'
            '${counted.length > 1 ? ', in ${[for (final k in AircraftClass.values)
                    if (counted.contains(k)) k.label].join(' and ')} together' : ''}.',
          );
          notes.add(
            'The refresher training is flown with a flight or class rating '
            'instructor (FI or CRI). It isn\'t needed after a class or type '
            'rating proficiency check, skill test, EBT practical assessment '
            'or assessment of competence in any class or type of aeroplane '
            '(FCL.740.A(b)(1)(ii)(C)).',
          );
          if (landAndSea) {
            notes.add(
              'Holding SEP (L) and SEP (S), the experience counts for both, '
              'with at least 1 hour of PIC time and 6 take-offs and landings '
              'in each (FCL.740.A(b)(4)).',
            );
          }
          sections.add(
            checkSection(
              'FCL.740.A(b)(1)(i)',
              note: 'Instead of revalidation by experience.',
            ),
          );
        } else if (c == AircraftClass.setLand || c == AircraftClass.setSea) {
          // The check is the only way: its section says it all.
          reference = null;
          sections.add(
            checkSection('FCL.740.A(b)(3)', ebtRef: 'FCL.740(a)(2)'),
          );
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
              ebtRef: 'FCL.740.A(a)(1)',
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
              ebtRef: 'FCL.740.A(a)(1)',
            ),
          );
        } else if (helicopter) {
          reference = 'FCL.740.H(a)(1)(i)';
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
              'FCL.740.H(a)(1)(ii)',
              note: 'Needed as well as the 2 hours on type.',
              ebtRef: 'FCL.740(a)(2)',
            ),
          );
          if (r.lightSingleEngine) {
            sections.add(
              _lightHelicopterSection(r, periodStart, checkWindow, expiry),
            );
          }
          notes.add(
            'Holding several single-engine piston types (or single-engine '
            'turbine types up to 3 175 kg, with 300 hours as PIC on '
            'helicopters and 15 hours on each type), a check or refresher '
            'training in one of them revalidates the others, with 2 hours '
            '(after a check) or 6 hours (after a refresher training) as PIC '
            'on each of them during the validity period. It is flown on a '
            'different type each time (FCL.740.H(b), (c)).',
          );
        } else {
          notes.add(checkInWindow);
        }
      case RatingKind.vcaTypeRating:
        reference = 'Article 4f(5)(a)(i)';
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
            'Article 4f(5)(a)(ii)',
            note:
                'Needed as well as the 2 hours on type, in the aircraft or '
                'an FSTD representing it.',
            earlierRef: 'Article 4f(5)(a)(ii)',
          ),
        );
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
            ebtRef: 'FCL.625(b)(4)',
          ),
        );
        if (aeroplane) {
          notes.add(
            'Not combined with a class or type rating check, it may be '
            'flown in an FNPT II or FFS, as long as at least every other IR '
            'revalidation check is flown in an aeroplane (FCL.625.A(a)(4)).',
          );
        }
      case RatingKind.basicInstrument:
        reference = 'FCL.835(g)(2)(ii)';
        final window = _between(periodStart, expiry, (_) => true);
        final asPicUnderIfr = window.where((f) => f.picIfr > Duration.zero);
        requirementsTitle = 'Revalidation by experience';
        requirements = [
          Requirement.time(
            'PIC time under IFR',
            done: _sum(window, (f) => f.picIfr),
            needed: const Duration(hours: 6),
          ),
          Requirement(
            'Instrument approach procedures',
            done: asPicUnderIfr.where((f) => f.instrumentApproach).length,
            needed: 3,
          ),
          Requirement(
            'Training flight of 1 hour with an instructor',
            done: window.any((f) => f.dual >= const Duration(hours: 1)) ? 1 : 0,
            needed: 1,
          ),
        ];
        notes.add(
          'During the validity period. The approaches are flown as PIC under '
          'IFR, the training flight with an instructor holding privileges '
          'for the BIR. For a multi-engine BIR, the training flight is in a '
          'multi-engine aeroplane (FCL.835(g)(7)).',
        );
        notes.add(
          'At least every other revalidation has to be a proficiency check '
          'in an aeroplane (FCL.835(g)(3)).',
        );
        sections.add(
          checkSection(
            'FCL.835(g)(2)(i)',
            label: 'BIR proficiency check',
            earlierRef: 'FCL.835(g)(4)',
            note:
                'Instead of the experience. It may be combined with the '
                'class rating proficiency check (FCL.835(g)(8)).',
          ),
        );
      case RatingKind.instructor:
        final named = normalizeTypeRating(r.name ?? '');
        if (named.startsWith('FI')) {
          reference = 'FCL.940.FI(a)';
          final airship = named.contains('(AS)');
          final outsidePartFcl =
              named.startsWith('FI(S)') || named.startsWith('FI(B)');
          if (outsidePartFcl) {
            reference = null;
            notes.add(
              'Sailplane and balloon instructors are revalidated under '
              'Part-SFCL and Part-BFCL.',
            );
          } else {
            final hours = airship ? 20 : 50;
            final window = _between(periodStart, expiry, (_) => true);
            requirementsTitle = 'During the validity period';
            requirements = [
              Requirement.time(
                'Flight instruction',
                done: _sum(window, (f) => f.instructor),
                needed: Duration(hours: hours),
              ),
            ];
            notes.add(
              'Revalidation needs 2 of: $hours hours of flight instruction '
              'as instructor or examiner, instructor refresher training, an '
              'assessment of competence in the 12 months before expiry. The '
              'assessment of competence is needed at least every '
              '${airship ? 'third' : 'other'} revalidation.',
            );
            if (!named.contains('(G)')) {
              notes.add(
                'To keep the privileges to instruct for the '
                '${airship ? 'IR' : 'BIR and the IR'}, 10 of those hours are '
                '${airship ? 'IR' : 'BIR or IR'} instruction in the 12 months '
                'before expiry.',
              );
            }
          }
        }
      case RatingKind.examiner:
        reference = 'FCL.1025(b)';
        notes.add(
          'Revalidation needs at least 6 skill tests, proficiency checks, '
          'assessments of competence or EBT evaluation phases before expiry, '
          'one of them in the 12 months before expiry observed by the '
          'authority or a senior examiner (or an assessment of competence), '
          'and an examiner refresher course in the 12 months before expiry.',
        );
      case RatingKind.mountain:
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

  /// FCL.740.H(a)(2)(ii): a single-engine helicopter up to 3 175 kg may be
  /// revalidated with 6 hours as PIC on type during the validity period and
  /// a refresher training in the 3 months before expiry, in the helicopter
  /// or an FSTD of the type.
  RequirementSection _lightHelicopterSection(
    LicenceRating r,
    DateTime periodStart,
    DateTime checkWindow,
    DateTime expiry,
  ) {
    final onType = _between(periodStart, expiry, r.covers);
    final refresher = _between(checkWindow, expiry, r.covers, sessions: true);
    return RequirementSection(
      title: 'Or revalidation by experience and refresher training',
      reference: 'FCL.740.H(a)(2)(ii)',
      requirements: [
        Requirement.time(
          'PIC time on type during the validity period',
          done: _sum(onType, (f) => f.pic),
          needed: const Duration(hours: 6),
        ),
        Requirement.time(
          'Refresher training with an instructor in the 3 months before '
          'expiry',
          done: _sum(refresher, (f) => f.instruction),
          needed: const Duration(hours: 1),
        ),
      ],
      notes: [
        'Instead of the proficiency check, for single-engine helicopters '
            'with a maximum take-off mass up to 3 175 kg.',
        'The refresher training may be flown in the helicopter, in an FSTD '
            'representing the type, or both '
            '(${today.isBefore(checkWindow) ? 'from' : 'since'} '
            '${_date(checkWindow)}).',
        'The instructor signs the refresher training in the logbook.',
      ],
    );
  }

  /// The rule and what to do to renew [r], expired on [expiry].
  (String?, List<String>) _renewal(
    LicenceRating r,
    DateTime expiry, {
    required bool helicopter,
  }) {
    const check =
        'then pass a proficiency check (Appendix 9) or an EBT practical '
        'assessment (Appendix 10).';
    switch (r.kind) {
      case RatingKind.classRating:
        final c = r.aircraftClass;
        final singlePiston =
            c == AircraftClass.sepLand ||
            c == AircraftClass.sepSea ||
            c == AircraftClass.tmg;
        final within3Years = !addMonths(expiry, 36).isBefore(today);
        return (
          'FCL.740(b)',
          [
            singlePiston
                ? 'Expired: to renew it, be assessed by an ATO, a DTO'
                      '${within3Years ? ' or an instructor' : ''}, who '
                      'decides whether you need refresher training, and '
                      'complete it with them if so; then pass a proficiency '
                      'check.'
                : 'Expired: to renew it, be assessed by an ATO (or an EBT '
                      'operator approved for it), who decides whether you '
                      'need refresher training, and complete it with them '
                      'if so; $check',
            if (singlePiston && within3Years)
              'An instructor may do the assessment and refresher training '
                  'until ${_date(addMonths(expiry, 36))}, 3 years after '
                  'expiry, for a non-high-performance aeroplane '
                  '(FCL.740(b)(1)(iii)).',
          ],
        );
      case RatingKind.typeRating:
      case RatingKind.vcaTypeRating:
        return (
          'FCL.740(b)',
          [
            'Expired: to renew it, be assessed by an ATO'
                '${helicopter && r.lightSingleEngine ? ' or a DTO' : ''} '
                '(or an EBT operator approved for it), who decides whether '
                'you need refresher training, and complete it with them if '
                'so; $check',
          ],
        );
      case RatingKind.instrument:
        return (
          'FCL.625(c)',
          [
            'Expired: to renew it, be assessed by an ATO (or an EBT operator '
                'approved for it), who decides whether you need refresher '
                'training, and complete it with them if so; then pass an IR '
                'proficiency check or an EBT practical assessment. You need '
                'the relevant class or type rating.',
            if (addMonths(expiry, 84).isBefore(today))
              'Not revalidated or renewed for 7 years: the IR theoretical '
                  'knowledge examination and skill test have to be passed '
                  'again (FCL.625(d)).',
          ],
        );
      case RatingKind.basicInstrument:
        final within3Years = !addMonths(expiry, 36).isBefore(today);
        return (
          'FCL.835(g)(6)',
          [
            'Expired: to renew it, complete refresher training if needed, at '
                'an ATO${within3Years ? ' or with a BIR instructor' : ''}, '
                'then pass a proficiency check in an aeroplane.',
          ],
        );
      case RatingKind.instructor:
        final named = normalizeTypeRating(r.name ?? '');
        return named.startsWith('FI')
            ? (
                'FCL.940.FI(b)',
                [
                  'Expired: to renew it, complete instructor refresher '
                      'training at an ATO or the authority and an assessment '
                      'of competence, both in the 12 months before applying.',
                ],
              )
            : (r.kind.reference, const []);
      case RatingKind.examiner:
        return (
          'FCL.1025(c)',
          [
            'Expired: to renew it, complete an examiner refresher course and '
                'an assessment of competence (FCL.1020) in the 12 months '
                'before applying.',
          ],
        );
      default:
        return (r.kind.reference, const []);
    }
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
  /// A check in an FSTD counts too: proficiency checks are often flown in
  /// one, and an FSTD session is flown on instruments.
  static bool _checksFor(LicenceRating r, CurrencyFlight f) {
    final device = f.simulator;
    if (device != null && !device.allowsProficiencyCheck) return false;
    return switch (r.kind) {
      RatingKind.instrument ||
      RatingKind.basicInstrument => f.ifr > Duration.zero || device != null,
      _ => r.covers(f),
    };
  }

  /// The day of the last flight logged as a proficiency check that [test]
  /// accepts.
  DateTime? _lastCheckFlight(bool Function(CurrencyFlight) test) {
    for (final f in _logged) {
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
        // FCL.060(b): aeroplanes, helicopters, powered-lift aircraft,
        // airships, VCA (flown on aeroplane or helicopter licences) and
        // gyroplanes.
        final powered = const [
          AircraftCategory.aeroplane,
          AircraftCategory.helicopter,
          AircraftCategory.poweredLift,
          AircraftCategory.airship,
          AircraftCategory.gyroplane,
        ].contains(l.licence.category);
        // No currency to keep on a rating that has expired: it has to be
        // renewed first.
        if (!powered || _expired(r)) continue;
        final key = switch (r.kind) {
          RatingKind.classRating when r.aircraftClass != null =>
            'class:${r.aircraftClass!.name}',
          RatingKind.typeRating || RatingKind.vcaTypeRating
              when (r.name?.trim() ?? '').isNotEmpty =>
            'type:${normalizeTypeRating(r.name!)}',
          _ => null,
        };
        if (key != null) ratings.putIfAbsent(key, () => (l.licence, r));
      }
    }

    final items = <CurrencyItem>[];
    for (final MapEntry(key: key, value: (licence, rating))
        in ratings.entries) {
      final covered = _recencyFlown.where(rating.covers).toList();
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
          notes: const [
            'As pilot flying, in the aircraft or an FFS representing it. '
                'Needed as PIC or co-pilot.',
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
              _lastCheckFlight(
                (f) => f.simulator == null && classes.contains(f.aircraftClass),
              ),
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
                // FCL.140.H(b): in the helicopter, an FSTD of the type, or
                // both.
                refresher: _logged.where(r.covers).toList(),
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

  /// [refresher]: where the refresher training may be flown, the flights
  /// of [flown] when not given.
  CurrencyItem _laplItem({
    required String key,
    required String title,
    required String reference,
    required List<CurrencyFlight> flown,
    List<CurrencyFlight>? refresher,
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
    final refresherTraining = _rolling(
      refresher ?? flown,
      amount: (f) => f.instruction.inMinutes,
      needed: 60,
      until: until,
    );
    final byExperience =
        [
          flying.validUntil,
          ldg.validUntil,
          refresherTraining.validUntil,
        ].contains(null)
        ? null
        : [
            flying.validUntil!,
            ldg.validUntil!,
            refresherTraining.validUntil!,
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
          done: Duration(minutes: refresherTraining.done),
          needed: const Duration(hours: 1),
        ),
      ],
      notes: [
        if (byCheck != null)
          'Proficiency check on ${_date(dateOnly(check!))}: recent until '
              '${_date(byCheck)}.'
        else
          'Or pass a proficiency check with an examiner.',
        if (refresher != null)
          'The refresher training may be flown in the aircraft, in an FSTD '
              'representing the type, or both.',
        'The instructor or examiner signs the dual flights, the refresher '
            'training and the check in the logbook.',
      ],
      licenceId: licence.id,
      ratingId: rating?.id,
    );
  }

  /// FCL.815(d): the privileges of a mountain rating need, in the last 2
  /// years, 6 landings on surfaces designated to require one, or a
  /// proficiency check.
  CurrencyItem _mountainRecency(Licence licence, LicenceRating r) {
    DateTime until(DateTime d) => addMonths(d, 24);
    final landings = _rolling(
      _flown,
      amount: (f) => f.mountainLandings,
      needed: 6,
      until: until,
    );
    final check = r.lastCheckDate == null ? null : dateOnly(r.lastCheckDate!);
    final byCheck = check == null ? null : until(check);
    return CurrencyItem(
      key: 'mountain:${r.id}',
      kind: CurrencyKind.recency,
      title: '${r.title} privileges',
      subtitle: 'Last 2 years',
      reference: 'FCL.815(d)',
      validUntil: _latest(landings.validUntil, byCheck),
      requirementsTitle: 'In the last 2 years',
      requirements: [
        Requirement(
          'Landings on mountain surfaces',
          done: landings.done,
          needed: 6,
        ),
      ],
      notes: [
        if (byCheck != null)
          'Proficiency check on ${_date(check!)}: privileges until '
              '${_date(byCheck)}.'
        else
          'Or pass a proficiency check, signed by the examiner in the '
              'logbook.',
        'Landings on surfaces designated to require a mountain rating are '
            'counted when logging the flight. The rating itself no longer '
            'expires.',
      ],
      licenceId: licence.id,
      ratingId: r.id,
    );
  }

  /// FCL.240.G: GPL recency, in each class or type held (or in the SPG
  /// class when none is entered); FCL.205.G(a)(2): passengers only after
  /// 10 hours as PIC on gyroplanes once the licence is issued.
  List<CurrencyItem> _gplRecency(LicenceWithRatings l) {
    final licence = l.licence;
    if (licence.kind != LicenceKind.gpl) return const [];
    final privileges = [
      for (final r in l.ratings)
        if (((r.kind == RatingKind.classRating &&
                    r.aircraftClass == AircraftClass.spg) ||
                r.kind == RatingKind.typeRating) &&
            !_expired(r))
          r,
    ];
    bool spg(CurrencyFlight f) => f.aircraftClass == AircraftClass.spg;
    bool gyroplane(CurrencyFlight f) =>
        spg(f) ||
        l.ratings.any((r) => r.kind == RatingKind.typeRating && r.covers(f));
    final items = <CurrencyItem>[
      if (privileges.isEmpty)
        _laplItem(
          key: 'gpl:${licence.id}',
          title: '${licence.title} recency',
          reference: 'FCL.240.G',
          flown: _flown.where(spg).toList(),
          months: 24,
          time: const Duration(hours: 12),
          landings: 12,
          check: _latest(
            licence.proficiencyCheckDate == null
                ? null
                : dateOnly(licence.proficiencyCheckDate!),
            _lastCheckFlight((f) => f.simulator == null && spg(f)),
          ),
          licence: licence,
        )
      else
        for (final r in privileges)
          _laplItem(
            key: 'gpl:${licence.id}:${r.id}',
            title: '${licence.title} recency on ${r.title}',
            reference: 'FCL.240.G',
            flown: _flown.where(r.covers).toList(),
            months: 24,
            time: const Duration(hours: 12),
            landings: 12,
            check: _lastCheck(r),
            licence: licence,
            rating: r,
          ),
    ];
    final issued = licence.issueDate == null
        ? null
        : dateOnly(licence.issueDate!);
    if (issued != null) {
      final pic = _sum(
        _flown.where((f) => !dateOnly(f.date).isBefore(issued) && gyroplane(f)),
        (f) => f.pic,
      );
      const needed = Duration(hours: 10);
      // Once flown, the condition is met for good.
      if (pic < needed) {
        items.add(
          CurrencyItem(
            key: 'gpl-passengers:${licence.id}',
            kind: CurrencyKind.recency,
            title: 'Passengers on ${licence.title}',
            reference: 'FCL.205.G(a)(2)',
            validUntil: null,
            requirementsTitle: 'Since the licence was issued',
            requirements: [
              Requirement.time(
                'PIC time on gyroplanes',
                done: pic,
                needed: needed,
              ),
            ],
            notes: [
              'Passengers can be carried after 10 hours as PIC on '
                  'gyroplanes flown since the licence was issued '
                  '(${_date(issued)}).',
            ],
            licenceId: licence.id,
          ),
        );
      }
    }
    return items;
  }

  /// FCL.060(b)(3): a cruise relief co-pilot needs, in the preceding 90
  /// days, 3 sectors as cruise relief co-pilot in the type, the operator's
  /// training with 3 such sectors in an FSTD, recurrent training (ORO.FC) or
  /// a proficiency check for cruise relief co-pilots. Shown for the type
  /// ratings flown as cruise relief co-pilot in the last year.
  List<CurrencyItem> _cruiseReliefRecency() {
    final yearAgo = addMonths(today, -12);
    final ratings = <String, (Licence, LicenceRating)>{};
    for (final l in licences) {
      for (final r in l.ratings) {
        if (r.kind != RatingKind.typeRating ||
            (r.name?.trim() ?? '').isEmpty ||
            _expired(r)) {
          continue;
        }
        final flownAsCrcp = _flown.any(
          (f) =>
              f.cruiseRelief &&
              r.covers(f) &&
              !dateOnly(f.date).isBefore(yearAgo),
        );
        if (flownAsCrcp) {
          ratings.putIfAbsent(
            normalizeTypeRating(r.name!),
            () => (l.licence, r),
          );
        }
      }
    }
    return [
      for (final MapEntry(key: type, value: (licence, rating))
          in ratings.entries)
        () {
          final sectors = _rolling(
            _flown.where((f) => f.cruiseRelief && rating.covers(f)).toList(),
            amount: (_) => 1,
            needed: 3,
            until: _plus90Days,
          );
          final check = _lastCheckFlight((f) => _checksFor(rating, f));
          final byCheck = check == null ? null : _plus90Days(check);
          return CurrencyItem(
            key: 'crcp:type:$type',
            kind: CurrencyKind.recency,
            title: 'Cruise relief on ${rating.title}',
            subtitle: 'Last 90 days',
            reference: 'FCL.060(b)(3)',
            validUntil: _latest(sectors.validUntil, byCheck),
            requirementsTitle: 'In the last 90 days',
            requirements: [
              Requirement(
                'Sectors as cruise relief co-pilot',
                done: sectors.done,
                needed: 3,
              ),
            ],
            notes: const [
              'Or, in the last 90 days: the operator\'s training with 3 '
                  'sectors as cruise relief co-pilot in an FSTD of the type, '
                  'recurrent training under ORO.FC, or a proficiency check '
                  'for cruise relief co-pilots.',
            ],
            licenceId: licence.id,
            ratingId: rating.id,
          );
        }(),
    ];
  }

  /// FCL.710(d), (da) and FCL.140.A(c): the privileges for SEP variants
  /// with another type of engine (piston, electric, hybrid) need flying one
  /// of them in the last 2 years; otherwise further differences training, a
  /// proficiency check or a refresher training in one first. Shown once SEP
  /// aeroplanes with more than one type of engine have been flown.
  List<CurrencyItem> _sepVariantRecency() {
    final holdsSep =
        _classesHeld.contains(AircraftClass.sepLand) ||
        _classesHeld.contains(AircraftClass.sepSea) ||
        licences.any(
          (l) =>
              l.licence.kind == LicenceKind.lapl &&
              l.licence.category == AircraftCategory.aeroplane,
        );
    if (!holdsSep) return const [];
    final lastFlown = <EngineType, DateTime>{};
    for (final f in _flown) {
      final engine = f.engineType;
      if (engine == null ||
          (f.aircraftClass != AircraftClass.sepLand &&
              f.aircraftClass != AircraftClass.sepSea)) {
        continue;
      }
      // Most recent first: the first one is the last flown.
      lastFlown.putIfAbsent(engine, () => dateOnly(f.date));
    }
    if (lastFlown.length < 2) return const [];
    return [
      for (final MapEntry(key: engine, value: last) in lastFlown.entries)
        CurrencyItem(
          key: 'sep-variant:${engine.name}',
          kind: CurrencyKind.recency,
          title: 'SEP variants, ${engine.name} engine',
          subtitle: 'Last 2 years',
          reference: 'FCL.710(d)',
          validUntil: addMonths(last, 24),
          notes: [
            'Last flown on ${_date(last)}.',
            'Not flown for 2 years, the privileges for SEP variants with this '
                'type of engine need further differences training, a '
                'proficiency check or a refresher training with an '
                'instructor in one of them first (FCL.710(d), '
                'FCL.140.A(c)).',
          ],
        ),
    ];
  }

  // Helpers ------------------------------------------------------------------

  /// Whether [r] has an expiry date that is past.
  bool _expired(LicenceRating r) =>
      r.expiryDate != null && dateOnly(r.expiryDate!).isBefore(today);

  /// Flights flown from [from] to [to] (both included, and never after
  /// today) that [test] accepts; simulator sessions as well with
  /// [sessions].
  List<CurrencyFlight> _between(
    DateTime from,
    DateTime to,
    bool Function(CurrencyFlight) test, {
    bool sessions = false,
  }) => [
    for (final f in sessions ? _logged : _flown)
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
