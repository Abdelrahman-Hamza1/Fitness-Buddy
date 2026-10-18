import 'package:fb_design_system/fb_design_system.dart';
import 'package:material_ui/material_ui.dart';

/// Light and dark themes; the app follows the system setting (UX-040).
///
/// They come from the design system (A02): [FbTheme] builds them from the
/// tokens, palette variant A by default. The app picks the variant through
/// [lightFor] / [darkFor] (`themeVariantProvider`, switched by the design
/// preview in the dev flavor).
abstract final class AppTheme {
  /// The light theme of [variant].
  static ThemeData lightFor(FbPaletteVariant variant) => FbTheme.light(variant);

  /// The dark theme of [variant].
  static ThemeData darkFor(FbPaletteVariant variant) => FbTheme.dark(variant);

  /// The light theme (palette variant A).
  static final ThemeData light = lightFor(FbPaletteVariant.a);

  /// The dark theme (palette variant A).
  static final ThemeData dark = darkFor(FbPaletteVariant.a);
}
