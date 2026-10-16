import 'package:material_ui/material_ui.dart';

/// Light and dark themes; the app follows the system setting (UX-040).
///
/// Placeholder colours from one seed until the design system brings the real
/// tokens and themes (A02, `fb_design_system`).
abstract final class AppTheme {
  // A02 replaces this seed with the design-system palette.
  static const MaterialColor _seed = Colors.teal;

  /// The light theme.
  static final ThemeData light = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: _seed),
  );

  /// The dark theme.
  static final ThemeData dark = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    ),
  );
}
