import 'package:fb_design_system/src/tokens/icons.dart';
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
/// The chip is at least 48 dp high, wraps its text at large text sizes and
/// uses start/end only. For a screen reader it is one button that reads the
/// label, then the value. A null [onTap] disables it. [selected] fills it
/// with the brand tint; the check mark keeps it from relying on colour alone.
class FbChoiceChip extends StatelessWidget {
  /// Creates a chip.
  const new({
    required this.label,
    required this.onTap,
    this.value,
    this.selected = false,
    this.dropdown = true,
    this.icon,
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
    final border = enabled ? scheme.outline : scheme.outlineVariant;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: label,
      value: hasValue ? value : null,
      onTap: onTap,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: FbSpace.s7),
        child: Material(
          color: background,
          shape: RoundedRectangleBorder(
            borderRadius: FbRadius.mdAll,
            side: BorderSide(color: border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: FbSpace.s3,
                vertical: FbSpace.s2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected) ...[
                    Icon(FbIcons.check, size: 18, color: primary),
                    const SizedBox(width: FbSpace.s2),
                  ] else if (icon != null) ...[
                    Icon(icon, size: 18, color: enabled ? primary : muted),
                    const SizedBox(width: FbSpace.s2),
                  ],
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
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
