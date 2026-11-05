import 'dart:math' as math;

import 'package:fb_design_system/src/tokens/colors.dart';
import 'package:fb_design_system/src/tokens/motion.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

/// The hero number of a screen with a caption under it (HM-001), e.g. the
/// calories left today.
///
/// [value] arrives formatted. Its text scale is clamped to 1.5 and it scales
/// down to fit, so it never overflows (UX-070, A02 D10). The caption scales
/// normally. When [over] is true the number takes the neutral over-target
/// tone: never an error colour, never a warning icon (SF-021).
///
/// [FbBigNumber.counting] counts from the previous [count] to the new one
/// when it changes (UX-025); instantly when animations are off. The first
/// value shows as is.
class FbBigNumber extends StatelessWidget {
  /// Creates a big number.
  const new({
    required String this._value,
    required this.caption,
    this.over = false,
    super.key,
  }) : count = null,
       format = null;

  /// A big number that counts to [count], shown through [format].
  const new counting({
    required double this.count,
    required String Function(double) this.format,
    required this.caption,
    this.over = false,
    super.key,
  }) : _value = null;

  final String? _value;

  /// The formatted number (for a counting one, the number it counts to).
  String get value => _value ?? format!(count!);

  /// The number to count to.
  final double? count;

  /// Formats a [count] value.
  final String Function(double)? format;

  /// The line under it.
  final String caption;

  /// Over the target: neutral tone.
  final bool over;

  /// The largest text scale the number itself follows (A57 A55: up to the
  /// largest system size).
  static const double maxTextScale = 2;

  @override
  Widget build(BuildContext context) {
    final count = this.count;
    final format = this.format;
    if (count == null || format == null) return _build(context, value);
    return Semantics(
      container: true,
      label: '${format(count)}, $caption',
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: count),
        duration: FbMotion.of(context, FbMotion.structural),
        curve: FbMotion.curve,
        builder: (context, shown, _) => _build(context, format(shown)),
      ),
    );
  }

  Widget _build(BuildContext context, String value) {
    final scheme = Theme.of(context).colorScheme;
    final color = over ? context.fbColors.overTarget : scheme.onSurface;
    return Semantics(
      container: true,
      label: '$value, $caption',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Follows the text size up to [maxTextScale]; a number too wide
          // for the space shrinks, but never below the 1.0-scale headline
          // size, and wraps rather than going smaller (A57 A55).
          LayoutBuilder(
            builder: (context, constraints) {
              final scale = MediaQuery.textScalerOf(context)
                  .clamp(maxScaleFactor: maxTextScale)
                  .scale(1);
              final style = FbType.numeric(FbType.display).copyWith(
                color: color,
                fontSize: FbType.display.fontSize! * scale,
              );
              final painter = TextPainter(
                text: TextSpan(text: value, style: style),
                textDirection: Directionality.of(context),
                maxLines: 1,
              )..layout();
              final width = painter.width;
              painter.dispose();
              final fits = width <= constraints.maxWidth;
              final size = fits
                  ? style.fontSize!
                  : math.max(
                      style.fontSize! * constraints.maxWidth / width,
                      FbType.headline.fontSize!,
                    );
              return Text(
                value,
                textScaler: TextScaler.noScaling,
                style: style.copyWith(fontSize: size),
              );
            },
          ),
          const SizedBox(height: FbSpace.s1),
          Text(
            caption,
            style: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
