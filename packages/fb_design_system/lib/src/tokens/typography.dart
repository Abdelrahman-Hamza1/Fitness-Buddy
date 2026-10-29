import 'package:fb_design_system/src/tokens/density.dart';
import 'package:material_ui/material_ui.dart';

/// The type scale (A02 §3.2, Embrace TD-098): Nunito (rounded, like the logo
/// wordmark) for display numbers, titles and the wordmark; Inter for body,
/// labels, buttons and chips. Noto Sans Arabic is the fallback for Arabic text
/// in every style. Sizes are in sp (they follow the system font scale).
///
/// Colours are not set here: the text inherits them from the theme.
abstract final class FbType {
  /// The package the bundled fonts belong to.
  static const String package = 'fb_design_system';

  /// Display family (Latin): big numbers, titles, the wordmark.
  static const String displayFamily = 'Nunito';

  /// Body family (Latin): everything else.
  static const String bodyFamily = 'Inter';

  /// Fallback family (Arabic).
  static const String arabicFamily = 'NotoSansArabic';

  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  /// Nunito extra-bold, tabular: the big number (HM-001). 40/48 in the
  /// compact density, 48/56 in the comfortable one ([FbDensity]).
  static const TextStyle display = TextStyle(
    fontFamily: displayFamily,
    package: package,
    fontFamilyFallback: [arabicFamily],
    fontSize: FbDensity.displaySize,
    height: FbDensity.displayLineHeight / FbDensity.displaySize,
    fontWeight: FontWeight.w800,
    fontFeatures: _tabular,
  );

  /// 24/32, Nunito extra-bold: screen titles.
  static const TextStyle headline = TextStyle(
    fontFamily: displayFamily,
    package: package,
    fontFamilyFallback: [arabicFamily],
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w800,
  );

  /// 18/24, Nunito bold: section and card titles.
  static const TextStyle title = TextStyle(
    fontFamily: displayFamily,
    package: package,
    fontFamilyFallback: [arabicFamily],
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w700,
  );

  /// 16/24, Inter regular.
  static const TextStyle body = TextStyle(
    fontFamily: bodyFamily,
    package: package,
    fontFamilyFallback: [arabicFamily],
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
  );

  /// 14/20, Inter regular.
  static const TextStyle bodySmall = TextStyle(
    fontFamily: bodyFamily,
    package: package,
    fontFamilyFallback: [arabicFamily],
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
  );

  /// 14/20, Inter medium: row labels.
  static const TextStyle label = TextStyle(
    fontFamily: bodyFamily,
    package: package,
    fontFamilyFallback: [arabicFamily],
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
  );

  /// 12/16, Inter medium: captions, badges.
  static const TextStyle caption = TextStyle(
    fontFamily: bodyFamily,
    package: package,
    fontFamilyFallback: [arabicFamily],
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
  );

  /// 15/20, Inter semibold: button labels.
  static const TextStyle button = TextStyle(
    fontFamily: bodyFamily,
    package: package,
    fontFamilyFallback: [arabicFamily],
    fontSize: 15,
    height: 20 / 15,
    fontWeight: FontWeight.w600,
  );

  /// 13/18, Inter medium: chip labels.
  static const TextStyle chip = TextStyle(
    fontFamily: bodyFamily,
    package: package,
    fontFamilyFallback: [arabicFamily],
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w500,
  );

  /// The "Fitness Buddy" wordmark at [size]: Nunito black (900).
  static TextStyle wordmark(double size) => TextStyle(
    fontFamily: displayFamily,
    package: package,
    fontFamilyFallback: const [arabicFamily],
    fontSize: size,
    height: 1.2,
    fontWeight: FontWeight.w900,
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
