import 'package:fb_design_system/src/components/button.dart';
import 'package:fb_design_system/src/tokens/density.dart';
import 'package:fb_design_system/src/tokens/icons.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

/// A notice as one row (UX-047, A63 D5): an [icon], one line of [text], one
/// action button and, optionally, a dismiss `×`. The longer explanation, if
/// any, opens from the action; a tap anywhere else on the row runs [onTap]
/// (or [onAction] when there is none).
///
/// At large text the text may wrap to a second line instead of losing its
/// end. A screen reader reads the row as one item (the text) with the
/// button and `×` as their own actions. Layout is start/end only.
class FbNoticeRow extends StatelessWidget {
  /// Creates a notice row.
  const new({
    required this.icon,
    required this.text,
    required this.actionLabel,
    required this.onAction,
    this.onTap,
    this.dismissTooltip,
    this.onDismiss,
    this.actionKey,
    super.key,
  }) : assert(
         (dismissTooltip == null) == (onDismiss == null),
         'dismissTooltip and onDismiss go together',
       );

  /// The leading icon (from `FbIcons`).
  final IconData icon;

  /// The (already translated) one-line notice.
  final String text;

  /// The (already translated) action's label.
  final String actionLabel;

  /// Called when the action is tapped.
  final VoidCallback onAction;

  /// Called when the row (not its buttons) is tapped; null runs [onAction].
  final VoidCallback? onTap;

  /// The (already translated) tooltip and label of the dismiss `×`.
  final String? dismissTooltip;

  /// Called when `×` is tapped; null shows no `×`.
  final VoidCallback? onDismiss;

  /// The action button's key (tests and device journeys find it).
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final large = MediaQuery.textScalerOf(context).scale(1) >= 1.3;
    return Semantics(
      container: true,
      child: Material(
        color: scheme.surfaceContainer,
        borderRadius: FbRadius.mdAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap ?? onAction,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: FbDensity.rowMinHeight,
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: FbSpace.s4,
                end: FbSpace.s1,
              ),
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: Icon(icon, size: 20, color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: FbSpace.s3),
                  Expanded(
                    child: Text(
                      text,
                      maxLines: large ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: FbType.bodySmall.copyWith(color: scheme.onSurface),
                    ),
                  ),
                  const SizedBox(width: FbSpace.s1),
                  FbButton.text(
                    key: actionKey,
                    label: actionLabel,
                    onPressed: onAction,
                  ),
                  if (onDismiss != null)
                    IconButton(
                      tooltip: dismissTooltip,
                      icon: const Icon(FbIcons.close),
                      onPressed: onDismiss,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
