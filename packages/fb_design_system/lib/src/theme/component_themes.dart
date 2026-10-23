import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

const double _minTouch = 48;

const Color _clear = Color(0x00000000);

const RoundedRectangleBorder _mdShape = RoundedRectangleBorder(
  borderRadius: FbRadius.mdAll,
);

ButtonStyle _base() => const ButtonStyle(
  minimumSize: WidgetStatePropertyAll(Size(_minTouch, _minTouch)),
  shape: WidgetStatePropertyAll(_mdShape),
  textStyle: WidgetStatePropertyAll(FbType.label),
  padding: WidgetStatePropertyAll(
    EdgeInsetsDirectional.symmetric(horizontal: FbSpace.s4),
  ),
  elevation: WidgetStatePropertyAll(FbElevation.flat),
);

/// Primary buttons (UX-021): filled, brand.
FilledButtonThemeData fbFilledButtonTheme(ColorScheme scheme) =>
    FilledButtonThemeData(style: _base());

/// Secondary buttons: outlined with a control-contrast border.
OutlinedButtonThemeData fbOutlinedButtonTheme(ColorScheme scheme) =>
    OutlinedButtonThemeData(
      style: _base().copyWith(
        side: WidgetStateProperty.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.disabled)
                ? scheme.outlineVariant
                : scheme.outline,
          ),
        ),
      ),
    );

/// Text buttons.
TextButtonThemeData fbTextButtonTheme(ColorScheme scheme) =>
    TextButtonThemeData(style: _base());

/// Cards are tonal and flat, with a hairline edge.
CardThemeData fbCardTheme(ColorScheme scheme) => CardThemeData(
  color: scheme.surfaceContainer,
  surfaceTintColor: _clear,
  elevation: FbElevation.flat,
  margin: EdgeInsets.zero,
  clipBehavior: Clip.antiAlias,
  shape: RoundedRectangleBorder(
    borderRadius: FbRadius.lgAll,
    side: BorderSide(color: scheme.outlineVariant),
  ),
);

/// Chips (assumption, answer, quick-add).
ChipThemeData fbChipTheme(ColorScheme scheme) => ChipThemeData(
  backgroundColor: scheme.surfaceContainer,
  selectedColor: scheme.primaryContainer,
  disabledColor: scheme.surfaceContainerHigh,
  labelStyle: FbType.label.copyWith(color: scheme.onSurface),
  secondaryLabelStyle: FbType.label.copyWith(color: scheme.onPrimaryContainer),
  side: BorderSide(color: scheme.outline),
  shape: const RoundedRectangleBorder(borderRadius: FbRadius.pillAll),
  padding: const EdgeInsetsDirectional.symmetric(horizontal: FbSpace.s2),
  surfaceTintColor: _clear,
  elevation: FbElevation.flat,
  pressElevation: FbElevation.flat,
);

/// Snackbars: inverse colours, floating, flat-ish.
SnackBarThemeData fbSnackBarTheme(ColorScheme scheme) => SnackBarThemeData(
  backgroundColor: scheme.inverseSurface,
  contentTextStyle: FbType.bodySmall.copyWith(color: scheme.onInverseSurface),
  actionTextColor: scheme.inversePrimary,
  behavior: SnackBarBehavior.floating,
  elevation: FbElevation.overlay,
  shape: _mdShape,
);

/// Bottom sheets: rounded top corners (UX-011).
BottomSheetThemeData fbBottomSheetTheme(ColorScheme scheme) =>
    BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainer,
      surfaceTintColor: _clear,
      elevation: FbElevation.overlay,
      modalElevation: FbElevation.overlay,
      showDragHandle: false,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(borderRadius: FbRadius.sheetTop),
    );

/// The bottom navigation bar.
NavigationBarThemeData fbNavigationBarTheme(ColorScheme scheme) =>
    NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainer,
      surfaceTintColor: _clear,
      elevation: FbElevation.flat,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStatePropertyAll(
        FbType.caption.copyWith(color: scheme.onSurface),
      ),
    );

/// Text fields: filled, control-contrast outline, muted-brick errors.
InputDecorationThemeData fbInputDecorationTheme(ColorScheme scheme) {
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: FbRadius.mdAll,
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecorationThemeData(
    filled: true,
    fillColor: scheme.surfaceContainer,
    contentPadding: const EdgeInsetsDirectional.symmetric(
      horizontal: FbSpace.s4,
      vertical: FbSpace.s3,
    ),
    hintStyle: FbType.body.copyWith(color: scheme.onSurfaceVariant),
    border: border(scheme.outline),
    enabledBorder: border(scheme.outline),
    focusedBorder: border(scheme.primary, 2),
    errorBorder: border(scheme.error),
    focusedErrorBorder: border(scheme.error, 2),
    disabledBorder: border(scheme.outlineVariant),
  );
}

/// List rows.
ListTileThemeData fbListTileTheme(ColorScheme scheme) => ListTileThemeData(
  tileColor: _clear,
  iconColor: scheme.onSurfaceVariant,
  textColor: scheme.onSurface,
  titleTextStyle: FbType.body.copyWith(color: scheme.onSurface),
  subtitleTextStyle: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
  contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: FbSpace.s4),
  minVerticalPadding: FbSpace.s2,
  shape: _mdShape,
);

/// The date picker dialog: tonal, rounded, no surface tint.
DatePickerThemeData fbDatePickerTheme(ColorScheme scheme) =>
    DatePickerThemeData(
      backgroundColor: scheme.surfaceContainer,
      surfaceTintColor: _clear,
      headerBackgroundColor: scheme.surfaceContainer,
      headerForegroundColor: scheme.onSurface,
      elevation: FbElevation.overlay,
      shape: const RoundedRectangleBorder(borderRadius: FbRadius.lgAll),
    );
