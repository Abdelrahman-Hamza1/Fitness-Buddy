import 'package:fb_design_system/src/components/chips.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:material_ui/material_ui.dart';

/// The quick-add row (DY-030, HM-008): [chips] side by side, then a trailing
/// "+" chip that opens the full search. It scrolls sideways when the chips
/// don't fit, starts and ends with the screen padding, and mirrors in
/// right-to-left layouts (the first chip is at the start edge, the "+" at the
/// end).
class FbQuickAddRow extends StatelessWidget {
  /// Creates the row. [addLabel] is the "+" chip's text and [onAdd] its tap;
  /// [semanticLabel] names the whole row for a screen reader.
  const new({
    required this.chips,
    required this.addLabel,
    required this.onAdd,
    this.addSemanticLabel,
    this.semanticLabel,
    super.key,
  });

  /// The suggestions, best first.
  final List<FbQuickAddChip> chips;

  /// The text of the "+" chip.
  final String addLabel;

  /// Called when the "+" chip is tapped.
  final VoidCallback onAdd;

  /// What a screen reader says for the "+" chip; its label when null.
  final String? addSemanticLabel;

  /// What a screen reader says for the row.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: semanticLabel,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: FbSpace.s4,
        vertical: FbSpace.s1,
      ),
      child: Row(
        spacing: FbSpace.s2,
        children: [
          ...chips,
          FbQuickAddChip.add(
            label: addLabel,
            onTap: onAdd,
            semanticLabel: addSemanticLabel,
          ),
        ],
      ),
    ),
  );
}
