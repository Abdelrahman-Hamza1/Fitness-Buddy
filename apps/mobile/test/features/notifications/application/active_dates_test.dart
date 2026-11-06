import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/notifications/application/notification_inputs.dart';
import 'package:flutter_test/flutter_test.dart';

// A62b review fix: a day estimate is logging, so a week of only day
// estimates had activity and gets its weekly summary (NT-004).

/// Saturday 31 October 2026, a Saturday week start.
final LocalDate _sat = LocalDate(2026, 10, 31);

void main() {
  test('NT-004 DY-006 an estimate-only week is active: its summary is '
      'planned', () {
    final from = _sat.plusDays(-14);
    final week = [
      for (var i = 1; i <= 3; i++)
        DailyTotals.dayEstimate(_sat.plusDays(-i), 2000 + i * 100.0),
    ];
    final active = activeDatesOf(
      totals: week,
      weighInDates: const [],
      workoutDates: const [],
      from: from,
      today: _sat,
    );
    expect(active, {for (final t in week) t.date});

    // Nothing logged: no active day.
    expect(
      activeDatesOf(
        totals: const [],
        weighInDates: const [],
        workoutDates: const [],
        from: from,
        today: _sat,
      ),
      isEmpty,
    );

    NotificationPrefs only(NotificationType type) => NotificationPrefs(
      types: {
        for (final t in NotificationType.values)
          t: NotificationTypePrefs(
            enabled: t == type,
            minute: t.defaultMinute ?? 0,
          ),
      },
    );
    List<NotificationCandidate> plan(Iterable<LocalDate> activeDates) =>
        NotificationPlanner.plan(
          prefs: only(NotificationType.weeklySummary),
          today: _sat,
          nowMinute: 6 * 60,
          state: NotificationState(activeDates: activeDates),
        ).toList();
    expect(plan(active).map((c) => (c.type, c.date)), [
      (NotificationType.weeklySummary, _sat),
    ]);
    expect(plan(const []), isEmpty);
  });
}
