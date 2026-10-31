import 'package:fb_design_system/src/tokens/motion.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

/// One answer of a single-choice question (A51 first run): an optional icon
/// tile, a [title], an optional [subtitle] and, when [selected], the brand
/// tint with a 2 dp brand border, so the choice never relies on colour
/// alone (UX-071). Steady: its size never depends on [selected] (A45 D1).
///
/// At least 64 dp tall; wraps at large text sizes; start/end only. For a
/// screen reader it is one button in a group that reads title, subtitle and
/// the selected state. A null [onTap] disables it.
class FbChoiceCard extends StatelessWidget {
  /// Creates a card.
  const new({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.selected = false,
    super.key,
  });

  /// The answer, already translated.
  final String title;

  /// A plain line under it.
  final String? subtitle;

  /// A decorative leading icon (from `FbIcons`).
  final IconData? icon;

  /// Whether this answer is chosen.
  final bool selected;

  /// Called on tap; null disables the card.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = selected
        ? scheme.primaryContainer
        : scheme.surfaceContainerLowest;
    final side = selected
        ? BorderSide(color: scheme.primary, width: 2)
        : BorderSide(color: scheme.outlineVariant);
    final onColor = selected ? scheme.onPrimaryContainer : scheme.onSurface;
    final muted = selected
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      enabled: onTap != null,
      child: AnimatedContainer(
        duration: FbMotion.of(context, FbMotion.fast),
        curve: FbMotion.curve,
        decoration: ShapeDecoration(
          color: background,
          shape: RoundedRectangleBorder(
            borderRadius: FbRadius.lgAll,
            side: side,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          shape: const RoundedRectangleBorder(borderRadius: FbRadius.lgAll),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: FbSpace.s4,
                  vertical: FbSpace.s3,
                ),
                child: Row(
                  spacing: FbSpace.s3,
                  children: [
                    if (icon != null)
                      ExcludeSemantics(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: selected
                                ? scheme.surfaceContainerLowest
                                : scheme.surfaceContainer,
                            borderRadius: FbRadius.mdAll,
                          ),
                          child: SizedBox.square(
                            dimension: 40,
                            child: Icon(icon, color: onColor),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 2,
                        children: [
                          Text(
                            title,
                            style: FbType.body.copyWith(
                              color: onColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              style: FbType.bodySmall.copyWith(color: muted),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
