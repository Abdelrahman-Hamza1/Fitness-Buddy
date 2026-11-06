import 'package:fb_design_system/src/painting/dashed.dart';
import 'package:material_ui/material_ui.dart';

/// An outline border drawn in dashes (A63 D15): an empty field whose hint is
/// only a suggestion (last time's numbers). Same geometry as
/// [OutlineInputBorder] (equality includes the type), so the field keeps
/// its size; a floating label's gap falls back to the solid outline.
class FbDashedInputBorder extends OutlineInputBorder {
  /// Creates a dashed outline.
  const new({super.borderSide, super.borderRadius, super.gapPadding});

  /// The same outline in dashes.
  factory from(OutlineInputBorder border) => FbDashedInputBorder(
    borderSide: border.borderSide,
    borderRadius: border.borderRadius,
    gapPadding: border.gapPadding,
  );

  @override
  FbDashedInputBorder copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
    double? gapPadding,
  }) => FbDashedInputBorder(
    borderSide: borderSide ?? this.borderSide,
    borderRadius: borderRadius ?? this.borderRadius,
    gapPadding: gapPadding ?? this.gapPadding,
  );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is FbDashedInputBorder) {
      return FbDashedInputBorder(
        borderRadius: BorderRadius.lerp(a.borderRadius, borderRadius, t)!,
        borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
        gapPadding: a.gapPadding,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is FbDashedInputBorder) {
      return FbDashedInputBorder(
        borderRadius: BorderRadius.lerp(borderRadius, b.borderRadius, t)!,
        borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
        gapPadding: b.gapPadding,
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    if (gapStart != null && gapExtent > 0 && gapPercentage > 0) {
      super.paint(
        canvas,
        rect,
        gapStart: gapStart,
        gapExtent: gapExtent,
        gapPercentage: gapPercentage,
        textDirection: textDirection,
      );
      return;
    }
    final outer = borderRadius.toRRect(rect);
    final center = outer.inflate(borderSide.strokeOffset / 2);
    canvas.drawPath(dashedPath(Path()..addRRect(center)), borderSide.toPaint());
  }
}

/// The dashed version of the theme's enabled border, for an empty field
/// whose hint is a suggestion. Null when the theme's border isn't an
/// outline (then the field keeps it).
InputBorder? fbDashedEnabledBorder(BuildContext context) {
  final theme = Theme.of(context).inputDecorationTheme;
  final border = theme.enabledBorder ?? theme.border;
  return border is OutlineInputBorder ? FbDashedInputBorder.from(border) : null;
}
