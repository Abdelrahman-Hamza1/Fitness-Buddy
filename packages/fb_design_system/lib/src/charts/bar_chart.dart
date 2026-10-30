import 'package:fb_design_system/l10n/gen/fb_localizations.dart';
import 'package:fb_design_system/src/charts/bar_chart_painter.dart';
import 'package:fb_design_system/src/charts/chart_types.dart';
import 'package:fb_design_system/src/charts/time_series_painter.dart'
    show ChartLabelCache;
import 'package:fb_design_system/src/tokens/colors.dart';
import 'package:fb_design_system/src/tokens/icons.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

/// A bar per category, usually per day (IN-002, IN-003, A16 D7; TD-012:
/// drawn with a `CustomPainter`, no chart library).
///
/// **Bars run in reading direction** (LC-003): the first bar sits at the
/// start edge, so in right-to-left layouts it is at the right. The value
/// axis starts at zero and includes every target. A bar's [FbBar.target] is
/// a short dark mark across it and the part above the target takes the
/// neutral over-target colour (never red, SF-021). [FbBarStyle] tells
/// counted, not counted (hatched) and in-progress (lighter) bars apart; a
/// bar without a value shows a baseline tick (unknown, never zero).
///
/// **Selection:** a tap picks the nearest bar by x (within half a slot or
/// 24 dp) and calls [onSelect] with its index; a tap on the selected bar or
/// beyond every bar calls it with null.
///
/// **Screen readers** (A16 review): every bar but a placeholder is its own
/// semantics node, in reading order, with [describeBar]'s words, whether or
/// not the chart is selectable; with [onSelect] a double tap on a bar
/// selects it (or clears it when already selected).
class FbBarChart extends StatefulWidget {
  /// Creates the chart.
  const new({
    required this.bars,
    this.tone = FbBarTone.primary,
    this.selected,
    this.onSelect,
    this.formatValue,
    this.formatLabel,
    this.describeBar,
    this.semanticLabel,
    this.emptyLabel,
    this.compact = false,
    this.aspectRatio = 16 / 9,
    super.key,
  });

  /// The bars, oldest first.
  final List<FbBar> bars;

  /// The bars' colour.
  final FbBarTone tone;

  /// The selected bar's index, drawn on a highlighted slot.
  final int? selected;

  /// Called with the tapped bar's index, or null.
  final ValueChanged<int?>? onSelect;

  /// Formats axis values (already translated). Defaults to whole numbers.
  final String Function(double value)? formatValue;

  /// The label under bar `index` (already translated), or null for none.
  final String? Function(int index)? formatLabel;

  /// Bar `index` in words, for screen readers (already translated).
  final String Function(int index)? describeBar;

  /// What the chart shows, for screen readers (already translated).
  final String? semanticLabel;

  /// Shown when no bar has a value or a target (already translated).
  final String? emptyLabel;

  /// A short chart (macros): only the top value label, no bar labels.
  final bool compact;

  /// Width over height. Fixed so layouts do not jump.
  final double aspectRatio;

  @override
  State<FbBarChart> createState() => _FbBarChartState();
}

class _FbBarChartState extends State<FbBarChart> {
  final ChartLabelCache _labels = ChartLabelCache();
  BarChartPainter? _painter;

  @override
  void dispose() {
    _labels.clear();
    super.dispose();
  }

  String _formatValue(double value) =>
      widget.formatValue?.call(value) ?? value.round().toString();

  bool _selectable(int index) =>
      index >= 0 &&
      index < widget.bars.length &&
      !widget.bars[index].placeholder;

  void _tap(TapUpDetails details) {
    final geometry = _painter?.lastGeometry;
    final onSelect = widget.onSelect;
    if (geometry == null || onSelect == null) return;
    final index = geometry.nearest(details.localPosition.dx);
    if (index == null || !_selectable(index) || index == widget.selected) {
      onSelect(null);
    } else {
      onSelect(index);
    }
  }

