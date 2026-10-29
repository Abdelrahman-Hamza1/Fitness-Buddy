import 'package:fb_design_system/src/components/progress_bar.dart';
import 'package:fb_design_system/src/tokens/colors.dart';
import 'package:fb_design_system/src/tokens/density.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

/// The macro nutrients with a colour of their own (UX-042).
enum FbMacroKind {
  /// Protein.
  protein,

  /// Carbs.
  carbs,

  /// Fat.
  fat,

  /// Fibre: shown smaller than the other three.
  fiber,
}

/// One macro row: its amounts and the texts that go with them.
@immutable
class FbMacroValue {
  /// Creates a macro value. Without a [target] the row shows its text only,
  /// with no track (TG-054: carbs and fat in "calories and protein only").
  const new({
    required this.kind,
    required this.value,
    required this.label,
    required this.valueText,
    this.target,
  });

  /// Which macro (decides the colour).
  final FbMacroKind kind;

  /// The amount so far (geometry only).
  final double value;

  /// The target, or null for a macro with no target: then no track is drawn
  /// and [valueText] carries the amount alone ("96 g").
  final double? target;

  /// The macro's name, e.g. "Protein". Always shown next to the colour
  /// (UX-071).
  final String label;

  /// The formatted amounts, e.g. "82 / 140 g" or "12 g over".
  final String valueText;
}

/// Macro bars, one per [FbMacroValue] (HM-003). Each bar has its text label
/// next to it, so colour is never the only cue (UX-071). Past the target a
/// bar is full in the neutral over-target tone (SF-021). A macro without a
/// target is its label and text only.
///
/// In the compact density ([FbDensity.macroColumns]) the macros sit side by
/// side, one column each (label, bar, amounts), but only while the text
/// scale is below 1.4 and the widest label and amount fit their column;
/// otherwise each macro gets its own row, so no width or text size
/// overflows (A44 PA3).
class FbMacroBars extends StatelessWidget {
  /// Creates the bars.
  const new({required this.macros, super.key});

  /// The macros, in display order.
  final List<FbMacroValue> macros;

  static const double _columnGap = FbSpace.s2;

  @override
  Widget build(BuildContext context) {
    if (!FbDensity.macroColumns || macros.isEmpty || _largeText(context)) {
      return _rows();
    }
    // Not a LayoutBuilder: that can't report intrinsic sizes, which tables,
    // IntrinsicHeight and the golden grids ask for.
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    return _ColumnsOrRows(
      fits: (maxWidth) => _columnsFit(maxWidth, scaler, direction),
      columns: _columns(),
      rows: _rows(),
    );
  }

  Widget _rows() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < macros.length; i++) ...[
        if (i > 0) const SizedBox(height: FbSpace.s3),
        _MacroBar(macro: macros[i]),
      ],
    ],
  );

  Widget _columns() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < macros.length; i++) ...[
        if (i > 0) const SizedBox(width: _columnGap),
        Expanded(child: _MacroColumn(macro: macros[i])),
      ],
    ],
  );

  bool _columnsFit(
    double maxWidth,
    TextScaler scaler,
    TextDirection direction,
  ) {
    if (!maxWidth.isFinite) return false;
    final column =
        (maxWidth - _columnGap * (macros.length - 1)) / macros.length;
    double width(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final w = painter.width;
      painter.dispose();
      return w;
    }

    return macros.every(
      (m) =>
          width(m.label, _MacroColumn.labelStyle) <= column &&
          width(m.valueText, _MacroColumn.valueStyle) <= column,
    );
  }
}

/// Shows the columns (first child) when [fits] says they fit the incoming max
/// width, else the rows (second child). Both are built; only the shown one
/// is laid out, painted, hit tested, in the semantics tree and onstage for
/// finders. Unlike a `LayoutBuilder` it reports intrinsic sizes (those of
/// the layout it would pick).
class _ColumnsOrRows extends MultiChildRenderObjectWidget {
  new({required this.fits, required Widget columns, required Widget rows})
    : super(children: [columns, rows]);

  final bool Function(double maxWidth) fits;

  @override
  MultiChildRenderObjectElement createElement() => _ColumnsOrRowsElement(this);

  @override
  _RenderColumnsOrRows createRenderObject(BuildContext context) =>
      _RenderColumnsOrRows(fits);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderColumnsOrRows renderObject,
  ) => renderObject.updateFits(fits);
}

class _ColumnsOrRowsElement extends MultiChildRenderObjectElement {
  new(_ColumnsOrRows super.widget);

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    final shown = (renderObject as _RenderColumnsOrRows)._shown;
    for (final child in children) {
      if (child.renderObject == shown) visitor(child);
    }
  }
}

