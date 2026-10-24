import 'package:fb_design_system/l10n/gen/fb_localizations.dart';
import 'package:fb_design_system/src/tokens/icons.dart';
import 'package:material_ui/material_ui.dart';

/// A labelled text field (D18): a [label] that floats above the text, an
/// optional length limit with a counter, a clear button while there is text,
/// and an [errorText] shown under the field.
///
/// The field only edits [controller] and reports changes; what the text means
/// is the caller's job. It reads label, text, counter and error as one text
/// field for a screen reader. Layout is start/end only, so it mirrors in
/// right-to-left layouts.
class FbTextField extends StatelessWidget {
  /// Creates a text field.
  const new({
    required this.controller,
    required this.label,
    this.maxLength,
    this.errorText,
    this.hint,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.keyboardType,
    this.autofocus = false,
    this.focusNode,
    this.enabled = true,
    this.textDirection,
    super.key,
  });

  /// The text being edited.
  final TextEditingController controller;

  /// The (already translated) name of the field.
  final String label;

  /// The most characters that can be typed. When set, a "typed/max" counter
  /// is shown and the field stops accepting more.
  final int? maxLength;

  /// Why the text is not acceptable. Shown under the field, in the neutral
  /// error colour.
  final String? errorText;

  /// Shown while the field is empty.
  final String? hint;

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

  @override
  Widget build(BuildContext context) {
    final l10n = FbLocalizations.of(context);
    return TextField(
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
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        errorMaxLines: 3,
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
}
