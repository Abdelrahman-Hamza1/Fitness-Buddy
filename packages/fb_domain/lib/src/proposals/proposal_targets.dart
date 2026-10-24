part of 'proposal_input.dart';

/// Application-observed lifecycle; superseded rows are historical only.
enum ProposalLifecycle {
  /// Pending confirmation.
  active,

  /// Successfully confirmed by the application.
  confirmed,

  /// Discarded by the application.
  discarded,

  /// Historical synced row; never executable.
  superseded,
}

/// Confirmed diary and A12 inputs. Pending proposals never enter this value.
final class ProposalDayContext {
  /// Dates, revisions and completeness are explicit, with no clock fallback.
  new({
    required this.today,
    Map<LocalDate, Nutrients> confirmed = const {},
    this.revision = 0,
    this.history,
    this.weightKg,
    Iterable<WeekIntake> earlierIntake = const [],
    Map<DayOfWeek, double> workoutWeights = const {},
    this.calendar = const WeekCalendar(),
    this.ramadan = false,
  }) : confirmed = Map.unmodifiable(confirmed),
       earlierIntake = List.unmodifiable(earlierIntake),
       workoutWeights = Map.unmodifiable(workoutWeights);

  /// Explicit current date.
  final LocalDate today;

  /// Frozen confirmed totals by date.
  final Map<LocalDate, Nutrients> confirmed;

  /// Diary revision, for invalidation.
  final int revision;

  /// Effective-dated A12 settings; absent until A13's read port exists.
  final TargetSettingsHistory? history;

  /// Effective body weight for A12 macros.
  final double? weightKg;

  /// Confirmed earlier days with explicit completeness.
  final List<WeekIntake> earlierIntake;

  /// Remaining-day workout weights.
  final Map<DayOfWeek, double> workoutWeights;

  /// User week calendar.
  final WeekCalendar calendar;

  /// Explicit calendar activation supplied by the application.
  final bool ramadan;
  @override
  String toString() => 'ProposalDayContext(redacted)';
}

/// Dated preview, independent of all sibling pending cards.
final class ProposalDayPreview extends ProposalValue {
  const new _(this.date, this.eaten, this.targetKcal, this.revision);

  /// The card's diary date, including past cards.
  final LocalDate date;

  /// Confirmed intake plus this active card; absent if its date was not loaded.
  final Nutrients? eaten;

  /// A12 projection, absent when targets are unavailable.
  final double? targetKcal;

  /// Input diary revision.
  final int revision;

  /// A13 has not yet supplied an effective target read port.
  bool get targetsUnavailable => targetKcal == null;

  /// Over-target intake remains negative.
  double? get remainingKcal =>
      targetKcal == null || eaten == null ? null : targetKcal! - eaten!.kcal;
  @override
  List<Object?> get _values => [date, eaten, targetKcal, revision];
}

ProposalDayPreview _preview(
  ProposalContext context,
  LocalDate date,
  Nutrients own,
) {
  final day = context.dayContext;
  final settings = day?.weightKg == null ? null : day?.history?.at(date);
  final target = settings
      ?.plan(ramadanActive: day!.ramadan)
      .day(
        date: date,
        weightKg: day.weightKg!,
        earlierIntake: day.earlierIntake.where(
          (i) =>
              i.date.isBefore(date) &&
              !i.date.isBefore(day.calendar.weekStartOf(date)),
        ),
        remainingWeights: day.workoutWeights,
        calendar: day.calendar,
      );
  return ProposalDayPreview._(
    date,
    day?.confirmed[date] == null ? null : _sum([day!.confirmed[date]!, own]),
    target?.kcal,
    day?.revision ?? 0,
  );
}

String _normalizeHint(String value) => value.trim().toLowerCase();
