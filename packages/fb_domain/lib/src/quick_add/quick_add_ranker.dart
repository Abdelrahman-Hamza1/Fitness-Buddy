import 'dart:math' as math;

import 'package:fb_domain/src/diary/diary_entry.dart';
import 'package:fb_domain/src/diary/food_ref.dart';
import 'package:fb_domain/src/diary/saved_meal.dart';
import 'package:fb_domain/src/quick_add/food_key.dart';
import 'package:fb_domain/src/quick_add/saved_meal_matcher.dart';
import 'package:fb_domain/src/time/local_date.dart';
import 'package:fb_domain/src/time/local_time.dart';

/// All tunable D12/D13 constants in one immutable value.
final class QuickAddWeights {
  /// Defaults are the reviewed A09 formula, not learned user data.
  const new({
    this.historyDays = 60,
    this.mealWindowMinutes = 90,
    this.halfLifeDays = 14,
    this.kernelMinutes = 75,
    this.baseline = 0.02,
    this.slotWeight = 0.58,
    this.timeWeight = 0.40,
    this.weekdayMultiplier = 1.25,
    this.suppressionMultiplier = 0.2,
  });

  /// Inclusive history window length.
  final int historyDays;

  /// Inclusive meal matching window.
  final int mealWindowMinutes;

  /// Recency half-life.
  final double halfLifeDays;

  /// Gaussian time-of-day kernel width.
  final double kernelMinutes;

  /// Minimum contribution.
  final double baseline;

  /// Same-slot contribution.
  final double slotWeight;

  /// Circular-time contribution.
  final double timeWeight;

  /// Same-weekday multiplier.
  final double weekdayMultiplier;

  /// Already-logged multiplier.
  final double suppressionMultiplier;
}

/// Caller-supplied wall-clock context; viewing history does not shift now.
final class QuickAddContext {
  /// Slot assignment belongs to the caller, which owns the active slots.
  const new({
    required this.now,
    required this.weekday,
    required this.slotId,
    required this.targetDate,
  });

  /// Current local clock.
  final LocalDateTime now;

  /// Current local weekday.
  final DayOfWeek weekday;

  /// Context slot, null only when no slot exists.
  final String? slotId;

  /// Viewed diary day, independently of the history window.
  final LocalDate targetDate;
}

/// Typed chip payload. A27 can add an open-batch case.
sealed class QuickAddCandidate {
  const new();

  /// Stable deterministic tie-break key; never log it.
  String get key;
}

/// Individual live food with last-used inputs for guarded logging (FD-022).
final class FoodCandidate extends QuickAddCandidate {
  /// The latest in-slot entry takes precedence for amount selection.
  const new({
    required this.foodKey,
    required this.latest,
    required this.latestInSlot,
  });

  /// Source identity.
  final FoodKey foodKey;

  /// Latest unassigned entry overall.
  final DiaryEntry latest;

  /// Latest unassigned entry in the context slot, when present.
  final DiaryEntry? latestInSlot;

  /// Original amount to repeat.
  DiaryEntry get lastUsed => latestInSlot ?? latest;
  @override
  String get key => foodKey.key;
  @override
  String toString() => 'FoodCandidate';
}

/// Live saved snapshot, logged through its exact-source guard.
final class SavedMealCandidate extends QuickAddCandidate {
  /// A nonempty meal that has attributed usage.
  const new(this.meal);

  /// Snapshot currently shown to the user.
  final SavedMeal meal;
  @override
  String get key => 'savedMeal:${meal.id}';
  @override
  String toString() => 'SavedMealCandidate';
}

/// Ranked typed payload; scores are private usage data.
final class RankedChip {
  /// Derived from canonical usage, with target-day suppression applied.
  const new({
    required this.candidate,
    required this.score,
    required this.occurrences,
    required this.latestUse,
  });

  /// Logging payload.
  final QuickAddCandidate candidate;

  /// Suppressed ranking score.
  final double score;

  /// Attributed usage count.
  final int occurrences;

  /// Latest local usage time.
  final LocalDateTime latestUse;
  @override
  String toString() => 'RankedChip';
}

/// Pure deterministic ranking over explicitly supplied live snapshots.
final class QuickAddRanker {
  /// Name identity normalization belongs to fb_text in the app.
  const new({required this.nameKey, this.weights = const QuickAddWeights()});

  /// Normalizes estimate identities.
  final String Function(String) nameKey;

  /// Tunable constants.
  final QuickAddWeights weights;

