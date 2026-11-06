import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/approx_text.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/progress/application/weekly_summary_providers.dart';
import 'package:fb_mobile/features/progress/presentation/progress_retry.dart';
import 'package:fb_mobile/features/progress/presentation/progress_text.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The calories card's title in week mode (P1 B, D-097, A63 D2): "Calories"
/// with the week's average vs target ("avg 1,940 / 2,100") and one line of
/// key numbers ("In target 4/5 · Protein 3/5 · −0.4 kg"), each part only
/// when it has data. The numbers are the weekly summary's (IN-001), from
/// the same series as the chart, so they agree with it. The whole header
/// opens the week's full summary in every state; while it loads it keeps
/// two skeleton lines, and a failure says so with Try again (A63 PA5), in
/// the same height (UX-045).
class CaloriesWeekHeader extends ConsumerWidget {
  /// The header of the week from [weekStart].
  const new({required this.weekStart, super.key});

  /// The week's first day.
  final LocalDate weekStart;

  /// The widest numbers the average is sized for; the localized words
  /// around them ("avg ") are measured with them (A63 review).
  static const _sampleKcal = '8,888';

  /// The width [text] takes in [style] at the current text scale.
  static double _widthOf(BuildContext context, String text, TextStyle style) {
    final painter = TextPainter(
      // As the Text draws it: over the inherited style (letter spacing).
      text: TextSpan(
        text: text,
        style: DefaultTextStyle.of(context).style.merge(style),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final muted = FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant);
    final summary = ref.watch(weeklySummaryProvider(weekStart));
    final unit =
        (ref.watch(unitSystemProvider).value ?? UnitSystem.defaultSystem)
            .bodyMass;
    // One body-small line, measured at the current text scale.
    final lineHeight = MediaQuery.textScalerOf(context).scale(
      (FbType.bodySmall.fontSize ?? 14) * (FbType.bodySmall.height ?? 1.43),
    );
    final String? average;
    final Widget line;
    switch (summary) {
      case AsyncData(:final value):
        average = switch (value) {
          WeeklySummary(:final averageKcal?, :final averageTargetKcal?) =>
            l10n.progressCaloriesWeekAvg(
              // "~" when a meal or day estimate is in it (A62, D-096).
              approxText(
                l10n,
                kcalNumber(l10n, averageKcal),
                approximate: value.estimated,
              ),
              kcalNumber(l10n, averageTargetKcal),
            ),
          _ => null,
        };
        line = Text(
          value == null ? '' : weekKeyLine(l10n, value, unit),
          key: const ValueKey('progress-week-line'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: muted,
        );
      case AsyncError():
        average = null;
        line = Row(
          key: const ValueKey('progress-week-failed'),
          children: [
            Expanded(
              child: Text(
                l10n.progressWeekUnavailable,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: muted,
              ),
            ),
            FbButton.text(
              key: const ValueKey('progress-week-retry'),
              label: l10n.weightGraphTryAgain,
              onPressed: () => retryProgress(ref),
            ),
          ],
        );
      case _:
        average = null;
        line = Align(
          alignment: AlignmentDirectional.centerStart,
          child: FbSkeleton.line(width: 180, height: lineHeight * 0.7),
        );
    }
    return Semantics(
      button: true,
      hint: l10n.progressWeekOpen,
      child: InkWell(
        key: const ValueKey('progress-week-header'),
        borderRadius: FbRadius.mdAll,
        onTap: () => ref
            .read(appNavigatorProvider)
            .push(WeeklySummaryRoute(start: weekStart)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The average beside the title when the widest one fits, else
            // under it (big text); decided by the sample, so the layout is
            // the same in every state (UX-045).
            LayoutBuilder(
              builder: (context, constraints) {
                final title = Semantics(
                  header: true,
                  child: Text(l10n.progressCaloriesTitle, style: FbType.title),
                );
                const iconSize = 20.0;
                final icon = Icon(
                  FbIcons.next,
                  size: iconSize,
                  color: scheme.onSurfaceVariant,
                );
                // Sized with the "~" of an estimated week (A62).
                final sample = l10n.progressCaloriesWeekAvg(
                  l10n.approx(_sampleKcal),
                  _sampleKcal,
                );
                // Resolved over the inherited style, so the slot is
                // measured with the letter spacing the text is drawn with
                // (else "avg 2,200 / 2,200" is cut, A63).
                final averageStyle = DefaultTextStyle.of(context).style
                    .merge(FbType.bodySmall.copyWith(color: scheme.onSurface));
                final sideBySide =
                    _widthOf(
                          context,
                          l10n.progressCaloriesTitle,
                          FbType.title,
                        ) +
                        FbSpace.s2 +
                        FbNumberSlot.widthFor(
                          sample,
                          averageStyle,
                          MediaQuery.textScalerOf(context),
                          Directionality.of(context),
                        ) +
                        iconSize <=
                    constraints.maxWidth;
                Widget slot(TextAlign align) => FbNumberSlot(
                  key: const ValueKey('progress-week-average'),
                  text: average ?? '',
                  sample: sample,
                  align: align,
                  style: averageStyle,
                );
                if (sideBySide) {
                  return Row(
                    children: [
                      title,
                      const SizedBox(width: FbSpace.s2),
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: slot(TextAlign.end),
                        ),
                      ),
                      icon,
                    ],
                  );
                }
                return Column(
                  key: const ValueKey('progress-week-stacked'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: title),
                        icon,
                      ],
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: slot(TextAlign.start),
                    ),
                  ],
                );
              },
            ),
            // The key line keeps its height whatever it shows (UX-045);
            // the retry button may make the failure line taller.
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: lineHeight),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: line,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The week's key numbers in one line (A63 D2): in target, protein days,
/// the trend change; a part without data is left out.
String weekKeyLine(AppLocalizations l10n, WeeklySummary s, MassUnit unit) => [
  if (s.targetDays > 0)
    l10n.progressWeekInTarget(s.daysWithinTarget, s.targetDays),
  if (s.proteinTargetDays > 0)
    l10n.progressWeekProtein(s.proteinDaysHit, s.proteinTargetDays),
  if (s.trendChangeKg case final change?) weightDiffText(l10n, change, unit),
].join(' · ');
