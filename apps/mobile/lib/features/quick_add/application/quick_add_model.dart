import 'dart:async';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_text/fb_text.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quick_add_model.g.dart';

/// A rendered chip carries the food choice/version the user actually saw.
final class QuickAddChip {
  /// Choice is prepared from current food values, or the guarded snapshot.
  const new({required this.ranked, required this.slotId, this.choice});

  /// Pure ranking evidence.
  final RankedChip ranked;

  /// Shown context slot, shared by logging and suppression.
  final String slotId;

  /// Prepared current or fallback food; absent for saved-meal chips.
  final FoodChoice? choice;

  /// Stable pending identity; never log.
  String get key => ranked.candidate.key;

  /// Private display name.
  String get name => switch (ranked.candidate) {
    FoodCandidate(:final lastUsed) =>
      choice?.names.en ?? lastUsed.food.names.en,
    SavedMealCandidate(:final meal) => meal.name,
  };
}

/// Reconstructs only the candidate's selected last-used amount (FD-022).
FoodHistoryItem quickAddHistory(FoodCandidate candidate) {
  final entry = candidate.lastUsed;
  return FoodHistoryItem(
    food: entry.food,
    amount: entry.amount,
    uses: 1,
    editedByUser: entry.editedByUser,
    // HistoryChoice needs an HLC but never uses it to resolve the snapshot.
    lastUsedHlc: Hlc(wallMs: 0, counter: 0, deviceId: entry.id),
  );
}

/// Keeps an unresolvable serving on its original nutrient snapshot (F2).
FoodChoice quickAddChoice(FoodCandidate candidate, FoodChoice current) =>
    current.measures.resolve(candidate.lastUsed.amount.input) is Resolved
    ? current
    : historyChoice(quickAddHistory(candidate), guard: current.guard);

/// Reschedules at slot boundaries, local midnight, or at most 30 minutes.
/// An on-resume invalidation also refreshes zone changes after backgrounding.
@riverpod
QuickAddContext quickAddContext(Ref ref) {
  final clock = ref.watch(clockProvider);
  final slots = ref.watch(foodSlotsProvider).value ?? const <MealSlot>[];
  final now = EntryTime.now(clock);
  final local = now.localDateTime;
  var delay = const Duration(minutes: 30);
  final midnight = nextDayStartUtc(
    local.date,
    clock,
  ).difference(now.occurredAtUtc);
  if (midnight > Duration.zero && midnight < delay) delay = midnight;
  for (final slot in slots) {
    if (!slot.active || slot.mode != SlotMode.normal || slot.window == null) {
      continue;
    }
    for (final minute in [slot.window!.startMin, slot.window!.endMin]) {
      final time = LocalTime.ofMinuteOfDay(minute);
      final date = time.compareTo(local.time) > 0
          ? local.date
          : local.date.plusDays(1);
      final boundary = EntryTime.fromLocal(time.on(date), clock).occurredAtUtc;
      final until = boundary.difference(now.occurredAtUtc);
      if (until > Duration.zero && until < delay) delay = until;
    }
  }
  final timer = Timer(delay, ref.invalidateSelf);
  final lifecycle = AppLifecycleListener(onResume: ref.invalidateSelf);
  ref.onDispose(() {
    timer.cancel();
    lifecycle.dispose();
  });
  return QuickAddContext(
    now: local,
    weekday: local.date.weekday,
    slotId: const SlotAssigner().assign(
      local.minuteOfDay,
      slots,
      SlotMode.normal,
    ),
    targetDate: local.date,
  );
}

/// Rebuildable 60-day usage input, never subscribed before the day's first
/// data frame has been drawn.
@riverpod
Stream<List<DiaryEntry>> quickAddWindow(Ref ref, LocalDate today) =>
    ref.watch(diaryRepositoryProvider).watchEntries(today.plusDays(-59), today);

/// False until the frame that first showed the viewed day's data has been
/// drawn, then true (A09 D14). The day's own frame stays free of chip work: no
/// history, meal, personal-food or slot subscription and no ranking happens
/// before this flips. A post-frame step, not a timer, so it follows the frame
/// however long that frame takes.
@riverpod
class QuickAddActivation extends _$QuickAddActivation {
  @override
  bool build(LocalDate viewedDate) {
    SchedulerBinding.instance
      ..addPostFrameCallback((_) {
        if (ref.mounted) state = true;
      })
      // A callback alone doesn't make a frame when none is under way.
      ..ensureVisualUpdate();
    return false;
  }
}

/// Scoped to the viewed day; its raw entries independently drive suppression.
@riverpod
AsyncValue<List<QuickAddChip>> quickAddChips(Ref ref, LocalDate viewedDate) {
  final raw = ref.watch(dayViewProvider(viewedDate));
  if (raw.value == null) {
    return raw.hasError
        ? AsyncError(raw.error!, raw.stackTrace!)
        : const AsyncLoading();
  }
  // Created only once the day has data, so its post-frame step follows the
  // data frame (D14); until then nothing below is subscribed.
  if (!ref.watch(quickAddActivationProvider(viewedDate))) {
    return const AsyncLoading();
  }
  final context = ref.watch(quickAddContextProvider);
  final window = ref.watch(quickAddWindowProvider(context.now.date));
  final meals = ref.watch(savedMealsProvider);
  final personal = ref.watch(personalFoodsProvider);
  final slots = ref.watch(foodSlotsProvider);
  for (final input in <AsyncValue<Object?>>[window, meals, personal, slots]) {
    if (input.hasError) return AsyncError(input.error!, input.stackTrace!);
    if (input.value == null) return const AsyncLoading();
  }
  final ranked = const QuickAddRanker(nameKey: identityKey).rank(
    windowEntries: window.value!,
    targetDayEntries: raw.value!.raw.entries,
    meals: meals.value!,
    liveFoodKeys: {
      for (final food in personal.value!)
        FoodKey(FoodRefKind.personal, food.id),
    },
    context: QuickAddContext(
      now: context.now,
      weekday: context.weekday,
      slotId: context.slotId,
      targetDate: viewedDate,
    ),
  );
  final chips = <QuickAddChip>[];
  AsyncValue<List<QuickAddChip>>? waiting;
  for (final chip in ranked) {
    final candidate = chip.candidate;
    FoodChoice? choice;
    if (candidate is FoodCandidate) {
      final history = quickAddHistory(candidate);
      if (candidate.foodKey.kind == FoodRefKind.personal) {
        // The live input is already observed by this build. Do not replace
        // its guard later at tap time, including a removed-serving fallback.
        final food = personal.value!
            .where((f) => f.id == candidate.foodKey.identity)
            .firstOrNull;
        if (food == null) continue;
        choice = personalChoice(food, history: history);
      } else {
        final loaded = ref.watch(
          foodChoiceProvider(FoodChoiceRef(candidate.lastUsed.food.ref)),
        );
        if (loaded.hasError) {
          waiting = AsyncError(loaded.error!, loaded.stackTrace!);
          continue;
        }
        if (loaded.isLoading) {
          waiting ??= const AsyncLoading();
          continue;
        }
        final current = loaded.value;
        choice =
            current == null ||
                (current.catalogFood == null && current.lastUsed != null)
            ? historyChoice(history)
            : current;
      }
      choice = quickAddChoice(candidate, choice);
    }
    chips.add(
      QuickAddChip(ranked: chip, slotId: context.slotId!, choice: choice),
    );
  }
  return waiting ?? AsyncData(List.unmodifiable(chips));
}
