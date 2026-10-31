import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/catalog/catalog_models.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/changes/change_set_applier.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/events/domain_event_bus.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/settings/settings_op_handler.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/progress/application/ramadan_comparison_provider.dart';
import 'package:fb_mobile/features/progress/application/weight_graph_providers.dart';
import 'package:fb_mobile/features/ramadan/ramadan.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/db/support/db_support.dart';
import '../diary/support/diary_fixtures.dart';
import '../diary/support/diary_harness.dart' show newEntry;

/// Ramallah, the owner's city (A05b).
const _ramallah = CatalogCity(
  id: 'city:282239',
  nameEn: 'Ramallah',
  nameAr: 'رام الله',
  countryCode: 'PS',
  population: 24599,
  timezone: 'Asia/Hebron',
  latitude: 31.89964,
  longitude: 35.20422,
);

// Ramadan 1448 (Umm al-Qura): Mon 2027-02-08 … Mon 2027-03-08.
final _start = LocalDate(2027, 2, 8);

/// One device over the journey: the database and the writer persist; each
/// moment gets a container with its clock (Palestine, UTC+2 in winter).
final class _Device {
  new() {
    addTearDown(bus.close);
    applier = ChangeSetApplier(
      db: db,
      tables: db.syncedTables,
      handlers: (db) => [SettingsOpHandler(db.settingsKv), DiaryOpHandler(db)],
      clock: clock,
      ids: ids,
      deviceId: () async => testDevice,
      events: bus,
    );
  }

  final AppDatabase db = memoryDatabase();
  final DomainEventBus bus = DomainEventBus();
  final ManualClock clock = ManualClock(DateTime.utc(2027), offsetMinutes: 120);
  final SequenceIdGenerator ids = SequenceIdGenerator();
  late final ChangeSetApplier<AppDatabase> applier;

  /// A container at local [hour]:[minute] on [date].
  ProviderContainer at(LocalDate date, int hour, [int minute = 0]) {
    clock.utc = DateTime.utc(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    ).subtract(const Duration(hours: 2));
    final undo = UndoStack(revert: applier.revert, clock: clock);
    addTearDown(undo.dispose);
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        changeSetApplierProvider.overrideWithValue(applier),
        clockProvider.overrideWithValue(clock),
        idGeneratorProvider.overrideWithValue(ids),
        undoStackProvider.overrideWithValue(undo),
        todayProvider.overrideWith((ref) => Stream.value(date)),
        selectedCityProvider.overrideWith((ref) async => _ramallah),
      ],
    );
    addTearDown(c.dispose);
    // Keep the auto-disposed chain alive while a test awaits it.
    c.listen(ramadanCalendarProvider, (_, _) {});
    return c;
  }

  /// Logs one entry now without a slot choice, the way the add flow does:
  /// the day's assignment picks the slot.
  Future<String> logNow(ProviderContainer c, int n) async {
    final now = EntryTime.now(clock);
    final slots = await _get(
      c,
      daySlotsProvider(now.localDate),
      daySlotsProvider(now.localDate).future,
    );
    final slot = slots.assign(now.localDateTime.minuteOfDay)!;
    final result = await applier.apply(
      ChangeSet([
        LogEntries([newEntry(n, when: EntryWhen.at(now), slotId: slot)]),
      ], origin: Origin.direct),
    );
    expect(result, isA<Applied>());
    return slot;
  }
}

/// [provider]'s value, listened to while it loads (an auto-disposed
/// provider read once would be disposed mid-load).
Future<T> _get<T>(
  ProviderContainer c,
  ProviderListenable<AsyncValue<T>> provider,
  ProviderListenable<Future<T>> future,
) async {
  final sub = c.listen(provider, (_, _) {});
  try {
    return await c.read(future);
  } finally {
    sub.close();
  }
}

