import 'package:fb_design_system/fb_design_system.dart';
import 'package:material_ui/material_ui.dart';

/// Light and dark themes; the app follows the system setting (UX-040).
///
/// They come from the design system (A02): [FbTheme] builds them from the
/// tokens, in the "Warm" palette (backlog #59).
abstract final class AppTheme {
  /// The light theme.
  static final ThemeData light = FbTheme.light();

  /// The dark theme.
  static final ThemeData dark = FbTheme.dark();
}
