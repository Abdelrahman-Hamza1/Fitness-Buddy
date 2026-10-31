import 'package:fb_design_system/src/components/muscle_map_paths.dart';
import 'package:flutter/foundation.dart' show setEquals;
import 'package:material_ui/material_ui.dart';
import 'package:path_parsing/path_parsing.dart';

/// The muscle regions [FbMuscleMap] can highlight (WO-007, A37 D16): the
/// muscles of the vendored body outline. Regions shown on both views (like
/// [deltoids]) light up on both. The app maps its own muscle vocabulary to
/// these; the design system knows no domain types.
enum FbBodyRegion {
  /// Chest (front).
  chest,

  /// Shoulders (front and back).
  deltoids,

  /// Biceps (front).
  biceps,

  /// Triceps (front and back).
  triceps,

  /// Forearms (front and back).
  forearms,

  /// Trapezius (front and back).
  trapezius,

  /// Upper back: lats and rhomboids (back).
  upperBack,

  /// Lower back (back).
  lowerBack,

  /// Abdominals (front).
  abs,

  /// Obliques (front).
  obliques,

  /// Quadriceps (front).
  quadriceps,

  /// Hamstrings (back).
  hamstrings,

  /// Glutes (back).
  glutes,

  /// Calves (front and back).
  calves,

  /// Adductors (front and back).
  adductors,
}

/// One side of the body.
enum FbBodyView {
  /// Seen from the front.
  front,

  /// Seen from the back.
  back,
}

/// A front and back body with the [primary] regions dark and the
/// [secondary] ones lighter (WO-007); everything else is the neutral body.
/// Empty sets show the neutral body ("no primary muscle", A37 D2).
///
/// The drawing is one image for accessibility: [semanticLabel] must name
/// the main and secondary muscles in words, so the map never relies on
/// colour alone. The front is at the start side; the bodies themselves are
/// never mirrored.
class FbMuscleMap extends StatelessWidget {
  /// Creates a map [height] dp tall (each view keeps the outline's aspect).
  const new({
    required this.primary,
    required this.semanticLabel,
    this.secondary = const {},
    this.height = 160,
    super.key,
  });

  /// The main muscles, drawn dark.
  final Set<FbBodyRegion> primary;

  /// The secondary muscles, drawn lighter. A region in [primary] stays dark.
  final Set<FbBodyRegion> secondary;

  /// What the map shows, in words (main and secondary muscles).
  final String semanticLabel;

  /// The height of both bodies.
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final neutral = scheme.outlineVariant;
    final colours = FbMuscleMapColours(
      neutral: neutral,
      primary: scheme.primary,
      secondary: Color.lerp(neutral, scheme.primary, 0.4)!,
    );
    final box = fbBodyViewBox;
    final width = height * box.width / box.height;
    // Each view is its own layer, cached by the raster cache: lists of maps
    // (a log form while typing, a scrolling picker) never repaint them.
    Widget view(FbBodyView side) => RepaintBoundary(
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          isComplex: true,
          painter: FbMuscleMapPainter(
            view: side,
            primary: primary,
            secondary: secondary,
            colours: colours,
          ),
        ),
      ),
    );
    return Semantics(
      container: true,
      image: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: height * 0.08,
          children: [view(FbBodyView.front), view(FbBodyView.back)],
        ),
      ),
    );
  }
}

/// The three fills of a muscle map.
@immutable
final class FbMuscleMapColours {
  /// Creates the fills.
  const new({
    required this.neutral,
    required this.primary,
    required this.secondary,
  });

  /// The body and every region not highlighted.
  final Color neutral;

  /// Main muscles.
  final Color primary;

  /// Secondary muscles.
  final Color secondary;

  @override
  bool operator ==(Object other) =>
      other is FbMuscleMapColours &&
      other.neutral == neutral &&
      other.primary == primary &&
      other.secondary == secondary;

  @override
  int get hashCode => Object.hash(neutral, primary, secondary);
}

/// A parsed body part: its region (or `null` for the neutral body) and path.
typedef FbBodyPart = (FbBodyRegion?, Path);

final Map<FbBodyView, List<FbBodyPart>> _parsed = {};

/// The parsed parts of [view], parsed once on first use (never on the
/// startup path). Don't mutate the paths.
List<FbBodyPart> fbBodyParts(FbBodyView view) =>
    _parsed[view] ??= List.unmodifiable([
      for (final (region, d) in switch (view) {
        FbBodyView.front => fbMuscleMapFront,
        FbBodyView.back => fbMuscleMapBack,
      })
        (region, _parse(d)),
    ]);

Path _parse(String d) {
  final path = Path();
  writeSvgPathDataToPath(d, _PathSink(path));
  return path;
}

final Map<FbBodyView, Rect> _boundsCache = {};

Rect _bounds(FbBodyView view) =>
    _boundsCache[view] ??= fbBodyParts(view)
        .map((p) => p.$2.getBounds())
        .reduce((a, b) => a.expandToInclude(b));

/// The size every view is fitted into: the larger width and height of the
/// two outlines, so both bodies share one scale.
Size get fbBodyViewBox {
  final front = _bounds(FbBodyView.front);
  final back = _bounds(FbBodyView.back);
  return Size(
    front.width > back.width ? front.width : back.width,
    front.height > back.height ? front.height : back.height,
  );
}

/// Paints one view of the body, scaled to fit and centred.
class FbMuscleMapPainter extends CustomPainter {
  /// Creates the painter.
  const new({
    required this.view,
    required this.primary,
    required this.secondary,
    required this.colours,
  });

  /// The side of the body.
  final FbBodyView view;

  /// Regions drawn with [FbMuscleMapColours.primary].
  final Set<FbBodyRegion> primary;

  /// Regions drawn with [FbMuscleMapColours.secondary].
  final Set<FbBodyRegion> secondary;

  /// The fills.
  final FbMuscleMapColours colours;

  /// The fill of [region] in this map.
  Color colourOf(FbBodyRegion? region) {
    if (region == null) return colours.neutral;
    if (primary.contains(region)) return colours.primary;
    if (secondary.contains(region)) return colours.secondary;
    return colours.neutral;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = _bounds(view);
    final box = fbBodyViewBox;
    final scale = (size.width / box.width) < (size.height / box.height)
        ? size.width / box.width
        : size.height / box.height;
    canvas
      ..save()
      ..translate(
        (size.width - bounds.width * scale) / 2,
        (size.height - bounds.height * scale) / 2,
      )
      ..scale(scale)
      ..translate(-bounds.left, -bounds.top);
    final paint = Paint()..isAntiAlias = true;
    for (final (region, path) in fbBodyParts(view)) {
      canvas.drawPath(path, paint..color = colourOf(region));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(FbMuscleMapPainter oldDelegate) =>
      oldDelegate.view != view ||
      oldDelegate.colours != colours ||
      !setEquals(oldDelegate.primary, primary) ||
      !setEquals(oldDelegate.secondary, secondary);
}

class _PathSink implements PathProxy {
  new(this.path);

  final Path path;

  @override
  void moveTo(double x, double y) => path.moveTo(x, y);

  @override
  void lineTo(double x, double y) => path.lineTo(x, y);

  @override
  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) => path.cubicTo(x1, y1, x2, y2, x3, y3);

  @override
  void close() => path.close();
}
