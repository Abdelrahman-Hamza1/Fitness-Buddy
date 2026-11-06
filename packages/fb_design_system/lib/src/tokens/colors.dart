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
    required this.spark,
    required this.markSoft,
    required this.markMid,
    required this.markStrong,
    required this.markPlate,
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
    spark: palette.spark,
    markSoft: palette.markSoft,
    markMid: palette.markMid,
    markStrong: palette.markStrong,
    markPlate: palette.markPlate,
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

  /// The sky spark: the Momentum mark's strong shape on the plate and on
  /// dark, small highlights. Decoration only, never text.
  final Color spark;

  /// The Momentum mark's short (start) shape.
  final Color markSoft;

  /// The Momentum mark's middle shape.
  final Color markMid;

  /// The Momentum mark's tall (end) shape on the theme's surfaces.
  final Color markStrong;

  /// The Buddy avatar's plate (the mark on it is soft, mid and [spark]).
  final Color markPlate;

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
    Color? spark,
    Color? markSoft,
    Color? markMid,
    Color? markStrong,
    Color? markPlate,
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
    spark: spark ?? this.spark,
    markSoft: markSoft ?? this.markSoft,
    markMid: markMid ?? this.markMid,
    markStrong: markStrong ?? this.markStrong,
    markPlate: markPlate ?? this.markPlate,
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
      spark: mix(spark, other.spark),
      markSoft: mix(markSoft, other.markSoft),
      markMid: mix(markMid, other.markMid),
      markStrong: mix(markStrong, other.markStrong),
      markPlate: mix(markPlate, other.markPlate),
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
