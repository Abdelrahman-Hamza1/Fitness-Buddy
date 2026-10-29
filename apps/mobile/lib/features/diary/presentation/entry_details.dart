import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/amount_text.dart';
import 'package:fb_mobile/core/l10n/assumption_labels.dart';
import 'package:fb_mobile/core/l10n/domain_labels.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/diary/application/diary_actions.dart';
import 'package:fb_mobile/features/diary/presentation/entry_actions.dart';
import 'package:fb_mobile/features/diary/presentation/entry_amount_sheet.dart';
import 'package:fb_mobile/features/diary/presentation/entry_row.dart';
import 'package:fb_mobile/features/diary/presentation/move_entry_sheet.dart';
import 'package:fb_mobile/features/diary/presentation/nutrient_override_sheet.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// What an opened item shows and edits (DY-021, AI-072): both names (LC-005),
/// where the numbers come from, the choices for amount, food, meal and time,
/// every nutrient of the logged amount (tap one to type your own value), an
/// estimate's range and assumptions, and a plain Delete button. The Meal chip
/// shows the current meal and is the visible Move control (one tap opens the
/// meals), so neither action depends on a swipe or a screen reader. Every
/// edit is a direct action with Undo (UX-030).
class EntryDetailsPanel extends ConsumerWidget {
  /// Creates the panel for [entry]; [slots] are the meals it can move to.
  const new({required this.entry, required this.slots, super.key});

  /// The item, with its stored snapshot, at the version shown.
  final DiaryEntry entry;

