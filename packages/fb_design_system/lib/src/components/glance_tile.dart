import 'dart:math' as math;

import 'package:fb_design_system/src/components/skeleton.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

/// One half of a slim summary line (A57 D5, the Today weight · workout
/// line): an icon and one line of text, tappable. Every state (loading,
/// text, muted text) has exactly the same height, [heightOf], which
/// depends only on the text scale, so the line never moves when its data
/// arrives or changes (UX-045). At least 48 dp tall (UX-071).
class FbGlanceTile extends StatelessWidget {
  /// A tile showing [text] after [icon].
  const new({
    required IconData this.icon,
    required String this.text,
    this.onTap,
    this.semanticLabel,
    this.muted = false,
    super.key,
  });

  /// A placeholder of the same height while the data loads.
  const new loading({super.key})
    : icon = null,
      text = null,
      onTap = null,
      semanticLabel = null,
      muted = false;

  /// The leading icon.
  final IconData? icon;

  /// The one line of text (cut with an ellipsis).
  final String? text;

  /// Called on tap.
  final VoidCallback? onTap;

  /// What a screen reader reads (with the tap action), instead of [text].
  final String? semanticLabel;

  /// Whether the text is quiet (an unavailable state).
  final bool muted;

  /// The text style.
  static const TextStyle style = FbType.body;

  static const double _padding = FbSpace.s2;

  /// The tile's height at the current text scale.
  static double heightOf(BuildContext context) {
    final painter = TextPainter(
      text: const TextSpan(text: _probe, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final line = painter.height;
    painter.dispose();
    return math.max(48, line + 2 * _padding);
  }

  // Measures one line; never shown.
  static const String _probe = 'Ag';

  @override
  Widget build(BuildContext context) {
    final height = heightOf(context);
    final text = this.text;
    if (text == null) {
      return SizedBox(
        height: height,
        child: const Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: _padding),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FbSkeleton.line(width: 120),
          ),
        ),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    final color = muted ? scheme.onSurfaceVariant : scheme.onSurface;
    return Semantics(
      label: semanticLabel ?? text,
      button: onTap != null,
      onTap: onTap,
      excludeSemantics: true,
      child: SizedBox(
        height: height,
        child: InkWell(
          onTap: onTap,
          borderRadius: FbRadius.mdAll,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: _padding,
            ),
            child: Row(
              spacing: FbSpace.s2,
              children: [
                Icon(icon, size: 20, color: scheme.onSurfaceVariant),
                Expanded(
                  child: Text(
                    text,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: FbType.numeric(style).copyWith(color: color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