  void _selectFromSemantics(int index) =>
      widget.onSelect?.call(index == widget.selected ? null : index);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final direction = Directionality.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final style = FbType.caption.copyWith(color: scheme.onSurfaceVariant);
    if (_labels.style != style ||
        _labels.scaler != scaler ||
        _labels.direction != direction) {
      _labels
        ..clear()
        ..style = style
        ..scaler = scaler
        ..direction = direction;
    }
    final l10n = FbLocalizations.of(context);
    final isEmpty = widget.bars.every(
      (b) => b.placeholder || (b.value == null && b.target == null),
    );
    if (isEmpty) {
      final label = widget.emptyLabel ?? l10n.fbChartNoData;
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Semantics(
          container: true,
          label: label,
          excludeSemantics: true,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(FbIcons.chart, color: scheme.onSurfaceVariant),
                const SizedBox(height: FbSpace.s2),
                Text(label, style: style, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }
    final painter = _painter = BarChartPainter(
      bars: widget.bars,
      selected: widget.selected,
      colors: BarChartColors.of(scheme, context.fbColors, widget.tone),
      labels: _labels,
      direction: direction,
      formatValue: _formatValue,
      formatLabel: widget.formatLabel,
      compact: widget.compact,
      describeBar: widget.describeBar,
      onSelectBar: widget.onSelect == null ? null : _selectFromSemantics,
    );
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: widget.semanticLabel,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTapUp: widget.onSelect == null ? null : _tap,
          child: RepaintBoundary(
            child: CustomPaint(painter: painter, size: Size.infinite),
          ),
        ),
      ),
    );
  }
}

/// What one entry of an [FbBarLegend] shows.
enum FbBarLegendKind {
  /// A counted bar (solid).
  bar,

  /// The part above a target (the neutral over-target colour).
  over,

  /// The target mark.
  target,

  /// A bar that isn't counted (hatched, outlined).
  notCounted,

  /// A bar still in progress (lighter).
  inProgress,
}

/// A small legend under an [FbBarChart]: one swatch drawn like the bars,
/// then its (already translated) label. Wraps at large text sizes.
class FbBarLegend extends StatelessWidget {
  /// Creates the legend.
  const new({required this.entries, this.tone = FbBarTone.primary, super.key});

  /// The swatches and their labels, in order.
  final List<(FbBarLegendKind, String)> entries;

  /// The chart's bar colour.
  final FbBarTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = BarChartColors.of(scheme, context.fbColors, tone);
    final style = FbType.caption.copyWith(color: scheme.onSurfaceVariant);
    return Wrap(
      spacing: FbSpace.s3,
      runSpacing: FbSpace.s1,
      children: [
        for (final (kind, label) in entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: CustomPaint(
                  size: const Size(12, 12),
                  painter: _SwatchPainter(kind, colors),
                ),
              ),
              const SizedBox(width: FbSpace.s1),
              Flexible(child: Text(label, style: style)),
            ],
          ),
      ],
    );
  }
}

final class _SwatchPainter extends CustomPainter {
  new(this.kind, this.colors);

  final FbBarLegendKind kind;
  final BarChartColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    switch (kind) {
      case FbBarLegendKind.bar:
        canvas.drawRect(rect, Paint()..color = colors.bar);
      case FbBarLegendKind.over:
        canvas.drawRect(rect, Paint()..color = colors.over);
      case FbBarLegendKind.inProgress:
        canvas.drawRect(
          rect,
          Paint()..color = colors.bar.withValues(alpha: 0.45),
        );
      case FbBarLegendKind.target:
        canvas.drawLine(
          Offset(0, size.height / 2),
          Offset(size.width, size.height / 2),
          Paint()
            ..color = colors.target
            ..strokeWidth = 2,
        );
      case FbBarLegendKind.notCounted:
        canvas
          ..drawRect(rect, Paint()..color = colors.bar.withValues(alpha: 0.16))
          ..save()
          ..clipRect(rect);
        final line = Paint()
          ..color = colors.bar
          ..strokeWidth = 1.5;
        for (var d = -size.height; d < size.width; d += 5) {
          canvas.drawLine(
            Offset(d, size.height),
            Offset(d + size.height, 0),
            line,
          );
        }
        canvas
          ..restore()
          ..drawRect(
            rect.deflate(0.75),
            Paint()
              ..color = colors.bar
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
    }
  }

  @override
  bool shouldRepaint(_SwatchPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.colors != colors;
}
