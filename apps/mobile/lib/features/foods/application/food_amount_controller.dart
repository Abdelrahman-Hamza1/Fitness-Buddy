import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/foods/application/food_choice.dart';
import 'package:fb_mobile/features/foods/application/foods_providers.dart';
import 'package:fb_mobile/features/foods/application/log_food.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'food_amount_controller.g.dart';

/// Immutable input and derived numbers for one amount sheet.
final class FoodAmountState {
  /// A sheet input; the initial portion is selected by the pure domain.
  const new({
    required this.food,
    required this.date,
    required this.amountBuffer,
    required this.unit,
    this.system = UnitSystem.metric,
    this.slotId,
    this.replacing,
    this.submitting = false,
  });

  /// Selected pack food or retired snapshot.
  final FoodChoice food;

  /// Requested diary day, including past dates.
  final LocalDate date;

  /// Display preference; changing it never replaces typed input.
  final UnitSystem system;

  /// Explicit route choice or automatically assigned slot.
  final String? slotId;

  /// Version captured when opening replace mode.
  final VersionedId? replacing;

  /// Decimal text, retaining incomplete edits without inventing an amount.
  final String amountBuffer;

  /// Unit code retained across compatible state switches.
  final String unit;

  /// Prevents duplicate submissions while an apply is running.
  final bool submitting;

  /// Validated positive input, or null while incomplete/invalid.
  Quantity? get input {
    final amount = double.tryParse(amountBuffer);
    return amount == null || !amount.isFinite || amount <= 0
        ? null
        : Quantity(amount, unit);
  }

  /// Resolves the typed input without a state conversion.
  QuantityResolution? get resolution =>
      input == null ? null : food.measures.resolve(input!);

  /// Locally calculated nutrients at storage precision.
  NutrientSnapshot? get snapshot => input == null
      ? null
      : switch (const NutritionCalculator().compute(
          per100: food.per100,
          measures: food.measures,
          input: input!,
        )) {
          Computed(:final snapshot) => snapshot,
          NotComputed() => null,
        };

  /// A valid amount, no apply in flight, and a meal chosen for a new log.
  bool get canAdd =>
      snapshot != null && !submitting && (replacing != null || slotId != null);

  /// Food servings first, then every other resolvable unit.
  List<String> get units => UnitOptions.of(food.measures, system: system);

  /// Display-only yield conversion; never persisted.
  YieldNote? get yieldNote {
    final resolved = resolution;
    final group = food.yieldGroup;
    final from = food.state;
    if (resolved is! Resolved ||
        resolved.basis != NutrientBasis.per100g ||
        group == null ||
        from == null) {
      return null;
    }
    for (final to in FoodState.values) {
      if (to == from) continue;
      final note = food.yields?.convert(
        amount: Mass.grams(resolved.amount),
        group: group,
        from: from,
        to: to,
      );
      if (note != null) return note;
    }
    return null;
  }

  /// Replaces edited fields while keeping all other sheet choices.
  FoodAmountState copyWith({
    UnitSystem? system,
    FoodChoice? food,
    String? amountBuffer,
    String? unit,
    String? slotId,
    bool clearSlot = false,
    VersionedId? replacing,
    bool? submitting,
  }) => FoodAmountState(
    system: system ?? this.system,
    replacing: replacing ?? this.replacing,
    food: food ?? this.food,
    date: date,
    amountBuffer: amountBuffer ?? this.amountBuffer,
    unit: unit ?? this.unit,
    slotId: clearSlot ? null : slotId ?? this.slotId,
    submitting: submitting ?? this.submitting,
  );
}

