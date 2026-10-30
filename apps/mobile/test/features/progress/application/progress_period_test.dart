import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/progress/application/progress_period.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

String _id(int n) =>
    '0199e3c2-5b1a-7000-8000-${n.toRadixString(16).padLeft(12, '0')}';

Versioned<GoalPhaseRecord> _phase(int n, LocalDate start, {LocalDate? end}) =>
    Versioned(
      GoalPhaseRecord(
        id: _id(n),
        revision: 1,
        start: start,
        end: end,
        type: GoalType.lose,
        expression: GoalExpression.weekly(-.5),
        weightInputUnit: MassUnit.kilogram,
      ),
      1,
    );

void main() {
  test('IN-009 period stepping: week start setting, month boundaries, phases '
      'in order, never past today or before the earliest data', () {
    final today = LocalDate(2026, 10, 28); // a Wednesday
    final none = GoalPhases(const []);
    ProgressPeriod at(
      ProgressPeriodKind kind,
      int back, {
      WeekCalendar calendar = const WeekCalendar(),
      GoalPhases? phases,
      LocalDate? on,
    }) => resolvePeriod(
      (kind: kind, back: back),
      today: on ?? today,
      calendar: calendar,
      phases: phases ?? none,
    );

    // Weeks follow the week-start setting (LC-021).
    expect(at(ProgressPeriodKind.week, 0), WeekPeriod(LocalDate(2026, 10, 24)));
    expect(
      at(
        ProgressPeriodKind.week,
        0,
        calendar: const WeekCalendar(weekStart: DayOfWeek.monday),
      ),
      WeekPeriod(LocalDate(2026, 10, 26)),
    );
    expect(at(ProgressPeriodKind.week, 2), WeekPeriod(LocalDate(2026, 10, 10)));
    expect(at(ProgressPeriodKind.week, 0).range(today, none), (
      from: LocalDate(2026, 10, 24),
      end: LocalDate(2026, 10, 30),
    ));

    // Months cross the year and know their lengths.
    final january = LocalDate(2026, 1, 15);
    expect(
      at(ProgressPeriodKind.month, 1, on: january),
      const MonthPeriod(2025, 12),
    );
    expect(
      at(ProgressPeriodKind.month, 13, on: january),
      const MonthPeriod(2024, 12),
    );
    expect(
      const MonthPeriod(2028, 2).range(today, none).end,
      LocalDate(2028, 2, 29),
    );
    expect(
      const MonthPeriod(2026, 2).range(today, none).end,
      LocalDate(2026, 2, 28),
    );

    // Phases in date order, started ones only; the current one first.
    final phases = GoalPhases([
      _phase(2, LocalDate(2026, 8, 1)),
      _phase(1, LocalDate(2026, 3, 1), end: LocalDate(2026, 6, 30)),
      _phase(3, LocalDate(2026, 12, 1)), // not started yet
    ]);
    expect(
      at(ProgressPeriodKind.phase, 0, phases: phases),
      PhasePeriod(_id(2)),
    );
    expect(
      at(ProgressPeriodKind.phase, 1, phases: phases),
      PhasePeriod(_id(1)),
    );
    expect(
      at(ProgressPeriodKind.phase, 5, phases: phases),
      PhasePeriod(_id(1)),
    );
    // The open current phase runs to today; a phase choice without phases
    // shows this week.
    expect(PhasePeriod(_id(2)).range(today, phases), (
      from: LocalDate(2026, 8, 1),
      end: today,
    ));
    expect(
      at(ProgressPeriodKind.phase, 0),
      WeekPeriod(LocalDate(2026, 10, 24)),
    );

    // ‹ stops at the earliest data; phases stop at the first.
    bool back(ProgressPeriodKind kind, int n, LocalDate earliest) => canGoBack(
      (kind: kind, back: n),
      today: today,
      calendar: const WeekCalendar(),
      phases: phases,
      earliest: earliest,
    );
    final earliest = LocalDate(2026, 10, 15);
    expect(back(ProgressPeriodKind.week, 0, earliest), isTrue); // 17–23 Oct
    expect(back(ProgressPeriodKind.week, 1, earliest), isTrue); // 10–16 Oct
    expect(back(ProgressPeriodKind.week, 2, earliest), isFalse); // 3–9 Oct
    expect(back(ProgressPeriodKind.month, 0, earliest), isFalse);
    expect(back(ProgressPeriodKind.month, 0, LocalDate(2026, 9, 30)), isTrue);
    expect(back(ProgressPeriodKind.phase, 0, earliest), isTrue);
    expect(back(ProgressPeriodKind.phase, 1, earliest), isFalse);

    // › never goes past the current period; a new kind starts there.
    final container = ProviderContainer.test();
    final controller = container.read(
      progressPeriodControllerProvider.notifier,
    );
    expect(container.read(progressPeriodControllerProvider), (
      kind: ProgressPeriodKind.week,
      back: 0,
    ));
    controller.next();
    expect(container.read(progressPeriodControllerProvider).back, 0);
    controller
      ..previous()
      ..previous()
      ..next();
    expect(container.read(progressPeriodControllerProvider).back, 1);
    controller.setKind(ProgressPeriodKind.month);
    expect(container.read(progressPeriodControllerProvider), (
      kind: ProgressPeriodKind.month,
      back: 0,
    ));
  });
}
