import 'dart:math' as math;

import 'package:fb_design_system/l10n/gen/fb_localizations.dart';
import 'package:fb_design_system/src/tokens/icons.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

/// A chip that shows an assumption Buddy made ("Rice: cooked", "1 tsp of
/// oil") and opens it for editing on tap (AI-033). The pencil says it can be
/// changed. A null [onTap] disables it (the card is being logged).
///
/// [semanticLabel] is what a screen reader says instead of [label]
/// ("Assumption: Rice: cooked"); [tapHint] completes "Double tap to …"
/// ("change it").
class FbAssumptionChip extends StatelessWidget {
  /// Creates the chip.
  const new({
    required this.label,
    required this.onTap,
    this.semanticLabel,
    this.tapHint,
    super.key,
  });

  /// The assumption text.
  final String label;

  /// Called on tap; null disables the chip.
  final VoidCallback? onTap;

  /// What a screen reader says for the chip; [label] when null.
  final String? semanticLabel;

  /// The screen reader's tap hint ("change it").
  final String? tapHint;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    label: semanticLabel ?? label,
    onTap: onTap,
    onTapHint: tapHint,
    excludeSemantics: true,
    child: ActionChip(
      label: Text(label),
      onPressed: onTap,
      avatar: const Icon(FbIcons.edit, size: 18),
    ),
  );
}

/// One answer to a clarifying question (AI-034). [selected] shows the chosen
/// one with the theme's tint and 2 dp border (no check mark, so the chip
/// keeps its width, A45 D2); [isDefault] marks the answer assumed if the
/// user doesn't pick, with a text label (not colour alone).
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
///
/// A food shows its name only. A saved meal passes an [icon] so it reads
/// differently from a food; the "add" chip carries a plus. [semanticLabel]
/// is what a screen reader says instead of the bare name ("Log Labaneh"): the
/// app supplies the words. A long name is cut with an ellipsis, so one chip
/// never fills the row.
class FbQuickAddChip extends StatelessWidget {
  /// A chip with a label and an optional leading [icon].
  const new({
    required this.label,
    required this.onTap,
    this.icon,
    this.semanticLabel,
    super.key,
  });

  /// A chip with a leading plus: "add this".
  const new add({
    required this.label,
    required this.onTap,
    this.semanticLabel,
    super.key,
  }) : icon = FbIcons.add;

  /// The item name.
  final String label;

  /// Called on tap.
  final VoidCallback onTap;

  /// A leading icon; null for a plain food chip.
  final IconData? icon;

  /// What a screen reader says for the chip; the label when null.
  final String? semanticLabel;

  /// The widest a label may be: 180 dp at the normal text size, growing with
  /// the text size, and never more than 70% of the screen.
  double _maxLabelWidth(BuildContext context) {
    final scaled = MediaQuery.textScalerOf(context).scale(180);
    return math.min(scaled, MediaQuery.sizeOf(context).width * 0.7);
  }

  @override
  Widget build(BuildContext context) {
    final chip = ActionChip(
      label: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _maxLabelWidth(context)),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      onPressed: onTap,
      avatar: icon == null ? null : Icon(icon, size: 18),
    );
    final semantics = semanticLabel;
    if (semantics == null) return chip;
    return Semantics(
      label: semantics,
      button: true,
      excludeSemantics: true,
      onTap: onTap,
      child: chip,
    );
  }
}

/// A chip naming what the next action applies to, with a ✕ that cancels
/// it: Buddy's "Updating Breakfast card ✕" above the composer (AI-044,
/// UX-023). [clearTooltip] is the ✕'s tooltip and screen-reader label.
class FbTargetChip extends StatelessWidget {
  /// The chip.
  const new({
    required this.label,
    required this.clearTooltip,
    required this.onClear,
    super.key,
  });

  /// What it applies to.
  final String label;

  /// The ✕'s (already translated) tooltip.
  final String clearTooltip;

  /// Called by the ✕.
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => InputChip(
    avatar: const Icon(FbIcons.edit, size: 18),
    label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    onDeleted: onClear,
    deleteIcon: const Icon(FbIcons.close, size: 18),
    deleteButtonTooltipMessage: clearTooltip,
  );
}
