import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/design_preview/application/fake_data.dart';
import 'package:fb_mobile/features/design_preview/presentation/mockups/mockup_layout.dart';
import 'package:material_ui/material_ui.dart';

/// The Today screen as `spec/16` §1 describes it (HM-001, HM-003, HM-008):
/// date header, remaining calories with a bar, the weekly line, macro bars,
/// the to-confirm strip, weight and workout rows, the diary by slot, quick-add
/// chips and the input bar. Static: nothing navigates.
class TodayMockup extends StatelessWidget {
  /// Creates the mockup.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final slotNames = {
      FakeSlotKind.breakfast: l10n.todaySlotBreakfast,
      FakeSlotKind.lunch: l10n.todaySlotLunch,
      FakeSlotKind.snacks: l10n.todaySlotSnacks,
      FakeSlotKind.dinner: l10n.todaySlotDinner,
    };
    final macroNames = {
      FbMacroKind.protein: l10n.todayMacroProtein,
      FbMacroKind.carbs: l10n.todayMacroCarbs,
      FbMacroKind.fat: l10n.todayMacroFat,
      FbMacroKind.fiber: l10n.todayMacroFiber,
    };
    const next = Icon(FbIcons.next);
    return MockupPage(
      children: [
        const FbDateHeader(label: FakeData.dateLabel, onPrevious: mockupNoop),
        FbBigNumber(value: FakeData.kcalLeft, caption: l10n.todayKcalLeft),
        const FbProgressBar(value: FakeData.eaten, target: FakeData.budget),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: FbSpace.s3,
          runSpacing: FbSpace.s1,
          children: [
            Text(
              l10n.todayWeekUnder(FakeData.weekUnder),
              style: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
            ),
            Text(
              l10n.todayEatenOfBudget(FakeData.eatenText, FakeData.budgetText),
              style: FbType.numeric(FbType.bodySmall)
                  .copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        FbMacroBars(
          macros: [
            for (final m in FakeData.macros)
              FbMacroValue(
                kind: m.kind,
                value: m.value,
                target: m.target,
                label: macroNames[m.kind]!,
                valueText: m.text,
              ),
          ],
        ),
        FbCard(
          padding: EdgeInsetsDirectional.zero,
          child: Column(
            children: [
              // Stands out from the rows below: the brand container tint.
              Material(
                color: scheme.primaryContainer,
                // Muted text is too faint on the tint: use the container's own.
                child: ListTileTheme(
                  data: ListTileTheme.of(context).copyWith(
                    subtitleTextStyle: FbType.bodySmall.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  child: FbListRow(
                    leading: const Icon(FbIcons.pending),
                    title: l10n.todayToConfirm(FakeData.toConfirmCount),
                    subtitle: l10n.todayToConfirmKcal(FakeData.toConfirmKcal),
                    trailing: FbButton.text(
                      label: l10n.todayConfirmAll,
                      onPressed: mockupNoop,
                    ),
                    onTap: mockupNoop,
                  ),
                ),
              ),
              FbListRow(
                title: l10n.todayWeight,
                subtitle: l10n.todayWeightTrendRate(
                  FakeData.weightTrend,
                  FakeData.weightRate,
                ),
                trailing: next,
                onTap: mockupNoop,
              ),
              FbListRow(
                title: l10n.todayWorkoutHint(FakeData.workoutName),
                trailing: next,
                onTap: mockupNoop,
              ),
            ],
          ),
        ),
        FbCard(
          padding: EdgeInsetsDirectional.zero,
          child: Column(
            children: [
              for (final slot in FakeData.slots)
                FbListRow(
                  title: slotNames[slot.kind]!,
                  subtitle: slot.summary ?? l10n.todaySlotEmpty,
                  trailing: slot.kcal == null
                      ? Semantics(
                          label: l10n.todaySlotNoKcalSemantics,
                          excludeSemantics: true,
                          child: Text(
                            l10n.todaySlotNoKcal,
                            style: FbType.numeric(FbType.body),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (slot.hasEstimate)
                              const FbEstimateMarker(
                                rangeText: FakeData.estimateRange,
                                reason: FakeData.estimateReason,
                              ),
                            Text(
                              slot.kcal!,
                              style: FbType.numeric(FbType.body),
                            ),
                          ],
                        ),
                  onTap: mockupNoop,
                ),
            ],
          ),
        ),
        Wrap(
          spacing: FbSpace.s2,
          runSpacing: FbSpace.s2,
          children: [
            for (final name in FakeData.quickAdds)
              FbQuickAddChip(label: name, onTap: mockupNoop),
            FbQuickAddChip.add(
              label: l10n.todayQuickAddMore,
              onTap: mockupNoop,
            ),
          ],
        ),
        FbInputBar(
          hint: l10n.todayInputHint,
          onTap: mockupNoop,
          onCamera: mockupNoop,
          onBarcode: mockupNoop,
        ),
      ],
    );
  }
}
