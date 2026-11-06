import 'package:fb_design_system/l10n/gen/fb_localizations.dart';
import 'package:fb_design_system/src/components/dashed_input_border.dart';
import 'package:fb_design_system/src/components/supporting_line.dart';
import 'package:fb_design_system/src/tokens/icons.dart';
import 'package:material_ui/material_ui.dart';

/// A labelled text field (D18): a [label] that floats above the text, an
/// optional length limit with a counter, a clear button while there is text,
/// and one reserved supporting line under the field (UX-045, A57 D12): the
/// [supportingText] or, in its place, the [errorText], with the counter at
/// its end. The line is [supportingLines] lines tall whatever it shows, so
/// nothing moves when an error appears or wraps; 0 reserves nothing.
///
/// The field only edits [controller] and reports changes; what the text means
/// is the caller's job. It reads label, text, counter and error as one text
/// field for a screen reader. Layout is start/end only, so it mirrors in
/// right-to-left layouts.
///
/// [hideLabel] drops the visible label where a header above names the
/// column (A63 D15); the label stays the field's spoken name.
/// [dashedWhenEmpty] draws a dashed outline while the field is empty and
/// unfocused, for a [hint] that is only a suggestion.
class FbTextField extends StatelessWidget {
  /// Creates a text field.
  const new({
    required this.controller,
    required this.label,
    this.maxLength,
    this.errorText,
    this.hint,
    this.supportingText,
    this.supportingLines = 1,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.keyboardType,
    this.autofocus = false,
    this.focusNode,
    this.enabled = true,
    this.textDirection,
    this.hideLabel = false,
    this.dashedWhenEmpty = false,
    super.key,
  });

  /// The text being edited.
  final TextEditingController controller;

  /// The (already translated) name of the field.
  final String label;

  /// The most characters that can be typed. When set, a "typed/max" counter
  /// is shown and the field stops accepting more.
  final int? maxLength;

  /// Why the text is not acceptable. Shown in the supporting line, in the
  /// error colour, and the field gets the error outline.
  final String? errorText;

  /// Shown while the field is empty.
  final String? hint;

  /// A hint shown in the supporting line while there is no error.
  final String? supportingText;

  /// How many lines the supporting line reserves (0 = none).
  final int supportingLines;

  /// Called on every edit, and with an empty string when the clear button
  /// empties the field.
  final ValueChanged<String>? onChanged;

  /// Called when the keyboard's action button is pressed.
  final ValueChanged<String>? onSubmitted;

  /// The keyboard's action button (done, next, ...).
  final TextInputAction? textInputAction;

  /// The kind of keyboard.
  final TextInputType? keyboardType;

  /// Whether the field takes focus when shown.
  final bool autofocus;

  /// An optional focus node.
  final FocusNode? focusNode;

  /// Whether the text can be edited.
  final bool enabled;

  /// The direction of the typed text, for a field that always holds one
  /// script (an Arabic name is right-to-left in an English screen). Null
  /// follows the surrounding layout.
  final TextDirection? textDirection;

  /// Whether the label is only spoken, not shown.
  final bool hideLabel;

  /// Whether an empty, unfocused field has a dashed outline.
  final bool dashedWhenEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = FbLocalizations.of(context);
    final dashed = dashedWhenEmpty ? fbDashedEnabledBorder(context) : null;
    var field = dashed == null
        ? _field(l10n, dashed: null)
        : ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) =>
                _field(l10n, dashed: value.text.isEmpty ? dashed : null),
          );
    if (hideLabel) field = Semantics(label: label, child: field);
    if (supportingLines == 0) return field;
    final limit = maxLength;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        field,
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => FbSupportingLine(
            text: supportingText,
            errorText: errorText,
            lines: supportingLines,
            counter: limit == null
                ? null
                : '${value.text.characters.length}/$limit',
          ),
        ),
      ],
    );
  }

  Widget _field(FbLocalizations l10n, {required InputBorder? dashed}) =>
      TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        enabled: enabled,
        textDirection: textDirection,
        maxLength: maxLength,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        // The counter is drawn in the supporting line, not under the field.
        buildCounter: (
          context, {
          required currentLength,
          required isFocused,
          required maxLength,
        }) => null,
        decoration: InputDecoration(
          labelText: hideLabel ? null : label,
          hintText: hint,
          enabledBorder: dashed,
          // The outline shows the error; the message is in the line.
          error: errorText == null ? null : const SizedBox.shrink(),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => value.text.isEmpty || !enabled
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: l10n.fbTextFieldClear,
                    icon: const Icon(FbIcons.close),
                    onPressed: () {
                      controller.clear();
                      onChanged?.call('');
                    },
                  ),
          ),
        ),
      );
}
