import 'package:fb_design_system/src/brand/brand_geometry.dart';
import 'package:fb_design_system/src/brand/brand_path.dart';
import 'package:fb_design_system/src/tokens/colors.dart';
import 'package:material_ui/material_ui.dart';

/// How the Embrace mark is coloured.
enum FbMarkColourway {
  /// On the theme's surfaces: the brand colour and mint (light: the logo's
  /// deep teal + mint; dark: the light teal brand + mint).
  onSurface,

  /// On the launcher plate ([FbBrandColors.plate]): cream and mint, as the
  /// app icon.
  reversed,

  /// One colour, the theme's text colour (like Android's themed icon).
  monochrome,
}

/// The Embrace brand mark (A44 D13), drawn from the one path source in
/// `brand_geometry.dart`. A logo, so it is excluded from semantics: put a
/// text label next to it where it means something.
class FbBrandMark extends StatelessWidget {
  /// Creates the mark, [size] dp square.
  const new({
    this.size = 48,
    this.colourway = FbMarkColourway.onSurface,
    this.cropped = false,
    super.key,
  });

  /// Width and height in dp (the 108-unit canvas, or the figure's square
  /// when [cropped], scales to it).
  final double size;

  /// Whether to draw only the figure ([fbEmbraceMarkFigure]) without the
  /// icon's safe-zone padding: for a mark next to text (lockup, licences).
  final bool cropped;

  /// The colours.
  final FbMarkColourway colourway;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (a, b) = switch (colourway) {
      FbMarkColourway.onSurface => (scheme.primary, context.fbColors.mint),
      FbMarkColourway.reversed => (FbBrandColors.reversedA, FbBrandColors.mint),
      FbMarkColourway.monochrome => (scheme.onSurface, scheme.onSurface),
    };
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: FbMarkPainter(
            shapes: fbEmbraceMark,
            viewBox: cropped
                ? fbEmbraceMarkFigure
                : const Rect.fromLTWH(
                    0,
                    0,
                    fbEmbraceMarkCanvas,
                    fbEmbraceMarkCanvas,
                  ),
            a: a,
            b: b,
          ),
        ),
      ),
    );
  }
}

/// Paints mark shapes, scaling the square [viewBox] of their coordinates to
/// the paint size. Shared by the brand widgets; not exported.
class FbMarkPainter extends CustomPainter {
  /// Creates the painter.
  const new({
    required this.shapes,
    required this.viewBox,
    required this.a,
    required this.b,
  });

  /// The shapes, painted in order.
  final List<FbMarkShape> shapes;

  /// The square of the shapes' coordinates that fills the paint size.
  final Rect viewBox;

  /// The colour of [FbMarkPart.a].
  final Color a;

  /// The colour of [FbMarkPart.b].
  final Color b;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / viewBox.shortestSide;
    canvas
      ..save()
      ..scale(scale)
      ..translate(-viewBox.left, -viewBox.top);
    for (final shape in shapes) {
      final paint = Paint()
        ..isAntiAlias = true
        ..color = shape.part == FbMarkPart.a ? a : b;
      if (shape.strokeWidth case final width?) {
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round;
      }
      canvas.drawPath(fbMarkPath(shape), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(FbMarkPainter oldDelegate) =>
      oldDelegate.a != a ||
      oldDelegate.b != b ||
      oldDelegate.viewBox != viewBox ||
      !identical(oldDelegate.shapes, shapes);
}
