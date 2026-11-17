import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/currency.dart';
import '../repositories/licence_repository.dart';
import '../services/currency_reminders.dart';
import '../services/database.dart';
import 'currency_settings_provider.dart';
import 'navigation_provider.dart';

final licencesStreamProvider = StreamProvider<List<LicenceWithRatings>>(
  (ref) => ref.watch(licenceRepositoryProvider).watchLicences(),
);

final licenceByIdStreamProvider =
    StreamProvider.family<LicenceWithRatings?, int>(
      (ref, id) => ref.watch(licenceRepositoryProvider).watchLicence(id),
    );

final medicalsStreamProvider = StreamProvider<List<MedicalCertificate>>(
  (ref) => ref.watch(licenceRepositoryProvider).watchMedicals(),
);

final medicalByIdStreamProvider =
    StreamProvider.family<MedicalCertificate?, int>(
      (ref, id) => ref.watch(licenceRepositoryProvider).watchMedical(id),
    );

/// The logbook as far back as any currency rule looks: 3 years for
/// instructor certificates, plus a margin for the period before expiry.
final currencyFlightsStreamProvider = StreamProvider<List<CurrencyFlight>>((
  ref,
) {
  final since = addMonths(dateOnly(DateTime.now()), -48);
  return ref
      .watch(licenceRepositoryProvider)
      .watchCurrencyFlights(since: since);
});

/// Every currency item, most urgent first.
final currencyItemsProvider = Provider<AsyncValue<List<CurrencyItem>>>((ref) {
  final licences = ref.watch(licencesStreamProvider);
  final medicals = ref.watch(medicalsStreamProvider);
  final flights = ref.watch(currencyFlightsStreamProvider);
  for (final value in [licences, medicals, flights]) {
    if (value case AsyncError(:final error, :final stackTrace)) {
      return AsyncError(error, stackTrace);
    }
  }
  if (!licences.hasValue || !medicals.hasValue || !flights.hasValue) {
    return const AsyncLoading();
  }
  final today = dateOnly(DateTime.now());
  final items = CurrencyCalculator(
    licences: licences.requireValue,
    medicals: medicals.requireValue,
    flights: flights.requireValue,
    today: today,
  ).compute();
  items.sort((a, b) {
    final ua = a.validUntil;
    final ub = b.validUntil;
    if (ua == null || ub == null) {
      return ua == null ? (ub == null ? 0 : -1) : 1;
    }
    return ua.compareTo(ub);
  });
  return AsyncData(items);
});

final currencyReminderServiceProvider = Provider<CurrencyReminderService>((
  ref,
) {
  final service = CurrencyReminderService();
  unawaited(
    service.initialize(
      onOpen: () => ref.read(mainTabProvider.notifier).select(MainTab.licences),
    ),
  );
  return service;
});

/// Keeps the scheduled reminders in step with the licences, the logbook and
/// the settings. Listen to it for as long as reminders should be kept up to
/// date.
final currencyReminderSyncProvider = Provider<void>((ref) {
  final service = ref.watch(currencyReminderServiceProvider);
  final settings = ref.watch(currencySettingsProvider);
  final items = ref.watch(currencyItemsProvider).value;
  if (!settings.loaded || items == null) return;
  final plan = planReminders(items, settings, DateTime.now());
  // Edits come in bursts (a flight and its crew, a licence and its
  // ratings): schedule once they settle.
  final timer = Timer(
    const Duration(seconds: 2),
    () => unawaited(service.schedule(plan)),
  );
  ref.onDispose(timer.cancel);
});
