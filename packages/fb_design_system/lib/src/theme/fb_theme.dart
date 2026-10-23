import 'package:fb_design_system/src/theme/component_themes.dart';
import 'package:fb_design_system/src/tokens/colors.dart';
import 'package:fb_design_system/src/tokens/palette.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

/// The design system's themes (A02 D4): an explicit [ColorScheme] and text
/// theme from the tokens plus an [FbColors] extension. No `fromSeed`.
abstract final class FbTheme {
  /// The light theme.
  static ThemeData light() => _build(FbPalette.of(Brightness.light));

  /// The dark theme.
  static ThemeData dark() => _build(FbPalette.of(Brightness.dark));

  static ThemeData _build(FbPalette p) {
    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.brand,
      onPrimary: p.onBrand,
      primaryContainer: p.brandContainer,
      onPrimaryContainer: p.onBrandContainer,
      secondary: p.brand,
      onSecondary: p.onBrand,
      secondaryContainer: p.brandContainer,
      onSecondaryContainer: p.onBrandContainer,
      error: p.error,
      onError: p.surface,
      errorContainer: p.errorContainer,
      onErrorContainer: p.onSurface,
      surface: p.surface,
      onSurface: p.onSurface,
      onSurfaceVariant: p.onSurfaceVariant,
      outline: p.outline,
      outlineVariant: p.outlineVariant,
      surfaceContainerLowest: p.surfaceContainer,
      surfaceContainerLow: p.surface,
      surfaceContainer: p.surfaceContainer,
      surfaceContainerHigh: p.surfaceContainerHigh,
      surfaceContainerHighest: p.surfaceContainerHigh,
      inverseSurface: p.inverseSurface,
      onInverseSurface: p.inverseOnSurface,
      inversePrimary: p.inversePrimary,
      surfaceTint: const Color(0x00000000),
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
    );
    final textTheme = FbType.textTheme.apply(
      bodyColor: p.onSurface,
      displayColor: p.onSurface,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.surface,
      canvasColor: p.surface,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      fontFamily: FbType.latinFamily,
      fontFamilyFallback: const [FbType.arabicFamily],
      package: FbType.package,
      splashFactory: InkRipple.splashFactory,
      extensions: [FbColors.fromPalette(p)],
      filledButtonTheme: fbFilledButtonTheme(scheme),
      outlinedButtonTheme: fbOutlinedButtonTheme(scheme),
      textButtonTheme: fbTextButtonTheme(scheme),
      cardTheme: fbCardTheme(scheme),
      chipTheme: fbChipTheme(scheme),
      snackBarTheme: fbSnackBarTheme(scheme),
      bottomSheetTheme: fbBottomSheetTheme(scheme),
      navigationBarTheme: fbNavigationBarTheme(scheme),
      inputDecorationTheme: fbInputDecorationTheme(scheme),
      listTileTheme: fbListTileTheme(scheme),
      datePickerTheme: fbDatePickerTheme(scheme),
      timePickerTheme: fbTimePickerTheme(scheme),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: const Color(0x00000000),
        titleTextStyle: textTheme.titleLarge,
      ),
    );
  }
}
