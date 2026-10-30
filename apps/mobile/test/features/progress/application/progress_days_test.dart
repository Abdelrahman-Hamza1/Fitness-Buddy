import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/progress/application/progress_providers.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:fb_mobile/features/workouts/workouts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../diary/support/diary_fixtures.dart';
import '../../targets/application/targets_app_harness.dart';

/// A container over [h]'s database with the real trend (no body-weight
/// override), today at the harness clock and [training] for every week.
ProviderContainer _container(
  TargetsAppHarness h, {
  TrainingShiftInput? training,
}) {
  final c = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(h.db),
      changeSetApplierProvider.overrideWithValue(h.applier),
      clockProvider.overrideWithValue(h.clock),
      idGeneratorProvider.overrideWithValue(h.ids),
      undoStackProvider.overrideWithValue(h.undo),
      todayProvider.overrideWith((ref) => Stream.value(h.date)),
      trainingShiftProvider.overrideWith((ref, range) async => training),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

LocalDate _oct(int day) => LocalDate(2026, 10, day);

/// A weigh-in of [kg] at 07:00 on [date].
CreateWeighIn _weighIn(TargetsAppHarness h, LocalDate date, double kg) =>
    CreateWeighIn(
      h.ids.next(),
      WeighInDraft(
        time: EntryTime.local(LocalDateTime(date, hour: 7), 0),
        input: WeighInInput(kg, MassUnit.kilogram),
      ),
    );

Future<List<ProgressDay>> _days(
  ProviderContainer c,
  LocalDate from,
  LocalDate to,
) async {
  await pumpEventQueue();
  return await c.read(progressDaysProvider(from, to).future);
}

void main() {
  test('IN-002 progress days follow a new entry and a day mark', () async {
    final h = TargetsAppHarness();
    await h.setUp(); // Saturday 17 October 2026: weekly mode from today.
    final c = _container(h);
    final from = _oct(11);
    c.listen(progressDaysProvider(from, _oct(17)), (_, _) {});

    var days = await _days(c, from, _oct(17));
    expect(days, hasLength(7));
    expect(days[3].status, DayStatus.unknown); // 14 October
    expect(days.last.status, DayStatus.inProgress);

    await insertEntries(h.db, [
      entryRow(1, date: '2026-10-14', slotId: DefaultSlots.lunchId, kcal: 1900),
    ]);
    days = await _days(c, from, _oct(17));
    expect(days[3].status, DayStatus.logged);
    expect(days[3].eaten.kcal, 1900);

    await h.apply([MarkDay(_oct(14), incomplete: true)]);
    days = await _days(c, from, _oct(17));
    expect(days[3].status, DayStatus.incomplete);
    expect(days[3].eaten.kcal, 1900, reason: 'its intake is still drawn');
  });

  test('IN-002 G10 progressDaysProvider targets equal dayTargetsProvider for '
      'every day of a month', () async {
    final h = TargetsAppHarness(); // today: Saturday 17 October 2026
    // Weekly mode from 20 September; a settings change on 8 October.
    await h.apply([
      PutProfile(setupInput().profile),
      PutGoalPhase(loseHalf.toRecord(id: h.ids.next(), start: _oct(1))),
      PutTargetSettings(
        TargetSettingsRecord(
          id: h.ids.next(),
          revision: 1,
          effectiveFrom: LocalDate(2026, 9, 20),
          baseKcal: setupBase,
          basisWeightKg: 80,
        ),
      ),
    ]);
    await h.apply([
      PutTargetSettings(
        TargetSettingsRecord(
          id: h.ids.next(),
          revision: 1,
          effectiveFrom: _oct(8),
          baseKcal: 2300,
          basisWeightKg: 80,
        ),
      ),
    ]);
    await h.apply([
      // A weigh-in early in the month and one mid-month: the trend moves.
      _weighIn(h, _oct(2), 83),
      _weighIn(h, _oct(11), 79),
    ]);
    await insertEntries(h.db, [
      for (var d = 1; d <= 16; d++)
        if (d != 5 && d != 12)
          entryRow(
            d,
            date: '${_oct(d)}',
            slotId: DefaultSlots.lunchId,
            kcal: 1500 + (d * 137) % 1300,
            protein: 80 + d.toDouble(),
          ),
    ]);
    // An incomplete day in a weekly week.
    await h.apply([MarkDay(_oct(13), incomplete: true)]);
    // Training on Mondays and Wednesdays; an unplanned workout logged on
    // Saturday 10 October (the same-day adjustment).
    final c = _container(
      h,
      training: TrainingShiftInput(
        plannedDays: {DayOfWeek.monday, DayOfWeek.wednesday},
        weight: 1.3,
        loggedDates: {_oct(10)},
      ),
    )..listen(progressDaysProvider(_oct(1), _oct(31)), (_, _) {});
    for (var d = 1; d <= 17; d++) {
      c.listen(dayTargetsProvider(_oct(d)), (_, _) {});
    }
    final days = await _days(c, _oct(1), _oct(31));
    expect(days, hasLength(17), reason: 'never past today');
    var targeted = 0;
    for (final day in days) {
      final shown = await c.read(dayTargetsProvider(day.date).future);
      expect(day.targetKcal, shown?.day.kcal, reason: '${day.date}');
      expect(
        day.targetMacros?.proteinGrams,
        shown?.day.macros.proteinGrams,
        reason: '${day.date}',
      );
      if (shown != null) targeted++;
    }
    expect(targeted, 17);
  });
}
