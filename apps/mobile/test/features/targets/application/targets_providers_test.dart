import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';

import '../../diary/support/diary_fixtures.dart';
import 'targets_app_harness.dart';

/// [dayTargetsProvider] for [date] once the streams have settled.
Future<DayTargets?> settled(ProviderContainer c, LocalDate date) async {
  await pumpEventQueue();
  return await c.read(dayTargetsProvider(date).future);
}

void main() {
  test('UX-050 TG-021 before setup the providers are empty and dayTargets is '
      'null (eaten mode); after setup they follow the stored rows and the '
      'explanation reproduces the base', () async {
    final h = TargetsAppHarness();
    final c = h.container();
    for (final provider in <ProviderListenable<Object?>>[
      isSetUpProvider,
      profileProvider,
      goalHistoryProvider,
      targetSettingsRecordsProvider,
      dayTargetsProvider(today),
      targetsExplanationProvider(today),
    ]) {
      c.listen(provider, (_, _) {});
    }
    expect(await c.read(isSetUpProvider.future), isFalse);
    expect(await c.read(profileProvider.future), isNull);
    expect((await c.read(goalHistoryProvider.future)).records, isEmpty);
    expect(await c.read(targetSettingsRecordsProvider.future), isEmpty);
    expect(await c.read(dayTargetsProvider(today).future), isNull);
    expect(await c.read(targetsExplanationProvider(today).future), isNull);

    await h.setUp();
    await pumpEventQueue();
    expect(await c.read(isSetUpProvider.future), isTrue);
    expect((await c.read(profileProvider.future))!.value, setupInput().profile);
    final goals = await c.read(goalHistoryProvider.future);
    final phase = goals.records.single;
    expect(goals.activeOn(today), phase);
    expect(goals.recordOf(phase.value.id), phase);
    expect(goals.history.phases.single.id, phase.value.id);
    expect(goals.activeOn(today.plusDays(-1)), isNull);
    expect(
      (await c.read(targetSettingsRecordsProvider.future))
          .single
          .value
          .baseKcal,
      setupBase,
    );
    final day = (await c.read(dayTargetsProvider(today).future))!;
    expect(day.day.kcal, setupBase);
    expect(day.floorKcal, 1750);
    expect(day.issues, isEmpty);
    final explanation = (await c.read(
      targetsExplanationProvider(today).future,
    ))!;
    expect(explanation.calculated.kcal, setupBase);
    expect(explanation.goal!.requestedKgPerWeek, -.5);
    // The day before the first version: still eaten mode.
    expect(await settled(c, today.plusDays(-1)), isNull);
  });

  test('HM-001 dayTargetsProvider follows a new entry, an incomplete mark, a '
      'week-start change and midnight', () async {
    final h = TargetsAppHarness();
    await h.setUp(); // Saturday 2026-10-17, weeks start on Saturday.
    h.advanceDays(3); // Tuesday 2026-10-20: day marks need a past day.
    final c = h.container();
    final tuesday = h.date;
    c.listen(dayTargetsProvider(tuesday), (_, _) {});

    // Saturday to Monday have no entries: unknown, reserved at plan.
    var day = (await settled(c, tuesday))!;
    expect(day.day.kcal, closeTo(setupBase, 1e-6));
    expect((day.week!.kcal, day.week!.uncountedDays), (0.0, 3));

    // 3,000 kcal on Sunday: 837.5 over; Tuesday–Friday share the rest.
    await insertEntries(h.db, [
      entryRow(1, date: '2026-10-18', slotId: DefaultSlots.lunchId, kcal: 3000),
    ]);
    day = (await settled(c, tuesday))!;
    expect(day.week!.kcal, closeTo(837.5, 1e-9));
    expect(day.week!.uncountedDays, 2);
    expect(
      day.day.kcal,
      closeTo((setupBase * 7 - setupBase * 2 - 3000) / 4, 1e-6),
    );

    // Sunday marked incomplete: unknown again, never counted.
    await h.apply([MarkDay(today.plusDays(1), incomplete: true)]);
    day = (await settled(c, tuesday))!;
    expect((day.week!.kcal, day.week!.uncountedDays), (0.0, 3));
    expect(day.day.kcal, closeTo(setupBase, 1e-6));

    // Weeks now start on Monday: only Monday is an earlier day.
    await h.apply([
      SettingsOp.put(
        AppSettings.weekStart.name,
        AppSettings.weekStart.codec.encode(DayOfWeek.monday),
      ),
    ]);
    day = (await settled(c, tuesday))!;
    expect((day.week!.kcal, day.week!.uncountedDays), (0.0, 1));

    // Midnight: Tuesday's intake becomes an earlier day of Wednesday.
    await insertEntries(h.db, [
      entryRow(2, date: '2026-10-20', slotId: DefaultSlots.lunchId, kcal: 2500),
    ]);
    day = (await settled(c, tuesday))!;
    expect((day.week!.kcal, day.week!.uncountedDays), (0.0, 1));
    h.advanceDays(1); // Wednesday 2026-10-21.
    final wednesday = h.date;
    c.listen(dayTargetsProvider(wednesday), (_, _) {});
    day = (await settled(c, wednesday))!;
    expect(day.week!.kcal, closeTo(2500 - setupBase, 1e-6));
    expect(day.week!.uncountedDays, 1);
  });

  test("D8 bodyWeightProvider returns null until A14's trend is wired (the "
      'seam), so targets use the basis weight; a trend weight, when given, '
      'is used for the floor', () async {
    final h = TargetsAppHarness();
    await h.setUp();
    final plain = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(h.db),
        changeSetApplierProvider.overrideWithValue(h.applier),
      ],
    );
    addTearDown(plain.dispose);
    plain.listen(dayTargetsProvider(today), (_, _) {});
    expect(await plain.read(bodyWeightProvider(today).future), isNull);
    final basis = (await settled(plain, today))!;
    expect((basis.weightKg, basis.floorKcal), (80.0, 1750.0));

    h.trend = 70;
    final c = h.container()..listen(dayTargetsProvider(today), (_, _) {});
    final trend = (await settled(c, today))!;
    // 70 kg: resting 1,650 is the floor; the stored base stays.
    expect((trend.weightKg, trend.floorKcal), (70.0, 1650.0));
    expect(trend.version.baseKcal, setupBase);
  });
}
