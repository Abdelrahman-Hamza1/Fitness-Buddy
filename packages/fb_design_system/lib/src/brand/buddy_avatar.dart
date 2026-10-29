import 'package:fb_design_system/src/brand/brand_geometry.dart';
import 'package:fb_design_system/src/brand/brand_mark.dart';
import 'package:fb_design_system/src/tokens/colors.dart';
import 'package:material_ui/material_ui.dart';

/// Buddy's avatar (A44 D13): a disc with the mini Embrace mark, two heads
/// above two overlapping arcs. Decorative, so excluded from semantics: the
/// text next to it says who is talking.
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
            color: colors.avatarBackground,
            shape: BoxShape.circle,
          ),
          child: CustomPaint(
            painter: FbMarkPainter(
              shapes: fbEmbraceMini,
              viewBox: const Rect.fromLTWH(
                0,
                0,
                fbEmbraceMiniCanvas,
                fbEmbraceMiniCanvas,
              ),
              a: colors.avatarForeground,
              b: colors.mint,
            ),
          ),
        ),
      ),
    );
  }
}
