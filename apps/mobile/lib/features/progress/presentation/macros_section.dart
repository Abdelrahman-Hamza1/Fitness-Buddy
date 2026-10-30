import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/progress/application/progress_providers.dart';
import 'package:fb_mobile/features/progress/application/weight_graph_providers.dart';
import 'package:fb_mobile/features/progress/presentation/progress_text.dart';
import 'package:material_ui/material_ui.dart';

/// One macro of the macros section.
enum ProgressMacro {
  /// Protein, with its target.
  protein,

  /// Carbs, without a target mark.
  carbs,

  /// Fat, without a target mark.
  fat,

  /// Fiber, with its target.
  fiber,
}

/// The macros charts (IN-003, A16 D13): four compact bar charts in a 2×2
/// grid in the macro colours, per bar of the calories chart. Protein and
/// fiber show their targets; carbs and fat show intake only. No
/// micronutrients (IN-021). Hidden while the period has nothing to draw.
class MacrosSection extends StatelessWidget {
  /// Creates the section for [view].
  const new({required this.view, super.key});

  /// What is shown.
  final ProgressView view;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasData = view.buckets.any(
      (b) => b.avgEaten != null || b.avgTargets != null,
    );
    if (!hasData) return const SizedBox.shrink();
    Widget chart(ProgressMacro macro) => _MacroChart(view: view, macro: macro);
    return FbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FbSpace.s3,
        children: [
          Semantics(
            header: true,
            child: Text(l10n.progressMacrosTitle, style: FbType.title),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: FbSpace.s3,
            children: [
              Expanded(child: chart(ProgressMacro.protein)),
              Expanded(child: chart(ProgressMacro.carbs)),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: FbSpace.s3,
            children: [
              Expanded(child: chart(ProgressMacro.fat)),
              Expanded(child: chart(ProgressMacro.fiber)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroChart extends StatelessWidget {
  const new({required this.view, required this.macro});

  final ProgressView view;
  final ProgressMacro macro;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = switch (macro) {
      ProgressMacro.protein => l10n.todayMacroProtein,
      ProgressMacro.carbs => l10n.todayMacroCarbs,
      ProgressMacro.fat => l10n.todayMacroFat,
      ProgressMacro.fiber => l10n.todayMacroFiber,
    };
    final withTarget =
        macro == ProgressMacro.protein || macro == ProgressMacro.fiber;
    final buckets = view.buckets;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FbSpace.s1,
      children: [
        Text(name, style: FbType.label),
        FbBarChart(
          key: ValueKey('progress-macro-${macro.name}'),
          bars: macroBars(view, macro),
          tone: switch (macro) {
            ProgressMacro.protein => FbBarTone.protein,
            ProgressMacro.carbs => FbBarTone.carbs,
            ProgressMacro.fat => FbBarTone.fat,
            ProgressMacro.fiber => FbBarTone.fiber,
          },
          compact: true,
          aspectRatio: 1.5,
          formatValue: (v) => gramsNumber(l10n, v),
          describeBar: (i) => macroBarWords(l10n, buckets[i], macro),
          semanticLabel: withTarget
              ? l10n.progressMacroSemantics(name, periodLabel(l10n, view))
              : l10n.progressMacroSemanticsNoTarget(
                  name,
                  periodLabel(l10n, view),
                ),
          emptyLabel: l10n.progressDetailsNothing,
        ),
      ],
    );
  }
}

/// A macro bar in words: the date, the grams, the target for protein and
/// fiber, and "not counted" / "so far" (UX-071: never by colour alone).
String macroBarWords(
  AppLocalizations l10n,
  ProgressBucket bucket,
  ProgressMacro macro,
) {
  final label = bucketName(l10n, bucket);
  final value = macroValue(bucket, macro);
  final target = macroTarget(bucket, macro);
  final base = value == null
      ? l10n.progressBarNothing(label)
      : target == null
      ? l10n.progressGramsValue(label, gramsNumber(l10n, value))
      : l10n.progressGramsValueTarget(
          label,
          gramsNumber(l10n, value),
          gramsNumber(l10n, target),
        );
  return switch (bucket.status) {
    DayStatus.incomplete => l10n.progressBarNotCounted(base),
    DayStatus.inProgress => l10n.progressBarSoFar(base),
    _ => base,
  };
}

/// [bucket]'s target grams of [macro]: protein and fiber only.
double? macroTarget(ProgressBucket bucket, ProgressMacro macro) =>
    switch (macro) {
      ProgressMacro.protein => bucket.avgTargets?.protein,
      ProgressMacro.fiber => bucket.avgTargets?.fiber,
      _ => null,
    };

/// [bucket]'s eaten grams of [macro], or null.
double? macroValue(ProgressBucket bucket, ProgressMacro macro) {
  final eaten = bucket.avgEaten;
  if (eaten == null) return null;
  return switch (macro) {
    ProgressMacro.protein => eaten.protein,
    ProgressMacro.carbs => eaten.carbs,
    ProgressMacro.fat => eaten.fat,
    ProgressMacro.fiber => eaten.fiber,
  };
}

/// The bars of [macro]'s chart: the same buckets and empty slots as the
/// calories chart; targets for protein and fiber only.
List<FbBar> macroBars(ProgressView view, ProgressMacro macro) => [
  for (final bucket in view.buckets)
    FbBar(
      at: chartDay(bucket.start),
      value: macroValue(bucket, macro),
      target: macroTarget(bucket, macro),
      style: switch (bucket.status) {
        DayStatus.incomplete => FbBarStyle.hatched,
        DayStatus.inProgress => FbBarStyle.faint,
        _ => FbBarStyle.solid,
      },
    ),
  for (var i = 1; i <= view.futureSlots; i++)
    FbBar(at: chartDay(view.today.plusDays(i)), placeholder: true),
];
