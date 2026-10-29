import 'package:fb_design_system/src/brand/brand_mark.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

/// Sizes of [FbBrandLockup].
enum FbLockupSize {
  /// A 26 dp figure with a 20 sp wordmark.
  small(26, 20),

  /// A 36 dp figure with a 28 sp wordmark (About).
  medium(36, 28),

  /// A 42 dp figure with a 32 sp wordmark (the first setup page).
  large(42, 32);

  new(this.mark, this.wordmark);

  /// The figure's size in dp at text scale 1 (about 1.3 × the wordmark).
  final double mark;

  /// The wordmark's font size in sp.
  final double wordmark;
}

/// The Embrace mark with the "Fitness Buddy" wordmark (Nunito 900) beside it
/// (A44 D13). The mark is drawn cropped to the figure, so its start edge
/// lines up with the text column, about 1.3 × the wordmark size; it grows
/// with the text scale up to [maxMarkScale], so it never looks tiny next to
/// enlarged text. The app passes the [name] (the DS owns no app strings);
/// screen readers hear it once, as its own header node. The wordmark wraps
/// rather than overflowing at large text sizes.
class FbBrandLockup extends StatelessWidget {
  /// Creates the lockup.
  const new({required this.name, this.size = FbLockupSize.medium, super.key});

  /// The app's name, already translated.
  final String name;

  /// How big.
  final FbLockupSize size;

  /// The largest text scale the mark follows.
  static const double maxMarkScale = 1.6;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mark = MediaQuery.textScalerOf(context)
        .clamp(minScaleFactor: 1, maxScaleFactor: maxMarkScale)
        .scale(size.mark);
    return Semantics(
      // Its own node: About puts more text right below it.
      container: true,
      header: true,
      label: name,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FbBrandMark(size: mark, cropped: true),
          const SizedBox(width: FbSpace.s2),
          Flexible(
            child: Text(
              name,
              style: FbType.wordmark(size.wordmark)
                  .copyWith(color: scheme.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
