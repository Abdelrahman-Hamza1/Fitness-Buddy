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
    Map<LocalDate, IntakeTotals> confirmed = const {},
    this.revision = 0,
    this.history,
    this.weightKg,
    Iterable<WeekIntake> earlierIntake = const [],
    this.calendar = const WeekCalendar(),
    this.ramadan = false,
  }) : confirmed = Map.unmodifiable(confirmed),
       earlierIntake = List.unmodifiable(earlierIntake);

  /// Explicit current date.
  final LocalDate today;

  /// Frozen confirmed totals by date, knowledge-aware (A62 D15).
  final Map<LocalDate, IntakeTotals> confirmed;

  /// Diary revision, for invalidation.
  final int revision;

  /// Effective-dated A12 settings; absent until A13's read port exists.
  final TargetSettingsHistory? history;

  /// Effective body weight for A12 macros.
  final double? weightKg;

  /// Confirmed earlier days with explicit completeness.
  final List<WeekIntake> earlierIntake;

  /// User week calendar.
  final WeekCalendar calendar;

  /// Explicit calendar activation supplied by the application.
  final bool ramadan;
  @override
  String toString() => 'ProposalDayContext(redacted)';
}

/// Dated preview, independent of all sibling pending cards.
final class ProposalDayPreview extends ProposalValue {
  const new _(this.date, this.intake, this.targetKcal, this.revision);

  /// The card's diary date, including past cards.
  final LocalDate date;

  /// Confirmed intake plus this active card, knowledge-aware (A62 D15):
  /// "~" when the day holds an estimate or a lower-bound macro. On a day
  /// whose intake is a day estimate it is the card alone, since confirming
  /// replaces the estimate (A62 D12). Absent if its date was not loaded.
  final IntakeTotals? intake;

  /// Confirmed intake plus this active card; absent if its date was not loaded.
  Nutrients? get eaten => intake?.sum;

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
  List<Object?> get _values => [date, intake, targetKcal, revision];
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
        calendar: day.calendar,
      );
  return ProposalDayPreview._(
    date,
    switch (day?.confirmed[date]) {
      // A day estimate stands in for a day without food: confirming the
      // card replaces it (A62 D12), so the day is the card's food alone,
      // macros known (A62b review fix).
      IntakeTotals(dayEstimate: true) => IntakeTotals.known(_sum([own])),
      final confirmed? => confirmed + IntakeTotals.known(_sum([own])),
      null => null,
    },
    target?.kcal,
    day?.revision ?? 0,
  );
}

String _normalizeHint(String value) => value.trim().toLowerCase();
