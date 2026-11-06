import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

/// A small static label on a card ("3 days a week", "Beginner"; A65 N5):
/// not tappable. [selected] tints it with the card's selected state.
class FbTag extends StatelessWidget {
  /// Creates a tag.
  const new({required this.label, this.selected = false, super.key});

  /// The (already translated) text.
  final String label;

  /// The card it sits on is selected.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest,
        borderRadius: FbRadius.mdAll,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: FbSpace.s2,
          vertical: FbSpace.s1,
        ),
        child: Text(
          label,
          style: FbType.caption.copyWith(
            color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}
