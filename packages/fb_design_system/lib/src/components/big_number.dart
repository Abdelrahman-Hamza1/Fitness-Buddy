import 'package:fb_design_system/src/tokens/colors.dart';
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
class FbBigNumber extends StatelessWidget {
  /// Creates a big number.
  const new({
    required this.value,
    required this.caption,
    this.over = false,
    super.key,
  });

  /// The formatted number.
  final String value;

  /// The line under it.
  final String caption;

  /// Over the target: neutral tone.
  final bool over;

  /// The largest text scale the number itself follows.
  static const double maxTextScale = 1.5;

  @override
  Widget build(BuildContext context) {
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
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: maxTextScale,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  value,
                  maxLines: 1,
                  style: FbType.numeric(FbType.display).copyWith(color: color),
                ),
              ),
            ),
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