class _ColumnsOrRowsSlot extends ContainerBoxParentData<RenderBox>;

class _RenderColumnsOrRows extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ColumnsOrRowsSlot>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ColumnsOrRowsSlot> {
  new(this._fits);

  bool Function(double maxWidth) _fits;

  void updateFits(bool Function(double maxWidth) value) {
    _fits = value;
    markNeedsLayout();
  }

  RenderBox? _shown;

  RenderBox _pick(double maxWidth) =>
      _fits(maxWidth) ? firstChild! : lastChild!;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ColumnsOrRowsSlot) {
      child.parentData = _ColumnsOrRowsSlot();
    }
  }

  @override
  void performLayout() {
    final child = _shown = _pick(constraints.maxWidth)
      ..layout(constraints, parentUsesSize: true);
    size = constraints.constrain(child.size);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.constrain(
    _pick(constraints.maxWidth).getDryLayout(constraints),
  );

  @override
  double computeMinIntrinsicWidth(double height) =>
      lastChild!.getMinIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      lastChild!.getMaxIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) =>
      _pick(width).getMinIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _pick(width).getMaxIntrinsicHeight(width);

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      _shown?.getDistanceToActualBaseline(baseline);

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_shown case final child?) context.paintChild(child, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      _shown?.hitTest(result, position: position) ?? false;

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (_shown case final child?) visitor(child);
  }
}

bool _largeText(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(14) >= 14 * 1.4;

Color _macroColor(BuildContext context, FbMacroKind kind) {
  final colors = context.fbColors;
  return switch (kind) {
    FbMacroKind.protein => colors.protein,
    FbMacroKind.carbs => colors.carbs,
    FbMacroKind.fat => colors.fat,
    FbMacroKind.fiber => colors.fiber,
  };
}

double _barHeight(FbMacroKind kind) =>
    kind == FbMacroKind.fiber ? 4 : FbDensity.macroBarHeight;

/// One macro as a column (compact): label, bar, amounts.
class _MacroColumn extends StatelessWidget {
  const new({required this.macro});

  final FbMacroValue macro;

  static const TextStyle labelStyle = FbType.caption;
  static final TextStyle valueStyle = FbType.numeric(FbType.caption);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Fibre stays quieter (HM-003): muted amounts and a thinner bar.
    final quiet = macro.kind == FbMacroKind.fiber;
    return Semantics(
      container: true,
      label: '${macro.label}, ${macro.valueText}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            macro.label,
            maxLines: 1,
            style: labelStyle.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: FbSpace.s1),
          SizedBox(
            height: FbDensity.macroBarHeight,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: switch (macro.target) {
                final target? => FbBarTrack(
                  value: macro.value,
                  target: target,
                  color: _macroColor(context, macro.kind),
                  height: _barHeight(macro.kind),
                ),
                null => const SizedBox.shrink(),
              },
            ),
          ),
          const SizedBox(height: FbSpace.s1),
          Text(
            macro.valueText,
            maxLines: 1,
            style: valueStyle.copyWith(
              color: quiet ? scheme.onSurfaceVariant : scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// One macro as a row: label and amounts on one line, the bar under them.
class _MacroBar extends StatelessWidget {
  const new({required this.macro});

  final FbMacroValue macro;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final small = macro.kind == FbMacroKind.fiber;
    final labelStyle = (small ? FbType.caption : FbType.label).copyWith(
      color: scheme.onSurface,
    );
    final valueStyle = FbType.numeric(small ? FbType.caption : FbType.bodySmall)
        .copyWith(color: scheme.onSurfaceVariant);
    return Semantics(
      container: true,
      label: '${macro.label}, ${macro.valueText}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The amounts keep one line at the end ("82 / 140 g" never wraps);
          // at large text sizes they go under the label instead.
          if (_largeText(context))
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(macro.label, style: labelStyle),
                Text(
                  macro.valueText,
                  style: valueStyle,
                  textAlign: TextAlign.end,
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(child: Text(macro.label, style: labelStyle)),
                const SizedBox(width: FbSpace.s2),
                Text(macro.valueText, style: valueStyle),
              ],
            ),
          if (macro.target case final target?) ...[
            const SizedBox(height: FbSpace.s1),
            FbBarTrack(
              value: macro.value,
              target: target,
              color: _macroColor(context, macro.kind),
              height: _barHeight(macro.kind),
            ),
          ],
        ],
      ),
    );
  }
}
