import 'package:fb_design_system/src/components/digits.dart';
import 'package:fb_design_system/src/components/number_pad.dart';
import 'package:fb_design_system/src/tokens/icons.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:flutter/services.dart';
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
    this.onKey,
    this.onSubmit,
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

  /// A hardware keyboard types into the amount while it has focus (A57
  /// A61): digits (Western, Arabic-Indic, Persian), `.`/`,`/`٫` and
  /// Backspace become pad keys.
  final ValueChanged<NumberPadKey>? onKey;

  /// Enter on a hardware keyboard (usually the pad's Done).
  final VoidCallback? onSubmit;

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    final onKey = this.onKey;
    if (onKey == null || event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.backspace) {
      onKey(NumberPadKey.backspace);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      onSubmit?.call();
      return onSubmit == null ? KeyEventResult.ignored : KeyEventResult.handled;
    }
    final char = event.character;
    if (char == null || char.length != 1) return KeyEventResult.ignored;
    if (char == '.' || char == ',' || char == '\u066b') {
      onKey(NumberPadKey.decimal);
      return KeyEventResult.handled;
    }
    final digit = int.tryParse(normalizeDigits(char));
    if (digit == null) return KeyEventResult.ignored;
    onKey(NumberPadKey.digit(digit));
    return KeyEventResult.handled;
  }

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
      // Keys from the box (or its tappable InkWell) reach [_onKeyEvent].
      child: Focus(
        canRequestFocus: onKey != null,
        onKeyEvent: _onKeyEvent,
        child: Builder(
          builder: (focusContext) => Material(
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
              onTap: onTap == null
                  ? null
                  : () {
                      // Tapping also takes the keyboard (A61).
                      if (onKey != null) Focus.of(focusContext).requestFocus();
                      onTap!();
                    },
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
        ),
      ),
    );
  }
}
