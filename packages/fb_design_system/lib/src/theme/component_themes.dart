import 'package:fb_design_system/src/tokens/density.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

const double _minTouch = 48;

const Color _clear = Color(0x00000000);

const RoundedRectangleBorder _mdShape = RoundedRectangleBorder(
  borderRadius: FbRadius.mdAll,
);

// Pill buttons, 48 tall (Embrace recipes). A radius of half the height
// rather than a StadiumBorder: identical at 48 dp, but a label that wraps at
// large text sizes keeps normal corners instead of huge round ends.
const RoundedRectangleBorder _pillShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(_minTouch / 2)),
);

ButtonStyle _base() => const ButtonStyle(
  minimumSize: WidgetStatePropertyAll(Size(_minTouch, _minTouch)),
  shape: WidgetStatePropertyAll(_pillShape),
  textStyle: WidgetStatePropertyAll(FbType.button),
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

/// Cards are tonal and flat (no shadow, no gradient): a hairline
/// outlineVariant edge in light, none in dark.
CardThemeData fbCardTheme(ColorScheme scheme) => CardThemeData(
  color: scheme.surfaceContainer,
  surfaceTintColor: _clear,
  elevation: FbElevation.flat,
  margin: EdgeInsets.zero,
  clipBehavior: Clip.antiAlias,
  shape: RoundedRectangleBorder(
    borderRadius: FbRadius.lgAll,
    side: scheme.brightness == Brightness.light
        ? BorderSide(color: scheme.outlineVariant)
        : BorderSide.none,
  ),
);

/// Chips (assumption, answer, quick-add): radius 12 on the raised tonal
/// fill. Selected = the brand tint plus a 2 dp brand border, so colour is
/// never the only cue (UX-071). There is no check mark and the border is
/// always 2 dp (transparent when not selected), so selecting a chip never
/// changes its size (A45 D2).
ChipThemeData fbChipTheme(ColorScheme scheme) => ChipThemeData(
  backgroundColor: scheme.surfaceContainerHigh,
  selectedColor: scheme.primaryContainer,
  disabledColor: scheme.surfaceContainerHigh,
  labelStyle: FbType.chip.copyWith(color: scheme.onSurface),
  secondaryLabelStyle: FbType.chip.copyWith(color: scheme.onPrimaryContainer),
  checkmarkColor: scheme.onPrimaryContainer,
  showCheckmark: false,
  side: WidgetStateBorderSide.resolveWith(
    (states) => states.contains(WidgetState.selected)
        ? BorderSide(color: scheme.primary, width: 2)
        : const BorderSide(color: _clear, width: 2),
  ),
  shape: const RoundedRectangleBorder(borderRadius: FbRadius.mdAll),
  padding: const EdgeInsetsDirectional.symmetric(horizontal: FbSpace.s2),
  // A little air above and below a label that wraps at large text.
  labelPadding: const EdgeInsetsDirectional.symmetric(
    horizontal: FbSpace.s2,
    vertical: 2,
  ),
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

/// The bottom navigation bar: 72 tall, a brand-tint pill behind the selected
/// icon, labels 12/600 (selected onSurface, others onSurfaceVariant).
NavigationBarThemeData fbNavigationBarTheme(ColorScheme scheme) =>
    NavigationBarThemeData(
      height: 72,
      backgroundColor: scheme.surfaceContainer,
      surfaceTintColor: _clear,
      elevation: FbElevation.flat,
      indicatorColor: scheme.primaryContainer,
      indicatorShape: const StadiumBorder(),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => FbType.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? scheme.onSurface
              : scheme.onSurfaceVariant,
        ),
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
    fillColor: scheme.surfaceContainerHigh,
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
  minTileHeight: FbDensity.rowMinHeight,
  shape: _mdShape,
);

/// Dialogs: tonal, radius 20, no surface tint.
DialogThemeData fbDialogTheme(ColorScheme scheme) => DialogThemeData(
  backgroundColor: scheme.surfaceContainer,
  surfaceTintColor: _clear,
  elevation: FbElevation.overlay,
  shape: const RoundedRectangleBorder(borderRadius: FbRadius.lgAll),
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

/// The time picker dialog: tonal like the date picker, with the dial and the
/// hour and minute boxes on quieter tonal fills and the brand tint selected.
TimePickerThemeData fbTimePickerTheme(ColorScheme scheme) =>
    TimePickerThemeData(
      backgroundColor: scheme.surfaceContainer,
      elevation: FbElevation.overlay,
      shape: const RoundedRectangleBorder(borderRadius: FbRadius.lgAll),
      dialBackgroundColor: scheme.surfaceContainerHigh,
      hourMinuteColor: scheme.surfaceContainerHigh,
      hourMinuteTextColor: scheme.onSurface,
      dayPeriodColor: scheme.surfaceContainerHigh,
      dayPeriodTextColor: scheme.onSurface,
      dayPeriodBorderSide: BorderSide(color: scheme.outline),
      dialTextColor: scheme.onSurface,
      entryModeIconColor: scheme.onSurfaceVariant,
      helpTextStyle: FbType.label.copyWith(color: scheme.onSurfaceVariant),
    );
