import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/settings/settings_store.dart';
import 'package:fb_mobile/features/buddy/application/weekly/weekly_review.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/buddy_harness.dart';

/// The weekly review (A68 D6, AI-130): only an answered review is stored;
/// a limit/quota end is a failure with Try again, and nothing asks again
/// on its own in the same session.
void main() {
  test('AI-130 a limit end is not cached; only Try again asks again, and '
      'an answered review is stored once', () async {
    final h = BuddyHarness();
    final week = LocalDate(2026, 10, 10);
    final summary = WeeklySummary(
      start: week,
      end: week.plusDays(6),
      elapsedDays: 7,
      countedDays: 5,
      targetDays: 5,
      daysWithinTarget: 3,
      proteinTargetDays: 5,
      proteinDaysHit: 4,
      averageKcal: 2050,
      averageTargetKcal: 2000,
    );
    var reason = 'limit';
    var posts = 0;
    h.adapter.respond = (request) {
      posts++;
      return turnEvents(
        (_, _) => [
          {'type': 'text', 'text': 'Intake: 2,050 kcal a day.'},
          {
            'type': 'done',
            'reason': reason,
            'usage': {'sends': 1, 'inputTokens': 0, 'outputTokens': 0},
          },
        ],
      )(request);
    };
    final writer = h.container.read(weeklyReviewWriterProvider(week).notifier);
    Future<String?> stored() => h.container
        .read(settingsStoreProvider)
        .read(AppSettings.weeklyReview(week));

    await writer.write(summary);
    expect(posts, 1);
    expect(
      h.container.read(weeklyReviewWriterProvider(week)),
      WeeklyReviewWriting.failed,
    );
    expect(await stored(), isNull);
    // Not again on its own (one paid attempt per session).
    await writer.write(summary);
    expect(posts, 1);

    reason = 'answered';
    await writer.write(summary, retry: true);
    expect(posts, 2);
    expect(
      h.container.read(weeklyReviewWriterProvider(week)),
      WeeklyReviewWriting.written,
    );
    expect(await stored(), 'Intake: 2,050 kcal a day.');
    await writer.write(summary, retry: true);
    expect(posts, 2);
  });
}
