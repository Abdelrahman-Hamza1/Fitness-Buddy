import 'package:material_ui/material_ui.dart';

/// The two figures of the Embrace mark: [a] is the deep-teal one hugging
/// [b], the mint one.
enum FbMarkPart {
  /// The teal figure (the brand colour).
  a,

  /// The mint figure.
  b,
}

/// One shape of a brand mark: an SVG path in the restricted syntax that
/// `parseFbMarkPath` reads (absolute M L C Q A Z only), stroked with round
/// caps at [strokeWidth], or filled when that is null.
@immutable
final class FbMarkShape {
  /// Creates a shape.
  const new({required this.part, required this.d, this.strokeWidth});

  /// Which figure it belongs to (decides the colour).
  final FbMarkPart part;

  /// The path data.
  final String d;

  /// The stroke width in canvas units, or null for a filled shape.
  final double? strokeWidth;
}

/// The single source of the Embrace mark's geometry (A44 D9, TD-098).
///
/// `brand/embrace-mark.svg`, `brand/embrace-mini.svg` and the Android
/// launcher VectorDrawables are verbatim copies of these strings, checked by
/// `apps/mobile/test/android/brand_sync_test.dart`. To change the mark, edit
/// here, look at the `brand_mark` golden, then copy the strings over.
///
/// Construction (D10, redesigned in the A44 review after the owner's draft):
/// two friends side by side, each a big head (r 7.25) above one bold stroke
/// (12.5 of 108, the same for both, round caps). The teal figure is an open
/// C whose mouth faces the mint figure and wraps around it: its lower arm
/// sweeps under and up in front of the mint body. The mint figure's arm
/// starts in the middle of the teal's embrace and rises through the mouth
/// into its own arc, which comes down beside the teal arm. Where the figures
/// meet there is a 3.6-unit gap of real background (about 0.3 stroke), never
/// an outline, so the one-colour version still shows two figures.
/// Everything lies inside r 31 of the centre of the 108 canvas (the
/// adaptive icon's safe circle is r 33).
const double fbEmbraceMarkCanvas = 108;

/// The full mark on the 108 × 108 adaptive-icon canvas ([fbEmbraceMarkCanvas]).
const List<FbMarkShape> fbEmbraceMark = [
  FbMarkShape(
    part: FbMarkPart.a,
    d: 'M39.75 31.4 A7.25 7.25 0 1 1 54.25 31.4 A7.25 7.25 0 1 1 39.75 31.4 Z',
  ),
  FbMarkShape(
    part: FbMarkPart.b,
    d: 'M58 33.5 A7.25 7.25 0 1 1 72.5 33.5 A7.25 7.25 0 1 1 58 33.5 Z',
  ),
  FbMarkShape(
    part: FbMarkPart.a,
    d: 'M38.43 45.66 A16.2 16.2 0 1 0 57 72.19',
    strokeWidth: 12.5,
  ),
  FbMarkShape(
    part: FbMarkPart.b,
    d: 'M47.25 59.25 L60.45 51.29 A10.75 10.75 0 0 1 73.33 68.36',
    strokeWidth: 12.5,
  ),
];

/// The figure's bounding square on the [fbEmbraceMarkCanvas] (the mark
/// without the icon's safe-zone padding): the lockup and the licence page
/// draw only this part, so the figure sits flush with the text beside it.
const Rect fbEmbraceMarkFigure = Rect.fromLTWH(24, 23, 60, 60);

/// The canvas size of [fbEmbraceMini].
const double fbEmbraceMiniCanvas = 28;

/// The mini mark of the Buddy avatar on a 28 × 28 canvas, the design canvas's
/// avatar verbatim: two touching heads, each above its own arc, the arcs
/// overlapping with the mint one in front (it reads as people at 24–28 dp).
const List<FbMarkShape> fbEmbraceMini = [
  FbMarkShape(
    part: FbMarkPart.a,
    d: 'M9 10 A2.5 2.5 0 1 1 14 10 A2.5 2.5 0 1 1 9 10 Z',
  ),
  FbMarkShape(
    part: FbMarkPart.b,
    d: 'M14 10 A2.5 2.5 0 1 1 19 10 A2.5 2.5 0 1 1 14 10 Z',
  ),
  FbMarkShape(
    part: FbMarkPart.a,
    d: 'M6.5 20 A5 5 0 0 1 16.5 20',
    strokeWidth: 2,
  ),
  FbMarkShape(
    part: FbMarkPart.b,
    d: 'M11.5 20 A5 5 0 0 1 21.5 20',
    strokeWidth: 2,
  ),
];

/// Fixed brand asset colours: the launcher icon's plate and the reversed
/// figures on it (D10). Not theme roles: they are what the Android icon
/// shows, in every theme, and the sync test checks the VectorDrawables
/// against them. They equal the light palette's brand, surface and mint
/// roles (`brand_path_test.dart` checks it).
abstract final class FbBrandColors {
  /// The prod launcher plate (the logo's deep teal).
  static const Color plate = Color(0xFF0B6E5F);

  /// The teal figure, reversed onto [plate] (the logo's cream).
  static const Color reversedA = Color(0xFFFAF9F4);

  /// The mint figure, in every colourway but monochrome.
  static const Color mint = Color(0xFFA8E3CB);
}
