import 'package:fb_design_system/src/tokens/icons.dart';
import 'package:fb_design_system/src/tokens/motion.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

/// A chip that shows one setting and opens a choice for it on tap: a [label]
/// ("Meal"), the current [value] ("Lunch") and, by default, a dropdown arrow
/// that says "this opens a choice" (D18; the details' Amount, Slot and Time).
///
/// Without a [value] it is a plain labelled chip (e.g. "Log as Rice, raw"),
/// and [dropdown] can be turned off when the tap does not open a list.
///
/// The chip is at least 48 × 48 dp, wraps its text at large text sizes and
/// uses start/end only. For a screen reader it is one button that reads the
/// label, then the value. A null [onTap] disables it.
///
/// **Steady:** its size never depends on [selected] (A45 D1). A selected chip
/// gets the brand tint and a 2 dp brand border, which the shape paints
/// without taking layout room; the border weight keeps the choice from
/// relying on colour alone (UX-071). The fill and border ease over
/// [FbMotion.fast] (none with reduced motion).
class FbChoiceChip extends StatelessWidget {
  /// Creates a chip.
  const new({
    required this.label,
    required this.onTap,
    this.value,
    this.selected = false,
    this.dropdown = true,
    this.icon,
    this.semanticLabel,
    super.key,
  });

  /// The (already translated) name of the setting, or the whole text of a
  /// chip with no [value].
  final String label;

  /// The current choice, in the setting's own words.
  final String? value;

  /// Called on tap. Null disables the chip.
  final VoidCallback? onTap;

  /// This chip's choice is the active one.
  final bool selected;

  /// Whether the dropdown arrow is shown.
  final bool dropdown;

  /// An optional leading icon (from `FbIcons`) that says what the tap does,
  /// for a chip that opens a screen rather than a list. Decorative: the
  /// label is what a screen reader reads.
  final IconData? icon;

  /// What a screen reader reads instead of [label], for a chip whose text
  /// needs its context to make sense on its own (a bare "g" next to a
  /// field reads "Serving size in grams"). The value is still read after.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    final hasValue = value != null && value!.isNotEmpty;
    final background = !enabled
        ? scheme.surfaceContainerHigh
        : selected
        ? scheme.primaryContainer
        : scheme.surfaceContainer;
    final primary = selected ? scheme.onPrimaryContainer : scheme.onSurface;
    final muted = selected
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;
    final side = !enabled
        ? BorderSide(color: scheme.outlineVariant)
        : selected
        ? BorderSide(color: scheme.primary, width: 2)
        : BorderSide(color: scheme.outline);
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: semanticLabel ?? label,
      value: hasValue ? value : null,
      onTap: onTap,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: FbSpace.s7,
          minHeight: FbSpace.s7,
        ),
        child: TweenAnimationBuilder<_ChipLook>(
          tween: _ChipLookTween(end: _ChipLook(background, side)),
          duration: FbMotion.of(context, FbMotion.fast),
          curve: FbMotion.curve,
          builder: (context, look, child) => Material(
            color: look.background,
            shape: RoundedRectangleBorder(
              borderRadius: FbRadius.mdAll,
              side: look.side,
            ),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: FbSpace.s3,
                vertical: FbSpace.s2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: enabled ? primary : muted),
                    const SizedBox(width: FbSpace.s2),
                  ],
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: hasValue
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: hasValue
                              ? FbType.caption.copyWith(color: muted)
                              : FbType.label.copyWith(
                                  color: enabled ? primary : muted,
                                ),
                        ),
                        if (hasValue)
                          Text(
                            value!,
                            style: FbType.label.copyWith(
                              color: enabled ? primary : muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (dropdown) ...[
                    const SizedBox(width: FbSpace.s1),
                    Icon(FbIcons.expand, size: 20, color: muted),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The animated part of a chip: its fill and its border.
@immutable
class _ChipLook {
  const new(this.background, this.side);

  final Color background;
  final BorderSide side;
}

class _ChipLookTween extends Tween<_ChipLook> {
  new({super.end});

  @override
  _ChipLook lerp(double t) {
    final a = begin ?? end!;
    final b = end!;
    return _ChipLook(
      Color.lerp(a.background, b.background, t)!,
      BorderSide.lerp(a.side, b.side, t),
    );
  }
}
