import 'package:material_ui/material_ui.dart';

/// The type scale (A02 §3.2): Inter, with Noto Sans Arabic as the fallback
/// for Arabic text. Sizes are in sp (they follow the system font scale).
///
/// Colours are not set here: the text inherits them from the theme.
abstract final class FbType {
  /// The package the bundled fonts belong to.
  static const String package = 'fb_design_system';

  /// Primary family (Latin).
  static const String latinFamily = 'Inter';

  /// Fallback family (Arabic).
  static const String arabicFamily = 'NotoSansArabic';

  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  /// 48/56, semibold, tabular: the big number (HM-001).
  static const TextStyle display = TextStyle(
    fontFamily: latinFamily,
    package: package,
    fontFamilyFallback: [arabicFamily],
    fontSize: 48,
    height: 56 / 48,
    fontWeight: FontWeight.w600,
    fontFeatures: _tabular,
  );

  /// 24/32, semibold.
  static const TextStyle headline = TextStyle(
    fontFamily: latinFamily,
    package: package,
    fontFamilyFallback: [arabicFamily],
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w600,
  );

  /// 18/24, semibold.
  static const TextStyle title = TextStyle(
    fontFamily: latinFamily,
    package: package,
    fontFamilyFallback: [arabicFamily],
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w600,
  );

  /// 16/24, regular.
  static const TextStyle body = TextStyle(
    fontFamily: latinFamily,
    package: package,
    fontFamilyFallback: [arabicFamily],
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
  );

  /// 14/20, regular.
  static const TextStyle bodySmall = TextStyle(
    fontFamily: latinFamily,
    package: package,
    fontFamilyFallback: [arabicFamily],
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
  );

  /// 14/20, medium: buttons, chips, row labels.
  static const TextStyle label = TextStyle(
    fontFamily: latinFamily,
    package: package,
    fontFamilyFallback: [arabicFamily],
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
  );

  /// 12/16, medium: captions, badges.
  static const TextStyle caption = TextStyle(
    fontFamily: latinFamily,
    package: package,
    fontFamilyFallback: [arabicFamily],
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
  );

  /// [style] with tabular figures, so digits line up in columns and don't
  /// jitter while they change.
  static TextStyle numeric(TextStyle style) =>
      style.copyWith(fontFeatures: [...?style.fontFeatures, ..._tabular]);

  /// The scale as a Material [TextTheme], so material_ui widgets pick it up.
  static const TextTheme textTheme = TextTheme(
    displayLarge: display,
    displayMedium: display,
    displaySmall: display,
    headlineLarge: headline,
    headlineMedium: headline,
    headlineSmall: headline,
    titleLarge: title,
    titleMedium: title,
    titleSmall: label,
    bodyLarge: body,
    bodyMedium: body,
    bodySmall: bodySmall,
    labelLarge: label,
    labelMedium: label,
    labelSmall: caption,
  );
}
