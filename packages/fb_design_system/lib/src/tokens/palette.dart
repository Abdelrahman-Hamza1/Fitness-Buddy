import 'package:material_ui/material_ui.dart';

/// Every colour role of the palette in one brightness: "Embrace" (TD-098), the
/// owner's identity from the design canvas: a deep-teal brand with a mint
/// accent, on green-black ("Deep Forest", dark) or cream ("Mint Cream",
/// light) neutrals. One brand palette in R1: a second one would be two more
/// consts and the switch in [FbPalette.of], all in this file.
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
    required this.mint,
    required this.avatarBackground,
    required this.avatarForeground,
  });

  /// The palette in [brightness].
  factory of(Brightness brightness) => switch (brightness) {
    Brightness.light => _embraceLight,
    Brightness.dark => _embraceDark,
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

  /// The logo's mint (the second figure of the Embrace mark): decoration
  /// only, never text and never information.
  final Color mint;

  /// The Buddy avatar's disc.
  final Color avatarBackground;

  /// The Buddy avatar's first figure (the second one is [mint]).
  final Color avatarForeground;
}

// Values from technical-planning/design/embrace/README.md. Deviations (all
// in light, for WCAG AA; listed in the A44 card's Outcome): outline #87938E ->
// #808C87 and overTarget #8C918E -> #686E6B. Roles the identity doesn't
// define (success, info, the inverse roles) are derived and AA-checked by
// test/tokens/contrast_test.dart. The light avatar uses the launcher
// colourway (a brand disc), since mint on brandContainer is invisible.

const _embraceLight = FbPalette(
  brightness: Brightness.light,
  brand: Color(0xFF0B6E5F),
  onBrand: Color(0xFFFFFFFF),
  brandContainer: Color(0xFFD3F0E3),
  onBrandContainer: Color(0xFF0A3B33),
  surface: Color(0xFFFAF9F4),
  surfaceContainer: Color(0xFFFFFFFF),
  surfaceContainerHigh: Color(0xFFEFF2EC),
  onSurface: Color(0xFF13201D),
  onSurfaceVariant: Color(0xFF53625D),
  outline: Color(0xFF808C87),
  outlineVariant: Color(0xFFE2E7E1),
  protein: Color(0xFF3D5FD9),
  carbs: Color(0xFFB9760F),
  fat: Color(0xFFC2457A),
  fiber: Color(0xFF5E8A12),
  overTarget: Color(0xFF686E6B),
  success: Color(0xFF14773A),
  info: Color(0xFF0369A1),
  error: Color(0xFFA2402F),
  errorContainer: Color(0xFFFBEAE6),
  inverseSurface: Color(0xFF13201D),
  inverseOnSurface: Color(0xFFFAF9F4),
  inversePrimary: Color(0xFF6FD6B6),
  mint: Color(0xFFA8E3CB),
  avatarBackground: Color(0xFF0B6E5F),
  avatarForeground: Color(0xFFFFFFFF),
);

const _embraceDark = FbPalette(
  brightness: Brightness.dark,
  brand: Color(0xFF6FD6B6),
  onBrand: Color(0xFF04241D),
  brandContainer: Color(0xFF123F36),
  onBrandContainer: Color(0xFFBFEEDD),
  surface: Color(0xFF0C1412),
  surfaceContainer: Color(0xFF141E1B),
  surfaceContainerHigh: Color(0xFF1D2925),
  onSurface: Color(0xFFE8EFEC),
  onSurfaceVariant: Color(0xFF9DAEA8),
  outline: Color(0xFF6C7C77),
  outlineVariant: Color(0xFF24322E),
  protein: Color(0xFF8EA8FF),
  carbs: Color(0xFFF2BE5C),
  fat: Color(0xFFF29AC0),
  fiber: Color(0xFFB5D86A),
  overTarget: Color(0xFF8F9A96),
  success: Color(0xFF86EFAC),
  info: Color(0xFF7DD3FC),
  error: Color(0xFFF0B4A8),
  errorContainer: Color(0xFF3A1E19),
  inverseSurface: Color(0xFFE8EFEC),
  inverseOnSurface: Color(0xFF0C1412),
  inversePrimary: Color(0xFF0B6E5F),
  mint: Color(0xFFA8E3CB),
  avatarBackground: Color(0xFF123F36),
  avatarForeground: Color(0xFF6FD6B6),
);
