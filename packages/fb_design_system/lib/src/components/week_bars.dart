import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

/// One day of an [FbWeekBars].
class FbWeekBar {
  /// A bar of [value] with [valueLabel] above and [label] below.
  const new({
    required this.value,
    required this.valueLabel,
    required this.label,
    required this.semanticLabel,
    this.highlighted = false,
  });

  /// The bar's height, relative to the largest bar.
  final double value;

  /// The number above the bar (already formatted).
  final String valueLabel;

  /// The short day name under the bar.
  final String label;

  /// The whole bar in words, for screen readers.
  final String semanticLabel;

  /// Today: the strong colour, the other days the light one (never red).
  final bool highlighted;
}

/// Seven tappable day columns (D-090 Targets): each day's number above a
/// bar and its short name below, in reading direction (the first day at the
/// start edge). A whole column is one 48 dp-wide-or-more button when
/// [onTap] is set.
class FbWeekBars extends StatelessWidget {
  /// Creates the chart.
  const new({required this.bars, this.onTap, this.barHeight = 120, super.key});

  /// The days, in order.
  final List<FbWeekBar> bars;

  /// Called with the tapped day's index; null makes the bars read-only.
  final ValueChanged<int>? onTap;

  /// The tallest bar's height.
  final double barHeight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final top = bars.fold<double>(0, (m, b) => b.value > m ? b.value : m);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final (i, bar) in bars.indexed)
          Expanded(
            child: Semantics(
              button: onTap != null,
              label: bar.semanticLabel,
              excludeSemantics: true,
              child: InkWell(
                onTap: onTap == null ? null : () => onTap!(i),
                borderRadius: FbRadius.smAll,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: FbSpace.s1,
                      vertical: FbSpace.s1,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: FbSpace.s1,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            bar.valueLabel,
                            maxLines: 1,
                            style: FbType.numeric(FbType.caption).copyWith(
                              color: bar.highlighted
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          height: top <= 0
                              ? 0
                              : barHeight * (bar.value / top).clamp(.05, 1),
                          decoration: BoxDecoration(
                            color: bar.highlighted
                                ? scheme.primary
                                : scheme.primaryContainer,
                            borderRadius: FbRadius.smAll,
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            bar.label,
                            maxLines: 1,
                            style: FbType.label.copyWith(
                              color: bar.highlighted
                                  ? scheme.onSurface
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