void main() {
  test('J11 a Ramadan day: proposed two days before, accepted; suhoor at '
      '03:30 in Suhoor on the fasting day, iftar in Iftar; charts shaded; a '
      'not-fasting day and the day after Ramadan use the normal meals; the '
      'comparison shows', () async {
    final d = _Device();

    // Before the proposal window: nothing to propose.
    var c = d.at(_start.plusDays(-4), 10);
    expect(
      await _get(c, ramadanProposalProvider, ramadanProposalProvider.future),
      isNull,
    );

    // LC-031: two days before, the proposal; Switch on.
    c = d.at(_start.plusDays(-2), 10);
    final proposed = await _get(
      c,
      ramadanProposalProvider,
      ramadanProposalProvider.future,
    );
    expect(proposed?.hijriYear, 1448);
    final outcome = await c
        .read(settingsActionsProvider)
        .setRamadanSeason(RamadanSeason(hijriYear: 1448, on: true));
    expect(outcome, isA<SettingsDone>());
    c = d.at(_start.plusDays(-2), 10, 1);
    expect(
      await _get(c, ramadanProposalProvider, ramadanProposalProvider.future),
      isNull,
    );
    expect(
      (await _get(
        c,
        daySlotsProvider(_start.plusDays(-1)),
        daySlotsProvider(_start.plusDays(-1)).future,
      )).mode,
      SlotMode.normal,
      reason: 'the day before Ramadan',
    );

    // Day 3 of Ramadan, 03:30: suhoor (T31: the calendar day eaten).
    final day3 = _start.plusDays(2);
    c = d.at(day3, 3, 30);
    final slots = await _get(
      c,
      daySlotsProvider(day3),
      daySlotsProvider(day3).future,
    );
    expect(slots.mode, SlotMode.ramadan);
    expect(await d.logNow(c, 1), RamadanSlots.suhoorId);
    final suhoor = await (d.db.select(
      d.db.diaryEntries,
    )..where((t) => t.id.equals(fixtureId(1)))).getSingle();
    expect(suhoor.localDate, '$day3');
    final times = (await _get(
      c,
      prayerTimesProvider(day3),
      prayerTimesProvider(day3).future,
    ))!;
    // Fajr in Ramallah is around 05:00 then; Suhoor ends at Fajr.
    expect(times.fajrMinute, inInclusiveRange(4 * 60 + 50, 5 * 60 + 10));
    expect(
      slots.slots.firstWhere((s) => s.id == RamadanSlots.suhoorId).window,
      TimeWindow(times.fajrMinute - 180, times.fajrMinute),
    );
    expect(
      (await _get(
        c,
        ramadanDayProvider(day3),
        ramadanDayProvider(day3).future,
      ))?.day,
      3,
    );

    // Iftar, 20 minutes after Maghrib.
    final iftarAt = times.maghribMinute + 20;
    c = d.at(day3, iftarAt ~/ 60, iftarAt % 60);
    expect(await d.logNow(c, 2), RamadanSlots.iftarId);
    expect(c.read(chartHighlightPeriodsProvider), isEmpty, reason: 'loading');
    await _get(c, ramadanOnPeriodsProvider, ramadanOnPeriodsProvider.future);
    expect(c.read(chartHighlightPeriodsProvider), [
      (start: _start, end: LocalDate(2027, 3, 8)),
    ]);

    // LC-034: day 4 not fasting → normal meals that day (a setting with
    // Undo; the diary's day marks are untouched, A41a fix 1).
    final day4 = _start.plusDays(3);
    expect(
      await c
          .read(settingsActionsProvider)
          .setNotFasting(day4, notFasting: true),
      isA<SettingsDone>(),
    );
    expect(await d.db.select(d.db.dayMarks).get(), isEmpty);
    c = d.at(day4, 18);
    expect(
      (await _get(
        c,
        daySlotsProvider(day4),
        daySlotsProvider(day4).future,
      )).mode,
      SlotMode.normal,
    );
    expect(await d.logNow(c, 3), DefaultSlots.dinnerId);

    // LC-030, fix 3: the calendar's first day of Shawwal (2027-03-09)
    // starts with normal meals, but the moon wasn't seen: that morning the
    // user can still add the day to Ramadan, and it becomes a fasting day.
    final shawwal1 = LocalDate(2027, 3, 9);
    c = d.at(shawwal1, 8);
    expect(
      (await _get(
        c,
        daySlotsProvider(shawwal1),
        daySlotsProvider(shawwal1).future,
      )).mode,
      SlotMode.normal,
    );
    final status = (await _get(
      c,
      ramadanStatusProvider,
      ramadanStatusProvider.future,
    ))!;
    expect(status.period.hijriYear, 1448, reason: 'not next year');
    expect(
      await c
          .read(settingsActionsProvider)
          .setRamadanSeason(status.season!.copyWith(endShift: 1)),
      isA<SettingsDone>(),
    );
    c = d.at(shawwal1, 8, 1);
    expect(
      (await _get(
        c,
        daySlotsProvider(shawwal1),
        daySlotsProvider(shawwal1).future,
      )).mode,
      SlotMode.ramadan,
    );

    // After Ramadan: normal meals; the comparison is still shown.
    final after = LocalDate(2027, 3, 10);
    c = d.at(after, 18);
    expect(
      (await _get(
        c,
        daySlotsProvider(after),
        daySlotsProvider(after).future,
      )).mode,
      SlotMode.normal,
    );
    final comparison = (await _get(
      c,
      ramadanComparisonProvider,
      ramadanComparisonProvider.future,
    ))!;
    expect(comparison.period.hijriYear, 1448);
    expect(comparison.inProgress, isFalse);
    expect(comparison.ramadan.loggedDays, 2);
  });
}
