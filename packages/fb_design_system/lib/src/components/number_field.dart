import 'package:fb_design_system/l10n/gen/fb_localizations.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Keeps digits and at most one decimal separator, with at most
/// [maxDecimals] digits after it.
///
/// Both `.` and `,` (and the Arabic decimal mark) are accepted as the
/// separator, because the keyboard decides which one a person gets. Western
/// and Arabic-Indic digits are kept. Anything else (a minus sign, a space,
/// a letter, a second separator) is dropped as it is typed or pasted, so the
/// field can never hold something that is not a plain nonnegative number.
/// What the digits mean is the caller's job.
class FbDecimalInputFormatter extends TextInputFormatter {
  /// Creates a formatter that allows [maxDecimals] digits after the
  /// separator.
  const new({this.maxDecimals = 2})
    : assert(maxDecimals >= 0, 'maxDecimals is not negative');

  /// The most digits after the decimal separator.
  final int maxDecimals;

  static bool _isDigit(int unit) =>
      (unit >= 0x30 && unit <= 0x39) ||
      (unit >= 0x660 && unit <= 0x669) ||
      (unit >= 0x6f0 && unit <= 0x6f9);

  static bool _isSeparator(int unit) =>
      unit == 0x2e || unit == 0x2c || unit == 0x66b;

  String _keep(String text) {
    final kept = StringBuffer();
    var seenSeparator = false;
    var decimals = 0;
    for (final unit in text.codeUnits) {
      if (_isDigit(unit)) {
        if (seenSeparator) {
          if (decimals == maxDecimals) continue;
          decimals++;
        }
        kept.writeCharCode(unit);
      } else if (_isSeparator(unit) && !seenSeparator && maxDecimals > 0) {
        seenSeparator = true;
        kept.writeCharCode(unit);
      }
    }
    return kept.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = _keep(newValue.text);
    if (text == newValue.text) return newValue;
    // The rule reads left to right, so the characters that survive before
    // the caret are exactly the filtered prefix.
    final before = newValue.selection.baseOffset.clamp(0, newValue.text.length);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: _keep(newValue.text.substring(0, before)).length,
      ),
    );
  }
}

/// A labelled numeric field (D16): a [label] that floats above the number,
/// a [unit] shown after it ("g", "kcal"), a decimal keyboard and an input
/// filter that only lets a plain nonnegative number through
/// ([FbDecimalInputFormatter], at most [maxDecimals] decimals), and an
/// [errorText] shown under the field.
///
/// The field only edits [controller] and reports changes; what the number
/// means (its range, a conversion) is the caller's job, so the caller keeps
/// the text as typed. A screen reader reads "label, value unit". Layout is
/// start/end only, so it mirrors in right-to-left layouts.
class FbNumberField extends StatelessWidget {
  /// Creates a number field.
  const new({
    required this.controller,
    required this.label,
    this.unit,
    this.maxDecimals = 2,
    this.errorText,
    this.hint,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.autofocus = false,
    this.focusNode,
    this.enabled = true,
    this.semanticLabel,
    super.key,
  });

  /// The number being edited, as text.
  final TextEditingController controller;

  /// The (already translated) name of the field.
  final String label;

  /// The (already translated) unit shown after the number, e.g. "g".
  final String? unit;

  /// The most digits after the decimal separator.
  final int maxDecimals;

  /// Why the number is not acceptable. Shown under the field, in the neutral
  /// error colour.
  final String? errorText;

  /// Shown while the field is empty.
  final String? hint;

  /// Called on every edit.
  final ValueChanged<String>? onChanged;

  /// Called when the keyboard's action button is pressed.
  final ValueChanged<String>? onSubmitted;

  /// The keyboard's action button (done, next, ...).
  final TextInputAction? textInputAction;

  /// Whether the field takes focus when shown.
  final bool autofocus;

  /// An optional focus node.
  final FocusNode? focusNode;

  /// Whether the number can be edited.
  final bool enabled;

  /// What a screen reader reads instead of [label], when two fields share
  /// a visible label and only their place tells them apart.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = FbLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        // One field for a screen reader: "Protein, 12 g".
        final reading = [
          value.text,
          ?unit,
        ].where((part) => part.isNotEmpty).join(' ');
        final name = semanticLabel ?? label;
        return Semantics(
          label: reading.isEmpty
              ? name
              : l10n.fbNumberFieldSemantics(name, reading),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: autofocus,
            enabled: enabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: textInputAction,
            inputFormatters: [
              FbDecimalInputFormatter(maxDecimals: maxDecimals),
            ],
            style: FbType.numeric(FbType.body),
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            decoration: InputDecoration(
              // Read once, in the label above, with the number and its unit.
              label: ExcludeSemantics(child: Text(label)),
              hintText: hint,
              errorText: errorText,
              errorMaxLines: 3,
              suffixText: unit,
              suffixStyle: FbType.body.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        );
      },
    );
  }
}
