import 'package:fb_design_system/src/brand/brand_geometry.dart';
import 'package:fb_design_system/src/brand/brand_mark.dart';
import 'package:fb_design_system/src/tokens/colors.dart';
import 'package:material_ui/material_ui.dart';

/// Buddy's avatar (A44 D13, Momentum TD-116): the mini Momentum mark (soft,
/// mid and the sky spark) on a plate disc, the ink on light and the dark
/// surface on dark. Decorative, so excluded from semantics: the text next to it
/// says who is talking.
class FbBuddyAvatar extends StatelessWidget {
  /// Creates the avatar, [size] dp across.
  const new({this.size = 28, super.key});

  /// The diameter in dp.
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.fbColors;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.markPlate,
            shape: BoxShape.circle,
          ),
          child: CustomPaint(
            painter: FbMarkPainter(
              shapes: fbMomentumMini,
              viewBox: const Rect.fromLTWH(
                0,
                0,
                fbMomentumMiniCanvas,
                fbMomentumMiniCanvas,
              ),
              soft: colors.markSoft,
              mid: colors.markMid,
              strong: colors.spark,
            ),
          ),
        ),
      ),
    );
  }
}
