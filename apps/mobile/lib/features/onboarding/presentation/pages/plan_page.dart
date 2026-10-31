import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/onboarding/application/setup_flow.dart';
import 'package:fb_mobile/features/onboarding/presentation/pages/page_parts.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// "Here's your plan" (D9 page 5, TG-021, D-088): the daily calories from
/// the A12 engine, the goal in one line, the macros, and the explanation on
/// demand. "Change the numbers" (below, [showChangeNumbers]) edits the pace
/// and activity in place; any single day is changed later in Targets.
class PlanPage extends StatefulWidget {
  /// Creates the page.
  const new({required this.draft, super.key});

  /// What the flow holds.
  final SetupDraft draft;

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  bool _how = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final draft = widget.draft;
    final preview = draft.preview;
    final calculation = preview?.calculation;
    final activity = draft.activity;
    if (preview == null || calculation == null || activity == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FbSpace.s4,
        children: [
          SetupHeader(title: l10n.setupPlanTitle),
          FbInlineBanner(
            kind: FbInlineBannerKind.info,
            message: draft.goalProblem == null
                ? l10n.setupPlanUnavailable
                : goalProblemText(l10n, draft.goalProblem!),
          ),
        ],
      );
    }
    final unit = draft.units.bodyMass;
    final goalLine = switch (draft.goal.type) {
      GoalType.lose => l10n.setupPlanLose(
        rateText(l10n, calculation.achievableKgPerWeek.abs(), unit),
      ),
      GoalType.gain => l10n.setupPlanGain(
        rateText(l10n, calculation.achievableKgPerWeek.abs(), unit),
      ),
      GoalType.maintain ||
      null => l10n.setupPlanKeep(massText(l10n, draft.weightKg ?? 0, unit)),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s4,
      children: [
        SetupHeader(title: l10n.setupPlanTitle),
        FbCard(
          padding: const EdgeInsetsDirectional.all(FbSpace.s5),
          child: MergeSemantics(
            child: Column(
              children: [
                Text(
                  l10n.setupPlanEat,
                  style: FbType.body.copyWith(color: scheme.onSurfaceVariant),
                ),
                Text(
                  l10n.diaryBigKcal(DisplayRounding.kcal(calculation.kcal)),
                  textScaler: MediaQuery.textScalerOf(context)
                      .clamp(maxScaleFactor: 1.5),
                  style: FbType.numeric(FbType.display)
                      .copyWith(color: scheme.onSurface),
                ),
                Text(
                  l10n.setupPlanKcal,
                  style: FbType.body.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: FbSpace.s3),
                Text(
                  goalLine,
                  textAlign: TextAlign.center,
                  style: FbType.label.copyWith(color: scheme.onSurface),
                ),
                if (calculation.warnings.contains(TargetWarning.lossRateCapped))
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: FbSpace.s2),
                    child: Text(
                      capMessage(l10n, calculation, unit),
                      textAlign: TextAlign.center,
                      style: FbType.bodySmall.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (preview.macros case final macros?) _MacroColumns(macros: macros),
        FbCard(
          padding: EdgeInsetsDirectional.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FbDisclosureRow(
                title: l10n.setupPlanHow,
                expanded: _how,
                onToggle: () => setState(() => _how = !_how),
              ),
              if (_how)
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    FbSpace.s4,
                    0,
                    FbSpace.s4,
                    FbSpace.s4,
                  ),
                  child: TargetExplanationView(
                    calculation: calculation,
                    activity: activity,
                    units: draft.units,
                    weeklyKcal: preview.weeklyKcal,
                  ),
                ),
            ],
          ),
        ),
        SetupHint(l10n.setupPlanLater),
      ],
    );
  }
}

/// Protein, carbs and fat side by side, each with its own colour (UX-042);
/// stacked at large text.
class _MacroColumns extends StatelessWidget {
  const new({required this.macros});

  final DailyMacros macros;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.fbColors;
    final scheme = Theme.of(context).colorScheme;
    String grams(double? g) => g == null
        ? l10n.targetsMacroNoTarget
        : l10n.targetsMacroGrams(DisplayRounding.macroTargetGrams(g));
    Widget cell(String label, double? g, Color color) => MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: FbSpace.s1,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: FbRadius.pillAll,
            ),
            child: const SizedBox(height: 6, width: double.infinity),
          ),
          const SizedBox(height: FbSpace.s1),
          Text(
            grams(g),
            style: FbType.numeric(FbType.title)
                .copyWith(color: scheme.onSurface),
          ),
          Text(
            label,
            style: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
    final cells = [
      cell(l10n.todayMacroProtein, macros.proteinGrams, colors.protein),
      cell(l10n.todayMacroCarbs, macros.carbsGrams, colors.carbs),
      cell(l10n.todayMacroFat, macros.fatGrams, colors.fat),
    ];
    final large = MediaQuery.textScalerOf(context).scale(1) > 1.5;
    return FbCard(
      padding: const EdgeInsetsDirectional.all(FbSpace.s4),
      child: large
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: FbSpace.s3,
              children: cells,
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: FbSpace.s4,
              children: [for (final c in cells) Expanded(child: c)],
            ),
    );
  }
}

/// "Change the numbers": the goal's pace (or target weight and date) and
/// the activity level, changed in place; the plan page follows.
Future<void> showChangeNumbers(BuildContext context, SetupMode mode) =>
    showFbSheet<void>(
      context,
      title: context.l10n.setupPlanChange,
      builder: (_) => _ChangeNumbers(mode: mode),
    );

class _ChangeNumbers extends ConsumerWidget {
  const new({required this.mode});

  final SetupMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final draft = ref.watch(setupFlowProvider(mode)).value;
    if (draft == null) return const SizedBox.shrink();
    final flow = ref.read(setupFlowProvider(mode).notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s4,
      children: [
        GoalForm(
          draft: draft.goal,
          onChanged: flow.setGoal,
          today: draft.today,
          calculation: draft.goalCalculation,
          problem: draft.goalProblem,
          showErrors: true,
        ),
        SetupLabel(l10n.setupPageActivity),
        ActivityOptions(selected: draft.activity, onSelected: flow.setActivity),
        FbButton.primary(
          label: l10n.setupPlanChangeDone,
          expand: true,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}
