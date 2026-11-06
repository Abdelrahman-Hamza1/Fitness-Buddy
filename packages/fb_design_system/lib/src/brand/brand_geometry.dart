import 'package:material_ui/material_ui.dart';

/// The three shapes of the Momentum mark, left to right (start to end on the
/// canvas; a logo, so it doesn't mirror in RTL): each one decides its colour.
enum FbMarkTone {
  /// The short shape: the soft tint.
  soft,

  /// The middle shape: the mid tint.
  mid,

  /// The tall shape: the brand ink on light surfaces, the sky spark on the
  /// plate and on dark.
  strong,
}

/// One shape of a brand mark: a filled SVG path in the restricted syntax
/// that `parseFbMarkPath` reads (absolute M L C Q A Z only).
@immutable
final class FbMarkShape {
  /// Creates a shape.
  const new({required this.tone, required this.d});

  /// Which shape it is (decides the colour).
  final FbMarkTone tone;

  /// The path data, filled.
  final String d;
}

/// The single source of the Momentum mark's geometry (A64, TD-116).
///
/// `brand/momentum-mark.svg`, `brand/momentum-mini.svg` and the Android
/// launcher VectorDrawables are verbatim copies of these strings, checked by
/// `apps/mobile/test/android/brand_sync_test.dart`. To change the mark, edit
/// here, look at the goldens, then copy the strings over.
///
/// Construction: the owner-approved drawing on a 100 × 100 canvas, three
/// rounded pills (corner radius = half the width) with aligned bottoms,
/// `translate(3.17, 3) skewX(-22°)` of the rects (x 32.32, y 48, 19 × 32),
/// (55.32, 32, 19 × 48) and (78.32, 14, 21 × 66). Each pill is written as
/// four quarter-circle cubics (k = 0.5522847) and one straight side, all
/// mapped through that skew: a cubic Bézier's image under an affine map is
/// the cubic of the mapped control points, so the slanted caps are exact.
/// The result is scaled about the centre of the mark's smallest enclosing
/// circle on the 100 canvas, (49.7829, 50.1276) with r 52.2607, so that
/// circle is r 31 on the 108 canvas (the adaptive icon's safe circle is
/// r 33) and r 10.5 on the 28 mini canvas. Coordinates are rounded to 0.01;
/// `test/brand/brand_path_test.dart` recomputes them.
const double fbMomentumMarkCanvas = 108;

/// The full mark on the 108 × 108 adaptive-icon canvas
/// ([fbMomentumMarkCanvas]), centred, inside the safe zone.
const List<FbMarkShape> fbMomentumMark = [
  FbMarkShape(
    tone: FbMarkTone.soft,
    d:
        'M31.74 60.15 C33 57.04 36.54 54.52 39.65 54.52 '
        'C42.77 54.52 44.27 57.04 43.01 60.15 L39.9 67.86 '
        'C38.64 70.98 35.1 73.5 31.98 73.5 '
        'C28.87 73.5 27.37 70.98 28.63 67.86 Z',
  ),
  FbMarkShape(
    tone: FbMarkTone.mid,
    d:
        'M49.22 50.66 C50.48 47.55 54.02 45.03 57.13 45.03 '
        'C60.24 45.03 61.75 47.55 60.49 50.66 L53.54 67.86 '
        'C52.28 70.98 48.74 73.5 45.63 73.5 '
        'C42.52 73.5 41.01 70.98 42.27 67.86 Z',
  ),
  FbMarkShape(
    tone: FbMarkTone.strong,
    d:
        'M66.94 40.58 C68.33 37.14 72.24 34.35 75.68 34.35 '
        'C79.12 34.35 80.78 37.14 79.39 40.58 L68.61 67.27 '
        'C67.22 70.71 63.3 73.5 59.86 73.5 '
        'C56.42 73.5 54.76 70.71 56.15 67.27 Z',
  ),
];

/// The mark's bounds on the [fbMomentumMarkCanvas], rounded out (the mark
/// without the icon's safe-zone padding; not square): the lockup and the
/// licence page draw only this part, so the mark sits flush with the text
/// beside it.
const Rect fbMomentumMarkFigure = Rect.fromLTRB(28, 34, 80, 74);

/// The canvas size of [fbMomentumMini].
const double fbMomentumMiniCanvas = 28;

/// The mini mark of the Buddy avatar on a 28 × 28 canvas: the same three
/// shapes, centred on the avatar's disc.
const List<FbMarkShape> fbMomentumMini = [
  FbMarkShape(
    tone: FbMarkTone.soft,
    d:
        'M6.46 16.08 C6.89 15.03 8.09 14.18 9.14 14.18 '
        'C10.19 14.18 10.7 15.03 10.28 16.08 L9.22 18.7 '
        'C8.8 19.75 7.6 20.6 6.54 20.6 C5.49 20.6 4.98 19.75 5.41 18.7 '
        'Z',
  ),
  FbMarkShape(
    tone: FbMarkTone.mid,
    d:
        'M12.38 12.87 C12.81 11.82 14.01 10.96 15.06 10.96 '
        'C16.11 10.96 16.62 11.82 16.2 12.87 L13.84 18.7 '
        'C13.42 19.75 12.22 20.6 11.16 20.6 '
        'C10.11 20.6 9.6 19.75 10.03 18.7 Z',
  ),
  FbMarkShape(
    tone: FbMarkTone.strong,
    d:
        'M18.38 9.45 C18.85 8.29 20.18 7.34 21.34 7.34 '
        'C22.51 7.34 23.07 8.29 22.6 9.45 L18.95 18.49 '
        'C18.48 19.66 17.15 20.6 15.99 20.6 '
        'C14.82 20.6 14.26 19.66 14.73 18.49 Z',
  ),
];

/// Fixed brand asset colours: the launcher icon's plate and the shapes on it
/// (TD-116). Not theme roles: they are what the Android icon shows, in every
/// theme, and the sync test checks the VectorDrawables against them. They
/// equal the light palette's brand, markSoft, markMid and spark roles
/// (`brand_path_test.dart` checks it).
abstract final class FbBrandColors {
  /// The prod launcher plate: the brand ink.
  static const Color plate = Color(0xFF1E2A32);

  /// The short shape.
  static const Color soft = Color(0xFFD3E3EA);

  /// The middle shape.
  static const Color mid = Color(0xFF8FB3C4);

  /// The tall shape on the plate: the sky spark.
  static const Color spark = Color(0xFF6EC8FF);
}
