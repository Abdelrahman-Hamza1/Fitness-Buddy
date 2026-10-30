import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/adaptive/application/adaptive_inputs.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/buddy/buddy.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'adaptive_providers.g.dart';

/// How many weekly points the expenditure chart shows (IN-005).
const int expenditureChartWeeks = 12;

/// The weekly check-in rows (`targetChange`), live.
@riverpod
Stream<List<ProposalRecord>> targetChangeRows(Ref ref) =>
    ref.watch(proposalRepositoryProvider).watchKind(targetChangeKind);

/// The answered incomplete-day suggestions (`dayIncomplete`), live.
@riverpod
Stream<List<ProposalRecord>> dayIncompleteRows(Ref ref) =>
    ref.watch(proposalRepositoryProvider).watchKind(dayIncompleteKind);

/// The estimate's intake days [from]–[to] (A38 D1): the diary totals with
/// meal counts, the day marks and the confirmed-complete answers. Follows
/// every source.
@riverpod
Future<List<IntakeDay>> adaptiveIntake(
  Ref ref,
  LocalDate from,
  LocalDate to,
) async {
  final totalsFuture = ref.watch(_totalsProvider(from, to).future);
  final marksFuture = ref.watch(_marksProvider(from, to).future);
  final answersFuture = ref.watch(dayIncompleteRowsProvider.future);
  return intakeDaysOf(
    totals: await totalsFuture,
    marks: await marksFuture,
    confirmed: confirmedDatesOf(await answersFuture),
  );
}

@riverpod
Stream<List<DailyTotals>> _totals(Ref ref, LocalDate from, LocalDate to) =>
    ref.watch(diaryRepositoryProvider).watchDailyTotals(from, to);

@riverpod
Stream<List<DayMark>> _marks(Ref ref, LocalDate from, LocalDate to) =>
    ref.watch(diaryRepositoryProvider).watchDayMarks(from, to);

/// The Expenditure card (IN-005, TG-031, TG-033). Content-free
/// [toString].
final class ExpenditureView {
  /// The view.
  new({
    required this.readiness,
    required List<ExpenditureEstimate> points,
    required this.mode,
    this.latest,
  }) : points = List.unmodifiable(points);

  /// Where the data stands for the window ending yesterday.
  final AdaptiveReadiness readiness;

  /// The estimate for the window ending yesterday, once ready.
  final ExpenditureEstimate? latest;

  /// The ready weekly estimates (each week's check-in basis), oldest
  /// first, then [latest].
  final List<ExpenditureEstimate> points;

  /// Ask or automatic.
  final CheckInMode mode;

  @override
  String toString() => 'ExpenditureView(${points.length} points)';
}

/// The [ExpenditureView], or null before setup. Local data only.
@Riverpod(retry: _noAutomaticRetry)
Future<ExpenditureView?> expenditureView(Ref ref) async {
  final todayFuture = ref.watch(todayProvider.future);
  final weekStartFuture = ref.watch(weekStartProvider.future);
  final dataFuture = ref.watch(targetsDataProvider.future);
  final weighInsFuture = ref.watch(weighInsProvider.future);
  final trendFuture = ref.watch(weightTrendProvider.future);
  final modeFuture = ref.watch(checkInModeProvider.future);
  final today = await todayFuture;
  final calendar = WeekCalendar(weekStart: await weekStartFuture);
  final data = await dataFuture;
  final weighIns = await weighInsFuture;
  final trend = await trendFuture;
  final mode = await modeFuture;
  if (data.profile == null || data.settings.isEmpty) return null;
  final yesterday = today.plusDays(-1);
  final weekStart = calendar.weekStartOf(today);
  final ends = [
    for (var k = expenditureChartWeeks - 1; k >= 0; k--)
      weekStart.plusDays(-7 * k - 1),
  ];
  final from = ends.first.plusDays(1 - adaptiveWindowDays);
  final days = await ref.watch(adaptiveIntakeProvider(from, yesterday).future);
  AdaptiveResult? at(LocalDate end) => adaptiveResultFor(
    end: end,
    data: data,
    days: days,
    weighIns: weighIns,
    trend: trend,
  );
  final latest = at(yesterday);
  if (latest == null) return null;
  return ExpenditureView(
    readiness: latest.readiness,
    latest: latest.estimate,
    points: [
      for (final end in ends)
        if (end != yesterday) ?at(end)?.estimate,
      ?latest.estimate,
    ],
    mode: mode,
  );
}

/// What the check-in card shows (A38 D4).
enum CheckInCardKind {
  /// A proposal to accept, adjust or keep.
  pending,

  /// A proposal made against targets that changed since: only Keep.
  stale,

  /// Applied automatically: "Targets updated", Change back.
  applied,
}

/// This week's check-in card. Content-free [toString].
final class CheckInCardView {
  /// The view.
  const new({
    required this.record,
    required this.draft,
    required this.kind,
    this.floorKcal,
  });

  /// The stored row.
  final ProposalRecord record;

  /// Its draft.
  final TargetChangeDraft draft;

  /// Which card.
  final CheckInCardKind kind;

  /// Today's safety floor (the adjust lower bound), when known.
  final double? floorKcal;

  /// The lowest base Adjust offers: 150 below the base, never below the
  /// floor.
  double get minKcal {
    final low = draft.fromKcal - const TargetDefaults().checkInMaxChangeKcal;
    final floor = floorKcal;
    return floor != null && floor > low ? floor : low;
  }

  /// The highest base Adjust offers: 150 above the base.
  double get maxKcal =>
      draft.fromKcal + const TargetDefaults().checkInMaxChangeKcal;

