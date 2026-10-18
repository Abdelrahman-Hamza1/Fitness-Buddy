import 'dart:math' as math;

import 'package:fb_design_system/src/tokens/colors.dart';
import 'package:fb_design_system/src/tokens/motion.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:material_ui/material_ui.dart';

/// How full a bar is, and whether it is past its target.
///
/// A zero or negative [target] reads as empty. Past the target the bar is
/// full and over (D11).
({double fraction, bool over}) fbBarFill(double value, double target) {
  if (target <= 0) return (fraction: 0, over: false);
  return (
    fraction: math.min(1, math.max(0, value / target)),
    over: value > target,
  );
}

/// A bar track with a fill. Shared by [FbProgressBar] and the macro bars.
///
/// The fill is full and neutral past the target (SF-021), with no warning
/// icon: the caller's text says "X over".
class FbBarTrack extends StatelessWidget {
  /// Creates a track.
  const new({
    required this.value,
    required this.target,
    required this.color,
    this.height = 8,
    super.key,
  });

  /// The amount so far (geometry only).
  final double value;

  /// The target.
  final double target;

  /// The fill colour while at or under the target.
  final Color color;

  /// Bar thickness in dp.
  final double height;

  @override
  Widget build(BuildContext context) {
    final fill = fbBarFill(value, target);
    final track = Theme.of(context).colorScheme.surfaceContainerHigh;
    final fillColor = fill.over ? context.fbColors.overTarget : color;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: ColoredBox(
          color: track,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: AnimatedFractionallySizedBox(
              duration: FbMotion.of(context),
              curve: FbMotion.curve,
              widthFactor: fill.fraction,
              heightFactor: 1,
              alignment: AlignmentDirectional.centerStart,
              child: ColoredBox(color: fillColor),
            ),
          ),
        ),
      ),
    );
  }
}

/// A calm progress bar towards a [target] (HM-003). Past it the bar is full
/// in the neutral over-target tone (SF-021, D11).
class FbProgressBar extends StatelessWidget {
  /// Creates a progress bar.
  const new({
    required this.value,
    required this.target,
    this.semanticsLabel,
    super.key,
  });

  /// The amount so far (geometry only; the caller formats the numbers).
  final double value;

  /// The target.
  final double target;

  /// A spoken description such as "1,200 of 1,800 kcal".
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticsLabel,
    container: semanticsLabel != null,
    excludeSemantics: semanticsLabel != null,
    child: Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: FbSpace.s1),
      child: FbBarTrack(
        value: value,
        target: target,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}
