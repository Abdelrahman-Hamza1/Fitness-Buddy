import 'package:fb_design_system/l10n/gen/fb_localizations.dart';
import 'package:fb_design_system/src/tokens/icons.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

/// A chip that shows an assumption Buddy made ("Assuming 1 tbsp oil") and
/// opens it for editing on tap (AI-033).
class FbAssumptionChip extends StatelessWidget {
  /// Creates the chip.
  const new({required this.label, required this.onTap, super.key});

  /// The assumption text.
  final String label;

  /// Called on tap.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ActionChip(
    label: Text(label),
    onPressed: onTap,
    avatar: const Icon(FbIcons.info, size: 18),
  );
}

/// One answer to a clarifying question (AI-034). [selected] shows the chosen
/// one; [isDefault] marks the answer assumed if the user doesn't pick, with
/// a text label (not colour alone).
class FbAnswerChip extends StatelessWidget {
  /// Creates the chip.
  const new({
    required this.label,
    required this.onTap,
    this.selected = false,
    this.isDefault = false,
    super.key,
  });

  /// The answer text.
  final String label;

  /// Called on tap.
  final VoidCallback onTap;

  /// This answer is chosen.
  final bool selected;

  /// This answer is assumed when none is chosen.
  final bool isDefault;

  @override
  Widget build(BuildContext context) {
    final l10n = FbLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: isDefault ? '$label, ${l10n.fbAnswerDefault}' : label,
      selected: selected,
      button: true,
      excludeSemantics: true,
      onTap: onTap,
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: selected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(label)),
            if (isDefault) ...[
              const SizedBox(width: FbSpace.s2),
              Text(
                l10n.fbAnswerDefault,
                style: FbType.caption.copyWith(
                  color: selected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A shortcut that logs a recent or frequent item in one tap (DY-030).
class FbQuickAddChip extends StatelessWidget {
  /// A chip with only a label.
  const new({required this.label, required this.onTap, super.key})
    : _add = false;

  /// A chip with a leading plus: "add this".
  const new add({required this.label, required this.onTap, super.key})
    : _add = true;

  /// The item name.
  final String label;

  /// Called on tap.
  final VoidCallback onTap;

  final bool _add;

  @override
  Widget build(BuildContext context) => ActionChip(
    label: Text(label),
    onPressed: onTap,
    avatar: _add ? const Icon(FbIcons.add, size: 18) : null,
  );
}
