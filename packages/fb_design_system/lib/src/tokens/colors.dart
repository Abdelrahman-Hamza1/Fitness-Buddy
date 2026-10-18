import 'package:fb_design_system/src/tokens/palette.dart';
import 'package:material_ui/material_ui.dart';

/// Product colour roles Material has no slot for (A02 D4). Read with
/// `context.fbColors`.
@immutable
final class FbColors extends ThemeExtension<FbColors> {
  /// Creates the extension.
  const new({
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.overTarget,
    required this.success,
    required this.info,
    required this.badge,
    required this.skeleton,
  });

  /// The roles of [palette].
  factory fromPalette(FbPalette palette) => FbColors(
    protein: palette.protein,
    carbs: palette.carbs,
    fat: palette.fat,
    fiber: palette.fiber,
    overTarget: palette.overTarget,
    success: palette.success,
    info: palette.info,
    badge: palette.onSurfaceVariant,
    skeleton: palette.surfaceContainerHigh,
  );

  /// Protein (UX-042).
  final Color protein;

  /// Carbs.
  final Color carbs;

  /// Fat.
  final Color fat;

  /// Fibre.
  final Color fiber;

  /// Over a target: neutral, never alarm red (SF-021).
  final Color overTarget;

  /// Success.
  final Color success;

  /// Information.
  final Color info;

  /// Source badges: monochrome so they stay small and consistent (UX-044).
  final Color badge;

  /// Skeleton placeholders (UX-051).
  final Color skeleton;

  @override
  FbColors copyWith({
    Color? protein,
    Color? carbs,
    Color? fat,
    Color? fiber,
    Color? overTarget,
    Color? success,
    Color? info,
    Color? badge,
    Color? skeleton,
  }) => FbColors(
    protein: protein ?? this.protein,
    carbs: carbs ?? this.carbs,
    fat: fat ?? this.fat,
    fiber: fiber ?? this.fiber,
    overTarget: overTarget ?? this.overTarget,
    success: success ?? this.success,
    info: info ?? this.info,
    badge: badge ?? this.badge,
    skeleton: skeleton ?? this.skeleton,
  );

  @override
  FbColors lerp(FbColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return FbColors(
      protein: mix(protein, other.protein),
      carbs: mix(carbs, other.carbs),
      fat: mix(fat, other.fat),
      fiber: mix(fiber, other.fiber),
      overTarget: mix(overTarget, other.overTarget),
      success: mix(success, other.success),
      info: mix(info, other.info),
      badge: mix(badge, other.badge),
      skeleton: mix(skeleton, other.skeleton),
    );
  }
}

/// `context.fbColors`.
extension FbColorsContext on BuildContext {
  /// The design system's product colours. Needs a theme built by FbTheme
  /// above (asserts otherwise).
  FbColors get fbColors {
    final colors = Theme.of(this).extension<FbColors>();
    assert(colors != null, 'No FbColors in the theme: use FbTheme.light/dark');
    return colors!;
  }
}
