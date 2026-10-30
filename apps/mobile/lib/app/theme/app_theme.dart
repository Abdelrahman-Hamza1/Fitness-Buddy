import 'package:fb_design_system/fb_design_system.dart';
import 'package:material_ui/material_ui.dart';

/// Light and dark themes (UX-040): light by default (D-083, TD-107), dark or
/// the system's on the user's choice in Settings.
///
/// They come from the design system (A02): [FbTheme] builds them from the
/// tokens, in the "Embrace" palette (TD-098).
abstract final class AppTheme {
  /// The light theme.
  static final ThemeData light = FbTheme.light();

  /// The dark theme.
  static final ThemeData dark = FbTheme.dark();
}