  /// Every live meal of the day.
  final List<MealSlot> slots;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final food = entry.food;
    final provenance = food.provenance;
    final n = entry.snapshot;
    final ar = food.names.ar;
    final time = entry.time.localDateTime;
    final amount = foodAmountText(
      l10n,
      input: entry.amount.input,
      amount: entry.amount.amount,
      basis: entry.amount.basis,
      system: ref.watch(unitSystemProvider).value ?? UnitSystem.metric,
    );
    final pending = ref.watch(
      diaryActionsControllerProvider.select(
        (s) => s.pending.contains(entry.id),
      ),
    );
    final slot = slots.where((s) => s.id == entry.slotId).firstOrNull;
    String grams(double v) =>
        l10n.foodNutrientGrams(DisplayRounding.nutrientGrams(v));
    final source = _sourceText(l10n, entry);
    final range = provenance.range;
    void edit(NutrientField field) =>
        unawaited(showNutrientOverrideSheet(context, entry, field));
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: FbSpace.s4,
        end: FbSpace.s4,
        bottom: FbSpace.s2,
      ),
      child: FbCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                ar == null
                    ? food.names.en
                    : l10n.foodSheetNames(food.names.en, ar),
                style: FbType.title.copyWith(color: scheme.onSurface),
              ),
            ),
            const SizedBox(height: FbSpace.s2),
            Row(
              children: [
                FbSourceBadge(source: entrySourceOf(entry)),
                const SizedBox(width: FbSpace.s2),
                Expanded(
                  child: Text(
                    source,
                    style: FbType.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: FbSpace.s3),
            Wrap(
              spacing: FbSpace.s2,
              runSpacing: FbSpace.s2,
              children: [
                FbChoiceChip(
                  label: l10n.diaryDetailsAmount,
                  value: amount,
                  onTap: pending
                      ? null
                      : () => unawaited(showEntryAmountSheet(context, entry)),
                ),
                FbChoiceChip(
                  label: l10n.diaryChangeFood,
                  icon: FbIcons.search,
                  dropdown: false,
                  onTap: pending ? null : () => changeFoodOf(ref, entry),
                ),
                FbChoiceChip(
                  label: l10n.diaryChipMeal,
                  value: slot == null
                      ? l10n.diarySlotOther
                      : slotLabel(l10n, slot),
                  onTap: pending
                      ? null
                      : () =>
                            unawaited(chooseSlotAndMove(context, entry, slots)),
                ),
                FbChoiceChip(
                  label: l10n.diaryDetailsTime,
                  value: timeText(context, time.hour, time.minute),
                  onTap: pending
                      ? null
                      : () => unawaited(chooseTimeAndChange(context, entry)),
                ),
              ],
            ),
            if (range != null) ...[
              const SizedBox(height: FbSpace.s2),
              _DetailRow(
                l10n.diaryDetailsEstimateRange,
                l10n.diaryDetailsEstimateRangeValue(
                  DisplayRounding.kcal(range.lowKcal),
                  DisplayRounding.kcal(range.highKcal),
                ),
              ),
            ],
            Divider(color: scheme.outlineVariant),
            Semantics(
              header: true,
              child: Text(
                l10n.diaryDetailsNutrition,
                style: FbType.label.copyWith(color: scheme.onSurface),
              ),
            ),
            const SizedBox(height: FbSpace.s1),
            _NutrientRow(
              label: l10n.foodNutrientEnergy,
              value: l10n.foodSheetKcal(DisplayRounding.kcal(n.kcal)),
              onTap: pending ? null : () => edit(NutrientField.kcal),
            ),
            _NutrientRow(
              label: l10n.foodNutrientProtein,
              value: grams(n.protein),
              onTap: pending ? null : () => edit(NutrientField.protein),
            ),
            _NutrientRow(
              label: l10n.foodNutrientCarbs,
              value: grams(n.carbs),
              onTap: pending ? null : () => edit(NutrientField.carbs),
            ),
            _NutrientRow(
              label: l10n.foodNutrientFat,
              value: grams(n.fat),
              onTap: pending ? null : () => edit(NutrientField.fat),
            ),
            _NutrientRow(
              label: l10n.foodNutrientFiber,
              value: grams(n.fiber),
              onTap: pending ? null : () => edit(NutrientField.fiber),
            ),
            for (final field in NutrientField.values)
              if (field.extraKey case final key?)
                if (n.extra(key) case final value?)
                  _NutrientRow(
                    label: nutrientKeyLabel(l10n, key),
                    value: key.unit == NutrientUnit.milligram
                        ? l10n.foodNutrientMilligrams(
                            DisplayRounding.milligrams(value).toDouble(),
                          )
                        : grams(value),
                    onTap: pending ? null : () => edit(field),
                  ),
            if (provenance.assumptions.isNotEmpty) ...[
              Divider(color: scheme.outlineVariant),
              Semantics(
                header: true,
                child: Text(
                  l10n.diaryDetailsAssumptions,
                  style: FbType.label.copyWith(color: scheme.onSurface),
                ),
              ),
              const SizedBox(height: FbSpace.s1),
              for (final assumption in provenance.assumptions)
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    vertical: FbSpace.s1,
                  ),
                  child: Text(
                    // Stored codes become words; unknown or legacy text a
                    // generic label, never the raw string (A22 D17).
                    assumptionText(
                      l10n,
                      assumption,
                      system:
                          ref.watch(unitSystemProvider).value ??
                          UnitSystem.metric,
                    ),
                    style: FbType.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
            Divider(color: scheme.outlineVariant),
            Wrap(
              spacing: FbSpace.s2,
              runSpacing: FbSpace.s2,
              children: [
                FbButton.secondary(
                  label: l10n.diaryDelete,
                  icon: FbIcons.delete,
                  onPressed: pending
                      ? null
                      : () => unawaited(deleteEntryWithUndo(context, entry)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _sourceText(AppLocalizations l10n, DiaryEntry entry) {
  final source = entry.food.provenance.source;
  if (entry.editedByUser) {
    return switch (source) {
      FoodSource.yours => l10n.diarySourceYoursEdited,
      FoodSource.database => l10n.diarySourceEdited(
        l10n.diarySourceNounDatabase,
      ),
      FoodSource.reference => l10n.diarySourceEdited(
        l10n.diarySourceNounReference,
      ),
      FoodSource.estimate => l10n.diarySourceEdited(
        l10n.diarySourceNounEstimate,
      ),
    };
  }
  return switch (source) {
    FoodSource.yours => l10n.diarySourceYours,
    FoodSource.database => l10n.diarySourceDatabase,
    FoodSource.reference => l10n.diarySourceReference,
    FoodSource.estimate => l10n.diarySourceEstimate,
  };
}

class _DetailRow extends StatelessWidget {
  const new(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: FbSpace.s1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: FbType.bodySmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: FbSpace.s3),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: FbType.numeric(FbType.bodySmall)
                    .copyWith(color: scheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A nutrient value that opens its editor on tap (AI-072): at least 48 dp
/// high, one button for a screen reader.
class _NutrientRow extends StatelessWidget {
  const new({required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      value: value,
      hint: context.l10n.diaryNutrientEditHint,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: FbSpace.s7),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: FbType.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: FbSpace.s3),
              Text(
                value,
                textAlign: TextAlign.end,
                style: FbType.numeric(FbType.bodySmall)
                    .copyWith(color: scheme.onSurface),
              ),
              const SizedBox(width: FbSpace.s2),
              Icon(FbIcons.edit, size: 16, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
