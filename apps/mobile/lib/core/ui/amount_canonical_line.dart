import 'package:fb_design_system/fb_design_system.dart';
import 'package:material_ui/material_ui.dart';

/// The line under an amount editor's typed value that says what a portion
/// or kitchen measure comes to, "That's 120 g" (backlog #117), shared by
/// the food sheet and the entry amount sheet. The editor still shows and
/// saves the typed value as it is.
///
/// While [text] is null (the amount is incomplete, or the chosen unit is
/// already grams or millilitres) the line keeps its height, empty and
/// silent, so nothing below it moves (UX-045).
class AmountCanonicalLine extends StatelessWidget {
  /// Creates the line.
  const new({required this.text, super.key});

  /// The line, from `amountEditorCanonical`, or null for none.
  final String? text;

  @override
  Widget build(BuildContext context) {
    final line = text;
    return ExcludeSemantics(
      excluding: line == null,
      child: Text(
        // One space holds a line's height at any text scale.
        line ?? ' ',
        textAlign: TextAlign.center,
        maxLines: 2,
        style: FbType.bodySmall.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
