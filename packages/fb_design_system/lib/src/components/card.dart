import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:material_ui/material_ui.dart';

/// A tonal, flat card (UX-041). Tappable when [onTap] is set.
class FbCard extends StatelessWidget {
  /// Creates a card.
  const new({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsetsDirectional.all(FbSpace.s4),
    super.key,
  });

  /// The content.
  final Widget child;

  /// Makes the whole card tappable.
  final VoidCallback? onTap;

  /// Inner padding, directional.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return Card(
      child: onTap == null
          ? SizedBox(width: double.infinity, child: content)
          : InkWell(
              onTap: onTap,
              child: SizedBox(width: double.infinity, child: content),
            ),
    );
  }
}
