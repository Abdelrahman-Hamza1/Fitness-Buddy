import 'package:fb_design_system/src/brand/brand_geometry.dart';
import 'package:fb_design_system/src/brand/brand_path.dart';
import 'package:fb_design_system/src/tokens/colors.dart';
import 'package:material_ui/material_ui.dart';

/// How the Momentum mark is coloured.
enum FbMarkColourway {
  /// On the theme's surfaces: soft, mid and the theme's strong shape (light:
  /// the brand ink; dark: the sky spark).
  onSurface,

  /// On the launcher plate ([FbBrandColors.plate]): soft, mid and the sky
  /// spark, as the app icon.
  plate,

  /// One colour, the theme's text colour (like Android's themed icon).
  monochrome,
}

/// The Momentum brand mark (A64, TD-116), drawn from the one path source in
/// `brand_geometry.dart`. A logo, so it is excluded from semantics: put a
/// text label next to it where it means something. It never mirrors in RTL.
class FbBrandMark extends StatelessWidget {
  /// Creates the mark, [size] dp tall (and as wide, unless [cropped]).
  const new({
    this.size = 48,
    this.colourway = FbMarkColourway.onSurface,
    this.cropped = false,
    super.key,
  });

  /// The height in dp. The 108-unit canvas is [size] square; the cropped
  /// figure is [size] tall and as wide as its aspect needs.
  final double size;

  /// Whether to draw only the mark's bounds ([fbMomentumMarkFigure]) without
  /// the icon's safe-zone padding: for a mark next to text (lockup,
  /// licences).
  final bool cropped;

  /// The colours.
  final FbMarkColourway colourway;

  @override
  Widget build(BuildContext context) {
    final colors = context.fbColors;
    final text = Theme.of(context).colorScheme.onSurface;
    final palette = switch (colourway) {
      FbMarkColourway.onSurface => (
        soft: colors.markSoft,
        mid: colors.markMid,
        strong: colors.markStrong,
      ),
      FbMarkColourway.plate => (
        soft: FbBrandColors.soft,
        mid: FbBrandColors.mid,
        strong: FbBrandColors.spark,
      ),
      FbMarkColourway.monochrome => (soft: text, mid: text, strong: text),
    };
    const canvas = Rect.fromLTWH(
      0,
      0,
      fbMomentumMarkCanvas,
      fbMomentumMarkCanvas,
    );
    final viewBox = cropped ? fbMomentumMarkFigure : canvas;
    return ExcludeSemantics(
      child: SizedBox(
        width: size * viewBox.width / viewBox.height,
        height: size,
        child: CustomPaint(
          painter: FbMarkPainter(
            shapes: fbMomentumMark,
            viewBox: viewBox,
            soft: palette.soft,
            mid: palette.mid,
            strong: palette.strong,
          ),
        ),
      ),
    );
  }
}

/// Paints mark shapes, scaling the [viewBox] of their coordinates to the
/// paint size (same aspect). Shared by the brand widgets; not exported.
class FbMarkPainter extends CustomPainter {
  /// Creates the painter.
  const new({
    required this.shapes,
    required this.viewBox,
    required this.soft,
    required this.mid,
    required this.strong,
  });

  /// The shapes, filled in order.
  final List<FbMarkShape> shapes;

  /// The part of the shapes' coordinates that fills the paint size.
  final Rect viewBox;

  /// The colour of [FbMarkTone.soft].
  final Color soft;

  /// The colour of [FbMarkTone.mid].
  final Color mid;

  /// The colour of [FbMarkTone.strong].
  final Color strong;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / viewBox.height;
    canvas
      ..save()
      ..scale(scale)
      ..translate(-viewBox.left, -viewBox.top);
    for (final shape in shapes) {
      final paint = Paint()
        ..isAntiAlias = true
        ..color = switch (shape.tone) {
          FbMarkTone.soft => soft,
          FbMarkTone.mid => mid,
          FbMarkTone.strong => strong,
        };
      canvas.drawPath(fbMarkPath(shape), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(FbMarkPainter oldDelegate) =>
      oldDelegate.soft != soft ||
      oldDelegate.mid != mid ||
      oldDelegate.strong != strong ||
      oldDelegate.viewBox != viewBox ||
      !identical(oldDelegate.shapes, shapes);
}
