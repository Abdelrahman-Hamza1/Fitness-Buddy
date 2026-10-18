import 'package:fb_design_system/src/tokens/colors.dart';
import 'package:fb_design_system/src/tokens/icons.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

/// What an inline banner says (UX-052, UX-053).
enum FbInlineBannerKind {
  /// Neutral information.
  info,

  /// No connection: AI features are unavailable, everything else works.
  offline,

  /// Changes are waiting to sync.
  pending,

  /// Something the user can fix. A muted brick, never alarm red.
  error,
}

/// A calm banner inside the content (UX-052, UX-053). [actionLabel] and
/// [onAction] add one text action, e.g. "Retry".
class FbInlineBanner extends StatelessWidget {
  /// Creates a banner.
  const new({
    required this.kind,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'actionLabel and onAction go together',
       );

  /// The tone.
  final FbInlineBannerKind kind;

  /// The (already translated) message.
  final String message;

  /// The action's label.
  final String? actionLabel;

  /// Called when the action is tapped.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isError = kind == FbInlineBannerKind.error;
    final background = isError
        ? scheme.errorContainer
        : scheme.surfaceContainerHigh;
    final iconColor = switch (kind) {
      FbInlineBannerKind.error => scheme.onErrorContainer,
      FbInlineBannerKind.info => context.fbColors.info,
      FbInlineBannerKind.offline ||
      FbInlineBannerKind.pending => scheme.onSurfaceVariant,
    };
    final icon = switch (kind) {
      FbInlineBannerKind.info => FbIcons.info,
      FbInlineBannerKind.offline => FbIcons.offline,
      FbInlineBannerKind.pending => FbIcons.pending,
      FbInlineBannerKind.error => FbIcons.error,
    };
    return Semantics(
      container: true,
      liveRegion: isError,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: FbRadius.mdAll,
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: FbSpace.s4,
            vertical: FbSpace.s3,
          ),
          child: Row(
            children: [
              ExcludeSemantics(child: Icon(icon, size: 20, color: iconColor)),
              const SizedBox(width: FbSpace.s3),
              Expanded(
                child: Text(
                  message,
                  style: FbType.bodySmall.copyWith(color: scheme.onSurface),
                ),
              ),
              if (actionLabel != null) ...[
                const SizedBox(width: FbSpace.s2),
                TextButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
