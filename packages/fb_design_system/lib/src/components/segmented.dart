import 'package:fb_design_system/src/components/option_sheet.dart';
import 'package:fb_design_system/src/tokens/motion.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

/// A small inline switch between a few short options (A51: Male / Female):
/// a tonal track with one raised segment per option. The chosen segment is
/// raised, bold and outlined, so the choice never relies on colour alone
/// (UX-071). Each segment is at least 48 dp tall and is announced as a
/// button in a group with its selected state. Nothing is chosen while
/// [selected] is null.
class FbSegmented<T> extends StatelessWidget {
  /// Creates the switch.
  const new({
    required this.options,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  /// The options, in order (their subtitles are not shown).
  final List<FbOption<T>> options;

  /// The chosen value, or null.
  final T? selected;

  /// Called with the tapped option's value.
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: FbRadius.mdAll,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(FbSpace.s1),
        child: Row(
          spacing: FbSpace.s1,
          children: [
            for (final option in options)
              Expanded(
                child: _Segment(
                  label: option.label,
                  selected: option.value == selected,
                  onTap: () => onSelected(option.value),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const new({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: AnimatedContainer(
        duration: FbMotion.of(context, FbMotion.fast),
        curve: FbMotion.curve,
        decoration: ShapeDecoration(
          color: selected ? scheme.surfaceContainerLowest : null,
          shape: RoundedRectangleBorder(
            borderRadius: FbRadius.smAll,
            side: selected
                ? BorderSide(color: scheme.primary, width: 1.5)
                : BorderSide.none,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          shape: const RoundedRectangleBorder(borderRadius: FbRadius.smAll),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: FbSpace.s7),
              child: Center(
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: FbSpace.s2,
                    vertical: FbSpace.s1,
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: FbType.body.copyWith(
                      color: scheme.onSurface,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
