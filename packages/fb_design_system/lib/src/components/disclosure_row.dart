import 'package:fb_design_system/src/tokens/icons.dart';
import 'package:fb_design_system/src/tokens/motion.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

/// A row that opens and closes the rows below it (HM-007): [title], an
/// optional [subtitle], [leading] and [trailing] widgets and a chevron that
/// turns over when [expanded].
///
/// It is a row, not a container: the caller puts what it reveals in the next
/// rows of its list, so long lists stay flat slivers. The whole row is one
/// button for a screen reader, which hears the open or closed state.
class FbDisclosureRow extends StatelessWidget {
  /// Creates a row.
  const new({
    required this.title,
    required this.expanded,
    required this.onToggle,
    this.subtitle,
    this.leading,
    this.trailing,
    super.key,
  });

  /// The main text.
  final String title;

  /// A second, muted line.
  final String? subtitle;

  /// At the start of the row.
  final Widget? leading;

  /// Before the chevron, at the end of the row (an amount, a total).
  final Widget? trailing;

  /// Whether what the row controls is shown.
  final bool expanded;

  /// Called on a tap, to flip [expanded].
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      expanded: expanded,
      child: ListTile(
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        leading: leading,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null)
              DefaultTextStyle.merge(
                style: FbType.numeric(FbType.label)
                    .copyWith(color: scheme.onSurface),
                child: trailing!,
              ),
            const SizedBox(width: FbSpace.s2),
            ExcludeSemantics(
              child: AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: FbMotion.of(context),
                curve: FbMotion.curve,
                child: Icon(FbIcons.expand, color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
        onTap: onToggle,
      ),
    );
  }
}
