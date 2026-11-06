import 'package:fb_design_system/src/brand/brand_mark.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

/// Sizes of [FbBrandLockup].
enum FbLockupSize {
  /// A 27 dp tall mark with a 16 sp wordmark.
  small(27, 16),

  /// A 37 dp tall mark with a 22 sp wordmark (About).
  medium(37, 22),

  /// A 44 dp tall mark with a 26 sp wordmark (the welcome page).
  large(44, 26);

  new(this.mark, this.wordmark);

  /// The mark's height in dp at text scale 1 (about 0.8 of the two-line
  /// wordmark's height).
  final double mark;

  /// The wordmark's font size in sp.
  final double wordmark;
}

/// The Momentum mark with the wordmark beside it, "Fitness / Buddy" on two
/// lines in Outfit extra-bold and the brand colour (A64, TD-116). The mark is
/// drawn cropped to its bounds, so its start edge lines up with the text
/// column; it grows with the text scale up to [maxMarkScale], so it never
/// looks tiny next to enlarged text. The app passes the [name] (the DS owns
/// no app strings): its first space becomes the line break, and screen
/// readers hear the name once, as its own header node. The wordmark wraps
/// further rather than overflowing at large text sizes.
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
          const SizedBox(width: FbSpace.s3),
          Flexible(
            child: Text(
              name.replaceFirst(' ', '\n'),
              style: FbType.wordmark(size.wordmark)
                  .copyWith(color: scheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}
