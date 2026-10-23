import 'package:fb_design_system/l10n/gen/fb_localizations.dart';
import 'package:fb_design_system/src/tokens/icons.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

/// A key on [FbNumberPad].
@immutable
sealed class NumberPadKey {
  const new();

  /// A digit key, 0 to 9.
  const factory digit(int digit) = NumberPadDigit;

  /// The decimal point.
  static const NumberPadKey decimal = NumberPadDecimal();

  /// Deletes the last character.
  static const NumberPadKey backspace = NumberPadBackspace();
}

/// A digit key.
final class NumberPadDigit extends NumberPadKey {
  /// Creates the key for [digit] (0 to 9).
  const new(this.digit) : assert(digit >= 0 && digit <= 9, 'digit');

  /// The digit.
  final int digit;

  @override
  bool operator ==(Object other) =>
      other is NumberPadDigit && other.digit == digit;

  @override
  int get hashCode => digit;
}

/// The decimal point key.
final class NumberPadDecimal extends NumberPadKey {
  /// Creates the key.
  const new();

  @override
  bool operator ==(Object other) => other is NumberPadDecimal;

  @override
  int get hashCode => 1;
}

/// The backspace key.
final class NumberPadBackspace extends NumberPadKey {
  /// Creates the key.
  const new();

  @override
  bool operator ==(Object other) => other is NumberPadBackspace;

  @override
  int get hashCode => 2;
}

/// The pure state behind a number pad (AI-040): the text typed so far and the
/// rules for the next key. Immutable: [apply] returns the next buffer.
///
/// - At most [maxDigits] digits before the decimal point and [maxDecimals]
///   after it.
/// - One decimal point. Pressing it first gives `0.`.
/// - No leading zeros (`0` then `5` is `5`).
/// - Empty text has no [value].
@immutable
class NumberPadBuffer {
  /// A buffer holding [text] (which must already follow the rules).
  const new({this.maxDigits = 4, this.maxDecimals = 1, this.text = ''})
    : assert(maxDigits > 0, 'maxDigits'),
      assert(maxDecimals >= 0, 'maxDecimals');

  /// The most digits before the decimal point.
  final int maxDigits;

  /// The most digits after the decimal point. 0 disallows the point.
  final int maxDecimals;

  /// What was typed, with `.` as the decimal point. Display it as is; the
  /// app formats separators for its locale.
  final String text;

  /// The number, or null when nothing was typed.
  double? get value => text.isEmpty ? null : double.tryParse(text);

  /// True when nothing was typed.
  bool get isEmpty => text.isEmpty;

  /// The buffer after [key]. Keys the rules reject return this buffer.
  NumberPadBuffer apply(NumberPadKey key) => switch (key) {
    NumberPadDigit(:final digit) => _digit(digit),
    NumberPadDecimal() => _decimal(),
    NumberPadBackspace() => _backspace(),
  };

  NumberPadBuffer _with(String next) => NumberPadBuffer(
    maxDigits: maxDigits,
    maxDecimals: maxDecimals,
    text: next,
  );

  NumberPadBuffer _digit(int digit) {
    final point = text.indexOf('.');
    if (point >= 0) {
      return text.length - point - 1 >= maxDecimals
          ? this
          : _with('$text$digit');
    }
    if (text == '0') return _with('$digit');
    return text.length >= maxDigits ? this : _with('$text$digit');
  }

  NumberPadBuffer _decimal() {
    if (maxDecimals == 0 || text.contains('.')) return this;
    return _with(text.isEmpty ? '0.' : '$text.');
  }

  NumberPadBuffer _backspace() =>
      text.isEmpty ? this : _with(text.substring(0, text.length - 1));
}

/// A calm 3x4 number pad (AI-040). It only emits keys: feed them to a
/// [NumberPadBuffer]. The layout keeps phone-keypad order in both text
/// directions. [onDone] confirms.
class FbNumberPad extends StatelessWidget {
  /// Creates the pad. Set [allowDecimal] false to disable the point key.
  const new({
    required this.onKey,
    required this.onDone,
    this.allowDecimal = true,
    super.key,
  });

  /// Called for every key press.
  final ValueChanged<NumberPadKey> onKey;

  /// Called when "Done" is pressed.
  final VoidCallback onDone;

  /// Whether the decimal point key is enabled.
  final bool allowDecimal;

  @override
  Widget build(BuildContext context) {
    final l10n = FbLocalizations.of(context);
    Widget digit(int d) => _PadKey(
      label: '$d',
      semanticLabel: '$d',
      onTap: () => onKey(NumberPadKey.digit(d)),
    );
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in const [
            [1, 2, 3],
            [4, 5, 6],
            [7, 8, 9],
          ])
            Row(children: [for (final d in row) digit(d)]),
          Row(
            children: [
              _PadKey(
                label: '.',
                semanticLabel: l10n.fbNumberPadDecimal,
                onTap: allowDecimal ? () => onKey(NumberPadKey.decimal) : null,
              ),
              digit(0),
              _PadKey(
                icon: FbIcons.backspace,
                semanticLabel: l10n.fbNumberPadBackspace,
                onTap: () => onKey(NumberPadKey.backspace),
              ),
            ],
          ),
          const SizedBox(height: FbSpace.s2),
          SizedBox(
            width: double.infinity,
            // Tonal, not filled: the sheet's own primary button (Add, Save)
            // stays the one dominant action (UX-021).
            child: FilledButton.tonal(
              onPressed: onDone,
              child: Text(l10n.fbDone),
            ),
          ),
        ],
      ),
    );
  }
}

class _PadKey extends StatelessWidget {
  const new({
    required this.semanticLabel,
    required this.onTap,
    this.label,
    this.icon,
  });

  final String? label;
  final IconData? icon;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = onTap == null ? scheme.onSurfaceVariant : scheme.onSurface;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(FbSpace.s1),
        child: Semantics(
          button: true,
          enabled: onTap != null,
          label: semanticLabel,
          excludeSemantics: true,
          onTap: onTap,
          child: Material(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(FbRadius.md),
            child: InkWell(
              borderRadius: BorderRadius.circular(FbRadius.md),
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Center(
                  child: icon != null
                      ? Icon(icon, color: color)
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            label!,
                            style: FbType.headline.copyWith(color: color),
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

/// One unit the user can pick (g, ml, piece, ...).
@immutable
class FbUnitOption {
  /// Creates an option: a stable [id] and an already translated [label].
  const new({required this.id, required this.label});

  /// Stable identifier the caller maps back to its unit.
  final String id;

  /// What the user sees.
  final String label;
}

/// A row of units, one selected (AI-040).
class FbUnitPicker extends StatelessWidget {
  /// Creates the picker. [selected] is an [FbUnitOption.id].
  const new({
    required this.units,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  /// The choices.
  final List<FbUnitOption> units;

  /// The id of the chosen unit.
  final String selected;

  /// Called with the id of the tapped unit.
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: FbSpace.s2,
    runSpacing: FbSpace.s2,
    children: [
      for (final unit in units)
        Semantics(
          label: unit.label,
          selected: unit.id == selected,
          button: true,
          excludeSemantics: true,
          onTap: () => onSelected(unit.id),
          child: ChoiceChip(
            label: Text(unit.label),
            selected: unit.id == selected,
            onSelected: (_) => onSelected(unit.id),
          ),
        ),
    ],
  );
}
