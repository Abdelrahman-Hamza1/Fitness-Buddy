import 'package:material_ui/material_ui.dart';

/// Every colour role of the palette in one brightness: "Warm", a deep indigo
/// brand on warm stone neutrals (the owner's pick, backlog #59). Raw values:
/// widgets read them through the theme (`Theme.of(context).colorScheme`,
/// `context.fbColors`), not from here.
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
  });

  /// The palette in [brightness].
  factory of(Brightness brightness) => switch (brightness) {
    Brightness.light => _light,
    Brightness.dark => _dark,
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
}

// Starting values from the A02 plan §3.2. Lightness was tuned until the
// contrast test (test/tokens/contrast_test.dart) passed; changes are listed
// in the step card's Outcome.

const _light = FbPalette(
  brightness: Brightness.light,
  brand: Color(0xFF3730A3),
  onBrand: Color(0xFFFFFFFF),
  brandContainer: Color(0xFFE0E7FF),
  onBrandContainer: Color(0xFF312E81),
  surface: Color(0xFFFAFAF9),
  surfaceContainer: Color(0xFFFFFFFF),
  surfaceContainerHigh: Color(0xFFF5F5F4),
  onSurface: Color(0xFF1C1917),
  onSurfaceVariant: Color(0xFF57534E),
  outline: Color(0xFF948C87),
  outlineVariant: Color(0xFFE7E5E4),
  protein: Color(0xFF0F766E),
  carbs: Color(0xFFB45309),
  fat: Color(0xFFBE185D),
  fiber: Color(0xFF4D7C0F),
  overTarget: Color(0xFF766F6A),
  success: Color(0xFF15803D),
  info: Color(0xFF0369A1),
  error: Color(0xFF9F3A2C),
  errorContainer: Color(0xFFFBEAE7),
  inverseSurface: Color(0xFF1C1917),
  inverseOnSurface: Color(0xFFFAFAF9),
  inversePrimary: Color(0xFFA5B4FC),
);

const _dark = FbPalette(
  brightness: Brightness.dark,
  brand: Color(0xFFA5B4FC),
  onBrand: Color(0xFF1E1B4B),
  brandContainer: Color(0xFF312E81),
  onBrandContainer: Color(0xFFE0E7FF),
  surface: Color(0xFF14110F),
  surfaceContainer: Color(0xFF1C1917),
  surfaceContainerHigh: Color(0xFF292524),
  onSurface: Color(0xFFF5F5F4),
  onSurfaceVariant: Color(0xFFA8A29E),
  outline: Color(0xFF746F68),
  outlineVariant: Color(0xFF292524),
  protein: Color(0xFF5EEAD4),
  carbs: Color(0xFFFCD34D),
  fat: Color(0xFFF9A8D4),
  fiber: Color(0xFFBEF264),
  overTarget: Color(0xFFA8A29E),
  success: Color(0xFF86EFAC),
  info: Color(0xFF7DD3FC),
  error: Color(0xFFF2B8AE),
  errorContainer: Color(0xFF3A1D18),
  inverseSurface: Color(0xFFF5F5F4),
  inverseOnSurface: Color(0xFF14110F),
  inversePrimary: Color(0xFF3730A3),
);
