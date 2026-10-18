import 'package:fb_design_system/l10n/gen/fb_localizations.dart';
import 'package:fb_design_system/src/charts/chart_types.dart';
import 'package:fb_design_system/src/tokens/icons.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

/// A chart of values over time (IN-004). Today a calm placeholder with the
/// final API; the real chart arrives with the progress charts step and no
/// chart-library type ever appears here.
///
/// Time runs chronologically (oldest to newest) in both text directions
/// (LC-003): in right-to-left layouts the axis is not mirrored.
class FbTimeSeriesChart extends StatelessWidget {
  /// Creates the chart.
  const new({
    required this.series,
    required this.range,
    this.bands = const [],
    this.goal,
    this.tooltip,
    this.aspectRatio = 16 / 9,
    super.key,
  });

  /// What to draw.
  final List<FbSeries> series;

  /// The visible time window.
  final FbChartRange range;

  /// Shaded ranges, e.g. the likely range around a trend.
  final List<FbBand> bands;

  /// A goal line.
  final FbGoalLine? goal;

  /// Text for the point under the finger (already translated).
  final String Function(FbPoint point)? tooltip;

  /// Width over height. Fixed so layouts do not jump.
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = FbLocalizations.of(context).fbChartPlaceholder;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Semantics(
        container: true,
        label: label,
        excludeSemantics: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(FbRadius.md),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(FbIcons.chart, color: scheme.onSurfaceVariant),
                const SizedBox(height: FbSpace.s2),
                Text(
                  label,
                  style: FbType.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
