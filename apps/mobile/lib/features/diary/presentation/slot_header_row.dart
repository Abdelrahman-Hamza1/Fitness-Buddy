import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/domain_labels.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/diary/application/diary_view_state.dart';
import 'package:fb_mobile/features/diary/presentation/large_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The one-line summary of a meal's items: the first names, then "…".
String slotSummary(List<String> names) {
  const shown = 3;
  final head = names.take(shown).join(' · ');
  return names.length > shown ? '$head · …' : head;
}

/// A meal of the day (HM-007): its name, a one-line summary of the items,
/// the calories (or a dash) and a "+" that opens the food search for this
/// meal and day (1 tap, UX-013). A tap opens or closes the meal.
class SlotHeaderTile extends ConsumerWidget {
  /// Creates the row for [section] of [date].
  const new({
    required this.section,
    required this.date,
    required this.expanded,
    super.key,
  });

  /// The meal with its items and totals.
  final SlotSection section;

  /// The day the "+" adds to.
  final LocalDate date;

  /// Whether the items are shown below.
  final bool expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final slot = section.slot;
    final name = slot == null ? l10n.diarySlotOther : slotLabel(l10n, slot);
    final empty = section.items.isEmpty;
    final large = usesLargeText(context);
    final kcal = empty
        ? l10n.todaySlotNoKcal
        : l10n.diaryKcal(DisplayRounding.kcal(section.totals.kcal));
    final summary = empty
        ? l10n.todaySlotEmpty
        : slotSummary(section.summaryNames);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(height: 1, color: scheme.outlineVariant),
        FbDisclosureRow(
          title: name,
          subtitle: large && !empty ? kcal : summary,
          expanded: expanded,
          // The "+" leads, so the end of the row stays small at large text
          // sizes: the name and the summary keep the room.
          leading: slot != null && slot.active
              ? IconButton(
                  tooltip: l10n.diarySlotAddTooltip(name),
                  icon: const Icon(FbIcons.add),
                  onPressed: () => ref
                      .read(appNavigatorProvider)
                      .push(FoodSearchRoute(date: date, slotId: slot.id)),
                )
              : null,
          trailing: large && !empty
              ? null
              : MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.3,
                  child: empty
                      ? Semantics(
                          label: l10n.todaySlotNoKcalSemantics,
                          excludeSemantics: true,
                          child: Text(kcal),
                        )
                      : Text(kcal),
                ),
          onToggle: () =>
              ref.read(diaryViewStateProvider.notifier).toggleSlot(section.key),
        ),
      ],
    );
  }
}

/// The compact macro line of an opened meal with full spoken nutrient names.
class SlotMacrosLine extends StatelessWidget {
  /// Creates the line for [section].
  const new({required this.section, super.key});

  /// The meal.
  final SlotSection section;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final n = section.totals;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          start: FbSpace.s4,
          end: FbSpace.s4,
          bottom: FbSpace.s2,
        ),
        child: Semantics(
          label: l10n.diarySlotMacrosSemantics(
            DisplayRounding.nutrientGrams(n.protein),
            DisplayRounding.nutrientGrams(n.carbs),
            DisplayRounding.nutrientGrams(n.fat),
            DisplayRounding.nutrientGrams(n.fiber),
          ),
          excludeSemantics: true,
          child: Text(
            l10n.diarySlotMacros(
              DisplayRounding.nutrientGrams(n.protein),
              DisplayRounding.nutrientGrams(n.carbs),
              DisplayRounding.nutrientGrams(n.fat),
              DisplayRounding.nutrientGrams(n.fiber),
            ),
            style: FbType.numeric(
              FbType.bodySmall,
            ).copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}
