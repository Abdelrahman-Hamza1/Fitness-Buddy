import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/day_label.dart';
import 'package:fb_mobile/core/l10n/domain_labels.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_snack_bar.dart';
import 'package:fb_mobile/features/diary/application/day_slots.dart';
import 'package:fb_mobile/features/diary/application/saved_meal_actions.dart';
import 'package:fb_mobile/features/diary/application/saved_meals.dart';
import 'package:fb_mobile/features/diary/presentation/entry_row.dart';
import 'package:fb_mobile/features/diary/presentation/large_text.dart';
import 'package:fb_mobile/features/diary/presentation/move_to_slot_sheet.dart';
import 'package:fb_mobile/features/diary/presentation/saved_meals/rename_saved_meal_sheet.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// One saved meal (DY-031, FD-010, A09 D11): its items with each item's own
/// badge, the totals, a Meal chip and a Day chip (the meal of the current
/// time and today until changed), and **Log**, a direct action with Undo that
/// copies the saved items into that meal and day. A pencil renames it and the
/// overflow menu deletes it, both with Undo.
///
/// The screen watches its meal by ID, so a rename or an edit elsewhere shows
/// at once and a deleted meal says so. What it logs is always the meal as
/// shown; if that changed in the moment between, nothing is written and the
/// refusal is said (PA1).
class SavedMealScreen extends ConsumerStatefulWidget {
  /// Creates the screen for the saved meal [id].
  const new({required this.id, super.key});

  /// The saved meal to show.
  final String id;

  @override
  ConsumerState<SavedMealScreen> createState() => _SavedMealScreenState();
}

class _SavedMealScreenState extends ConsumerState<SavedMealScreen> {
  /// The day to log into; null follows today.
  LocalDate? _day;

  /// The chosen meal; null is the meal of the current time.
  String? _slotId;

  bool _busy = false;

  LocalDate get _today => EntryTime.now(ref.read(clockProvider)).localDate;

  /// The chosen day's meals (DY-012: Ramadan on a fasting day).
  SlotMode get _mode =>
      ref.read(daySlotsProvider(_day ?? _today)).value?.mode ?? SlotMode.normal;

  /// The meal a log lands in: the chosen one, else the meal of the current
  /// time, else the first one.
  String? _targetSlot(List<MealSlot> slots) {
    final chosen = _slotId;
    if (chosen != null && slots.any((s) => s.id == chosen)) return chosen;
    final now = EntryTime.now(ref.read(clockProvider)).localDateTime;
    final day = ref.read(daySlotsProvider(_day ?? _today)).value;
    return day?.assign(now.minuteOfDay) ??
        movableSlots(slots, _mode).firstOrNull?.id;
  }

  Future<void> _pickDay() async {
    final today = _today;
    final day = _day ?? today;
    final picked = await showFbDatePicker(
      context,
      initialDate: DateTime(day.year, day.month, day.day),
      lastDate: DateTime(today.year, today.month, today.day),
    );
    if (picked == null || !mounted) return;
    setState(() => _day = LocalDate(picked.year, picked.month, picked.day));
  }

  Future<void> _pickSlot(List<MealSlot> slots) async {
    final l10n = context.l10n;
    final target = _targetSlot(slots);
    final chosen = await showFbSheet<MealSlot>(
      context,
      title: l10n.savedMealPickMealTitle,
      builder: (sheet) => MoveToSlotList(
        slots: movableSlots(slots, _mode),
        currentSlotId: target ?? '',
        onPick: (slot) => Navigator.of(sheet).pop(slot),
      ),
    );
    if (chosen == null || !mounted) return;
    setState(() => _slotId = chosen.id);
  }

