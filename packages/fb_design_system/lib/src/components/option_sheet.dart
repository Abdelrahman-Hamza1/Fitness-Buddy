import 'package:fb_design_system/src/components/sheet.dart';
import 'package:fb_design_system/src/tokens/icons.dart';
import 'package:material_ui/material_ui.dart';

/// One choice of [showFbOptionSheet]: the [value] it returns, its (already
/// translated) [label] and an optional muted [subtitle].
class FbOption<T> {
  /// Creates a choice.
  const new({required this.value, required this.label, this.subtitle});

  /// What the sheet returns when this choice is tapped.
  final T value;

  /// The main text.
  final String label;

  /// A second, muted line.
  final String? subtitle;
}

/// The rows of an option sheet: one tappable row per option, the [selected]
/// one checked and announced as selected, so the check mark does not carry
/// the state alone. [onSelected] gets the tapped option's value.
class FbOptionList<T> extends StatelessWidget {
  /// Creates the rows.
  const new({
    required this.options,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  /// The choices, in order.
  final List<FbOption<T>> options;

  /// The current choice, or null when none is.
  final T? selected;

  /// Called with the value of the tapped option.
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final option in options)
        ListTile(
          contentPadding: EdgeInsetsDirectional.zero,
          title: Text(option.label),
          subtitle: option.subtitle == null ? null : Text(option.subtitle!),
          trailing: option.value == selected
              ? const ExcludeSemantics(child: Icon(FbIcons.check))
              : null,
          selected: option.value == selected,
          onTap: () => onSelected(option.value),
        ),
    ],
  );
}

/// Shows a bottom sheet with one tappable row per option and returns the
/// value of the one the user taps, or null when the sheet is dismissed.
///
/// It is a [showFbSheet], so it opens on the root navigator, above the app
/// shell and its Undo snackbar.
Future<T?> showFbOptionSheet<T>(
  BuildContext context, {
  required String title,
  required List<FbOption<T>> options,
  required T? selected,
}) => showFbSheet<T>(
  context,
  title: title,
  builder: (context) => FbOptionList<T>(
    options: options,
    selected: selected,
    onSelected: (value) => Navigator.of(context).pop(value),
  ),
);
