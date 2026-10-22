import 'package:fb_design_system/src/tokens/icons.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

/// The amount being entered next to a number pad (FD-022, AI-040): the
/// number large and the unit beside it, in a box that shows when the pad is
/// editing it.
///
/// [amount] and [unit] arrive formatted for the locale. The box is a button
/// when [onTap] is set (tap to bring the pad back). The state is also in the
/// semantics ([semanticLabel], selected), not only in the border colour.
class FbAmountDisplay extends StatelessWidget {
  /// Creates the display. [semanticLabel] is the already translated
  /// description a screen reader reads, e.g. "Amount, 100 g".
  const new({
    required this.amount,
    required this.unit,
    required this.semanticLabel,
    this.active = false,
    this.onTap,
    super.key,
  });

  /// The formatted number, as typed so far.
  final String amount;

  /// The formatted unit, e.g. "g" or "loaves".
  final String unit;

  /// What a screen reader says.
  final String semanticLabel;

  /// The pad is editing this amount: a stronger border.
  final bool active;

  /// Makes the display tappable.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      button: onTap != null,
      selected: active,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: FbRadius.mdAll,
          side: BorderSide(
            color: active ? scheme.primary : scheme.outlineVariant,
            width: active ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: FbRadius.mdAll,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: FbSpace.s4,
                vertical: FbSpace.s2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: amount,
                            style: FbType.numeric(FbType.headline)
                                .copyWith(color: scheme.onSurface),
                          ),
                          const TextSpan(text: ' '),
                          TextSpan(
                            text: unit,
                            style: FbType.body.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: FbSpace.s2),
                    Icon(
                      FbIcons.edit,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
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
