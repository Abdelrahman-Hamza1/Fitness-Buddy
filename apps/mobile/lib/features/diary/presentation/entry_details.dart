import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/domain_labels.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/diary/presentation/entry_row.dart';
import 'package:material_ui/material_ui.dart';

/// What an opened item shows (DY-021, read-only in A08a): both names
/// (LC-005), where the numbers come from, the amount, the time, every
/// nutrient of the logged amount and, for an estimate, its range and
/// assumptions (AI-072 edits arrive with A08b).
class EntryDetailsPanel extends StatelessWidget {
  /// Creates the panel for [entry].
  const new({required this.entry, super.key});

  /// The item, with its stored snapshot.
  final DiaryEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final food = entry.food;
    final provenance = food.provenance;
    final n = entry.snapshot;
    final ar = food.names.ar;
    final time = entry.time.localDateTime;
    final resolved = _resolvedAmount(l10n, entry.amount);
    String grams(double v) =>
        l10n.foodNutrientGrams(DisplayRounding.nutrientGrams(v));
    final source = _sourceText(l10n, entry);
    final range = provenance.range;
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
            const SizedBox(height: FbSpace.s2),
            _DetailRow(
              l10n.diaryDetailsAmount,
              resolved == null
                  ? entryAmountText(l10n, entry.amount)
                  : l10n.diaryDetailsAmountResolved(
                      entryAmountText(l10n, entry.amount),
                      resolved,
                    ),
            ),
            _DetailRow(
              l10n.diaryDetailsTime,
              MaterialLocalizations.of(context).formatTimeOfDay(
                TimeOfDay(hour: time.hour, minute: time.minute),
                alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(
                  context,
                ),
              ),
            ),
            if (range != null)
              _DetailRow(
                l10n.diaryDetailsEstimateRange,
                l10n.diaryDetailsEstimateRangeValue(
                  DisplayRounding.kcal(range.lowKcal),
                  DisplayRounding.kcal(range.highKcal),
                ),
              ),
            Divider(color: scheme.outlineVariant),
            Semantics(
              header: true,
              child: Text(
                l10n.diaryDetailsNutrition,
                style: FbType.label.copyWith(color: scheme.onSurface),
              ),
            ),
            const SizedBox(height: FbSpace.s1),
            _DetailRow(
              l10n.foodNutrientEnergy,
              l10n.foodSheetKcal(DisplayRounding.kcal(n.kcal)),
            ),
            _DetailRow(l10n.foodNutrientProtein, grams(n.protein)),
            _DetailRow(l10n.foodNutrientCarbs, grams(n.carbs)),
            _DetailRow(l10n.foodNutrientFat, grams(n.fat)),
            _DetailRow(l10n.foodNutrientFiber, grams(n.fiber)),
            for (final key in NutrientKey.values)
              if (n.extra(key) case final value?)
                _DetailRow(
                  nutrientKeyLabel(l10n, key),
                  key.unit == NutrientUnit.milligram
                      ? l10n.foodNutrientMilligrams(
                          DisplayRounding.milligrams(value).toDouble(),
                        )
                      : grams(value),
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
                    assumption,
                    style: FbType.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The canonical amount ("60 g") when the logged unit isn't already it.
String? _resolvedAmount(AppLocalizations l10n, EntryAmount amount) {
  final unit = amount.basis == NutrientBasis.per100g ? 'g' : 'ml';
  if (amount.input.unitCode == unit) return null;
  return l10n.foodResultServing(
    DisplayRounding.foodAmount(amount.amount).toDouble(),
    unitLabel(l10n, unit, amount.amount),
  );
}

String _sourceText(AppLocalizations l10n, DiaryEntry entry) {
  final source = switch (entry.food.provenance.source) {
    FoodSource.yours => l10n.diarySourceYours,
    FoodSource.database => l10n.diarySourceDatabase,
    FoodSource.reference => l10n.diarySourceReference,
    FoodSource.estimate => l10n.diarySourceEstimate,
  };
  return entry.editedByUser ? l10n.diarySourceEdited(source) : source;
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