  @override
  String toString() => 'CheckInCardView(${kind.name})';
}

/// This week's pending check-in card (or a stale one), or null; the
/// automatic change's note is [appliedCheckInCard].
@riverpod
Future<CheckInCardView?> checkInCard(Ref ref) async {
  final todayFuture = ref.watch(todayProvider.future);
  final weekStartFuture = ref.watch(weekStartProvider.future);
  final rowsFuture = ref.watch(targetChangeRowsProvider.future);
  final dataFuture = ref.watch(targetsDataProvider.future);
  final today = await todayFuture;
  final calendar = WeekCalendar(weekStart: await weekStartFuture);
  final rows = await rowsFuture;
  final data = await dataFuture;
  final current = TargetsTimeline.versionOn([
    for (final s in data.settings) s.value,
  ], today);
  final found = checkInOfWeek(rows, calendar.weekStartOf(today));
  if (found != null && found.record.isPending) {
    final (:record, :draft) = found;
    final targets = await ref.watch(dayTargetsProvider(today).future);
    final stale =
        current == null ||
        current.id != draft.versionId ||
        current.revision != draft.versionRevision;
    return CheckInCardView(
      record: record,
      draft: draft,
      kind: stale ? CheckInCardKind.stale : CheckInCardKind.pending,
      floorKcal: targets?.floorKcal,
    );
  }
  return null;
}

/// The unseen automatic change's card ("Your target changed … Change
/// back"), or null. Separate from [checkInCard], so a newer week's
/// proposal never hides it: it stays, past the week's end and a restart,
/// until the user says OK or the targets move on (the version it wrote
/// must still be in effect; A38 review 5, 6).
@riverpod
Future<CheckInCardView?> appliedCheckInCard(Ref ref) async {
  final todayFuture = ref.watch(todayProvider.future);
  final rowsFuture = ref.watch(targetChangeRowsProvider.future);
  final dataFuture = ref.watch(targetsDataProvider.future);
  final today = await todayFuture;
  final rows = await rowsFuture;
  final data = await dataFuture;
  final current = TargetsTimeline.versionOn([
    for (final s in data.settings) s.value,
  ], today);
  final applied = appliedCheckInOf(rows, current);
  return applied == null
      ? null
      : CheckInCardView(
          record: applied.record,
          draft: applied.draft,
          kind: CheckInCardKind.applied,
        );
}

/// The newest automatic check-in of [rows] the user hasn't acknowledged
/// whose written version is [current] (same ID and revision, not manual),
/// or null.
({ProposalRecord record, TargetChangeDraft draft})? appliedCheckInOf(
  Iterable<ProposalRecord> rows,
  TargetSettingsRecord? current,
) {
  if (current == null || current.manual) return null;
  ({ProposalRecord record, TargetChangeDraft draft})? found;
  for (final r in rows) {
    if (r.kind != targetChangeKind || r.status != ProposalStatus.confirmed) {
      continue;
    }
    final draft = TargetChangeDraft.tryParse(r.draftJson);
    if (draft == null ||
        !draft.automatic ||
        draft.seen ||
        draft.appliedVersionId != current.id ||
        draft.appliedRevision != current.revision) {
      continue;
    }
    if (found == null || !r.createdAt.isBefore(found.record.createdAt)) {
      found = (record: r, draft: draft);
    }
  }
  return found;
}

/// The day an incomplete-day suggestion asks about (DY-004). Content-free
/// [toString].
final class IncompleteDaySuggestion {
  /// The suggestion.
  const new({
    required this.date,
    required this.kcal,
    required this.mealCount,
    required this.targetKcal,
  });

  /// The day.
  final LocalDate date;

  /// What was logged.
  final double kcal;

  /// In how many meals.
  final int mealCount;

  /// The day's target.
  final double targetKcal;

  @override
  String toString() => 'IncompleteDaySuggestion($date)';
}

/// How far back the suggestion looks (yesterday and 13 days before).
const int incompleteSuggestionDays = 14;

/// The most recent unanswered day of the last two weeks that looks
/// incomplete: under half of its target in fewer than two meals (DY-004),
/// not marked, not confirmed, not answered. Never today. Null without one.
@riverpod
Future<IncompleteDaySuggestion?> incompleteDaySuggestion(Ref ref) async {
  final today = await ref.watch(todayProvider.future);
  final to = today.plusDays(-1);
  final from = today.plusDays(-incompleteSuggestionDays);
  final daysFuture = ref.watch(adaptiveIntakeProvider(from, to).future);
  final answersFuture = ref.watch(dayIncompleteRowsProvider.future);
  final days = await daysFuture;
  final answered = dayAnswersOf(await answersFuture);
  final candidates = [
    for (final d in days)
      if (d.logged &&
          !d.incomplete &&
          !d.confirmed &&
          d.mealCount < IncompleteDayRule.minMeals &&
          !answered.containsKey(d.date))
        d,
  ]..sort((a, b) => b.date.compareTo(a.date));
  for (final day in candidates) {
    final targets = await ref.watch(dayTargetsProvider(day.date).future);
    final target = targets?.day.kcal;
    if (target == null) continue;
    if (IncompleteDayRule.matches(
      kcal: day.kcal,
      entryCount: day.entryCount,
      mealCount: day.mealCount,
      referenceKcal: target,
    )) {
      return IncompleteDaySuggestion(
        date: day.date,
        kcal: day.kcal,
        mealCount: day.mealCount,
        targetKcal: target,
      );
    }
  }
  return null;
}

Duration? _noAutomaticRetry(int retryCount, Object error) => null;
