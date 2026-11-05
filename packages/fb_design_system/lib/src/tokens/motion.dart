import 'package:material_ui/material_ui.dart';

/// The motion vocabulary (UX-046, TD-113, A57 D16). Every animation reads
/// its duration and easing from here, and through [localOf] /
/// [structuralOf] it is zero when the system asks for no animations.
///
/// - [local] (200 ms): a control's own state, a reveal inside a region,
///   a fade, a tab's content.
/// - [structural] (300 ms): sheets, regions that change shape, step
///   changes, number tweens.
/// - [fast] (120 ms): tap highlights only.
///
/// No motion, ever, on: keystrokes, validation messages, search result
/// reorders and the initial drawing of a chart.
abstract final class FbMotion {
  /// 120 ms: taps, highlights.
  static const Duration fast = Duration(milliseconds: 120);

  /// 200 ms: local changes.
  static const Duration local = Duration(milliseconds: 200);

  /// 300 ms: structural changes.
  static const Duration structural = Duration(milliseconds: 300);

  /// How long an undo stays offered (UX-030).
  static const Duration undoWindow = Duration(seconds: 5);

  /// The standard easing (Material 3 "standard").
  static const Curve standard = Cubic(0.2, 0, 0, 1);

  /// For things entering the screen (Material 3 "emphasized decelerate").
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1);

  /// The default easing: [standard].
  static const Curve curve = standard;

  /// [duration], or [Duration.zero] when the system asks for no animations
  /// (`MediaQuery.disableAnimations`).
  static Duration of(BuildContext context, [Duration duration = local]) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;

  /// [local], or zero under reduced motion.
  static Duration localOf(BuildContext context) => of(context);

  /// [structural], or zero under reduced motion.
  static Duration structuralOf(BuildContext context) => of(context, structural);
}