  Future<void> _log(SavedMeal meal, String slotId) async {
    final host = Navigator.of(context, rootNavigator: true).context;
    final today = _today;
    final day = _day ?? today;
    setState(() => _busy = true);
    final outcome = await ref
        .read(savedMealActionsProvider)
        .log(meal, day, slotId);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!host.mounted) return;
    switch (outcome) {
      case SavedMealDone(:final undoEntryId):
        showUndoFeedback(
          host,
          message: withDayClause(
            host,
            host.l10n.quickAddLoggedItems(meal.name, meal.items.length),
            day,
            today,
          ),
          undoEntryId: undoEntryId,
        );
      case SavedMealFailed(:final reason):
        showFbSnackBar(
          host,
          reason == SavedMealFailure.changed
              ? host.l10n.quickAddChanged
              : host.l10n.diaryActionFailed,
        );
      case SavedMealPending() || SavedMealUnchanged():
        break;
    }
  }

  Future<void> _openMenu(SavedMeal meal) async {
    final l10n = context.l10n;
    final delete = await showFbSheet<bool>(
      context,
      builder: (sheet) => FbListRow(
        title: l10n.savedMealDeleteAction,
        leading: const Icon(FbIcons.delete),
        onTap: () => Navigator.of(sheet).pop(true),
      ),
    );
    if (delete != true || !mounted) return;
    await _delete(meal);
  }

  Future<void> _delete(SavedMeal meal) async {
    final host = Navigator.of(context, rootNavigator: true).context;
    final navigator = ref.read(appNavigatorProvider);
    final outcome = await ref.read(savedMealActionsProvider).delete(meal);
    if (!host.mounted) return;
    switch (outcome) {
      case SavedMealDone(:final undoEntryId, :final args):
        if (mounted) navigator.pop();
        showUndoFeedback(
          host,
          message: host.l10n.savedMealDeletedMessage('${args['name']}'),
          undoEntryId: undoEntryId,
        );
      case SavedMealFailed(:final reason):
        showFbSnackBar(
          host,
          reason == SavedMealFailure.changed
              ? host.l10n.savedMealChangedDelete
              : host.l10n.diaryActionFailed,
        );
      case SavedMealPending() || SavedMealUnchanged():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stored = ref.watch(savedMealProvider(widget.id));
    final meal = stored.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(meal?.name ?? l10n.savedMealDefaultTitle),
        actions: [
          if (meal != null) ...[
            FbIconButton(
              icon: FbIcons.edit,
              tooltip: l10n.savedMealRenameTooltip,
              onPressed: () =>
                  unawaited(showRenameSavedMealSheet(context, meal)),
            ),
            FbIconButton(
              icon: FbIcons.more,
              tooltip: l10n.savedMealMenuTooltip,
              onPressed: () => unawaited(_openMenu(meal)),
            ),
          ],
        ],
      ),
      body: switch (stored) {
        AsyncData(value: final loaded?) => _content(context, loaded),
        AsyncData() => Padding(
          padding: const EdgeInsetsDirectional.all(FbSpace.s4),
          child: FbInlineBanner(
            kind: FbInlineBannerKind.info,
            message: l10n.savedMealGone,
          ),
        ),
        AsyncError() => Padding(
          padding: const EdgeInsetsDirectional.all(FbSpace.s4),
          child: FbInlineBanner(
            kind: FbInlineBannerKind.error,
            message: l10n.savedMealsLoadFailed,
            actionLabel: l10n.foodTryAgain,
            onAction: () => ref.invalidate(savedMealProvider(widget.id)),
          ),
        ),
        _ => const Padding(
          padding: EdgeInsetsDirectional.all(FbSpace.s4),
          child: Column(
            spacing: FbSpace.s3,
            children: [
              FbSkeleton.line(height: 56),
              FbSkeleton.line(height: 56),
            ],
          ),
        ),
      },
    );
  }

  Widget _content(BuildContext context, SavedMeal meal) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final slots = ref.watch(savedMealSlotsProvider).value ?? const [];
    // Rebuild when the chosen day's meals load or change.
    ref.watch(daySlotsProvider(_day ?? _today));
    final today = _today;
    final slotId = _targetSlot(slots);
    final slot = slots.where((s) => s.id == slotId).firstOrNull;
    final totals = meal.totals;
    final empty = meal.items.isEmpty;
    final canLog = !empty && !_busy && slotId != null;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsetsDirectional.only(top: FbSpace.s3),
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: FbSpace.s4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: FbSpace.s1,
                  children: [
                    Text(
                      l10n.diaryKcal(DisplayRounding.kcal(totals.kcal)),
                      style: FbType.numeric(FbType.title)
                          .copyWith(color: scheme.onSurface),
                    ),
                    Text(
                      l10n.foodSheetMacros(
                        DisplayRounding.nutrientGrams(totals.protein),
                        DisplayRounding.nutrientGrams(totals.carbs),
                        DisplayRounding.nutrientGrams(totals.fat),
                        DisplayRounding.nutrientGrams(totals.fiber),
                      ),
                      style: FbType.numeric(FbType.bodySmall)
                          .copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.all(FbSpace.s4),
                child: Wrap(
                  spacing: FbSpace.s2,
                  runSpacing: FbSpace.s2,
                  children: [
                    FbChoiceChip(
                      label: l10n.diaryChipMeal,
                      value: slot == null ? null : slotLabel(l10n, slot),
                      onTap: () => unawaited(_pickSlot(slots)),
                    ),
                    FbChoiceChip(
                      label: l10n.diaryCopyDay,
                      value: dayLabel(context, _day ?? today, today),
                      onTap: () => unawaited(_pickDay()),
                    ),
                  ],
                ),
              ),
              FbSectionHeader(title: l10n.savedMealItemsHeader),
              for (final item in meal.items)
                _ItemRow(key: ValueKey(item.id), item: item),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.all(FbSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FbSpace.s2,
            children: [
              if (empty)
                Text(
                  l10n.savedMealNoItems,
                  style: FbType.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              FbButton.primary(
                label: slot == null
                    ? l10n.savedMealLogButton
                    : l10n.savedMealLogToButton(slotLabel(l10n, slot)),
                expand: true,
                onPressed: canLog ? () => unawaited(_log(meal, slotId)) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One saved item: its own badge, name, amount and calories (FD-010).
class _ItemRow extends ConsumerWidget {
  const new({required this.item, super.key});

  final SavedMealItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final amount = entryAmountText(
      l10n,
      item.amount,
      ref.watch(unitSystemProvider).value ?? UnitSystem.metric,
    );
    final kcal = l10n.diaryKcal(DisplayRounding.kcal(item.snapshot.kcal));
    final large = usesLargeText(context);
    final source = item.food.editedByUser
        ? FbSource.yours
        : fbSourceOf(item.food.provenance.source);
    final names = watchFoodNames(ref, item.food.names);
    final detail = large ? l10n.savedMealItemSubtitle(amount, kcal) : amount;
    return FbListRow(
      title: names.primary,
      subtitle: switch (names.secondary) {
        final ar? => l10n.foodResultSubtitle(isolateName(ar), detail),
        null => detail,
      },
      leading: FbSourceBadge(source: source),
      trailing: large
          ? null
          : MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.3,
              child: Text(kcal, style: FbType.numeric(FbType.body)),
            ),
    );
  }
}
