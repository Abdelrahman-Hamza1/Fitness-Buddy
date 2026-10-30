import 'package:fb_domain/fb_domain.dart';

import '../../diary/support/diary_fixtures.dart';
import '../../targets/application/targets_app_harness.dart';

/// One year of synthetic data for the Progress benchmark (A16 WP6, D16):
/// 365 days × 15 entries ≈ 5,500 rows, a day marked incomplete every 17
/// days, a weigh-in a day, two goal phases and three settings versions,
/// on [TargetsAppHarness]'s database (today: Saturday 17 October 2026).
/// Synthetic only: no user content.
final class ProgressWorkload {
  /// The workload on a fresh harness.
  new() : h = TargetsAppHarness();

  /// The database, applier and clock.
  final TargetsAppHarness h;

  /// The first day of the year of data.
  LocalDate get first => today.plusDays(-364);

  /// The first phase's ID: its phase period is the whole year.
  late final String firstPhaseId;

  /// Entries per day.
  static const int perDay = 15;

  /// Writes the year. Call once, outside any fake async zone.
  Future<void> seed() async {
    firstPhaseId = h.ids.next();
    await h.apply([
      PutProfile(setupInput().profile),
      PutGoalPhase(
        GoalPhaseRecord(
          id: firstPhaseId,
          revision: 1,
          start: first,
          type: GoalType.lose,
          expression: GoalExpression.targetRate(80, .5),
          weightInputUnit: MassUnit.kilogram,
        ),
      ),
      PutGoalPhase(
        GoalPhaseRecord(
          id: h.ids.next(),
          revision: 1,
          // Planned after today, so the first phase spans the whole year.
          start: LocalDate(2026, 11, 1),
          type: GoalType.lose,
          expression: GoalExpression.targetDate(76, LocalDate(2027, 6, 1)),
          weightInputUnit: MassUnit.kilogram,
        ),
      ),
    ]);
    for (final (from, base) in [
      (first, 2300.0),
      (LocalDate(2026, 2, 1), 2200.0),
      (LocalDate(2026, 6, 15), 2100.0),
    ]) {
      await h.apply([
        PutTargetSettings(
          TargetSettingsRecord(
            id: h.ids.next(),
            revision: 1,
            effectiveFrom: from,
            baseKcal: base,
            basisWeightKg: 86,
          ),
        ),
      ]);
    }
    await insertEntries(h.db, [
      for (var d = 0; d < 365; d++)
        for (var e = 0; e < perDay; e++)
          entryRow(
            d * perDay + e + 1,
            date: '${first.plusDays(d)}',
            slotId: DefaultSlots.lunchId,
            kcal: 90 + (d * 31 + e * 17) % 120,
            protein: 5 + e % 7,
            carbs: 10 + e % 11,
            fat: 3 + e % 5,
            fiber: 1 + e % 3,
          ),
    ]);
    await h.apply([
      for (var d = 0; d < 365; d += 17)
        MarkDay(first.plusDays(d), incomplete: true),
    ]);
    await h.apply([
      for (var d = 0; d < 365; d++)
        CreateWeighIn(
          h.ids.next(),
          WeighInDraft(
            time: EntryTime.local(LocalDateTime(first.plusDays(d), hour: 7), 0),
            input: WeighInInput(
              ((88 - d * 0.02 + (d % 5) * 0.1) * 10).roundToDouble() / 10,
              MassUnit.kilogram,
            ),
          ),
        ),
    ]);
  }
}
