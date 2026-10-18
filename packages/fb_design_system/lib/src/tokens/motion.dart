import 'package:material_ui/material_ui.dart';

/// Motion durations and curve (A02 D4). Animations honour the system
/// "remove animations" setting through [of].
abstract final class FbMotion {
  /// 120 ms: taps, highlights.
  static const Duration fast = Duration(milliseconds: 120);

  /// 200 ms: most transitions.
  static const Duration normal = Duration(milliseconds: 200);

  /// 300 ms: sheets, larger moves.
  static const Duration slow = Duration(milliseconds: 300);

  /// How long an undo stays offered (UX-030).
  static const Duration undoWindow = Duration(seconds: 5);

  /// The one curve used everywhere.
  static const Curve curve = Curves.easeOutCubic;

  /// [duration], or [Duration.zero] when the system asks for no animations
  /// (`MediaQuery.disableAnimations`).
  static Duration of(BuildContext context, [Duration duration = normal]) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}
