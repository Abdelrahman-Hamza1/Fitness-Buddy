import 'package:fb_design_system/l10n/gen/fb_localizations.dart';
import 'package:fb_design_system/src/charts/chart_geometry.dart';
import 'package:fb_design_system/src/charts/chart_types.dart';
import 'package:fb_design_system/src/charts/time_series_painter.dart';
import 'package:fb_design_system/src/tokens/icons.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

/// A chart of values over time (IN-004, TD-012: drawn with a
/// `CustomPainter`, no chart library; no drawing type leaks out).
///
/// **Time runs in reading direction** (LC-003, A15 PA2): the oldest moment
/// sits at the start edge, so in right-to-left layouts it is at the right.
/// A drag follows the finger in either direction. X values are naive
/// wall-clock times (see [FbPoint]).
///
/// **Pan** (A15 PA4): with [panBounds], a horizontal drag moves a transient
/// offset kept inside the chart, which repaints only itself; on drag end it
/// calls [onRangeChanged] once with the moved window (a continuous start).
/// The next [range] the parent passes resets the offset.
///
/// **Selection** (WB-022): a tap within 24 dp of a point of a selectable
/// series calls [onSelect] with it; a tap elsewhere calls it with null. The
/// [selected] point is always drawn, even when down-sampling dropped it.
/// Screen readers step through the points with increase/decrease.
///
/// Long series are thinned per frame with LTTB over the visible slice only
/// (A15 D4); hit-testing uses the full data.
class FbTimeSeriesChart extends StatefulWidget {
  /// Creates the chart.
  const new({
    required this.series,
    required this.range,
    this.panBounds,
    this.onRangeChanged,
    this.bands = const [],
    this.goal,
    this.periods = const [],
    this.selected,
    this.onSelect,
    this.formatValue,
    this.formatDate,
    this.semanticLabel,
    this.emptyLabel,
    this.aspectRatio = 16 / 9,
    super.key,
  });

  /// What to draw.
  final List<FbSeries> series;

  /// The visible time window.
  final FbChartRange range;

  /// How far a drag may pan, or null for no panning.
  final FbChartRange? panBounds;

  /// Called once per drag, on drag end, with the moved window.
  final ValueChanged<FbChartRange>? onRangeChanged;

  /// Shaded value ranges over time, e.g. the likely range of a projection.
  final List<FbBand> bands;

  /// A goal line (an edge marker when far off the visible values).
  final FbGoalLine? goal;

  /// Shaded stretches of time (goal phases, highlighted periods).
  final List<FbPeriod> periods;

  /// The selected point, drawn with a ring.
  final FbPointRef? selected;

  /// Called with the tapped point, or null when a tap hit nothing.
  final ValueChanged<FbPointRef?>? onSelect;

  /// Formats axis values (already translated). Defaults to one decimal.
  final String Function(double value)? formatValue;

  /// Formats axis dates (already translated). Defaults to ISO dates.
  final String Function(DateTime at, FbTimeStep step)? formatDate;

  /// What the chart shows, for screen readers (already translated).
  final String? semanticLabel;

  /// Shown when no series has a point (already translated).
  final String? emptyLabel;

  /// Width over height. Fixed so layouts do not jump.
  final double aspectRatio;

  @override
  State<FbTimeSeriesChart> createState() => _FbTimeSeriesChartState();
}

class _FbTimeSeriesChartState extends State<FbTimeSeriesChart> {
  final ValueNotifier<double> _offset = ValueNotifier(0);
  final ChartLabelCache _labels = ChartLabelCache();
  TimeSeriesPainter? _painter;

