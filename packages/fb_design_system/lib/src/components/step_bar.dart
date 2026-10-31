import 'package:fb_design_system/src/tokens/motion.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:material_ui/material_ui.dart';

/// A segmented progress bar for a short flow (A51): [count] equal segments,
/// the first [current] + 1 filled. Directional: it fills from the start edge.
/// For a screen reader it is one label ([semanticsLabel], e.g. "Step 2 of
/// 5"); the segments themselves are decorative.
class FbStepBar extends StatelessWidget {
  /// Creates the bar; [current] is the 0-based index of the step shown.
  const new({
    required this.count,
    required this.current,
    required this.semanticsLabel,
    super.key,
  }) : assert(count > 0, 'at least one step');

  /// The number of steps.
  final int count;

  /// The step shown, from 0; it and the steps before it are filled.
  final int current;

  /// What a screen reader reads ("Step 2 of 5").
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: semanticsLabel,
      excludeSemantics: true,
      child: Row(
        spacing: FbSpace.s1,
        children: [
          for (var i = 0; i < count; i++)
            Expanded(
              child: AnimatedContainer(
                duration: FbMotion.of(context),
                curve: FbMotion.curve,
                height: FbSpace.s1,
                decoration: BoxDecoration(
                  color: i <= current ? scheme.primary : scheme.outlineVariant,
                  borderRadius: FbRadius.pillAll,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