/// Per-sheet notifier exposing immutable input and derived nutrition state.
@riverpod
class FoodAmountController extends _$FoodAmountController {
  @override
  Future<FoodAmountState> build(
    FoodChoiceRef choice,
    LocalDate date, {
    String? slotId,
    ParsedAmount? carried,
    VersionedId? replacing,
  }) async {
    final food = await ref.watch(foodChoiceProvider(choice).future);
    if (food == null) throw StateError('foodUnavailable');
    // Read once: slot edits must not rebuild the sheet or reset its input.
    ref.listen(foodSlotsProvider(date), (previous, next) {
      final current = state.value;
      final slots = next.value;
      if (current != null &&
          current.replacing == null &&
          current.slotId != null &&
          slots != null &&
          !slots.any((s) => s.id == current.slotId && s.active)) {
        state = AsyncData(current.copyWith(clearSlot: true));
      }
    });
    final slots = await ref.read(foodSlotsProvider(date).future);
    final mode = slotModeOf(slots);
    final clock = ref.watch(clockProvider);
    final entry = replacing == null
        ? null
        : await ref
              .read(diaryRepositoryProvider)
              .watchEntry(replacing.id)
              .first;
    ref.listen(unitSystemProvider, (previous, next) {
      final current = state.value;
      if (current != null && next.value != null) {
        state = AsyncData(current.copyWith(system: next.value));
      }
    });
    final system = await ref.read(unitSystemProvider.future);
    final initial = food.defaultPortion(
      system: system,
      lastUsed: replacing == null
          ? food.lastUsed?.amount.input
          : entry?.amount.input,
      parsed: carried,
    );
    final liveSlots = ref.read(foodSlotsProvider(date)).value ?? slots;
    final chosenSlot =
        slotId ??
        const SlotAssigner().assign(
          EntryTime.now(clock).localDateTime.time.minuteOfDay,
          slots,
          mode,
        );
    return FoodAmountState(
      system: system,
      replacing: replacing,
      food: food,
      date: date,
      amountBuffer: '${initial.amount}',
      unit: initial.unitCode,
      slotId:
          replacing != null ||
              liveSlots.any((s) => s.id == chosenSlot && s.active)
          ? chosenSlot
          : null,
    );
  }

  /// Edits decimal text; invalid/zero input disables Add.
  void setAmount(String text) =>
      state = AsyncData(state.requireValue.copyWith(amountBuffer: text));

  /// Selects a unit, including an unresolved one that disables Add.
  void setUnit(String code) =>
      state = AsyncData(state.requireValue.copyWith(unit: code));

  /// An explicit route/user slot always wins over automatic assignment.
  void setSlot(String slotId) =>
      state = AsyncData(state.requireValue.copyWith(slotId: slotId));

  /// Change-food mode only: expects [entry]'s newer version from now on, once
  /// the item moved or was reloaded under the open sheet (A08 D12(4)). What
  /// was typed stays.
  void rebase(VersionedId entry) =>
      state = AsyncData(state.requireValue.copyWith(replacing: entry));

  /// Only loader-approved siblings may replace the weighed food. The typed
  /// input stays intact; no conversion or assumption is stored (PA6/PA12).
  bool switchState(String siblingId) {
    final current = state.requireValue;
    final food = current.food;
    final sibling = food.siblings.where((f) => f.id == siblingId).firstOrNull;
    if (sibling == null || current.submitting) return false;
    final next = catalogChoice(
      sibling,
      siblings: [
        ?food.catalogFood,
        ...food.siblings.where((f) => f.id != siblingId),
      ],
      yields: food.yields,
    );
    // The typed input stays as typed. Only a unit the other food can't
    // measure (a loaf it has no weight for) falls back to its basis unit,
    // so Add is never left disabled with no chip to fix it.
    final unit =
        UnitOptions.of(
          next.measures,
          system: current.system,
        ).contains(current.unit)
        ? current.unit
        : next.measures.basis.unitCode;
    state = AsyncData(current.copyWith(food: next, unit: unit));
    return true;
  }

  /// Submits the exact validated state and records the direct action's undo.
  Future<LogFoodOutcome> submit() async {
    final current = state.requireValue;
    if (current.replacing == null && current.slotId == null) {
      return const FoodLogFailed('noMeal');
    }
    final typed = current.input;
    if (!current.canAdd || typed == null) {
      return const FoodLogFailed('invalidAmount');
    }
    state = AsyncData(current.copyWith(submitting: true));
    try {
      if (current.replacing case final entry?) {
        return await ref.read(replaceEntryFoodProvider)(
          entry,
          current.food,
          typed,
        );
      }
      return await ref.read(logFoodProvider)(
        choice: current.food,
        input: typed,
        date: current.date,
        slotId: current.slotId,
      );
    } finally {
      if (ref.mounted) {
        state = AsyncData(state.requireValue.copyWith(submitting: false));
      }
    }
  }
}
