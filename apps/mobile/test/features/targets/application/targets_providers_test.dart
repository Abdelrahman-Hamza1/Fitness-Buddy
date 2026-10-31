import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/settings/settings_store.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/targets/presentation/targets_day_rollover.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

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
      setupStatusProvider,
      profileProvider,
      goalHistoryProvider,
      targetSettingsRecordsProvider,
      dayTargetsProvider(today),
      targetsExplanationProvider(today),
    ]) {
      c.listen(provider, (_, _) {});
    }
    expect(await c.read(setupStatusProvider.future), SetupStatus.notSetUp);
    expect(await c.read(profileProvider.future), isNull);
    expect((await c.read(goalHistoryProvider.future)).records, isEmpty);
    expect(await c.read(targetSettingsRecordsProvider.future), isEmpty);
    expect(await c.read(dayTargetsProvider(today).future), isNull);
    expect(await c.read(targetsExplanationProvider(today).future), isNull);

    await h.setUp();
    await pumpEventQueue();
    expect(await c.read(setupStatusProvider.future), SetupStatus.setUp);
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

  test('TD-090 targets use the trend weight once weigh-ins exist, else the '
      'basis weight', () async {
    final h = TargetsAppHarness();
    // Targets rows without any weigh-in (written directly, not by setup).
    await h.apply([
      PutProfile(setupInput().profile),
      PutGoalPhase(loseHalf.toRecord(id: h.ids.next(), start: today)),
      PutTargetSettings(
        TargetSettingsRecord(
          id: h.ids.next(),
          revision: 1,
          effectiveFrom: today,
          baseKcal: setupBase,
          basisWeightKg: 80,
        ),
      ),
    ]);
    // The real seam: no bodyWeightProvider override.
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(h.db),
        changeSetApplierProvider.overrideWithValue(h.applier),
        clockProvider.overrideWithValue(h.clock),
        idGeneratorProvider.overrideWithValue(h.ids),
        undoStackProvider.overrideWithValue(h.undo),
      ],
    );
    addTearDown(c.dispose);
    c
      ..listen(dayTargetsProvider(today), (_, _) {})
      ..listen(bodyWeightProvider(today), (_, _) {});
    expect(await c.read(bodyWeightProvider(today).future), isNull);
    final basis = (await settled(c, today))!;
    expect((basis.weightKg, basis.floorKcal), (80.0, 1750.0));

    // A14's weigh-in: its trend replaces the basis weight from that day.
    await h.apply([
      CreateWeighIn(
        h.ids.next(),
        WeighInDraft(
          time: EntryTime.now(h.clock),
          input: const WeighInInput(70, MassUnit.kilogram),
        ),
      ),
    ]);
    await pumpEventQueue();
    expect(await c.read(bodyWeightProvider(today).future), 70);
    final trend = (await settled(c, today))!;
    // 70 kg: resting 1,650 is the floor; the stored base stays.
    expect((trend.weightKg, trend.floorKcal), (70.0, 1650.0));
    expect(trend.version.baseKcal, setupBase);
    // The session-owned commands read the same seam (no listener of their
    // own): "Recalculate" uses the trend weight.
    final recalculated = await c
        .read(targetsActionsProvider)
        .recalculate(await h.shownVersion());
    expect(recalculated, isA<TargetsDone>());
    expect((await h.currentVersion()).basisWeightKg, 70);
    // Before the first weigh-in there is no trend: the basis weight again.
    expect(await c.read(bodyWeightProvider(today.plusDays(-1)).future), isNull);
  });

  test(
    'TD-090 the session-owned commands read the trend once, from a '
    'container with no other listener: recalculate and saveProfile',
    () async {
      final h = TargetsAppHarness();
      await h.setUp();
      // The next day, A14's weigh-in of 70 kg after setup's 80 kg: the
      // trend today (between the two) is what the commands must see.
      h.advanceDays(1);
      await h.apply([
        CreateWeighIn(
          h.ids.next(),
          WeighInDraft(
            time: EntryTime.now(h.clock),
            input: const WeighInInput(70, MassUnit.kilogram),
          ),
        ),
      ]);
      ProviderContainer fresh() {
        // The real seam and nothing watching anything: the commands' read
        // must not depend on a provider someone else keeps alive.
        final c = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(h.db),
            changeSetApplierProvider.overrideWithValue(h.applier),
            clockProvider.overrideWithValue(h.clock),
            idGeneratorProvider.overrideWithValue(h.ids),
            undoStackProvider.overrideWithValue(h.undo),
          ],
        );
        addTearDown(c.dispose);
        return c;
      }

      final trend = await fresh().read(bodyWeightReaderProvider)(h.date);
      expect(trend, isNotNull);
      expect(trend, isNot(80));

      final recalculated = await fresh()
          .read(targetsActionsProvider)
          .recalculate(await h.shownVersion());
      expect(recalculated, isA<TargetsDone>());
      expect((await h.currentVersion()).basisWeightKg, trend);

      final saved = await fresh()
          .read(targetsActionsProvider)
          .saveProfile(const ProfilePatch(activity: ActivityLevel.high), 1);
      expect(saved, isA<TargetsDone>());
      expect((saved as TargetsDone).recomputedKcal, isNotNull);
      expect((await h.currentVersion()).basisWeightKg, trend);
    },
  );

  test('a failing read or write is a typed failure (unavailable), never a '
      'throw to the UI; nothing is written', () async {
    final h = TargetsAppHarness();
    await h.setUp();
    final failingRead = TargetsActions(
      apply: h.applier.apply,
      undoStack: h.undo,
      ids: h.ids,
      clock: h.clock,
      read: TargetsRepository(h.db).read,
      settings: SettingsStore(db: h.db, applier: h.applier),
      bodyWeightKg: (_) async => throw StateError('weigh-ins unreadable'),
    );
    final shown = await h.shownVersion();
    final before = await h.raw();
    expect(
      await failingRead.recalculate(shown),
      isA<TargetsFailed>().having(
        (f) => f.reason,
        'reason',
        TargetsFailure.unavailable,
      ),
    );
    expect(await h.raw(), before);

    h.applyHook = (_) async => throw StateError('database closed');
    final outcome = await h.expectNoWrite<TargetsFailed>(
      () => h.actions.saveProfile(
        const ProfilePatch(activity: ActivityLevel.high),
        1,
      ),
    );
    expect(outcome.reason, TargetsFailure.unavailable);
  });

  testWidgets('#197 the targets screens move to the next day at midnight '
      'while they stay open; the timer ends with the screen', (tester) async {
    final clock = ManualClock(
      DateTime.utc(2026, 10, 17, 20, 59, 30),
      offsetMinutes: 180,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [clockProvider.overrideWithValue(clock)],
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: TargetsDayRollover(
            child: Consumer(
              builder: (context, ref, _) =>
                  Text('${ref.watch(targetsTodayProvider)}'),
            ),
          ),
        ),
      ),
    );
    expect(find.text('${LocalDate(2026, 10, 17)}'), findsOneWidget);
    clock.advance(const Duration(seconds: 31));
    await tester.pump(const Duration(seconds: 31));
    expect(find.text('${LocalDate(2026, 10, 18)}'), findsOneWidget);
    // Unmounted: no timer is left behind (the test fails if one is).
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
