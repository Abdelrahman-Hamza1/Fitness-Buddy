import 'package:material_ui/material_ui.dart';

/// Every colour role of the palette in one brightness: "Ink & Sky" (TD-116),
/// the owner's identity of 2026-11-06: an ink blue-grey brand with a sky-blue
/// spark, on cool off-white (light) or blue-black (dark) neutrals, and the
/// Momentum mark's soft / mid / strong shapes. One brand palette in R1: a
/// second one would be two more consts and the switch in [FbPalette.of], all
/// in this file.
///
/// Raw values: widgets read them through the theme
/// (`Theme.of(context).colorScheme`, `context.fbColors`), not from here.
final class FbPalette {
  /// Creates a palette.
  const new({
    required this.brightness,
    required this.brand,
    required this.onBrand,
    required this.brandContainer,
    required this.onBrandContainer,
    required this.surface,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.overTarget,
    required this.success,
    required this.info,
    required this.error,
    required this.errorContainer,
    required this.inverseSurface,
    required this.inverseOnSurface,
    required this.inversePrimary,
    required this.spark,
    required this.sparkContainer,
    required this.onSparkContainer,
    required this.markSoft,
    required this.markMid,
    required this.markStrong,
    required this.markPlate,
  });

  /// The palette in [brightness].
  factory of(Brightness brightness) => switch (brightness) {
    Brightness.light => _inkSkyLight,
    Brightness.dark => _inkSkyDark,
  };

  /// Light or dark.
  final Brightness brightness;

  /// Brand colour: primary actions, selection, focus.
  final Color brand;

  /// Text and icons on [brand].
  final Color onBrand;

  /// A calm brand tint: selected chips, highlights.
  final Color brandContainer;

  /// Text and icons on [brandContainer].
  final Color onBrandContainer;

  /// Screen background.
  final Color surface;

  /// Cards and sheets.
  final Color surfaceContainer;

  /// Inputs, bar tracks, raised areas.
  final Color surfaceContainerHigh;

  /// Primary text.
  final Color onSurface;

  /// Secondary ("muted") text and icons.
  final Color onSurfaceVariant;

  /// Borders of controls (input fields, outlined buttons, badges): 3:1.
  final Color outline;

  /// Dividers and other decoration. Exempt from contrast (not information).
  final Color outlineVariant;

  /// Macro colours (UX-042): one per macro, never used as text.
  final Color protein;

  /// See [protein].
  final Color carbs;

  /// See [protein].
  final Color fat;

  /// See [protein].
  final Color fiber;

  /// Over a target (SF-021): a neutral tone, never alarm red.
  final Color overTarget;

  /// Success (calm green).
  final Color success;

  /// Information.
  final Color info;

  /// Errors the user can fix: a muted brick, not alarm red. Used only by the
  /// inline error banner and input errors.
  final Color error;

  /// Background of the inline error banner.
  final Color errorContainer;

  /// Snackbar background.
  final Color inverseSurface;

  /// Snackbar text.
  final Color inverseOnSurface;

  /// Snackbar action ([brand] seen on [inverseSurface]).
  final Color inversePrimary;

  /// The sky spark: the Momentum mark's strong shape on the plate and on
  /// dark, and small highlights. Decoration only: never text, and never thin
  /// data on a light surface (about 1.8:1 there).
  final Color spark;

  /// A calm sky tint for small highlights with text on them.
  final Color sparkContainer;

  /// Text and icons on [sparkContainer].
  final Color onSparkContainer;

  /// The Momentum mark's short (start) shape.
  final Color markSoft;

  /// The Momentum mark's middle shape.
  final Color markMid;

  /// The Momentum mark's tall (end) shape on the theme's surfaces: the brand
  /// ink on light, the [spark] on dark.
  final Color markStrong;

  /// The plate the mark sits on in the Buddy avatar (the mark on it is
  /// [markSoft], [markMid] and [spark]): the ink on light, the dark surface
  /// on dark (an edge on the input bar and on cards).
  final Color markPlate;
}

// Values from technical-planning/design/momentum/README.md (TD-116). Roles
// the identity doesn't fix (outline, overTarget, the dark outlineVariant, the
// inverse roles) are derived and AA-checked by test/tokens/contrast_test.dart;
// carbs, fat, fiber, success, info and error keep their earlier values,
// re-checked on the new neutrals.

const _inkSkyLight = FbPalette(
  brightness: Brightness.light,
  brand: Color(0xFF1E2A32),
  onBrand: Color(0xFFFFFFFF),
  brandContainer: Color(0xFFE6EEF2),
  onBrandContainer: Color(0xFF1E2A32),
  surface: Color(0xFFFAFAF8),
  surfaceContainer: Color(0xFFFFFFFF),
  surfaceContainerHigh: Color(0xFFEEF1F3),
  onSurface: Color(0xFF1A2329),
  onSurfaceVariant: Color(0xFF57636B),
  outline: Color(0xFF7E8A92),
  outlineVariant: Color(0xFFE5E9EC),
  protein: Color(0xFF7C4DDB),
  carbs: Color(0xFFB9760F),
  fat: Color(0xFFC2457A),
  fiber: Color(0xFF5E8A12),
  overTarget: Color(0xFF666D72),
  success: Color(0xFF14773A),
  info: Color(0xFF0369A1),
  error: Color(0xFFA2402F),
  errorContainer: Color(0xFFFBEAE6),
  inverseSurface: Color(0xFF1A2329),
  inverseOnSurface: Color(0xFFFAFAF8),
  inversePrimary: Color(0xFFA9CDDC),
  spark: Color(0xFF6EC8FF),
  sparkContainer: Color(0xFFDDF1FF),
  onSparkContainer: Color(0xFF06324D),
  markSoft: Color(0xFFD3E3EA),
  markMid: Color(0xFF8FB3C4),
  markStrong: Color(0xFF1E2A32),
  markPlate: Color(0xFF1E2A32),
);

const _inkSkyDark = FbPalette(
  brightness: Brightness.dark,
  brand: Color(0xFFA9CDDC),
  onBrand: Color(0xFF0E1418),
  brandContainer: Color(0xFF22343F),
  onBrandContainer: Color(0xFFD6E8F0),
  surface: Color(0xFF0E1418),
  surfaceContainer: Color(0xFF1A242B),
  surfaceContainerHigh: Color(0xFF24303A),
  onSurface: Color(0xFFEAF0F3),
  onSurfaceVariant: Color(0xFFA7B3BA),
  outline: Color(0xFF717F88),
  outlineVariant: Color(0xFF2B3740),
  protein: Color(0xFFB79BFF),
  carbs: Color(0xFFF2BE5C),
  fat: Color(0xFFF29AC0),
  fiber: Color(0xFFB5D86A),
  overTarget: Color(0xFF8E989E),
  success: Color(0xFF86EFAC),
  info: Color(0xFF7DD3FC),
  error: Color(0xFFF0B4A8),
  errorContainer: Color(0xFF3A1E19),
  inverseSurface: Color(0xFFEAF0F3),
  inverseOnSurface: Color(0xFF0E1418),
  inversePrimary: Color(0xFF1E2A32),
  spark: Color(0xFF6EC8FF),
  sparkContainer: Color(0xFF12384F),
  onSparkContainer: Color(0xFFDDF1FF),
  markSoft: Color(0xFFD3E3EA),
  markMid: Color(0xFF8FB3C4),
  markStrong: Color(0xFF6EC8FF),
  markPlate: Color(0xFF0E1418),
);