  @override
  void didUpdateWidget(FbTimeSeriesChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.range != widget.range) _offset.value = 0;
  }

  @override
  void dispose() {
    _offset.dispose();
    _labels.clear();
    super.dispose();
  }

  String _formatValue(double value) =>
      widget.formatValue?.call(value) ?? value.toStringAsFixed(1);

  String _formatDate(DateTime at, FbTimeStep step) =>
      widget.formatDate?.call(at, step) ??
      at.toIso8601String().substring(0, 10);

  (FbPoint, FbSeriesTone)? _selectedPoint() {
    final ref = widget.selected;
    if (ref == null || ref.series >= widget.series.length) return null;
    final s = widget.series[ref.series];
    for (final p in s.points) {
      if (p.key == ref.key) return (p, s.tone);
    }
    return null;
  }

  void _drag(DragUpdateDetails details, TextDirection direction) {
    final bounds = widget.panBounds;
    final map = _painter?.lastMapping;
    if (bounds == null || map == null) return;
    final sign = direction == TextDirection.ltr ? 1 : -1;
    // Dragging towards the end edge shows earlier times.
    final next = _offset.value - details.delta.dx * sign * map.msPerPixel;
    final min =
        bounds.start.millisecondsSinceEpoch -
        widget.range.start.millisecondsSinceEpoch;
    final max =
        bounds.end.millisecondsSinceEpoch -
        widget.range.end.millisecondsSinceEpoch;
    _offset.value = next.clamp(
      min.toDouble(),
      max < min ? min.toDouble() : max.toDouble(),
    );
  }

  void _dragEnd() {
    if (_offset.value == 0) return;
    widget.onRangeChanged?.call(
      widget.range.shift(Duration(milliseconds: _offset.value.round())),
    );
  }

  void _tap(TapUpDetails details) {
    final map = _painter?.lastMapping;
    if (map == null || widget.onSelect == null) return;
    widget.onSelect!(hitTest(widget.series, map, details.localPosition));
  }

  /// The selectable points in time order, for screen-reader stepping.
  List<(int, FbPoint)> _selectable() => [
    for (final (index, s) in widget.series.indexed)
      if (s.selectable)
        for (final p in s.points)
          if (p.key != null) (index, p),
  ]..sort((a, b) => a.$2.at.compareTo(b.$2.at));

  void _step(int delta) {
    final points = _selectable();
    if (points.isEmpty) return;
    final ref = widget.selected;
    var index = points.indexWhere(
      (e) => ref != null && e.$1 == ref.series && e.$2.key == ref.key,
    );
    index = index < 0
        ? points.length - 1
        : (index + delta).clamp(0, points.length - 1);
    final (series, point) = points[index];
    widget.onSelect?.call(FbPointRef(series: series, key: point.key!));
  }

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
    final isEmpty = widget.series.every((s) => s.points.isEmpty);
    final l10n = FbLocalizations.of(context);
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
    final selected = _selectedPoint();
    final painter = _painter = TimeSeriesPainter(
      series: widget.series,
      bands: widget.bands,
      periods: widget.periods,
      goal: widget.goal,
      selected: selected,
      range: widget.range,
      offset: _offset,
      colors: ChartColors.of(scheme),
      labels: _labels,
      direction: direction,
      formatValue: _formatValue,
      formatDate: _formatDate,
    );
    final points = _selectable();
    final canSelect = widget.onSelect != null && points.isNotEmpty;
    String describe(FbPoint p) => l10n.fbChartPointValue(
      _formatDate(p.at, FbTimeStep.day),
      _formatValue(p.value),
    );
    final ref = widget.selected;
    final index = selected == null
        ? -1
        : points.indexWhere((e) => e.$1 == ref!.series && e.$2.key == ref.key);
    // Increase/decrease need the neighbours' values next to the value.
    final value = selected == null ? null : describe(selected.$1);
    final increased = index < 0
        ? null
        : describe(points[(index + 1).clamp(0, points.length - 1)].$2);
    final decreased = index < 0
        ? null
        : describe(points[(index - 1).clamp(0, points.length - 1)].$2);
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Semantics(
        container: true,
        label: widget.semanticLabel,
        value: index < 0 ? null : value,
        increasedValue: increased,
        decreasedValue: decreased,
        onIncrease: canSelect ? () => _step(1) : null,
        onDecrease: canSelect ? () => _step(-1) : null,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: widget.onSelect == null ? null : _tap,
          onHorizontalDragUpdate: widget.panBounds == null
              ? null
              : (d) => _drag(d, direction),
          onHorizontalDragEnd: widget.panBounds == null
              ? null
              : (_) => _dragEnd(),
          child: RepaintBoundary(
            child: CustomPaint(painter: painter, size: Size.infinite),
          ),
        ),
      ),
    );
  }
}