  /// Attributes meals before foods; suppresses using the separate viewed day.
  List<RankedChip> rank({
    required Iterable<DiaryEntry> windowEntries,
    required Iterable<DiaryEntry> targetDayEntries,
    required Iterable<SavedMeal> meals,
    required Set<FoodKey> liveFoodKeys,
    required QuickAddContext context,
    int limit = 6,
  }) {
    if (limit <= 0 || context.slotId == null) return const [];
    bool eligible(EntryFood food) =>
        food.ref.kind != FoodRefKind.personal ||
        liveFoodKeys.contains(FoodKey.of(food, nameKey: nameKey));
    final liveMeals = meals
        .where(
          (m) => m.items.isNotEmpty && m.items.every((i) => eligible(i.food)),
        )
        .toList();
    final matcher = SavedMealMatcher(windowMinutes: weights.mealWindowMinutes);
    final attributed = matcher.attribute(
      windowEntries.where((e) {
        final age = e.localDate.daysUntil(context.now.date);
        return age >= 0 && age < weights.historyDays && eligible(e.food);
      }),
      liveMeals,
      nameKey: nameKey,
    );
    final target = targetDayEntries
        .where(
          (e) =>
              e.localDate == context.targetDate &&
              e.slotId == context.slotId &&
              eligible(e.food),
        )
        .toList();
    final targetAttribution = matcher.attribute(
      target,
      liveMeals,
      nameKey: nameKey,
    );
    // Raw entries suppress foods even when a meal consumes them.
    final suppressed = <String>{
      for (final e in target) FoodKey.of(e.food, nameKey: nameKey).key,
      for (final o in targetAttribution.mealOccurrences)
        'savedMeal:${o.meal.id}',
    };
    final usage = <String, List<DiaryEntry>>{};
    final mealByKey = <String, SavedMeal>{};
    for (final o in attributed.mealOccurrences) {
      final key = 'savedMeal:${o.meal.id}';
      mealByKey[key] = o.meal;
      (usage[key] ??= []).add(o.first);
    }
    for (final e in attributed.unassignedEntries) {
      if (e.food.ref.kind == FoodRefKind.estimate) continue;
      (usage[FoodKey.of(e.food, nameKey: nameKey).key] ??= []).add(e);
    }
    final ranked = <RankedChip>[];
    for (final MapEntry(:key, :value) in usage.entries) {
      // Summation order must not change the floating-point score (PA4).
      value.sort((a, b) {
        final date = a.localDate.compareTo(b.localDate);
        if (date != 0) return date;
        final time = a.time.localDateTime.time.compareTo(
          b.time.localDateTime.time,
        );
        return time != 0 ? time : a.id.compareTo(b.id);
      });
      var score = 0.0;
      for (final e in value) {
        final age = e.localDate.daysUntil(context.now.date);
        final delta =
            (e.time.localDateTime.minuteOfDay - context.now.minuteOfDay).abs();
        final distance = math.min(delta, LocalTime.minutesPerDay - delta);
        final kernel = math.exp(
          -distance *
              distance /
              (2 * weights.kernelMinutes * weights.kernelMinutes),
        );
        score +=
            math.pow(2, -age / weights.halfLifeDays) *
            (weights.baseline +
                (e.slotId == context.slotId ? weights.slotWeight : 0) +
                weights.timeWeight * kernel) *
            (e.localDate.weekday == context.weekday
                ? weights.weekdayMultiplier
                : 1);
      }
      if (suppressed.contains(key)) score *= weights.suppressionMultiplier;
      final latest = value.reduce((a, b) => compareEntryTime(a, b) > 0 ? a : b);
      final inSlot = value.where((e) => e.slotId == context.slotId).toList()
        ..sort(compareEntryTime);
      final meal = mealByKey[key];
      ranked.add(
        RankedChip(
          candidate: meal == null
              ? FoodCandidate(
                  foodKey: FoodKey.of(latest.food, nameKey: nameKey),
                  latest: latest,
                  latestInSlot: inSlot.isEmpty ? null : inSlot.last,
                )
              : SavedMealCandidate(meal),
          score: score,
          occurrences: value.length,
          latestUse: value.last.time.localDateTime,
        ),
      );
    }
    ranked.sort((a, b) {
      final score = b.score.compareTo(a.score);
      if (score != 0) return score;
      final count = b.occurrences.compareTo(a.occurrences);
      if (count != 0) return count;
      final latest = b.latestUse.compareTo(a.latestUse);
      return latest != 0 ? latest : a.candidate.key.compareTo(b.candidate.key);
    });
    return List.unmodifiable(ranked.take(math.min(limit, 6)));
  }
}
