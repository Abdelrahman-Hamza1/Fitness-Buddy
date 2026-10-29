import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/targets/application/body_weight.dart';
import 'package:fb_mobile/features/targets/data/targets_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'targets_providers.g.dart';

/// The stored goal phases with their row versions, and the A12 projection
/// over them (TG-012). A15/A16 shade charts from [history]; Me lists
/// [records] (names, versions). Content-free [toString].
final class GoalPhases {
  /// The live phase rows.
  new(Iterable<Versioned<GoalPhaseRecord>> records)
    : records = List.unmodifiable(records);

  /// Live phase rows, by ID. Unmodifiable.
  final List<Versioned<GoalPhaseRecord>> records;

  /// The non-overlapping projected phases (names are placeholders: look
  /// a phase's record up with [recordOf] for its name).
  late final GoalHistory history = GoalHistory([
    for (final record in records) record.value.toPhase(),
  ]);

  /// The stored row of phase [id], or null.
  Versioned<GoalPhaseRecord>? recordOf(String id) {
    for (final record in records) {
      if (record.value.id == id) return record;
    }
    return null;
  }

  /// The stored row of the phase in effect on [date], or null in a gap.
  Versioned<GoalPhaseRecord>? activeOn(LocalDate date) {
    final phase = history.at(date);
    return phase == null ? null : recordOf(phase.id);
  }

  @override
  String toString() => 'GoalPhases(${records.length})';
}

/// One read of the targets tables, live (tolerant decode, skipped rows
/// counted). Local only: no spinner beyond the first frame (UX-001).
@riverpod
Stream<TargetsData> targetsData(Ref ref) =>
    ref.watch(targetsRepositoryProvider).watchTargets();

/// The live profile with its row version, or null before setup.
@riverpod
Future<Versioned<ProfileRecord>?> profile(Ref ref) async =>
    (await ref.watch(targetsDataProvider.future)).profile;

/// The live goal phases and their projection (TG-012).
@riverpod
Future<GoalPhases> goalHistory(Ref ref) async =>
    GoalPhases((await ref.watch(targetsDataProvider.future)).phases);

/// The live target settings versions with their row versions.
@riverpod
Future<List<Versioned<TargetSettingsRecord>>> targetSettingsRecords(
  Ref ref,
) async => (await ref.watch(targetsDataProvider.future)).settings;

/// Whether setup has run: a profile and at least one target settings
/// version exist (D10: Today's setup row and Me's entry use it).
@riverpod
Future<bool> isSetUp(Ref ref) async {
  final data = await ref.watch(targetsDataProvider.future);
  return data.profile != null && data.settings.isNotEmpty;
}

/// Everything Today and Targets show for [date] (D6), derived by
/// [TargetsTimeline.day] from the stored rows, the earlier days of [date]'s
/// week (totals and day marks), the week start and [bodyWeightProvider].
/// Null when there is no profile or no version in effect on [date]
/// (Today's eaten mode). Follows every source: a new entry, a day mark, a
/// week-start change, a targets edit.
@riverpod
Future<DayTargets?> dayTargets(Ref ref, LocalDate date) async {
  // The sources are watched before the first await; only the intake, whose
  // range depends on the week start, is watched after it.
  final dataFuture = ref.watch(targetsDataProvider.future);
  final weekStartFuture = ref.watch(weekStartProvider.future);
  final weightFuture = ref.watch(bodyWeightProvider(date).future);
  final data = await dataFuture;
  final calendar = WeekCalendar(weekStart: await weekStartFuture);
  final weightKg = await weightFuture;
  final settings = [for (final s in data.settings) s.value];
  if (data.profile == null ||
      TargetsTimeline.versionOn(settings, date) == null) {
    return null;
  }
  final from = calendar.weekStartOf(date);
  final intake = from.isBefore(date)
      ? await ref.watch(_weekIntakeProvider(from, date.plusDays(-1)).future)
      : const <DayIntake>[];
  return TargetsTimeline.day(
    date: date,
    settings: settings,
    profile: data.profile!.value,
    goals: [for (final g in data.phases) g.value],
    bodyWeightKg: weightKg,
    intake: intake,
    calendar: calendar,
  );
}

/// The numbers behind the plain-language explanation of the version in
/// effect on [date] (TG-021, D6), or null before setup.
@riverpod
Future<TargetExplanation?> targetsExplanation(Ref ref, LocalDate date) async {
  final data = await ref.watch(targetsDataProvider.future);
  return TargetsTimeline.explain(
    date: date,
    settings: [for (final s in data.settings) s.value],
    profile: data.profile?.value,
    goals: [for (final g in data.phases) g.value],
  );
}

/// The diary days [from]–[to] (inclusive) as [DayIntake]s: each day with
/// entries or a mark. Days with neither are left out (unknown, TG-032).
@riverpod
Future<List<DayIntake>> _weekIntake(
  Ref ref,
  LocalDate from,
  LocalDate to,
) async {
  final totalsFuture = ref.watch(_dailyTotalsProvider(from, to).future);
  final marksFuture = ref.watch(_dayMarksProvider(from, to).future);
  final totals = {for (final t in await totalsFuture) t.date: t};
  final marks = {for (final m in await marksFuture) m.localDate: m};
  return [
    for (final date in {...totals.keys, ...marks.keys})
      DayIntake(
        date: date,
        kcal: totals[date]?.totals.kcal ?? 0,
        entryCount: totals[date]?.entryCount ?? 0,
        incomplete: marks[date]?.incomplete ?? false,
      ),
  ];
}

@riverpod
Stream<List<DailyTotals>> _dailyTotals(Ref ref, LocalDate from, LocalDate to) =>
    ref.watch(diaryRepositoryProvider).watchDailyTotals(from, to);

@riverpod
Stream<List<DayMark>> _dayMarks(Ref ref, LocalDate from, LocalDate to) =>
    ref.watch(diaryRepositoryProvider).watchDayMarks(from, to);
