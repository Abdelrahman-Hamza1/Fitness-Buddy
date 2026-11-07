import 'dart:convert';

import 'package:fb_api_client/fb_api_client.dart' hide LocalDate;
import 'package:fb_domain/fb_domain.dart';

/// The fixed English message of a weekly-review turn (never user content;
/// the server needs a non-empty message, B26 D3).
const String weeklyReviewMessage = 'Weekly review';

/// The start body of a `weeklyReview` turn (A68 D6, B26 D3): [chat] (the
/// usual start body: profile and snapshot) with no history, personal slice,
/// summary or compaction, and the week's aggregates only ([summary], with
/// this week's pending check-in from [fromKcal] to [toKcal]). Numbers are
/// clamped to the contract's bounds. As JSON, ready for the runner.
Map<String, Object?> weeklyReviewBody(
  BuddyTurnStart chat,
  WeeklySummary summary, {
  double? fromKcal,
  double? toKcal,
}) {
  double? kcal(double? v) => v?.clamp(0, 20000).toDouble();
  final workouts = summary.workouts;
  final body = chat.copyWith(
    mode: BuddyTurnMode.weeklyReview,
    message: const BuddyTurnMessage(text: weeklyReviewMessage, image: null),
    history: const [],
    summary: null,
    compact: null,
    personal: const [],
    ackTurn: null,
    priorAttempt: null,
    trace: false,
    weekly: BuddyWeeklySummary(
      start: '${summary.start}',
      end: '${summary.end}',
      elapsedDays: summary.elapsedDays,
      countedDays: summary.countedDays,
      targetDays: summary.targetDays,
      daysWithinTarget: summary.daysWithinTarget,
      proteinTargetDays: summary.proteinTargetDays,
      proteinDaysHit: summary.proteinDaysHit,
      averageKcal: kcal(summary.averageKcal),
      averageTargetKcal: kcal(summary.averageTargetKcal),
      averageFiberG: summary.averageFiber?.clamp(0, 5000).toDouble(),
      trendChangeKg: summary.trendChangeKg?.clamp(-100, 100).toDouble(),
      workouts: workouts == null
          ? null
          : BuddyWeeklyWorkouts(
              sessions: workouts.sessions.clamp(0, 100),
              planned: workouts.planned?.clamp(0, 7),
              prs: workouts.prs.clamp(0, 1000),
            ),
      estimated: summary.estimated,
      checkIn: fromKcal == null || toKcal == null
          ? null
          : BuddyWeeklyCheckIn(
              currentKcal: kcal(fromKcal)!,
              proposedKcal: kcal(toKcal)!,
            ),
    ),
  );
  return (jsonDecode(jsonEncode(body.toJson())) as Map<String, Object?>)
    ..remove('priorAttempt');
}
