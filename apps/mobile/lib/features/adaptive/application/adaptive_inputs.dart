import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/targets/targets.dart';

/// The days the estimate looks back over (A38 D1).
final int adaptiveWindowDays = const AdaptiveConfig().windowDays;

/// The estimate's intake days from the diary's per-day totals, the day
/// marks and the dates the user confirmed complete (A38 D1): a day with
/// entries is logged; its mark says whether it is incomplete; a "count
/// again" mark (a mark that isn't incomplete) or a dismissed suggestion
/// ([confirmed]) means the user said it is complete. Days with only a mark
/// are not logged (unknown, TG-032).
List<IntakeDay> intakeDaysOf({
  required Iterable<DailyTotals> totals,
  required Iterable<DayMark> marks,
  Set<LocalDate> confirmed = const {},
}) {
  final byDate = {for (final m in marks) m.localDate: m};
  return [
    for (final t in totals)
      if (t.entryCount > 0)
        IntakeDay(
          date: t.date,
          kcal: t.totals.kcal,
          entryCount: t.entryCount,
          mealCount: t.mealCount,
          incomplete: byDate[t.date]?.incomplete ?? false,
          confirmed:
              confirmed.contains(t.date) || byDate[t.date]?.incomplete == false,
        ),
  ];
}

/// The dates of answered incomplete-day suggestions (DY-004), by answer:
/// `true` marked incomplete, `false` confirmed complete. Pending or
/// unreadable rows are skipped.
Map<LocalDate, bool> dayAnswersOf(Iterable<ProposalRecord> rows) => {
  for (final r in rows)
    if (r.kind == dayIncompleteKind && !r.isPending)
      ?DayIncompleteDraft.dateOf(r.draftJson):
          r.status == ProposalStatus.confirmed,
};

/// The dates the user confirmed complete by answering a suggestion.
Set<LocalDate> confirmedDatesOf(Iterable<ProposalRecord> rows) => {
  for (final MapEntry(key: date, value: incomplete) in dayAnswersOf(
    rows,
  ).entries)
    if (!incomplete) date,
};

/// The formula expenditure on [date] (TG-020: resting energy × activity)
/// at [weightKg], the estimate's prior; null when the profile can't be
/// evaluated.
double? formulaExpenditure({
  required ProfileRecord profile,
  required double weightKg,
  required LocalDate date,
  TargetDefaults defaults = const TargetDefaults(),
}) {
  try {
    final p = profile.toProfile(weightKg);
    final kcal =
        TargetCalculator.resting(p, date) * defaults.activityFactor(p.activity);
    return kcal.isFinite && kcal > 0 ? kcal : null;
  }
  // The engine's content-free signal for impossible input (PA3).
  // ignore: avoid_catching_errors
  on ArgumentError {
    return null;
  }
}

/// The estimate for the window ending on [end] from the stored data, or
/// null before setup (no profile or no targets) or when the profile can't
/// be evaluated. The prior's weight is the trend on [end], else the basis
/// weight of the version in effect then (or the first one).
AdaptiveResult? adaptiveResultFor({
  required LocalDate end,
  required TargetsData data,
  required List<IntakeDay> days,
  required List<WeighIn> weighIns,
  required WeightTrend trend,
  bool Function(LocalDate date)? isRamadan,
  TargetDefaults defaults = const TargetDefaults(),
}) {
  final profile = data.profile?.value;
  final settings = [for (final s in data.settings) s.value];
  if (profile == null || settings.isEmpty) return null;
  final version =
      TargetsTimeline.versionOn(settings, end) ??
      settings.reduce(
        (a, b) => a.effectiveFrom.isBefore(b.effectiveFrom) ? a : b,
      );
  final weight = trend.trendOn(end) ?? version.basisWeightKg;
  if (!TargetRules.input.weight(weight)) return null;
  final prior = formulaExpenditure(
    profile: profile,
    weightKg: weight,
    date: end,
    defaults: defaults,
  );
  if (prior == null) return null;
  return AdaptiveExpenditure.estimate(
    end: end,
    days: days,
    weighIns: weighIns,
    priorKcal: prior,
    isRamadan: isRamadan,
    defaults: defaults,
  );
}

/// The live row of [rows] whose draft is the check-in of [weekStart] (the
/// newest when a sync left several), with its draft.
({ProposalRecord record, TargetChangeDraft draft})? checkInOfWeek(
  Iterable<ProposalRecord> rows,
  LocalDate weekStart,
) {
  ({ProposalRecord record, TargetChangeDraft draft})? found;
  for (final r in rows) {
    if (r.kind != targetChangeKind) continue;
    final draft = TargetChangeDraft.tryParse(r.draftJson);
    if (draft == null || draft.weekStart != weekStart) continue;
    if (found == null || !r.createdAt.isBefore(found.record.createdAt)) {
      found = (record: r, draft: draft);
    }
  }
  return found;
}
