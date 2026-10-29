import 'package:material_ui/material_ui.dart';

/// The 4-point spacing scale (A02 D4). Use these, never raw numbers.
abstract final class FbSpace {
  /// 4.
  static const double s1 = 4;

  /// 8.
  static const double s2 = 8;

  /// 12.
  static const double s3 = 12;

  /// 16, the default screen and card padding.
  static const double s4 = 16;

  /// 24.
  static const double s5 = 24;

  /// 32.
  static const double s6 = 32;

  /// 48.
  static const double s7 = 48;
}

/// Corner radii (Embrace, TD-098). Buttons are pills: a 24 dp radius on the
/// 48 dp button (see `component_themes.dart`), so a label that wraps at large
/// text keeps normal corners.
abstract final class FbRadius {
  /// 8: small elements (badges inside cards, bar caps).
  static const double sm = 8;

  /// 12: chips, inputs, banners, snackbars.
  static const double md = 12;

  /// 20: cards, dialogs, bubbles.
  static const double lg = 20;

  /// 28, the top corners of a bottom sheet.
  static const double sheet = 28;

  /// Large enough to make any box a pill.
  static const double pill = 999;

  /// A [BorderRadius] of [sm].
  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));

  /// A [BorderRadius] of [md].
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));

  /// A [BorderRadius] of [lg].
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));

  /// A [BorderRadius] of [pill].
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));

  /// The top corners of a sheet.
  static const BorderRadiusDirectional sheetTop = BorderRadiusDirectional.only(
    topStart: Radius.circular(sheet),
    topEnd: Radius.circular(sheet),
  );
}

/// Elevations. Cards are tonal and flat ("clean, not empty", UX-043).
abstract final class FbElevation {
  /// 0.
  static const double flat = 0;

  /// 1.
  static const double raised = 1;

  /// 3, for sheets and snackbars.
  static const double overlay = 3;
}
