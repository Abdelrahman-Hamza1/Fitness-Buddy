import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

/// A section title with an optional trailing widget (usually a text button).
class FbSectionHeader extends StatelessWidget {
  /// Creates a header.
  const new({required this.title, this.trailing, super.key});

  /// The section title.
  final String title;

  /// At the end of the row.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(
      start: FbSpace.s4,
      end: FbSpace.s4,
      top: FbSpace.s4,
      bottom: FbSpace.s2,
    ),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: FbType.title.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}
