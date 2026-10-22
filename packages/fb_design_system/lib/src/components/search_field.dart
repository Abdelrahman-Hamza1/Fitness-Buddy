import 'package:fb_design_system/l10n/gen/fb_localizations.dart';
import 'package:fb_design_system/src/tokens/icons.dart';
import 'package:material_ui/material_ui.dart';

/// A single-line search box (FD-020): a magnifier at the start, a clear
/// button at the end while there is text, the keyboard's search action.
///
/// The field only edits [controller] and reports changes; searching is the
/// caller's job. It has no autocorrect or suggestions, since food names are
/// often in Arabic or Arabizi. Everything is start/end, so it mirrors in
/// right-to-left layouts.
class FbSearchField extends StatelessWidget {
  /// Creates a search field. [hint] is the (already translated) text shown
  /// while the field is empty; it is also what a screen reader announces.
  const new({
    required this.controller,
    required this.hint,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.focusNode,
    super.key,
  });

  /// The text being edited.
  final TextEditingController controller;

  /// The hint shown while the field is empty.
  final String hint;

  /// Called on every edit, and with an empty string when the clear button
  /// empties the field.
  final ValueChanged<String>? onChanged;

  /// Called when the keyboard's search action is pressed.
  final ValueChanged<String>? onSubmitted;

  /// Whether the field takes focus (and opens the keyboard) when shown.
  final bool autofocus;

  /// An optional focus node, e.g. to keep the keyboard open after clearing.
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final l10n = FbLocalizations.of(context);
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const ExcludeSemantics(child: Icon(FbIcons.search)),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => value.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  tooltip: l10n.fbSearchClear,
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
