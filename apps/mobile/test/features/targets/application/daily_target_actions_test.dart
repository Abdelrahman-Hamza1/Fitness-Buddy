import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'targets_app_harness.dart';

// Covers: TG-046, SF-012
void main() {
  test('TG-046 the daily target sets an own number on every day: the weekday '
      'numbers and their floor confirmations go in one change set; Undo '
      'restores them', () async {
    final h = TargetsAppHarness();
    await h.setUp();
    final base = (await h.currentVersion()).baseKcal;
    await h.actions.setDayTarget(
      await h.shownVersion(),
      DayOfWeek.monday,
      2300,
      suggestionKcal: base,
    );
    await h.actions.setDayTarget(
      await h.shownVersion(),
      DayOfWeek.friday,
      1200,
      suggestionKcal: base,
      acknowledged: true,
    );
    expect(await h.actions.settings.read(AppSettings.dayFloorAcks), isNotEmpty);
    final before = await h.currentVersion();

    final done = await h.actions.setManualTarget(
      await h.shownVersion(),
      1900,
      everyDay: true,
    ) as TargetsDone;
    final after = await h.currentVersion();
    expect(
      (after.baseKcal, after.manual, after.acknowledged),
      (1900, true, false),
    );
    expect(after.dayFactors, isEmpty);
    expect(await h.actions.settings.read(AppSettings.dayFloorAcks), isEmpty);

    expect(await h.undo.undo(done.undoEntryId), UndoOutcome.undone);
    expect(await h.currentVersion(), before);
    expect(await h.actions.settings.read(AppSettings.dayFloorAcks), isNotEmpty);
  });

  test('TG-046 SF-012 a daily number below the floor asks first, then is '
      'the acknowledged fixed own number', () async {
    final h = TargetsAppHarness();
    await h.setUp();
    final need = await h.expectNoWrite<TargetsNeedsAcknowledgement>(
      () async => await h.actions.setManualTarget(
        await h.shownVersion(),
        1500,
        everyDay: true,
      ),
    );
    expect(need.warnings, contains(TargetWarning.manualBelowFloor));
    await h.actions.setManualTarget(
      await h.shownVersion(),
      1500,
      acknowledged: true,
      everyDay: true,
    );
    final version = await h.currentVersion();
    expect((version.manual, version.acknowledged), (true, true));
    expect(version.mode, TargetMode.fixed);
  });

  test('TG-046 "Suggested" goes back to the calculated target on every day; '
      'from a generated version it only clears the weekday numbers', () async {
    final h = TargetsAppHarness();
    await h.setUp();
    final base = (await h.currentVersion()).baseKcal;
    // Generated, every weekday at 1,800: only the factors go.
    for (final day in DayOfWeek.values) {
      await h.actions.setDayTarget(
        await h.shownVersion(),
        day,
        1800,
        suggestionKcal: base,
      );
    }
    expect((await h.currentVersion()).dayFactors, hasLength(7));
    await h.actions.useSuggestedEveryDay(await h.shownVersion());
    final cleared = await h.currentVersion();
    expect(cleared.dayFactors, isEmpty);
    expect((cleared.baseKcal, cleared.manual), (base, false));
    // Already there: unchanged.
    expect(
      await h.actions.useSuggestedEveryDay(await h.shownVersion()),
      isA<TargetsUnchanged>(),
    );

    // An own number goes back to the calculation.
    await h.actions.setManualTarget(
      await h.shownVersion(),
      2000,
      everyDay: true,
    );
    final done = await h.actions.useSuggestedEveryDay(
      await h.shownVersion(),
    ) as TargetsDone;
    final back = await h.currentVersion();
    expect((back.manual, back.acknowledged), (false, false));
    expect(back.baseKcal, setupBase);
    expect(done.recomputedKcal, setupBase);
  });

  test('TG-046 "Suggested" is refused when the calculation no longer gives '
      'the number the sheet showed; nothing written', () async {
    final h = TargetsAppHarness();
    await h.setUp();
    await h.actions.setManualTarget(
      await h.shownVersion(),
      2000,
      everyDay: true,
    );
    final failed = await h.expectNoWrite<TargetsFailed>(
      () async => await h.actions.useSuggestedEveryDay(
        await h.shownVersion(),
        expectedKcal: setupBase + 40,
      ),
    );
    expect(failed.reason, TargetsFailure.changed);
    await h.actions.useSuggestedEveryDay(
      await h.shownVersion(),
      expectedKcal: setupBase,
    );
    expect((await h.currentVersion()).manual, isFalse);
  });

  test('TG-046 TG-060 during Ramadan "maintain", "Suggested" from an own '
      'number previews and checks the resulting maintain base, which is '
      'what the saved version gets', () async {
    final h = TargetsAppHarness();
    await h.setUp();
    final actions = TargetsActions(
      apply: h.applier.apply,
      undoStack: h.undo,
      ids: h.ids,
      clock: h.clock,
      read: h.actions.read,
      settings: h.actions.settings,
      bodyWeightKg: (_) async => null,
      ramadanMaintainOn: (_) async => true,
    );
    await actions.setManualTarget(await h.shownVersion(), 2000, everyDay: true);
    final data = await h.data();
    final current = await h.currentVersion();
    final goals = [for (final p in data.phases) p.value];
    final calc = TargetsTimeline.generated(
      profile: data.profile!.value,
      goals: goals,
      weightKg: current.basisWeightKg,
      date: h.date,
    )!;
    // What the sheet shows: the maintain base (lose 0.5 kg/week: +550).
    final suggested = TargetsTimeline.suggestedBase(
      version: current,
      calculation: calc,
      weightKg: current.basisWeightKg,
      profile: data.profile!.value,
      goals: goals,
      date: h.date,
      ramadanMaintain: true,
    )!;
    expect(suggested, closeTo(calc.kcal + 550, 1e-6));
    // The unadjusted calculation is refused: it isn't what would be saved.
    expect(
      (await h.expectNoWrite<TargetsFailed>(
        () async => await actions.useSuggestedEveryDay(
          await h.shownVersion(),
          expectedKcal: calc.kcal,
        ),
      )).reason,
      TargetsFailure.changed,
    );
    await actions.useSuggestedEveryDay(
      await h.shownVersion(),
      expectedKcal: suggested,
    );
    final saved = TargetsTimeline.day(
      date: h.date,
      settings: [for (final s in (await h.data()).settings) s.value],
      profile: data.profile!.value,
      goals: goals,
      ramadanMaintain: true,
    )!;
    expect((await h.currentVersion()).manual, isFalse);
    expect(saved.plan.baseKcal, closeTo(suggested, 1e-6));
  });
}
