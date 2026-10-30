import 'package:material_ui/material_ui.dart';

/// A row with a [title], an optional [subtitle] and a checkbox at the start
/// (an explicit acknowledgement, like "I understand and want to use
/// 1,300 kcal a day", SF-012).
///
/// The whole row is the touch target and one checkbox for a screen reader,
/// which hears the title, the subtitle and whether it is checked. The
/// checkbox sits at the start and mirrors in right-to-left layouts. A null
/// [onChanged] disables the row.
class FbCheckboxRow extends StatelessWidget {
  /// Creates a row.
  const new({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    super.key,
  });

  /// The main text.
  final String title;

  /// A second, muted line.
  final String? subtitle;

  /// Whether the box is checked.
  final bool value;

  /// Called with the new value on a tap. Null disables the row.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => CheckboxListTile(
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle!),
    value: value,
    controlAffinity: ListTileControlAffinity.leading,
    onChanged: onChanged == null ? null : (v) => onChanged!(v ?? false),
  );
}
